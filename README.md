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
- ✅ Jobs vs. shifts model added (`sql/004_jobs_multi_day_tracking.sql`) — a
  JOB (Company + Division + Activity) can span multiple days/crews until
  explicitly marked complete; a SHIFT (`sessions` table) is one crew's single
  day of work on that job, with its own OIC/crew/time tracking
- ✅ Working app (`app/index.html`) — login, job/shift workflow: pick Company +
  Division + Activity to resume an in-progress job or start a new one; the
  hydrant dropdown shows only what's still pending FOR THE WHOLE JOB (not
  just today's shift), so progress carries forward across days and crews;
  "End Shift" closes today's work and logs time while leaving the job open
  for the next crew; an optional checkbox on that same screen can also mark
  the whole job complete (e.g. all hydrants done, or storm cleanup over) —
  the next storm then starts a fresh, full list; Edit Shift screen for
  correcting OIC/crew/date (company/division/activity are fixed to the job);
  duplicate-test-today warning if another company already tested a hydrant;
  log w/ search+filter, chief stats (incl. overdue retest flags), admin
  settings, CSV backup export
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
2. Run `sql/001_initial_schema.sql` (creates all tables)
3. Run `sql/002_seed_sample_data.sql` (adds test companies/hydrants/members)
4. Run `sql/003_session_start_end_timestamps.sql` (real start/end timestamps + session status)
5. Run `sql/004_jobs_multi_day_tracking.sql` (adds the jobs table for multi-day/multi-crew tracking)
6. In Supabase → **Authentication → Providers**, make sure Email is enabled.
   For quick testing, "Confirm email" is currently OFF so accounts work instantly
   — turn this back on before real department rollout.
7. Visit the live site: `https://lfd-hydrants.vercel.app` — click "Create Account"
   to make yourself a login, then sign in.
8. On the **Session** tab: pick Company, Division, Activity → Continue. Since no
   job exists yet, this starts a new one — fill in Date/OIC/Crew, Start Shift.
   Log a couple of sample hydrants (H-101, H-102, H-203, H-310), then click
   End Shift — leave "job complete" unchecked and confirm. Go back to the
   Session tab, pick the same Company/Division/Activity again — it should
   resume the SAME job with the hydrants you already did still excluded
   from the dropdown. Try ending a shift with "job complete" checked, then
   start again — the dropdown should show the full list again.
9. Check the Log tab, Stats tab, and Admin tab.

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
