# LFD Hydrant Testing System — Master File

This is the living roadmap for the project. Keep it updated as things change —
anyone (including a future Claude conversation) should be able to read this and
pick up exactly where things left off.

## What this is

A digital replacement for the paper hydrant-testing spreadsheet. Crews log flow
tests, condition checks, and snow removal in the field; the chief gets live
visibility, stats, and exportable reports/backups.

## Current status

- ✅ **Real data loaded**: 1,856 real hydrants (from the department's
  actual master flow-test spreadsheet), 176 real members, and the real
  company fleet (Engine 1/3/5/7/9/10, Ladder 1/2/4). No sample/
  placeholder data remains in active use.
- ✅ **Real database-enforced access control**: real Supabase Auth
  accounts for the shared Admin login and the hidden deeper-tier login,
  with actual RLS policies restricting admin-only actions (Settings,
  campaign editing, company management, Mark Repaired specifically) —
  not just hidden buttons. See "Security note" below for the full
  picture, including what's deliberately still left open.
- ✅ Deployed live at `https://lfd-hydrants.vercel.app` (auto-redeploys
  on GitHub push)
- ✅ Companies belong to a permanent **List** (A–D, called `block` in
  the schema), independent of the operational **Division** (Group 1-4,
  which is just crew/shift identity). Jobs are scoped by Company + List
  + Activity.
- ✅ Sticky hydrant status (Good/Damaged/OOS), Incomplete Inspections
  tracking, offline fillable sheets with auto-import, Report Hydrant
  with email notification, and a full reporting suite (Campaigns,
  lean condition Reports, Master List Snapshot) — see Build History
  below for the full list of what exists.
- ⏳ **ISO/state fire marshal export format** — pending the chief's
  input on the exact format needed; holding this for its own dedicated
  session rather than guessing at it.
- ⏳ **Photos** — not built.
- ⏳ **Auto-emailed backups** — not built; only the manual "Download
  Full Backup" button in Settings exists today.
- ⏳ **Scheduled ping to prevent Supabase's 7-day auto-pause** — not
  built. May become moot with real daily usage, but worth keeping in
  mind during any quiet stretch (holidays, etc.).
- ⏳ **QR codes / map view** — not built.
- ⏳ **GPS-based nearest-hydrant route ordering** — parked, pending
  hydrant coordinate data (worth checking whether Water & Sewer/GIS
  already has this before building it from scratch).
- ⏳ **First Due export compatibility** — parked, pending their import
  format.
- ⏳ **Wipe Training Data script** — ready to write whenever a training
  date is set; not needed until then.

## Build history

### In-app Help link + training document (this session) — no new SQL

- **"?" Help button** added to every header — the login screen, the
  company shell, and the chief shell. Opens a collapsible reference
  covering the real workflow: signing in, starting/ending a job,
  entering each activity type, Unable to Test vs. incomplete-save,
  Report Hydrant, what the status colors mean and why they stick,
  offline sheets. Chief/admin logins additionally see sections on
  Campaigns, the three report types, Mark Repaired, Stats, and
  Settings — content is tailored to who's actually signed in.
- **`LFD_Hydrant_App_Training_Guide.docx`** — a standalone Word document
  for teaching the department, covering the same ground as the in-app
  Help but formatted for printing/presenting: numbered sections, callout
  boxes for the "gotcha" moments (missing readings, Unable to Test,
  sticky status), and a one-page quick-reference table at the end.

### Real Excel files instead of CSV, plus missing filter descriptions on PDFs (this session) — no new SQL, 1 new CDN library

- **Every "CSV" export is now a real `.xlsx` file**, using SheetJS
  (new CDN dependency). This was a genuine format limitation, not
  something fixable within CSV: a `.csv` is plain text with no way to
  carry column widths or structure, so no amount of formatting inside
  the file could make Excel display it "properly" — Excel was always
  going to render it as an unstyled wall of text. A real spreadsheet
  file solves this at the format level: correct column widths sized to
  content, a merged/spanning title block, and — as a side benefit —
  the whole UTF-8/BOM encoding problem from earlier this session
  disappears entirely, since `.xlsx` isn't a text format Excel has to
  guess the encoding of.
  - Note: the free/community version of SheetJS used here doesn't
    support cell-level styling (bold text, colored fills) — that
    requires a paid tier. What's included is genuinely real formatting
    (structure, column widths, spanning title rows), just not colored/
    bold text on top of it.
  - Applies to all four: Campaign Export, Condition Report, Master
    List Snapshot, and Full Backup. Buttons relabeled "Export/Generate
    Excel" to match.
