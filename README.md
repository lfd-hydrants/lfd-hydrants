# LFD Hydrant Testing System — Master File

This is the living roadmap for the project. Keep it updated as things change —
anyone (including a future Claude conversation) should be able to read this and
pick up exactly where things left off.

## What this is

A digital replacement for the paper hydrant-testing spreadsheet. Crews log flow
tests, condition checks, and snow removal in the field; the chief gets live
visibility, stats, and exportable reports/backups.

## Current status (as of this build)

- ✅ Database schema created (`sql/001_initial_schema.sql`)
- ✅ Sample/placeholder data for testing (`sql/002_seed_sample_data.sql`)
- ✅ Session timing model updated to real timestamps (`sql/003_session_start_end_timestamps.sql`)
- ✅ Jobs vs. shifts model added (`sql/004_jobs_multi_day_tracking.sql`)
- ✅ Real-fleet test data — 12 companies, 4 divisions, 50 members, 80 hydrants (`sql/005_real_fleet_test_data.sql`)
- ✅ Company login + job integrity (`sql/006_company_login_and_job_integrity.sql`) —
  adds `access_code` to companies, `snow_status` to hydrant_tests
- ✅ Hydrant division assignment (`sql/007_hydrant_division_assignment.sql`) —
  **correction**: hydrants belong to a permanent Company + Division pair (a
  portion of a company's list is permanently assigned to each of the 4
  groups), not just a company. Jobs are scoped by Company + Division +
  Activity again to match this. The original cross-division concern is
  instead solved by making "done" checking **global** — a hydrant is
  marked complete for its OWNING division's job the moment anyone logs a
  test against it (e.g. via the manual "search all hydrants" field),
  regardless of which company/division/crew actually recorded it.
- ✅ Campaigns + admin tiers (`sql/008_campaigns_and_admin_tiers.sql`):
  - **Campaigns** — an umbrella above jobs. Auto-created the moment the
    first company/division starts a job for an activity type (named
    e.g. "Flow Test — started March 2026"), and every other
    company/division's job for that same activity automatically joins
    it while it's open. No manual setup required, though a chief can
    rename or manually pre-create one from the Campaigns tab.
  - **Chief-level companies** (`companies.is_chief`) — C1 (Chief of
    Department), C2 (Deputy Chief), and C4 (District Chief) are seeded
    as chief-level. Logging in as one skips the normal company
    hydrant-testing flow entirely and goes to a cross-company chief
    dashboard.
  - **Personal admin login** (`super_admins` table) — a login not tied
    to any company, for troubleshooting. Default seeded account:
    username `admin`, password `changeme2026` — **change this
    immediately** from Settings → Personal Admin Login once deployed.
  - **Snow Removal status split** — `snow_cleared_status`
    (cleared/not_cleared) and `snow_condition_flag` (damaged/oos) are
    now independent, so a hydrant can be marked Cleared AND Damaged at
    the same time. The old single `snow_status` column from migration
    006 is no longer written to (harmless, unused).
- ✅ **Major app update** (`app/index.html`):
  - **Chief dashboard** (Campaigns / Reports / Log / Stats / Settings
    tabs) for chief-level and personal admin logins. Regular company
    logins only see Home / Log — Stats and Admin/Settings are no
    longer visible to them.
  - **Campaigns tab** — browse open/closed campaigns, click into one
    for a district-wide rollup: overall % complete, a sortable-by-read
    table of every company/division's progress, hydrants tested in
    the last 7 days, rename, close/reopen.
  - **Reports tab** — company + division sub-tabs, a sortable table
    (click any column header) of every hydrant with its latest test
    data (condition, wet/dry, flow, static/residual, last tested), a
    "flagged only" toggle, and a **Custom CSV Export** card — filter
    by date range, company, division, activity type, wet/dry, and
    status/condition, export everything matching with all columns.
  - **Searchable OIC/crew pickers** on Start Shift / Shift Settings —
    type a few letters to filter instead of scrolling a long dropdown.
  - **"Edit Shift" renamed to "Shift Settings"**, and its button is now
    visually distinct (neutral styling) from the red "End Shift"
    button next to it.
  - **Hydrant picker** now offers both a browsable dropdown (all
    hydrants, with company/division shown) and a search box, in
    addition to the normal pending-list dropdown. Company/division
    context only shows on the manual picker, not the regular list.
  - **Snow Removal screen**: Cleared/Not Cleared is one toggle pair;
    Damaged/OOS is a separate, independent flag that can be combined
    with either — notes appear if Not Cleared or a flag is set.
- ✅ **Major rebuild of `app/index.html`**:
  - **Login is now company-based**, not individual accounts — pick a
    Company, enter its shared password, then pick which Division is
    working today. Under the hood this uses Supabase's anonymous auth
    (so Row Level Security still works) plus an app-level password
    check against `companies.access_code` — there's no per-person
    Supabase Auth account anymore.
  - **Jobs are scoped to Company + Division + Activity**, matching how
    hydrants are actually permanently assigned. Two open jobs can't exist
    for the same company+division+activity at once (enforced at the
    database level) — the original "wrong division's list" concern is
    solved by checking done-ness globally (by hydrant + activity type,
    not by which job recorded it), so a hydrant tested by the wrong
    crew still correctly clears off its real owning division's list.
  - **Company Home screen**: shows all open jobs for the logged-in
    company (Resume / End Shift / Close Job Permanently), a "recently
    closed, tap to reopen" section (14-day window) for jobs closed by
    mistake, a "recently ended, tap to reopen" list per job for shifts
    ended by mistake, a Start New Job flow, and the District Hydrant
    Checklist.
  - **End Shift vs. Close Job Permanently** are now distinct: End Shift
    saves/pauses and keeps the job open for the next crew (any day);
    Close Job Permanently is separate and intended for when the whole
    list is done.
  - **Activity-specific entry screens**: Flow Test keeps the full form
    (defaults: outlet size 2.5, Wet/Dry defaults to Dry); Condition
    Check is simplified to a Wet/Dry toggle + Good/Repair/OOS buttons
    with notes only appearing if Repair or OOS is picked; Snow Removal
    is simplified to Cleared/Not Cleared/Damaged/OOS buttons with notes
    only appearing if Not Cleared or Damaged is picked.
  - **Manual "search all hydrants"** field on every entry screen, so a
    hydrant can be logged even if it's not on the current job's own
    company list — since pending/done status is computed by matching
    hydrant + activity type (not restricted to the recording company),
    this correctly marks it done wherever it actually belongs.
  - **Edit Shift** now allows changing Division, OIC, crew, and date.
    Company and Activity are intentionally NOT editable post-start,
    since those define which job the shift belongs to — this is a
    consequence of the company+activity job-scoping fix above, and
    starting a new job from Company Home is the correct path if the
    activity was picked wrong.
  - **District Hydrant Checklist**: full ordered hydrant list with a
    checkmark per hydrant for the selected activity type, for visual
    route planning.
  - Admin tab now includes an editable **Company Login Codes** section.
  - Log, Stats, and CSV export updated to handle Condition Check and
    Snow Removal entries alongside Flow Test.
