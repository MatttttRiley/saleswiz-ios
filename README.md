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
- **Inbox** — every email in the CRM, newest first, with In / Queued /
  Sent / Failed badges and the lead name. Tap a message for the thread
  and reply (the reply is queued — it only sends after Matt approves
  the send). Compose a new email to a lead or a typed address.
- **Interest** — the leads who replied or are marked interested, newest
  first, with the reply snippet. Tap a row for the full lead, including
  the email thread (lead detail has an Emails section too).
- **Call List** (v1.2) — Matt's personal calling list: the 155
  St. George-area numbers, priority first, each with tap-to-call,
  status/priority badges, the last history entry, and an inline outcome
  form (outcome, notes, email, discussion time) that posts to
  `log_call_outcome` — the same endpoint as the web Call List, so an
  "interested" outcome pins the lead to the top and fires the interest
  push.
- **Swipe actions** (v1.2.2) — on the Call List, swipe a card left for
  two quick actions: **Interested** (green) opens the outcome form
  pre-set to interested so notes/email/discussion time can be added —
  saving pins the lead to the top (priority 100, interest push fires);
  **Not interested** (red) asks for confirmation, then logs the outcome
  and flags the lead do-not-call, which removes it from the Call List
  for good (the record stays in the CRM as lost, so it is never
  re-researched or re-added). Swiping right also offers Interested.
- **Copy number** (v1.2.1) — every Call List card and the lead page get
  a Copy button next to the phone number, so the number can be pasted
  into the Google Voice dialer. Matt's business calls go out on his
  Voice number, not his carrier number, so tap-to-call (tel:) alone
  would show the wrong caller ID.
- **Email opens + priority** (v1.2) — leads show a "★ Priority N" badge
  and an "Opened ×N" badge; lead detail shows the priority and
  "Opened — N times · last …" (or "Not opened yet"); the dashboard
  funnel gains an "Emails opened" tile. All from the API fields that
  already existed (`priority`, `open_count`, `opens`,
  `emails_opened`/`opens_total`).

## How it talks to the CRM

Same JSON API as the web UI (`api.php`): `dashboard`, `leads`, `lead`,
`update_lead`, `log_call`, `log_reply`, `record_bounce`, `add_lead`,
`queue_batch`, `actions`, `list_emails`, `interested_leads`,
`queue_email`, `call_list`, `log_call_outcome`. See `../riley-crm/API.md`
for the spec.

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

Tested (Nov 11, 2026, v1.1, against the live endpoint):

- Login with the new password (MattRiley11) works (302 + dashboard 200).
- `list_emails` returns 200 with real rows (id, lead_id, direction,
  from/to, subject, body, gmail_id, received_at, status, error,
  lead_name).
- `interested_leads` returns 200 with `{"ok":true,"leads":[],"total":0}`
  — 0 rows is correct, there are 0 replies so far.
- `queue_email` round-trips live: a row to philbertmail@proton.me came
  back `status: queued`, and the test row was deleted from the CRM
  database seconds later, before the bridge could send it. No mail went
  to any real lead.

Tested (Nov 12, 2026, v1.2, against the live endpoint):

- `call_list` returns 200 with 155 rows; row keys match the app model
  (incl. `priority` and nested `last_history`), order is priority-first.
- `leads` rows carry `priority` + `open_count`; `lead` carries the
  nested `opens {count, first_at, last_at}`; `dashboard` carries
  `emails_opened` + `opens_total` (both 0 today — no tracked opens yet,
  which matches the web dashboard).
- `log_call_outcome` was verified end-to-end on the web side Nov 11
  (throwaway lead, since deleted); it was NOT re-executed from the app
  against the live database.

Not tested (needs a phone):

- The Xcode build itself — there is no macOS/Swift toolchain in this
  sandbox, so compile errors, if any, will surface on the first Actions
  run. The Swift was written against the verified API shapes and reviewed
  line by line, but it has not been compiled yet.
- Anything on a real iPhone: layout, login on-device, tap-to-call,
  Keychain persistence across launches, background session expiry and
  silent re-login, the Inbox and Interest tabs, reply/compose queueing.
  Nothing here is claimed to work on a phone until Matt confirms it on
  his.
- Write endpoints (`log_call`, `log_reply`, `record_bounce`,
  `update_lead`, `add_lead`, `queue_batch`) were verified against the
  server source (`api.php`) but deliberately NOT executed against the live
  database, so no test data pollutes the real CRM.
