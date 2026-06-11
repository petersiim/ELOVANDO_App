#!/usr/bin/env python3
"""
Lädt die monatlichen Finanzberichte aus App Store Connect und Google Play
und verschickt sie als Anhänge per Gmail SMTP.

Benötigte Umgebungsvariablen (in GitHub Actions als Secrets hinterlegen):
  ASC_KEY_ID            App Store Connect API Key-ID
  ASC_ISSUER_ID         App Store Connect Issuer-ID
  ASC_PRIVATE_KEY       Inhalt der .p8-Datei (kompletter Text inkl. BEGIN/END)
  ASC_VENDOR_NUMBER     Apple Vendor-Nummer (in ASC unter "Payments and Financial Reports")
  PLAY_BUCKET_ID        z.B. pubsite_prod_rev_01234567890987654321
  GCP_SERVICE_ACCOUNT_JSON  Inhalt der Service-Account-JSON-Datei
  MAIL_FROM             Gmail-Adresse (Absender)
  MAIL_TO               Empfänger (kommagetrennt für mehrere)
  GMAIL_APP_PASSWORD    Gmail App-Passwort (https://myaccount.google.com/apppasswords)
"""

import gzip
import io
import json
import os
import smtplib
import sys
import time
from datetime import date, timedelta
from email.message import EmailMessage

import jwt  # PyJWT
import requests
from google.cloud import storage
from google.oauth2 import service_account

ASC_API = "https://api.appstoreconnect.apple.com/v1"


NOTES = []  # Hinweise, die in den Mailtext aufgenommen werden


def env(name: str) -> str:
    value = os.environ.get(name, "").strip()
    if not value:
        sys.exit(f"FEHLER: Umgebungsvariable {name} fehlt.")
    return value


def previous_month() -> str:
    first = date.today().replace(day=1)
    prev = first - timedelta(days=1)
    return prev.strftime("%Y-%m")


# ---------------------------------------------------------------- Apple ----

def asc_token() -> str:
    now = int(time.time())
    payload = {
        "iss": env("ASC_ISSUER_ID"),
        "iat": now,
        "exp": now + 19 * 60,  # max. 20 Minuten
        "aud": "appstoreconnect-v1",
    }
    return jwt.encode(
        payload,
        env("ASC_PRIVATE_KEY"),
        algorithm="ES256",
        headers={"kid": env("ASC_KEY_ID"), "typ": "JWT"},
    )


def fetch_apple_finance_report(report_date: str) -> list:
    """Holt FINANCIAL- und FINANCE_DETAIL-Report für den Fiskalmonat."""
    headers = {"Authorization": f"Bearer {asc_token()}"}
    attachments = []
    variants = [
        ("FINANCIAL", "ZZ"),       # konsolidierter Bericht, alle Regionen
        ("FINANCE_DETAIL", "Z1"),  # Detailbericht (falls verfügbar)
    ]
    for report_type, region in variants:
        params = {
            "filter[reportType]": report_type,
            "filter[regionCode]": region,
            "filter[reportDate]": report_date,
            "filter[vendorNumber]": env("ASC_VENDOR_NUMBER"),
        }
        r = requests.get(f"{ASC_API}/financeReports", headers=headers,
                         params=params, timeout=60)
        if r.status_code == 404:
            print(f"Apple {report_type}: noch nicht verfügbar für {report_date}.")
            continue
        r.raise_for_status()
        data = r.content
        # Antwort ist gzip-komprimierte CSV (a-gzip)
        try:
            data = gzip.decompress(data)
        except OSError:
            pass  # war nicht komprimiert
        name = f"apple_{report_type.lower()}_{report_date}.csv"
        attachments.append((name, data))
        print(f"Apple {report_type}: {len(data)} Bytes geladen.")
    return attachments


# --------------------------------------------------------------- Google ----

def fetch_play_reports(month: str) -> list:
    """Lädt Earnings- und Sales-Reports (YYYY-MM) aus dem GCS-Bucket."""
    yyyymm = month.replace("-", "")
    creds_info = json.loads(env("GCP_SERVICE_ACCOUNT_JSON"))
    creds = service_account.Credentials.from_service_account_info(
        creds_info, scopes=["https://www.googleapis.com/auth/devstorage.read_only"]
    )
    client = storage.Client(credentials=creds, project=creds_info.get("project_id"))
    bucket = client.bucket(env("PLAY_BUCKET_ID"))

    attachments = []
    for folder, stem in (("earnings", "earnings"), ("sales", "salesreport")):
        blobs = list(client.list_blobs(bucket, prefix=f"{folder}/{stem}_{yyyymm}"))
        if not blobs:
            # Zielmonat noch nicht da -> neuesten verfügbaren Report nehmen
            all_blobs = sorted(client.list_blobs(bucket, prefix=f"{folder}/{stem}_"),
                               key=lambda b: b.name)
            if all_blobs:
                blobs = [all_blobs[-1]]
                raise_note = (f"Google Play {folder}: Report für {yyyymm} noch nicht "
                              f"verfügbar, stattdessen neuester angehängt: {blobs[0].name}")
                NOTES.append(raise_note)
                print(raise_note)
            else:
                NOTES.append(f"Google Play {folder}: noch gar keine Reports im Bucket.")
                continue
        for blob in blobs:
            buf = io.BytesIO()
            blob.download_to_file(buf)
            attachments.append((os.path.basename(blob.name), buf.getvalue()))
            print(f"Google Play: {blob.name} ({buf.tell()} Bytes) geladen.")
    return attachments


# ----------------------------------------------------------------- Mail ----

def send_mail(subject: str, body: str, attachments: list):
    msg = EmailMessage()
    msg["From"] = env("MAIL_FROM")
    msg["To"] = env("MAIL_TO")
    msg["Subject"] = subject
    msg.set_content(body)
    for name, data in attachments:
        if name.endswith(".csv"):
            maintype, subtype = "text", "csv"
        else:
            maintype, subtype = "application", "zip"
        msg.add_attachment(data, maintype=maintype, subtype=subtype, filename=name)
    with smtplib.SMTP_SSL("smtp.gmail.com", 465) as smtp:
        smtp.login(env("MAIL_FROM"), env("GMAIL_APP_PASSWORD"))
        smtp.send_message(msg)
    print(f"Mail an {msg['To']} verschickt ({len(attachments)} Anhänge).")


def main():
    month = os.environ.get("REPORT_MONTH") or previous_month()
    print(f"Hole Finanzberichte für {month} ...")
    attachments = []
    errors = []

    for label, fn in (("Apple", fetch_apple_finance_report),
                      ("Google Play", fetch_play_reports)):
        try:
            attachments += fn(month)
        except Exception as e:  # noqa: BLE001
            errors.append(f"{label}: {e}")
            print(f"FEHLER bei {label}: {e}")

    if not attachments and errors:
        sys.exit("Keine Berichte geladen:\n" + "\n".join(errors))

    body = f"Im Anhang die Finanzberichte der ELOVANDO-App für {month}.\n"
    if NOTES or errors:
        body += "\nHinweise/Fehler:\n" + "\n".join(NOTES + errors) + "\n"
    body += "\nAutomatisch versendet via GitHub Actions."
    send_mail(f"ELOVANDO – Store-Finanzberichte {month}", body, attachments)


if __name__ == "__main__":
    main()