- ✅ Deployed live at `https://lfd-hydrants.vercel.app` (auto-redeploys on GitHub push)
- ⏳ Real hydrant / member / company CSVs — not loaded yet (using sample data)
- ⏳ ISO/state fire marshal format — pending chief's input
- ⏳ Photos — not built yet
- ⏳ Auto-emailed backups — not built yet
- ⏳ Scheduled ping (keep Supabase awake) — not built yet
- ⏳ QR codes, map view — not built yet
- ✅ Deployed live at `https://lfd-hydrants.vercel.app` (auto-redeploys on GitHub push)
- ⏳ **Role-based permissions are UI-only, not database-enforced** — every
  "chief-only" feature (Status tab repairs, Settings, editing campaigns,
  Company Login Code, everything) is only hidden from regular company
  logins by which buttons the app chooses to render. The database itself
  (Supabase RLS) treats every signed-in session as equally trusted, since
  login runs through one shared anonymous connection rather than real
  individual accounts — see "Security note on the company-login model"
  below. Anyone with basic browser dev-tools knowledge could bypass the
  UI and read/write anything directly. This is a bigger gap than when
  this note was first written, since there's now meaningfully more
  chief-only surface area than there used to be. **Worth fixing before
  handing this to the full department**, not just before "real rollout"
  in the abstract.

## Build history

### "Unable to Test" (this session) — requires migration 020

- **`sql/020_unable_to_test.sql`** — adds `unable_to_test` to
  `hydrant_tests`.
