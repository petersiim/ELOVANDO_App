#!/usr/bin/env python3
"""
Prüft App Store und Google Play auf neue Rezensionen und verschickt sie per
Gmail SMTP. Bereits gemeldete Reviews werden in seen_reviews.json gemerkt
(wird vom GitHub-Actions-Workflow zurück ins Repo committet).

Benötigte Umgebungsvariablen:
  ASC_KEY_ID, ASC_ISSUER_ID, ASC_PRIVATE_KEY   wie beim Finanz-Skript
  ASC_APP_ID                Apple-App-ID (Zahl, in ASC unter App Information)
  PLAY_PACKAGE_NAME         z.B. com.example.app
  GCP_SERVICE_ACCOUNT_JSON  Service-Account-JSON (braucht Play-Console-Zugriff
                            "Replies to reviews" bzw. App-Berechtigung)
  MAIL_FROM, MAIL_TO, GMAIL_APP_PASSWORD
"""

import html
import json
import os
import smtplib
import sys
import time
from email.message import EmailMessage
from pathlib import Path

import jwt  # PyJWT
import requests
from google.oauth2 import service_account
from googleapiclient.discovery import build

ASC_API = "https://api.appstoreconnect.apple.com/v1"
STATE_FILE = Path(__file__).parent / "seen_reviews.json"


def env(name: str) -> str:
    value = os.environ.get(name, "").strip()
    if not value:
        sys.exit(f"FEHLER: Umgebungsvariable {name} fehlt.")
    return value


def load_state() -> dict:
    if STATE_FILE.exists():
        return json.loads(STATE_FILE.read_text(encoding="utf-8"))
    return {"apple": [], "google": []}


def save_state(state: dict):
    # Listen begrenzen, damit die Datei nicht endlos wächst
    state["apple"] = state["apple"][-500:]
    state["google"] = state["google"][-500:]
    STATE_FILE.write_text(json.dumps(state, indent=2), encoding="utf-8")


# ---------------------------------------------------------------- Apple ----

def asc_token() -> str:
    now = int(time.time())
    payload = {
        "iss": env("ASC_ISSUER_ID"),
        "iat": now,
        "exp": now + 19 * 60,
        "aud": "appstoreconnect-v1",
    }
    return jwt.encode(payload, env("ASC_PRIVATE_KEY"), algorithm="ES256",
                      headers={"kid": env("ASC_KEY_ID"), "typ": "JWT"})


def fetch_apple_reviews() -> list:
    url = f"{ASC_API}/apps/{env('ASC_APP_ID')}/customerReviews"
    params = {"sort": "-createdDate", "limit": 50}
    r = requests.get(url, headers={"Authorization": f"Bearer {asc_token()}"},
                     params=params, timeout=60)
    r.raise_for_status()
    reviews = []
    for item in r.json().get("data", []):
        a = item["attributes"]
        reviews.append({
            "id": item["id"],
            "store": "App Store",
            "rating": a.get("rating"),
            "title": a.get("title") or "",
            "body": a.get("body") or "",
            "author": a.get("reviewerNickname") or "",
            "date": a.get("createdDate") or "",
            "extra": a.get("territory") or "",
        })
    return reviews


# --------------------------------------------------------------- Google ----

def fetch_google_reviews() -> list:
    """Hinweis: Die Play-API liefert nur Reviews der letzten 7 Tage."""
    creds_info = json.loads(env("GCP_SERVICE_ACCOUNT_JSON"))
    creds = service_account.Credentials.from_service_account_info(
        creds_info, scopes=["https://www.googleapis.com/auth/androidpublisher"]
    )
    service = build("androidpublisher", "v3", credentials=creds,
                    cache_discovery=False)
    resp = service.reviews().list(
        packageName=env("PLAY_PACKAGE_NAME"), maxResults=100
    ).execute()
    reviews = []
    for item in resp.get("reviews", []):
        comment = item["comments"][0]["userComment"]
        ts = int(comment["lastModified"]["seconds"])
        reviews.append({
            "id": item["reviewId"],
            "store": "Google Play",
            "rating": comment.get("starRating"),
            "title": "",
            "body": comment.get("text", "").strip(),
            "author": item.get("authorName") or "",
            "date": time.strftime("%Y-%m-%d %H:%M", time.gmtime(ts)),
            "extra": comment.get("reviewerLanguage") or "",
        })
    return reviews


# ----------------------------------------------------------------- Mail ----

def format_review(rv: dict) -> str:
    stars = "★" * int(rv["rating"] or 0) + "☆" * (5 - int(rv["rating"] or 0))
    lines = [f"[{rv['store']}] {stars}  {rv['date']}  {rv['extra']}"]
    if rv["author"]:
        lines.append(f"von {rv['author']}")
    if rv["title"]:
        lines.append(f"Titel: {rv['title']}")
    if rv["body"]:
        lines.append(html.unescape(rv["body"]))
    return "\n".join(lines)


def send_mail(new_reviews: list):
    count = len(new_reviews)
    avg = sum(int(r["rating"] or 0) for r in new_reviews) / count
    msg = EmailMessage()
    msg["From"] = env("MAIL_FROM")
    msg["To"] = env("MAIL_TO")
    msg["Subject"] = f"ELOVANDO – {count} neue Review(s) – Ø {avg:.1f}★"
    body = "Neue Rezensionen für die ELOVANDO-App:\n\n" + "\n\n----------------------------------------\n\n".join(
        format_review(r) for r in new_reviews
    )
    msg.set_content(body + "\n\nAutomatisch versendet via GitHub Actions.")
    with smtplib.SMTP_SSL("smtp.gmail.com", 465) as smtp:
        smtp.login(env("MAIL_FROM"), env("GMAIL_APP_PASSWORD"))
        smtp.send_message(msg)
    print(f"Mail mit {count} Review(s) verschickt.")


def main():
    first_run = not STATE_FILE.exists()
    state = load_state()
    new_reviews = []

    for store, key, fn in (("Apple", "apple", fetch_apple_reviews),
                           ("Google", "google", fetch_google_reviews)):
        try:
            for rv in fn():
                if rv["id"] not in state[key]:
                    new_reviews.append(rv)
                    state[key].append(rv["id"])
        except Exception as e:  # noqa: BLE001
            print(f"FEHLER bei {store}: {e}")

    save_state(state)

    if first_run:
        print(f"Erster Lauf: {len(new_reviews)} bestehende Reviews als gesehen "
              "markiert, keine Mail verschickt.")
    elif new_reviews:
        new_reviews.sort(key=lambda r: r["date"], reverse=True)
        send_mail(new_reviews)
    else:
        print("Keine neuen Reviews.")


if __name__ == "__main__":
    main()
