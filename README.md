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
- ⏳ Deployed live website (currently local-only file) — not deployed yet
- ⏳ Role-based permissions (admin vs. field user) — currently all authenticated
  users have full read/write access; needs tightening before real rollout

## Latest build (this session) — no new SQL, app-level only

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

- `companies` / `divisions` — reference lists
- `members` — the roster (linked to a company)
- `hydrants` — the roster of hydrants (linked to a company, has a retest interval)
- `sessions` — one row per outing: date, OIC, division, company, crew (array of
  member IDs), total minutes. This is the "header" the OIC fills out once.
- `hydrant_tests` — one row per flow test, linked to a session and a hydrant.
  Stores raw readings + calculated flow/drop/flow-at-20psi.
- `hydrant_events` — for non-flow-test activity (shoveling, damage checks, etc.),
  same session/hydrant linkage.
- `app_settings` — key/value store for admin-editable settings (retest interval,
  discharge coefficient default, etc.) so nothing is hardcoded.

## How to test this right now

1. Open Supabase → your project → **SQL Editor**
2. Run `sql/001_initial_schema.sql` through `sql/005_real_fleet_test_data.sql` in order,
   if you haven't already.
3. Run `sql/006_company_login_and_job_integrity.sql`.
4. Run `sql/007_hydrant_division_assignment.sql`.
5. Run `sql/008_campaigns_and_admin_tiers.sql`.
6. Run `sql/009_campaign_company_scope.sql`.

**Note on login codes after this update**: non-chief companies now all
share ONE login code (Settings → Company Login Code, defaults to `lfd2026`
until changed). Any individual `access_code` values set per-company in an
earlier session are no longer used for login — only chief-level companies'
individual codes still matter.
6. Visit the live site: `https://lfd-hydrants.vercel.app`
7. **Test a regular company**: sign in as e.g. "Engine 1" (password `lfd2026`),
   pick a division, Start New Job, log a couple of hydrants, End Shift. Confirm
   only Home and Log tabs are visible — no Stats/Admin.
8. **Test chief access**: sign in as "C4" (password `lfd2026`) — this should
   skip division selection entirely and go straight to a Campaigns/Reports/
   Log/Stats/Settings dashboard.
9. **Test the personal admin login**: from the login screen, click "Admin
   Login", sign in with username `admin` / password `changeme2026`. **Change
   this password immediately** from Settings → Personal Admin Login.
10. **Test campaigns**: after step 7's job was started, go to the chief
    dashboard's Campaigns tab — a campaign should already exist automatically
    (e.g. "Flow Test — started [month/year]"), showing that company/division's
    progress. Start a job under a different company/division for the same
    activity and confirm it joins the same campaign.
11. **Test Reports**: browse company/division sub-tabs, click column headers
    to sort, try "flagged only", then try the Custom CSV Export with a few
    filters.

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