- **Flow Test gets an explicit "Unable to Test" checkbox**, since
  Condition alone isn't a reliable signal for whether testing was
  actually possible — OOS usually means untestable, but "Needs Repair"
  often doesn't (a leak or missing cap usually doesn't stop a valid
  test). When checked: the missing-reading warning is skipped
  entirely, and the entry is excluded from Stats' Incomplete
  Inspections list — because it's not an oversight, it's an accurate
  report that testing wasn't possible.
  - Selecting **OOS** auto-checks it as a sensible default (OOS
    structurally means the hydrant can't deliver water), but it stays
    fully editable — a crew can uncheck it if they got a reading
    anyway, or check it manually for a "Needs Repair" hydrant where
    testing genuinely wasn't possible.
  - Also editable from the Log's edit modal for Flow Test entries, for
    consistency.

### Incomplete inspection warning + tracking list (this session) — no new SQL

- **Flow Test now validates before saving**: if Static, Residual, or
  Pitot is left blank, a warning shows exactly which readings are
  missing, with two choices — **"Go Back & Complete"** (returns to the
  form to finish it) or **"Save Incomplete & Continue"** (a deliberate
  manual bypass, so an unusual situation in the field never blocks the
  crew from moving on to the next hydrant). No schema change — those
  fields were already nullable, this is purely a client-side check.
- **Stats → Incomplete Inspections**: a new card, matching the
  existing Overdue-for-Retest pattern exactly — total count, a
  per-company breakdown table, and a PDF export. Shows every hydrant
  whose **most recent** flow test is missing a reading (including ones
  saved via the bypass above). If a hydrant gets properly retested
  later, it naturally drops off this list — nothing needs resetting.
- Also fixed a latent bug while in this code: Stats' main data fetch
  was using a plain unpaginated query, which could have silently
  truncated at 1,000 rows as `hydrant_tests` grows (same class of bug
  fixed for hydrants earlier). Switched to the already-paginated
  `fetchAllHydrantTestsWithSession()` helper used elsewhere.

### Report-only logins (this session) — requires migration 019

- **`sql/019_report_only_logins.sql`** — adds `skip_list_assignment`
  to `companies`.
- For units that report hydrants but never test them (EMS, Communications,
  Fire Prevention, etc.), a company can now be flagged so its login
  **skips Division + List selection entirely** and lands straight on
  Company Home — unchanged itself; they just use Report Hydrant /
  Master Hydrant List / Log from there like anyone else. "Open Work"
  and "Start New Job" simply show empty for these logins since they
  never create jobs, but nothing prevents them from working if ever
  needed.
- **Settings**: Add Company has a new "Report-only login" checkbox,
  and a new **Report-Only Logins** card lets this be toggled for any
  existing company too.
- Combined with the Company Emails feature from earlier, each flagged
  party gets its own login and its own confirmation CC when it reports
  a hydrant — no shared credentials needed between different reporting
  units.

### Company emails on Report Hydrant (this session) — requires migration 018

- **`sql/018_company_emails.sql`** — adds an `email` column to
  `companies`.
- **Settings → Company Emails** (chief-only, matches the pattern for
  Report Hydrant Email Recipients) — one email field per company.
- **Report Hydrant now CC's the reporting company's own email** on the
  notification draft, as a verifying copy — alongside the fixed 2-3
  recipients (District Chief, Water & Sewer, LFD Water Liaison) who
  always get the "To." If a company doesn't have an email set, the
  report still goes out to the fixed recipients as before — nothing
  breaks, the CC is just skipped.

### "Complete List" option + single Wet checkbox (this session) — requires migration 017

- **`sql/017_complete_list_option.sql`** — widens what a `jobs.block`
  value can be (adding `'ALL'` alongside `A`/`B`/`C`/`D`) so a crew can
  work through their **entire company roster in one sitting** instead
  of navigating block by block. Real hydrants are untouched — a
  hydrant is still always permanently assigned to a real A/B/C/D block;
  this only widens what a *job* can be scoped to.
  - New **"Complete [Company] List"** button on the List-select screen,
    alongside A/B/C/D.
  - Doesn't affect campaign or status tracking at all — completion math
    is based on each hydrant's real block and test history, not which
    job scope happened to log the entry, so entries logged under a
    Complete List job still count correctly toward each real block's
    progress everywhere else (Campaign Detail, Master Hydrant List,
    Reports).
  - Displays as "Complete List" everywhere a list/block would normally
    show (header, Hydrant Entry screen) rather than a confusing "List
    ALL".
- **Wet/Dry simplified to a single "Wet?" checkbox** (assumed dry
  unless checked) across Flow Test, Condition Check, and the Log's
  edit modal — one tap instead of picking between two options every
  time, since dry is the default assumption. No schema change; the
  underlying `wet_dry` value is still stored exactly as `'wet'` or
  `'dry'`, so nothing downstream (Reports, Master Hydrant List,
  exports) needed to change.

### Real database-enforced access control + Suggested Next Stop (this session) — requires migration 015 + manual Supabase setup

**This is the big one, and it requires a manual step in the Supabase
Dashboard that I can't do from here — read all the way through before
deploying, since nobody can reach the chief dashboard until the manual
step is done.**

- **`sql/015_access_control.sql`** — replaces the old model (every
  "chief-only" restriction was just which buttons the app chose to
  show) with real database-enforced rules:
  - Regular companies are **unchanged** — still fully open to read/
    write hydrants, tests, jobs, sessions, campaigns citywide. That
    was a deliberate decision from earlier in this project, not
    something this migration touches.
  - Only genuinely admin-level actions are now locked down at the
    database level: Settings, campaign editing/closing (not
    creation — a company's first job still auto-creates one),
    company management (Add Company, login codes), and specifically
    **Mark Repaired**.
  - Mark Repaired is locked down by its exact signature — a
    `hydrant_tests` row with `condition='good'` and no `session_id`.
    Normal field entries always have a session_id; Report Hydrant
    never logs 'good'. So this one specific shape requires a
    privileged account, while every other kind of entry (including a
    company logging Damaged/OOS through completely normal means)
    stays exactly as open as it always was.
- **Login model simplified**: C1/C2/C4's individual chief logins are
  retired. In their place: **one shared "Admin" login** for district
  chiefs day-to-day, plus the existing hidden deeper-tier login (kept
  hidden, just renamed). Both are now **real Supabase Auth accounts**
  — genuinely verified by the database when someone signs in, not an
  app-level string comparison anyone with dev tools could bypass.
  - The hidden login's username still never appears anywhere in the
    app's source code (same property the old hidden `admin` login
    had) — it's looked up dynamically against a small lookup table
    instead of being hardcoded.
  - Regular company login is **completely unchanged** — still the
    shared anonymous session + app-level password check. That was
    never the actual security gap.
- **Settings cleanup**: removed the now-obsolete "Chief Login Codes"
  and "Chief-Level Access" cards (companies no longer have any
  chief/non-chief distinction — that's handled entirely by the new
  real-auth accounts now). Add Company simplified to just a name
  field.
- **Suggested Next Stop** — text only, no map, no turn-by-turn (all
  explicitly ruled out during design). A card at the top of all three
  entry forms showing the next pending hydrant in the list's current
  order, with a one-tap Accept button. Pulls from whatever order the
  pending list already has — today that's hydrant-number order;
  later, if GPS-based loop ordering gets built, this card starts using
  that automatically with no changes needed to the feature itself.
  The existing manual search/dropdown is untouched as the override
  path for deviating from the suggestion.

### Deploying this update — READ BEFORE RUNNING

1. Run `sql/015_access_control.sql` in Supabase SQL Editor.
2. **Do the manual setup at the bottom of that file before deploying
   the new `index.html`** — create two real accounts in Supabase
   Dashboard → Authentication → Users (the shared Admin login, and
   your renamed hidden login), then register their user IDs via the
   SQL snippet the file provides. Full step-by-step instructions are
   in the file itself.
3. Test both logins on the *current* (old) `index.html` first if
   possible, or budget for a short window where chief access is down
   between running this SQL and finishing the manual setup — until
   both accounts exist and are registered, nobody can reach the chief
   dashboard, including via the old C1/C2/C4 credentials (which stop
   working the moment this SQL runs, since the RLS policies change
   immediately).
4. Once both privileged logins are confirmed working, replace
   `index.html` on GitHub and tell every district chief the new shared
   Admin password. The old individual C1/C2/C4 passwords no longer do
   anything.

### Real member roster (this session) — requires migration 014

- **`sql/014_real_member_roster.sql`** — imports the real 176-member
  department roster, replacing the placeholder test names ("FF Test
  001" etc). Names were cleaned from the source file: the trailing
  `#`/`##` markers and the "(you)" tag were stripped per confirmation,
  and the redundant "FF" suffix was dropped (real ranks — Lieutenant,
  Captain, District Chief — are kept, since those stay part of the
  display name; there's no separate rank column, matching how simple
  the OIC/crew search picker is meant to stay).
  - **Read the warning comment in the file before running** — it
    clears the `members` table first. Any shifts already logged
    against the old placeholder test names will keep their historical
    entries intact (the foreign key doesn't cascade-delete), but those
    old entries' OIC/crew names will show blank once the placeholder
    rows are gone, since the names only ever lived in `members`. Worth
    exporting a backup first if any of that test-era history needs to
    stay readable.

### Log filter fix: respects sticky-flag status, not stale per-row data (this session) — no new SQL

- **Bug fix, directly caused by the sticky-flag logic added last session**: Log's "Needs Attention" filter (and the Damaged/OOS filters) used to check each individual entry's own condition — meaning a hydrant's old flagged rows would keep showing up under Needs Attention forever, even after a chief marked it repaired, since nothing told Log that hydrant's overall status had changed.
- **Fixed**: those filters now check each hydrant's **current computed status** (same worst-since-reset logic used everywhere else), not the row's own historical fields. Once a hydrant is marked back in service, none of its rows — old or new — show up under Needs Attention/Damaged/OOS anymore.
- Renamed the remaining per-row filters (Good/Wet/Dry/Cleared/Not Cleared) to say "(this entry)" in the dropdown, to make clear those are point-in-time facts about that specific visit, not the hydrant's current state — distinguishing them from the now-current-status-based filters.

### Structural reorganization: sticky flags, Status→Log merge, lean Reports, Campaigns dropdown, flexible email list, Stats drill-down (this session) — no new SQL

- **Sticky flag status logic (real behavior change)**: once any company logs a hydrant as Damaged or OOS, that stays the hydrant's displayed status — even if a different company later logs a routine "Good" test on it — until a **chief explicitly clears it** via Mark Repaired. The badge shown is the **worst status since the last reset**; if the most recent flag differs from that worst one, it's shown as secondary text ("Most recent: Damaged, Aug 12") so nothing gets buried. Applies everywhere status is computed: Master Hydrant List, Hydrant Detail, Log, and the Master List Snapshot export.
- **Status tab removed, folded into Log** — its chief-only quick actions (Set Damaged / Set OOS / Mark Repaired) now live inside Log's edit-entry modal, shown only to chief logins, only on entries that are currently flagged.
- **List-select screen** (the screen between picking Division and List) now has **All Hydrants** and **Report Hydrant** buttons, so neither requires committing to a specific list first.
- **Master Hydrant List**: added Status and Wet/Dry filters, plus a Sort By dropdown (Hydrant #, Address, Company, List, Status).
- **Reports tab rebuilt from scratch — much leaner.** Click a company to add it to a selected list (with a × to remove); empty selection = citywide. Good/Damaged/OOS toggle chips narrow further. Output is deliberately minimal: **Hydrant #, Address, Date Last Checked** — a "who needs a look" list, not a data dump. Activity-based reporting (Flow Test/Condition Check/Snow Removal breakdowns) lives in Campaigns instead, where it already existed. The richer Master List Snapshot (status + flow data) stays exactly where it was, unchanged in shape.
- **Campaigns**: closed campaigns switched from a card list to a searchable typeahead dropdown — type or browse, select one, and it opens the existing Campaign Detail view (Edit / Close / Export CSV+PDF all already live there).
- **Settings → Report Hydrant Email Recipients**: changed from 3 fixed named fields to a real add/remove list — type an email, hit Add; each entry has a × to remove. Stored as a single comma-separated setting rather than 3 separate keys.
- **Stats redesigned**: Today/Week/Month cards no longer show a raw "Shifts" count — instead, a row of clickable company shorthand chips (E1, L2, etc.) for whoever was active that period; tapping one opens exactly what they logged in that window. Added **Hours & Man-Hours by Campaign** (open campaigns) alongside the existing by-Company breakdown, plus an "All Companies" grand-total row on the by-Company table.
- Confirmed **Report Hydrant never creates or touches a campaign** — it only ever inserts a single standalone `hydrant_tests` row, exactly as intended.
- Confirmed **per-activity summaries already only show relevant fields** — Snow Removal's form never captures Wet/Dry in the first place, so it was never displaying there; no change needed, just verified.

### Not done this session — flagged for a dedicated pass
- **Real database-level access control** (per-company/chief Supabase accounts, RLS enforcement) — deliberately not rushed into this same sweep, since a mistake here could lock out the whole department; needs its own careful, testable session.
- **CSV/PDF format documentation** — a written spec of every report's exact columns.
- **Admin tab reorganization** — revisit now that Status is gone and Reports is leaner; the remaining 5 tabs (Campaigns/Reports/Log/Stats/Settings) may already be in better shape, worth a fresh look.
- **General "everything editable where practical" audit.**
- **Wipe Training Data script** — still pending an actual training date.

### Offline fillable sheets + auto-import (this session) — no new SQL, 2 new CDN libraries

- **The problem this solves**: iPads normally have connectivity, but if
  one drops signal, the web app itself becomes unreachable (nothing's
  cached for true offline use — see the earlier discussion on why full
  offline sync is a much bigger build). So the fix is a fillable PDF
  that lives on the device **before** connectivity ever becomes an
  issue, entirely independent of the app or internet.
- **Settings → Offline Sheets → "Generate All (ZIP)"** (chief-only) —
  produces one real fillable PDF per Company + List (e.g. "Engine
  1-List-A.pdf"), bundled into a single ZIP. Each sheet has a header
  (Activity, Date, OIC, Division, Crew) and a row per hydrant with
  fields for Static/Residual/Pitot/Gauge readings, Condition, Wet/Dry,
  Snow Cleared/Flag, and Notes — covering all 3 activity types in one
  sheet, since the header's Activity selection determines how each
  row gets interpreted later. **Distribution is manual and outside the
  app** — AirDrop, email, cable, whatever's normal — done ahead of
  time, not generated in the moment of losing signal.
  - Built with **pdf-lib** (new CDN dependency) so the fields are real
    AcroForm form fields, not flat visual blanks — fillable natively
    in iOS's Files/Preview app (or Adobe, PDF Expert, etc.), which
    actually stores structured values rather than freehand markup.
  - Each hydrant's fields are secretly tagged with its database ID
    (not its hydrant number), so import matching is exact regardless
    of number formatting or duplicates.
  - Bulk ZIP packaging via **JSZip** (new CDN dependency).
- **Company Home → "Import Offline Sheet"** — upload the completed
  PDF; the app reads the form field values directly (no retyping),
  shows a review summary (company/list/activity/date/OIC/division/
  crew-matched/row-count) with warnings for anything that couldn't be
  matched (e.g. an OIC name that doesn't match current members), then
  on confirm: finds-or-creates the matching job (and campaign, same
  logic as a normal Start Shift), creates one shift already marked
  closed (start/end both stamped at import time, since the real
  offline start/end time isn't captured on paper), and inserts one
  `hydrant_tests` row per filled-in hydrant row — using the same fixed
  Testing Settings (coefficient/outlet size/# outlets) and flow
  formula as live entry.
  - **Known limitation**: since real offline start/end times aren't
    captured, imported shifts don't have a `total_minutes` value —
    they won't contribute to the Man-Hours stat. Worth noting if that
    becomes a real gap.

### Master List Snapshot report + Division/List export bug fix (this session) — no new SQL

- **Master List Snapshot** — a new report type: one row per hydrant
  (not a transaction log), showing its **current status color**
  (Good/Damaged/OOS, same logic as the Master Hydrant List's dots),
  last interaction date (any activity type), and its **most recent
  Flow Test data** (static/residual/pitot/flow/flow-at-20psi) even if
  that wasn't the latest thing logged for it. Available as CSV or PDF
  from **two places**:
  - **Reports tab** — new "Master List Snapshot" card, scoped by the
    same company chip selection used for the existing Custom Export.
  - **Master Hydrant List** screen — export buttons right there,
    exporting exactly whatever's currently filtered/shown on screen.
- **Bug fix**: the Custom Export (CSV/PDF) and Campaign Detail's
  CSV/PDF export were still querying hydrants' old `division_id`
  field for their "Division" column — which has been unused since the
  List/Block correction, so that column was showing blank/wrong data.
  Fixed to pull `block` instead, and the column is now correctly
  labeled "List" in all four export functions.

### Location notes, fixed flow-test settings, gauge reading, Report Hydrant (this session) — requires migrations 012 + 013

- **New migrations**:
  - `sql/012_notes_gauge_reporting_columns.sql` — adds
    `hydrants.location_notes`, `hydrant_tests.gauge_flow_gpm`, and
    `hydrant_tests.reported_by_company_id`.
  - `sql/013_backfill_location_notes.sql` — backfills the "Location
    Notes" data from the original spreadsheet (1,612 hydrants have
    notes) — this got missed in the first real-data import and is
    matched back in by `hydrant_number`, which is globally unique.
- **Location Notes now shown on every entry screen** — once a hydrant
  is selected (Flow Test, Condition Check, or Snow Removal), its
  location notes appear right under the picker with a pencil icon to
  edit them inline if they need correcting.
- **Flow Test form simplified** — Outlet Size, Discharge Coefficient,
  and # of Outlets are no longer per-entry fields. They're now fixed
  values set once in Settings → Testing Settings and applied to every
  flow calculation automatically; companies can't change them per test.
- **Gauge Flow Reading (GPM)** — optional field on the Flow Test form
  for a gauge's direct flow measurement. Purely informational — shown
  alongside the calculated flow in the Log and Hydrant Detail history,
  never used in the flow/drop/flow-at-20psi calculations.
- **Report Hydrant** — a new button on Company Home for flagging a
  hydrant on sight (e.g. spotted damaged while driving by), with no job
  or shift required. Search the hydrant, mark Damaged or Out of
  Service, add notes, submit. Records which company reported it and
  opens a pre-filled email (`mailto:`) to whichever recipients are set
  in Settings → Report Hydrant Email Recipients (District Chief,
  Water & Sewer Rep, LFD Water Liaison) — the officer still has to hit
  Send themselves; this doesn't email automatically without that click,
  since there's no email-sending service wired up (deliberately kept
  this way — see the option-A/option-B tradeoff discussed when this was
  designed). No cost either way — a `mailto:` link is just a normal web
  standard, not a paid service.

**Deploying this update:**
1. Run `sql/012_notes_gauge_reporting_columns.sql`
2. Run `sql/013_backfill_location_notes.sql`
3. Replace `index.html` on GitHub
4. Go to Settings → Testing Settings and confirm Outlet Size / # Outlets
   are set correctly (defaults: 2.5 / 1) — these now apply to every
   flow test department-wide
5. Go to Settings → Report Hydrant Email Recipients and fill in the
   three addresses

### Real hydrant data + List (block) assignment correction — requires migrations 010 + 011

**This is the big one — real hydrant data goes live, and a structural
correction to how hydrant lists are assigned.**

- **CORRECTION: hydrants are assigned by "List" (A/B/C/D), not by
  Division.** The department's actual model: each company's hydrant
  roster is permanently split into 4 lists (tied to the address), and
  the captain assigns whichever crew/Division is on duty to work a
  given list for a given task — the pairing is flexible, decided task
  by task, not fixed. Division (Group 1-4) stays exactly as it was —
  still selected at login, still recorded per shift for time tracking —
  it just no longer determines which hydrants show up. That's now
  driven by List instead.
  - New `hydrants.block` column (`A`/`B`/`C`/`D`) — the permanent
    assignment, replacing the incorrect use of `division_id` for this
    from earlier sessions.
  - New `jobs.block` column — jobs are now scoped by
    **Company + List + Activity**, not Company + Division + Activity.
    The database-level uniqueness constraint moved to match.
  - **Login flow gets a third step**: Company → Division (unchanged) →
    **"Which list are you assigned?"** (pick A/B/C/D) — that list's
    hydrants become the job's pending list. A **"Change List"** button
    on Company Home lets a crew switch lists without a full re-login
    (e.g. captain reassigns them mid-shift).
  - Every screen that showed Division alongside a hydrant (Master
    Hydrant List, hydrant search/picker, Campaign Detail's breakdown
    table, the Status tab) now shows **List** instead — Division still
    appears where it's actually about the crew/shift (Shift Settings,
    the hydrant entry header's crew info line).
- **Real hydrant data imported** — 1,856 hydrants from the department's
  actual master flow-test spreadsheet, replacing all placeholder test
  data. See `sql/011_real_hydrant_import.sql` for the full list and
  data-quality notes (264 hydrants had no number in the source sheet
  and got sequential `TBD-####` placeholders; a couple of numbers that
  collided across two companies got a `-b` suffix on the second
  occurrence). **This migration wipes all hydrant_tests, sessions,
  jobs, and campaigns** — anything logged during testing so far is
  gone. Companies, divisions, members, and settings are untouched.

**Deploying this update:**
1. Run `sql/010_hydrant_block_assignment.sql`
2. Run `sql/011_real_hydrant_import.sql` — **read the warning in that
   file first**; it clears all test activity data
3. Replace `index.html` on GitHub

### Status tab, colorblind symbols, chip-based exports (earlier session) — no new SQL

- **New "Status" tab** (chief-level dashboard) — a filtered problem list
  showing only currently Damaged or Out of Service hydrants, department-
  wide (wet/dry has no effect on this list, matching the Master Hydrant
  List's status logic). Each entry shows quick action buttons right on
  the card: **Set Damaged**, **Set OOS**, or **Mark Repaired** — no need
  to open the detail view first, though "View History" is still one tap
  away if needed. Every status change is logged as a new entry (session_id
  null, a note explaining who/why), preserving full history rather than
  overwriting anything.

- **Master Hydrant List** (replaces the old "District Hydrant Checklist" —
  same nav entry, same Company/Division/See-All scoping, but now
  color-coded by actual hydrant condition instead of job-completion
  checkmarks): 🟢 Good, 🟡 Damaged (but working), 🔴 Out of Service. A
  hydrant with no entries yet is assumed Good. Status comes from each
  hydrant's most recent entry that actually specifies a condition or
  damage flag — wet/dry is intentionally NOT a factor. Visible to
  everyone (company and chief logins alike).
- **Hydrant Detail view** — clicking any hydrant (from the Master List)
  shows its full test history: every static/residual/pitot reading and
  calculated flow, condition, wet/dry, snow status, and notes, across
  every activity type, newest first.
- **"Mark Repaired — Back In Service" is now chief/admin-only**, lives
  exclusively on the Hydrant Detail view (only shown to chief-level
  logins, only when status isn't already Good). Removed entirely from
  the Log's edit-entry modal — there's now one clear path, matching the
  "confirmed by Water & Sewer" workflow.
- **Campaigns tab**: "Create Campaign" moved here from Settings (a
  "+ Create Campaign" button at the top). Open campaigns now also have
  an **Edit** button — rename, and adjust which companies are scoped in;
  activity type is locked once created (jobs already reference it).
- **Reports → Custom Export**: Wet/Dry and Status/Condition switched
  from dropdowns to multi-select toggle chips with an "All" option, so
  multiple values (e.g. Needs Repair + OOS together) can be pulled in
  one export instead of running it repeatedly.
- **Log's "Needs Attention" default** no longer includes Wet — only
  genuinely bad statuses (Needs Repair, OOS, Not Cleared, Damaged) show
  by default now.
- **Stats**: added a **Today** card matching This Week / This Month
  (shifts, hours, man-hours, entries). Added **Man-Hours** everywhere
  hours are shown — crew size × shift duration, summed (OIC counts as
  part of the crew). **Overdue for Retest** is now a total count + a
  per-company breakdown table (Engines-first order) instead of a raw
  hydrant list on screen — the full detailed list still lives in the
  PDF export, which is now also sorted by company the same way.
- **Hydrant Entry header** now shows the campaign name (when the job
  belongs to one) alongside two progress figures: this job's own
  completion (e.g. "23/46 complete") and the campaign's citywide
  completion (e.g. "50% — 250/500 complete").
- **Same-day crew resume prompt**: resuming a job with no currently-open
  shift now checks whether the last shift under it was closed *today*.
  If so, a quick prompt offers to continue with the same OIC/crew/
  division (skipping straight to hydrant entry) or start fresh via the
  normal Shift Settings screen.

## Previous build — requires migration 009

- **New migration**: `sql/009_campaign_company_scope.sql` — adds
  `campaigns.company_ids` (nullable array) so a manually-created campaign
  can optionally be scoped to specific companies. NULL/empty = all
  companies, which is what auto-created campaigns still use.
- **Login overhaul**: Company field is now a searchable typeahead (type or
  click to browse) instead of a plain text box with browser-native
  autocomplete — no more remembered/auto-filled previous entries.
- **One shared login code for all non-chief companies** (Settings →
  Company Login Code), stored in `app_settings`. Chief-level companies
  (C1/C2/C4) keep their own individual passwords (Settings → Chief Login
  Codes). Add Company now defaults its login code field to the shared
  code, and unlocks it for a custom entry only when "Chief-level access"
  is checked.
- **Back button at the top of every sub-page**, company side and chief
  side alike (Activity Picker, Start/Edit Shift, Hydrant Entry, District
  Checklist, Campaign Detail) — no more hunting for a link at the bottom
  of a card.
- **District Hydrant Checklist reworked**: defaults to the signed-in
  company + division instead of the full citywide list; Company and
  Division dropdowns let you view any other one; a "See All Hydrants
  (Citywide)" button resets to the full list. Now also reachable from the
  chief dashboard (via the Reports tab), where it defaults to citywide
  since chiefs aren't tied to one company/division.
- **Log: "Mark Repaired — Back In Service"** — editing a flagged entry
  (Needs Repair/OOS/Damaged/Not Cleared) now offers this as a separate
  action from Save Changes. It inserts a brand-new "good" entry rather
  than overwriting history, so the record still shows exactly when it
  broke and when it was fixed.
- **Stats: Overdue list gets a PDF export** — formatted list with
  hydrant/address/assigned company, for handing off or printing.
- **Campaigns list** (chief dashboard) now shows live **% complete** and
  **Damaged/OOS quick counts** right on each open campaign's row, plus a
  **Close Campaign** button directly in the list (not just inside detail).
  Closing a campaign (from the list or from Campaign Detail) now sets its
  end date to the **actual last hydrant entry**, not the moment someone
  clicked Close.
- **Campaign Detail**: removed "View in Reports"; added direct **Export
  CSV** and **Export PDF** buttons scoped to that campaign's own data. The
  "By Company / Division" table now sorts Engines first (numerically),
  then Ladders, then everything else — not alphabetically.
- **Reports tab is now filter-and-export only** — the row-by-row hydrant
  table has been removed entirely (it doesn't scale past a few hundred
  hydrants). What's left: a summary card (counts only), company toggle
  chips in a wrapped grid (multi-select + "All Companies"), activity
  chips, a "Flagged only" filter, and Custom Export (CSV + PDF).
- **Settings → Create Campaign** — manually pre-create a campaign with a
  name, activity type, and a company multi-select that defaults to all
  companies selected (uses the new `company_ids` column).

- **Login fields hardened against browser autofill** — the Company and
  Password fields use a readonly-until-focus trick plus obscured field
  names, since `autocomplete="off"` alone doesn't reliably stop browsers
  from suggesting saved logins or offering to remember the password.
  Same searchable dropdown+type behavior as before, just no more
  browser-suggested previous entries.

### Unsaved-work warnings, PWA install, colorblind dots, log date filter — no new SQL, 2 new files

- **Warn before losing unsaved work** — the three hydrant entry forms and
  Shift Settings now track unsaved changes and prompt ("You have unsaved
  changes. Leave without saving?") before navigating away via the top
  back button, End Shift, switching tabs, or signing out. Also guards
  against an accidental browser tab close/refresh via `beforeunload`.
- **Home-screen install (PWA)** — two new files, `manifest.json` and
  `sw.js` (a minimal pass-through service worker, no offline caching
  since the app needs a live Supabase connection anyway), plus icon
  files `icon-192.png` and `icon-512.png`. Opening the site now offers
  "Add to Home Screen" / "Install" like a real app, with an actual icon
  — these are simple placeholder icons (dark background, red stripe,
  "LFD" text) generated for this build; swap them out anytime for a
  proper department logo by replacing the two PNG files.
- **Colorblind-safe status indicators** — Good/Damaged/OOS status dots
  and badges (Master Hydrant List, Hydrant Detail, Status tab) now show
  a symbol (✓ / ! / ✕) in addition to color, so status doesn't rely on
  color perception alone.
- **Date range filter on the Log tab** — From/To date fields alongside
  the existing Company/Status/Hydrant# filters.

### Deploying this update

Along with replacing `index.html`, this update adds **three new files**
that must also be uploaded to the repo root (same folder as `index.html`):
`manifest.json`, `sw.js`, `icon-192.png`, `icon-512.png`.

## Previous build — no new SQL, app-level only

- **Dates display as MM/DD/YYYY** everywhere in the UI (CSV/PDF exports
  still use YYYY-MM-DD for spreadsheet sortability — flag if you'd rather
  those match too).
- **Log tab overhaul**: entries are clickable to reopen an edit form
  matching their activity type and save changes directly; plain "Wet/Dry:"
  text replaced with a simple green/red tag scheme (Good/Dry/Cleared =
  green, everything else = red); status filter now covers every activity
  type and **defaults to "Needs Attention"** (hides Good/Dry/Cleared).
- **Stats tab redesigned** around operational/time metrics (This Week/This
  Month shifts, hours, entries logged, hours by company) since Campaigns
  and Reports now cover hydrant-condition rollups better than Stats did.
- **Settings tab flags unsaved changes** — editing a field highlights that
  card's Save button until it's actually saved.
- **Campaign Detail shows the full department picture from day one** —
  every company/division with hydrants for that activity shows up (0% /
  "not started" if they haven't begun), not just companies already working.
- **Campaigns list has Year and Activity Type filters.**
- **PDF export** added alongside CSV — same filters, formatted/searchable,
  suitable to hand directly to Water & Sewer (via jsPDF, loaded from CDN).
- **Settings → Add Company** — create a new company (name + login code +
  optional chief flag) directly from the app, no SQL needed.

## Accounts

- **Supabase project**: `byddmktjldogehwhapog` (URL: `https://byddmktjldogehwhapog.supabase.co`)
- **GitHub org**: `lfd-hydrants`
- Both under a dedicated department email (not tied to any individual's personal account)

## Architecture

- **Database**: Supabase (Postgres) — see `sql/001_initial_schema.sql` for the full structure
- **App**: a single static HTML file (`app/index.html`) using the Supabase JS
  client directly from a CDN — no build step, no framework. Simple on purpose:
  easy for a future developer to read top-to-bottom.
- **Auth**: Supabase Auth (email/password). Every crew member needs their own
  login. RLS (row-level security) currently allows any authenticated user full
  access — this is intentionally loose for early testing and MUST be tightened
  before real deployment (see "Next steps").

## SQL file naming convention

Every SQL migration file follows `00N_short-description.sql` — the number
preserves run order (each one may depend on earlier ones), the description
says what it does at a glance. Next ones in line will likely be something like
`003_add_photo_storage.sql`, `004_tighten_rls_admin_roles.sql`, etc.

## ⚠️ Before real rollout — change the default admin password

Migration 008 seeds a personal admin login with username `admin` and
password `changeme2026`. This account can see and edit everything.

Login for this account is now intentionally invisible in the UI — there's
no "Admin Login" button anymore. Typing `admin` into the Company field
(instead of a real company name) and the matching password signs in as
this account instead. Since the Settings tab's password-editing UI for
this account was also removed (by request, to keep it fully hidden), the
only way to change this password now is directly in Supabase:

```sql
update super_admins set access_code = 'your-new-password' where username = 'admin';
```

Do this from the SQL Editor as soon as the deploy is confirmed working.

## Security note on the company-login model

Since login is now a shared password per company (not individual Supabase
Auth accounts), the underlying database access uses Supabase's **anonymous
auth** — every visitor becomes an "authenticated" (anonymous) Supabase user
automatically, and the actual company gate is enforced only at the app
level (checking the entered password against `companies.access_code`).

Practical implications:
- Row Level Security policies currently allow any authenticated (including
  anonymous) user full read/write access to everything — this was already
  true before this change, so nothing got LESS secure, but it's worth
  knowing the company password is a light gate, not a hard security
  boundary. Anyone with the site URL and a bit of browser dev-tools
  knowledge could bypass the password screen and hit the database directly.
- This is a reasonable trade-off for an internal department tool with no
  sensitive personal data, but if that ever changes, real per-company (or
  per-person) Supabase Auth accounts with RLS scoped by company would be
  the next step up in security.

## Database structure (plain-English)

- `companies` — the fleet (Engine 1/3/5/7/9/10, Ladder 1/2/4, plus
  chief-level entries C1/C2/C4). Has `access_code` (used only for
  chief-level logins — regular companies share one code from
  `app_settings`) and `is_chief`.
- `divisions` — the 4 operational crew groups (Group 1-4), purely for
  shift/time tracking. Not tied to hydrant assignment.
- `members` — the roster (not tied to a company).
- `hydrants` — the real roster (1,856 rows). `company_id` + `block`
  (A/B/C/D) is the permanent assignment; `block` is what the app calls
  "List" in the UI.
- `jobs` — the ongoing task for one Company + Block + Activity. Can
  span many days/shifts. Optionally belongs to a `campaign_id`.
- `sessions` — one shift: date, OIC, division (Group), crew, total
  minutes, linked to a `job_id`.
- `hydrant_tests` — one row per logged entry (test, condition check,
  snow status, or a chief's status update), linked to a hydrant and
  optionally a session (null `session_id` for chief-issued status
  changes not tied to a shift).
- `campaigns` — the citywide umbrella above jobs, optionally scoped to
  specific companies via `company_ids`.
- `super_admins` — the hidden personal admin login(s).
- `app_settings` — key/value store (retest interval, discharge
  coefficient default, shared company login code, etc.).

## How to test this right now

1. Open Supabase → your project → **SQL Editor**
2. Run `sql/001_initial_schema.sql` through `sql/011_real_hydrant_import.sql`
   in order, if you haven't already. **`011` wipes any test data logged so
   far and loads the real 1,856-hydrant roster** — read its warning comment
   before running.
3. Visit the live site: `https://lfd-hydrants.vercel.app`
4. **Test a regular company**: sign in with a Company name (e.g. "Engine 1")
   and the shared password (Settings → Company Login Code, defaults to
   `lfd2026` until changed). Pick a Division (Group), then pick a **List**
   (A/B/C/D) when prompted. Start New Job, log a couple of hydrants, End
   Shift. Confirm only Home and Log tabs are visible.
5. **Test "Change List"**: from Company Home, click Change List and confirm
   it swaps to a different list's hydrants without a full re-login.
6. **Test chief access**: sign in as "C1", "C2", or "C4" (their own
   individual password, set in Settings → Chief Login Codes) — this skips
   Division/List entirely and goes to the Campaigns/Status/Reports/Log/
   Stats/Settings dashboard.
7. **Test the personal admin login**: on the login screen, type `admin` as
   the Company (this is intentionally not a visible button — see the
   security note above) with its password. **Change this password
   immediately** via SQL Editor — there's no in-app UI for it by design.
8. **Test campaigns**: after step 4's job was started, go to the chief
   dashboard's Campaigns tab — a campaign should already exist automatically.
   Start a job under a different company/list for the same activity and
   confirm it joins the same campaign.
9. **Test Reports**: try the company/activity chip filters, "flagged only",
   and the Custom CSV/PDF Export with a few filters.
10. **Test the Master Hydrant List and Status tab**: confirm hydrants show
    real addresses from the import, color-coded correctly, and that a
    flagged one can be marked repaired from the Status tab (chief-only).

## Next steps (in rough order)

1. Load real hydrant / member / company CSVs (replace sample data)
2. Get chief's input: retest interval, formula constants, ISO format, admin list
3. Tighten RLS policies — separate "admin" permissions (edit roster/settings)
   from "field user" permissions (add tests/events only)
4. Deploy the app to a real hosting URL (Vercel, free tier) so it's a proper
   link instead of a local file
5. Set up the scheduled ping (GitHub Actions) to keep Supabase from pausing
6. Add photo upload (Supabase Storage)
7. Add auto-emailed backups
8. Build the formatted report for Water & Sewer
9. QR codes / map view (lower priority, nice-to-have)

## Formula currently used (placeholder — confirm with chief)

```
Flow at test:      Q = 29.83 * C * d² * √P   (per outlet, × number of outlets)
Flow at 20 psi:    Q20 = Q * ((Hs - 20) / (Hs - Hr)) ^ 0.54   [NFPA 291 style]
```
Where C = discharge coefficient (default 0.9), d = outlet diameter (in),
P = pitot pressure (psi), Hs = static psi, Hr = residual psi.