- **Fixed two PDFs that were missing the filter-description block**
  added to CSVs earlier this session — Condition Report and Master
  List Snapshot PDFs now also show which companies/conditions/lists
  are actually represented in that export, matching their Excel
  counterparts.

### CSV formatting fixes + a real bug in Campaign export (this session) — no new SQL

- **Fixed a real bug in Campaign CSV/PDF export**: it was requesting a
  field (`tested_at`) from the wrong table in its Supabase query —
  that field doesn't exist on `sessions`, only on `hydrant_tests` —
  which silently failed and returned zero rows **every single time**,
  for every campaign, regardless of how much real data existed. This
  had nothing to do with a data threshold; it was broken from the start.
- **Every CSV export now has a descriptive header block** at the top —
  report title, the active filter conditions (companies selected,
  condition/status filters, campaign name/activity), generation date,
  and record count — before the actual column headers. Professional
  enough to hand off or file, not just a raw data dump.
- **Fixed the actual cause of "columns look wrong" in Excel**: every
  CSV now includes a UTF-8 byte-order-mark (BOM) prefix. Without it,
  Excel doesn't reliably detect UTF-8 encoding and can misread
  non-ASCII characters (the app uses em-dashes and similar throughout),
  which visually breaks column alignment even though the underlying
  comma/quote escaping was already correct. This affects Campaign
  Export, Condition Report, Master List Snapshot, and Full Backup —
  all four CSV exports in the app.

### Real fix: incomplete flow tests no longer count as "done" (this session) — no new SQL

**This is a genuine behavior change, not just a display addition** — the
previous Incomplete Inspections build only added a way to *see*
incomplete entries; it didn't stop them from silently counting as
finished everywhere else. Fixed properly this time:

- **Job/campaign completion tracking** (`computeCompletionForCompanyBlock`
  — the one function powering Company Home's progress numbers, the
  pending-hydrant dropdown, and Campaign Detail's rollups) now requires
  a flow test to have **all three readings, or be explicitly marked
  Unable to Test**, before it counts as done. An entry saved incomplete
  keeps that hydrant on the pending list — exactly where it should
  stay until someone actually finishes it.
- **Stats' Overdue for Retest** got the same fix — an incomplete flow
  test no longer quietly resets a hydrant's retest clock. Only a
  genuinely complete test (or Unable to Test) counts as a real retest.
- Condition Check and Snow Removal are unaffected — they don't have a
  "partial data" concept, so any entry there still counts as done, same
  as before.
- One practical side effect, worth knowing: since incomplete hydrants
  now correctly stay pending, they'll also start showing up naturally
  in the normal hydrant picker and Suggested Next Stop for that job —
  not just the dedicated Incomplete Inspections list. That's intentional
  and consistent with the fix.

### Incomplete Inspections on the company side (this session) — no new SQL

- **Company Home now shows its own Incomplete Inspections** — same
  underlying logic as the chief-level Stats version (excludes anything
  marked Unable to Test), scoped to that company's own hydrants across
  all of their Lists, not just whichever List they're currently signed
  into.
- **Tapping one jumps straight into finishing it** — resumes or
  creates whatever job/shift is needed for that hydrant's own List
  (switching the signed-in List if needed, same as picking it manually
  would), then lands directly in the Flow Test form with that hydrant
  already selected. This required a small special case: an incomplete
  entry already technically counts as "done" for job-progress purposes
  (it has *an* entry, just a blank one), so it wouldn't normally appear
  in the pending-hydrant dropdown — the fix reuses the same "browse any
  hydrant" override path the manual search already had, rather than
  needing changes to how job completion is tracked.

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

- **Database**: Supabase (Postgres) — see `sql/001_initial_schema.sql` for
  the base structure; each numbered migration in `sql/` builds on it.
- **App**: a single static HTML file (`app/index.html`) using the Supabase
  JS client directly from a CDN — no build step, no framework. Simple on
  purpose: easy to read top-to-bottom.
- **Auth model**: two tiers, by design, not per-person accounts —
  - **Companies** share one login code (Settings → Company Login Code)
    over Supabase's anonymous auth. This is intentionally open —
    companies can read/write any hydrant citywide, not just their own —
    since that's how the department actually works, not an oversight.
  - **Admin/hidden logins** are real individual Supabase Auth accounts,
    with actual RLS policies restricting admin-only actions. See
    "Security note" below for exactly what is and isn't enforced.

## SQL file naming convention

Every SQL migration file follows `0NN_short-description.sql` — the number
preserves run order (each one may depend on earlier ones), the description
says what it does at a glance. Always run them in order; check the top
comment of each file for anything that needs manual follow-up (a few
require a step in the Supabase Dashboard, not just SQL Editor).

## Resetting the Admin or hidden-tier password

Both are real Supabase Auth accounts now (not the old `super_admins`
table, which is retired/unused — see Database structure below). To reset
either password:

1. Supabase Dashboard → **Authentication → Users**
2. Find the account by its email (check `privileged_logins` in SQL
   Editor if you don't remember which email maps to which username:
   `select * from privileged_logins;`)
3. Set a new password directly on that account in the Dashboard — don't
   rely on the "send reset email" option unless the account's email is
   real and deliverable (a fake/placeholder email will silently fail to
   deliver anything)
4. If you ever change which Supabase Auth account backs a username
   (e.g. creating a fresh account because the old one's email wasn't
   real), update `privileged_logins.auth_email` to match, and swap the
   corresponding row in `privileged_users` to the new account's User ID
   — both tables need to agree, or login will silently fail with
   "Incorrect login" even with the right password.

## Security note on the login model

- **Companies**: a shared password, checked at the app level against
  `app_settings`, over one shared anonymous Supabase session. This is a
  light gate, not a hard boundary — anyone with the site URL and basic
  browser dev-tools knowledge could technically bypass it and read/write
  hydrant data directly. **This is intentional, not a gap** — companies
  are supposed to have full citywide access, so there's nothing to
  "protect" here that isn't already meant to be open to every company.
- **Admin-only actions ARE genuinely database-enforced** (as of the
  access-control rebuild) — real Supabase Auth accounts for the shared
  Admin login and the hidden deeper tier, with RLS policies that
  actually check who's signed in, not just which buttons the app shows.
  Locked down this way: Settings (including the Company Login Code
  itself), campaign editing/closing (not creation — that's a normal
  company action), company management, and specifically the Mark
  Repaired action (identified by its exact signature — a `condition:
  'good'` entry with no `session_id` — everything else stays exactly as
  open as before, including a company logging Damaged/OOS through
  completely normal means).
- **What's still not covered**: this is a reasonable, deliberately-scoped
  security model for an internal department tool, not an exhaustive
  lockdown. If requirements ever change (e.g. genuinely sensitive data
  enters the system, or per-company data isolation becomes necessary),
  that would need real per-company Supabase Auth accounts with RLS
  scoped by company — a bigger step up from what exists today.

## Database structure (plain-English)

- `companies` — the real fleet (Engine 1/3/5/7/9/10, Ladder 1/2/4, plus
  any report-only units like EMS/Communications). Has `email` (for the
  Report Hydrant CC), `skip_list_assignment` (report-only logins that
  skip Division/List and land straight on Home), and legacy
  `access_code`/`is_chief` columns that are no longer used for login —
  chief access now goes entirely through the accounts below.
- `divisions` — the 4 operational crew groups (Group 1-4), purely for
  shift/time tracking. Not tied to hydrant assignment.
- `members` — the real 176-member roster (not tied to a company).
- `hydrants` — the real roster (1,856 rows). `company_id` + `block`
  (A/B/C/D) is the permanent assignment; `block` is what the app calls
  "List" in the UI. Also has `location_notes` (editable inline from the
  entry screen).
- `jobs` — the ongoing task for one Company + Block + Activity (`block`
  can also be `'ALL'` for a "Complete List" job spanning every block).
  Can span many days/shifts. Optionally belongs to a `campaign_id`.
- `sessions` — one shift: date, OIC, division (Group), crew, total
  minutes, linked to a `job_id`.
- `hydrant_tests` — one row per logged entry (test, condition check,
  snow status, a chief's status update, or a standalone Report Hydrant
  entry), linked to a hydrant and optionally a session (null
  `session_id` for entries not tied to a shift — chief status changes
  and Report Hydrant both work this way). Also has `gauge_flow_gpm`
  (optional, informational only), `reported_by_company_id` (for Report
  Hydrant entries), and `unable_to_test` (explicit "couldn't test this"
  flag, distinct from an entry that's just missing data).
- `campaigns` — the citywide umbrella above jobs, optionally scoped to
  specific companies via `company_ids`.
- `privileged_users` — maps a real Supabase Auth user ID to admin
  privileges. Fully locked by RLS — no client-side access at all, only
  reachable via SQL Editor or the internal `is_privileged()` function.
- `privileged_logins` — maps a typed username (Admin, the hidden tier)
  to the real Supabase Auth email behind it. Readable by anyone (just
  email addresses, not secrets) but which usernames exist here never
  appears in the app's source code.
- `super_admins` — **retired, unused.** The old hidden-admin mechanism
  before the real-auth rebuild. Left in place rather than dropped since
  deleting it serves no purpose; safe to `drop table if exists
  super_admins;` anytime if you want it gone.
- `app_settings` — key/value store (retest interval, discharge
  coefficient, outlet size/# outlets, shared company login code, Report
  Hydrant email recipients, etc.).

## How to test this right now

1. Open Supabase → your project → **SQL Editor**
2. Run every file in `sql/` in numeric order, if you haven't already —
   check each file's top comment for anything needing manual follow-up
   in the Supabase Dashboard (a few do, notably `015_access_control.sql`).
3. Visit the live site: `https://lfd-hydrants.vercel.app`
4. **Test a regular company**: sign in with a Company name (e.g. "Engine 1")
   and the shared password (Settings → Company Login Code). Pick a
   Division (Group), then pick a **List** (A/B/C/D, or Complete List)
   when prompted. Start New Job, log a couple of hydrants, End Shift.
   Confirm only Home and Log tabs are visible.
5. **Test "Change List"** from Company Home, and confirm **All Hydrants**
   / **Report Hydrant** both work from the List-select screen without
   needing a List chosen first.
6. **Test the Admin login**: type `admin` as the Company, with its
   password — reaches the chief dashboard (Campaigns/Reports/Log/
   Stats/Settings). There's also a hidden deeper-tier login, same
   mechanism, different (undocumented-by-design) username.
7. **Test campaigns**: after step 4's job was started, go to the chief
   dashboard's Campaigns tab — a campaign should already exist
   automatically. Start a job under a different company/list for the
   same activity and confirm it joins the same campaign.
8. **Test the Master Hydrant List**: confirm hydrants show real
   addresses, color-coded status, sortable/filterable, and that a
   flagged one can be marked repaired from there (chief-only).
9. **Test Incomplete Inspections**: save a Flow Test missing a reading,
   confirm the warning fires with a "Save Incomplete" bypass, and that
   it shows up on both the chief Stats page and the company's own Home
   screen — clicking it from Home should jump straight into finishing it.
10. **Test the three report types** — Campaign Detail's export, the lean
    Reports tab (company add/remove + condition toggles), and the
    Master List Snapshot — and confirm each produces what it's supposed
    to (they're deliberately different in shape, not redundant).

## Next steps (in rough order)

1. Set a training date, then run a Wipe Training Data script beforehand
   (not yet written — trivial once a date exists)
2. Get chief's input on the ISO/state fire marshal export format
3. Add photo upload (Supabase Storage)
4. Add auto-emailed backups
5. Set up the scheduled ping (GitHub Actions) to keep Supabase from
   pausing on quiet stretches
6. QR codes / map view (lower priority, nice-to-have)
7. If/when GIS coordinate data becomes available: GPS-based
   nearest-hydrant route ordering
8. If First Due's import format is ever obtained: shape the CSV export
   to match it directly

## Formula currently used (placeholder — confirm with chief)

```
Flow at test:      Q = 29.83 * C * d² * √P   (per outlet, × number of outlets)
Flow at 20 psi:    Q20 = Q * ((Hs - 20) / (Hs - Hr)) ^ 0.54   [NFPA 291 style]
```
Where C = discharge coefficient (default 0.9), d = outlet diameter (in),
P = pitot pressure (psi), Hs = static psi, Hr = residual psi.
