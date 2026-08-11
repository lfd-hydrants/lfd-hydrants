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
4. Visit the live site: `https://lfd-hydrants.vercel.app`
5. On the login screen, pick a Company (e.g. "Engine 1") and enter the
   password (default for all companies right now: `lfd2026` — change this
   per-company in Admin → Company Login Codes once you're past testing).
6. Pick a Division (e.g. "Group 1"). You'll land on Company Home.
7. Click **Start New Job**, pick an activity, fill in the shift form, Start
   Shift. Log a couple of sample hydrants, then **End Shift** (leave the job
   open). Go back to Company Home — the job should still be listed as open
   with the right pending count. Click **Resume** and confirm you land back
   in the hydrant entry loop with the same hydrants still excluded.
8. Try **Close Job Permanently** on a job and confirm a new job for the same
   activity starts with a full hydrant list again.
9. Try the **Recently Closed** reopen and the per-job "reopen shift" links.
10. Check the **District Hydrant Checklist**, **Log**, **Stats**, and **Admin**
    tabs (including editing a company's login code).

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
