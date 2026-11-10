# SalesWiZ — iPhone app

Native SwiftUI app for the Riley AI Consulting CRM (SalesWiZ), the same
data as the web CRM at https://crm.129-146-5-140.sslip.io/. iOS 17+, no
third-party dependencies, no web views.

## What it does

- **Login** — the shared CRM password, stored in the Keychain. The app
  logs in silently on launch and re-logs in on its own if the server
  session expires.
- **Dashboard** — the progress bar (stage-weighted, never fake-filled),
  time-to-first-sale range, funnel counts, money, today's calls and
  follow-ups, and the per-industry funnel.
- **Leads** — search, status and industry filters, pagination, lead detail
  with full history, tap-to-call and tap-to-email.
- **Actions** — today's follow-ups due, the call queue, the next batch of
  20, and one-tap queueing of the next batch.
- **Log a call / log a reply** — outcome, note, follow-up date; change
  status; record a bounce (with confirmation — a bounce can never be
  undone). Add a lead from the Leads tab.

## How it talks to the CRM

Same JSON API as the web UI (`api.php`): `dashboard`, `leads`, `lead`,
`update_lead`, `log_call`, `log_reply`, `record_bounce`, `add_lead`,
`queue_batch`, `actions`. See `../riley-crm/API.md` for the spec.

Auth is the **session cookie**: POST the password to `login.php`, and the
cookie authenticates every API call after that. There is no API token in
this repo and no secret baked into the app — the password lives only in
the Keychain on the phone. The server is HTTPS, so App Transport Security
is happy with the default settings.

## Build

Unsigned IPA via GitHub Actions (macos-26, `CODE_SIGNING_ALLOWED=NO`).
SideStore re-signs it on the phone with your Apple ID.

```sh
xcodebuild -project SalesWiZ.xcodeproj -scheme SalesWiZ \
  -configuration Release -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY="" DEVELOPMENT_TEAM="" build
```

## Tested / untested

Tested (Nov 10, 2026, against the live HTTPS endpoint with real data):

- `dashboard`, `leads` (search + status filter), `lead` detail with
  history, and `actions` all return 200 with the expected shapes — 571
  leads, progress 6% Outreach, ETA 10–26 days, 12 in the call queue.
- Login flow: POSTing the shared password sets a session cookie and the
  dashboard then loads with that cookie; a wrong password stays on the
  login page; no credentials at all gives 401.
- Project structure follows the Dscribe repo's proven unsigned-IPA
  workflow (same macos-26 runner, same packaging steps).

Not tested (needs a phone):

- The Xcode build itself — there is no macOS/Swift toolchain in this
  sandbox, so compile errors, if any, will surface on the first Actions
  run. The Swift was written against the verified API shapes and reviewed
  line by line, but it has not been compiled yet.
- Anything on a real iPhone: layout, login on-device, tap-to-call,
  Keychain persistence across launches, background session expiry and
  silent re-login. Nothing here is claimed to work on a phone until Matt
  confirms it on his.
- Write endpoints (`log_call`, `log_reply`, `record_bounce`,
  `update_lead`, `add_lead`, `queue_batch`) were verified against the
  server source (`api.php`) but deliberately NOT executed against the live
  database, so no test data pollutes the real CRM.
