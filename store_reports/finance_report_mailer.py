#!/usr/bin/env python3
"""
Lädt die monatlichen Finanzberichte aus App Store Connect und Google Play
und verschickt sie als Anhänge per Gmail SMTP.

Benötigte Umgebungsvariablen (in GitHub Actions als Secrets hinterlegen):
  ASC_KEY_ID            App Store Connect API Key-ID
  ASC_ISSUER_ID         App Store Connect Issuer-ID
  ASC_PRIVATE_KEY       Inhalt der .p8-Datei (kompletter Text inkl. BEGIN/END)
  ASC_VENDOR_NUMBER     Apple Vendor-Nummer
  PLAY_BUCKET_ID        z.B. pubsite_prod_rev_01234567890987654321
  GCP_SERVICE_ACCOUNT_JSON  Inhalt der Service-Account-JSON-Datei
  MAIL_FROM             Gmail-Adresse (Absender)
  MAIL_TO               Standard-Empfänger
  MAIL_TO_FINANCE       Empfänger für Finanzberichte (optional, sonst MAIL_TO)
  GMAIL_APP_PASSWORD    Gmail App-Passwort
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
from pathlib import Path

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


def apple_fiscal(month: str) -> str:
    """Kalendermonat YYYY-MM -> Apple-Fiskalperiode YYYY-PP.
    Apples Geschaeftsjahr beginnt im Oktober: Okt=P1 ... Feb=P5 ... Mai=P8."""
    y, m = map(int, month.split("-"))
    return f"{y + 1}-{m - 9:02d}" if m >= 10 else f"{y}-{m + 3:02d}"


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


def fetch_apple_finance_report(month: str) -> list:
    """Holt FINANCIAL- und FINANCE_DETAIL-Report (Kalendermonat -> Fiskalperiode)."""
    report_date = apple_fiscal(month)
    print(f"Apple: Kalendermonat {month} = Fiskalperiode {report_date}")
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
            note = f"Apple {report_type}: Bericht für {month} (Fiskalperiode {report_date}) noch nicht verfügbar."
            NOTES.append(note)
            print(note)
            continue
        r.raise_for_status()
        data = r.content
        try:
            data = gzip.decompress(data)
        except OSError:
            pass  # war nicht komprimiert
        name = f"apple_{report_type.lower()}_{month}.csv"
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
                note = (f"Google Play {folder}: Report für {yyyymm} noch nicht "
                        f"verfügbar, stattdessen neuester angehängt: {blobs[0].name}")
                NOTES.append(note)
                print(note)
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
    msg["To"] = os.environ.get("MAIL_TO_FINANCE", "").strip() or env("MAIL_TO")
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


PENDING_FILE = Path(__file__).parent / "pending_retry"


def main():
    month = os.environ.get("REPORT_MONTH") or previous_month()
    # Lauf am 10. = Hauptlauf; Lauf ab dem 15. (also der 20.) = zweiter Versuch,
    # der nur stattfindet, wenn beim Hauptlauf etwas gefehlt hat.
    retry_run = date.today().day >= 15 and not os.environ.get("REPORT_MONTH")
    if retry_run:
        if not PENDING_FILE.exists():
            print("Zweiter Versuch nicht nötig – beim Hauptlauf war alles aktuell.")
            return
        month = PENDING_FILE.read_text().strip() or month

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

    incomplete = bool(NOTES or errors)
    subject = f"ELOVANDO – Store-Finanzberichte {month}"
    body = f"Im Anhang die Finanzberichte der ELOVANDO-App für {month}.\n"
    if retry_run:
        subject += " (2. Versuch)"
        body = (f"Zweiter Versuch: Im Anhang die Finanzberichte der "
                f"ELOVANDO-App für {month}.\n")
    if NOTES or errors:
        body += "\nHinweise/Fehler:\n" + "\n".join(NOTES + errors) + "\n"
    if incomplete and not retry_run:
        body += ("\nMindestens ein Bericht war noch nicht aktuell – am 20. "
                 "dieses Monats folgt automatisch ein zweiter Versuch.\n")
        PENDING_FILE.write_text(month)
    elif incomplete and retry_run:
        body += ("\nAuch beim zweiten Versuch war noch nicht alles aktuell – "
                 "der nächste reguläre Lauf ist am 10. des Folgemonats.\n")
        PENDING_FILE.unlink(missing_ok=True)
    else:
        PENDING_FILE.unlink(missing_ok=True)
    body += "\nAutomatisch versendet via GitHub Actions."
    send_mail(subject, body, attachments)


if __name__ == "__main__":
    main()
