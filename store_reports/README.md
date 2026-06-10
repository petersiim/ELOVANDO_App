# Store-Reports: Finanzberichte & Review-Mails via GitHub Actions

Zwei Skripte, die per GitHub Actions laufen — kein eigener Server nötig:

| Skript | Zeitplan | Funktion |
|---|---|---|
| `finance_report_mailer.py` | am 10. jedes Monats | Finanzberichte aus App Store Connect + Google Play als Mail-Anhang |
| `review_notifier.py` | alle 6 Stunden | Neue Rezensionen aus beiden Stores per Mail |

## Setup

### 1. Repo anlegen

Privates GitHub-Repo erstellen und diese Dateien hochladen (Ordnerstruktur beibehalten, v. a. `.github/workflows/`).

### 2. Apple: API-Key erstellen

1. App Store Connect → **Users and Access → Integrations → App Store Connect API** → neuen Key mit Rolle **Finance** erstellen (Finance ist nötig für Finanzberichte und deckt Reviews mit ab).
2. `.p8`-Datei herunterladen (geht nur einmal!), **Key-ID** und **Issuer-ID** notieren.
3. **Vendor-Nummer**: App Store Connect → Payments and Financial Reports, oben links.
4. **App-ID**: App Store Connect → App → App Information → Apple ID (Zahl).

### 3. Google: Service-Account erstellen

1. [Google Cloud Console](https://console.cloud.google.com) → Projekt anlegen → **IAM → Service Accounts** → Service-Account erstellen → JSON-Key herunterladen.
2. APIs aktivieren: **Google Play Android Developer API** (für Reviews).
3. Play Console → **Users and permissions** → Service-Account-E-Mail einladen mit:
   - **View financial data** (global) — für Finanzberichte
   - **Reply to reviews** bzw. App-Zugriff — für Reviews
4. **Bucket-ID**: Play Console → Download reports → Finanzberichte → "Copy Cloud Storage URI" (beginnt mit `pubsite_prod_rev_`, ohne `gs://`-Präfix als Secret speichern).

### 4. Gmail: App-Passwort

1. Google-Konto → 2-Faktor-Authentifizierung aktivieren (falls noch nicht).
2. [App-Passwörter](https://myaccount.google.com/apppasswords) → neues App-Passwort generieren.

### 5. GitHub Secrets setzen

Repo → **Settings → Secrets and variables → Actions** → folgende Secrets anlegen:

| Secret | Inhalt |
|---|---|
| `ASC_KEY_ID` | Apple Key-ID |
| `ASC_ISSUER_ID` | Apple Issuer-ID |
| `ASC_PRIVATE_KEY` | Kompletter Inhalt der `.p8`-Datei |
| `ASC_VENDOR_NUMBER` | Apple Vendor-Nummer |
| `ASC_APP_ID` | Apple App-ID (Zahl) |
| `PLAY_BUCKET_ID` | `pubsite_prod_rev_...` |
| `PLAY_PACKAGE_NAME` | z. B. `com.example.app` |
| `GCP_SERVICE_ACCOUNT_JSON` | Kompletter Inhalt der Service-Account-JSON |
| `MAIL_FROM` | Deine Gmail-Adresse |
| `MAIL_TO` | Empfänger (kommagetrennt für mehrere) |
| `GMAIL_APP_PASSWORD` | Gmail App-Passwort |

### 6. Testen

Repo → **Actions** → Workflow auswählen → **Run workflow** (manueller Start).
Beim Finanzbericht kannst du optional einen Monat (`YYYY-MM`) angeben.

## Hinweise

- **Erster Review-Lauf** verschickt keine Mail, sondern markiert nur alle bestehenden Reviews als gesehen (`seen_reviews.json` wird ins Repo committet).
- **Play Reviews API** liefert nur Reviews der letzten 7 Tage — der 6h-Rhythmus verpasst daher nichts.
- **Apple-Finanzberichte** nutzen Apples Fiskalkalender; der Bericht für einen Monat erscheint ca. am ersten Freitag des Folge-Fiskalmonats. Falls am 10. noch nichts da ist (404), meldet die Mail das als Hinweis — dann manuell mit `Run workflow` nachholen.
- **GitHub-Actions-Cron** kann sich um einige Minuten verzögern; das ist normal.
- Bei Repos ohne Aktivität deaktiviert GitHub geplante Workflows nach 60 Tagen — der Review-Workflow committet aber regelmässig und hält das Repo aktiv.
