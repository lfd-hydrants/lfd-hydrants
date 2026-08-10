-- ============================================================
-- LFD HYDRANTS — Core Schema (v1)
-- Run this in Supabase: Project > SQL Editor > New query > Paste > Run
-- ============================================================

-- ---------- Reference tables ----------

create table companies (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  created_at timestamptz not null default now()
);

create table divisions (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  created_at timestamptz not null default now()
);

create table members (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  company_id uuid references companies(id) on delete set null,
  is_admin boolean not null default false,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

-- ---------- Hydrant roster (structure/asset data — owned/maintained by Lynn Water & Sewer) ----------

create table hydrants (
  id uuid primary key default gen_random_uuid(),
  hydrant_number text not null unique,
  address text,
  company_id uuid references companies(id) on delete set null,
  latitude numeric,
  longitude numeric,
  retest_interval_months integer not null default 12,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

-- ---------- Sessions (one per outing — OIC fills this once, hydrants logged underneath) ----------

create table sessions (
  id uuid primary key default gen_random_uuid(),
  session_date date not null default current_date,
  start_time time,
  end_time time,
  oic_member_id uuid references members(id),
  division_id uuid references divisions(id),
  company_id uuid references companies(id),
  activity_type text not null check (activity_type in ('flow_test','condition_check','snow_removal','other')),
  crew_member_ids uuid[] not null default '{}',   -- selected crew (names), count = crew size
  total_minutes integer,                           -- total time for the whole session
  notes text,
  created_at timestamptz not null default now()
);

-- ---------- Hydrant flow tests (linked to a session + hydrant) ----------

create table hydrant_tests (
  id uuid primary key default gen_random_uuid(),
  session_id uuid references sessions(id) on delete cascade,
  hydrant_id uuid not null references hydrants(id),
  static_psi numeric,
  residual_psi numeric,
  pitot_psi numeric,
  orifice_diameter numeric,
  discharge_coeff numeric default 0.9,
  num_outlets integer default 1,
  flow_gpm numeric,          -- calculated
  drop_pct numeric,          -- calculated
  flow_at_20psi numeric,     -- calculated
  condition text not null default 'good' check (condition in ('good','repair','oos')),
  wet_dry text check (wet_dry in ('wet','dry')),
  notes text,
  photo_url text,
  tested_at timestamptz not null default now()
);

-- ---------- General hydrant events: shoveling, damage checks, anything not a full flow test ----------

create table hydrant_events (
  id uuid primary key default gen_random_uuid(),
  session_id uuid references sessions(id) on delete cascade,
  hydrant_id uuid not null references hydrants(id),
  event_type text not null check (event_type in ('shovel','damage_check','leak','missing_cap','other')),
  condition text check (condition in ('good','repair','oos')),
  notes text,
  photo_url text,
  created_at timestamptz not null default now()
);

-- ---------- App settings (editable from the admin portal, not hardcoded) ----------

create table app_settings (
  key text primary key,
  value text not null,
  updated_at timestamptz not null default now()
);

insert into app_settings (key, value) values
  ('default_retest_interval_months', '12'),
  ('default_discharge_coeff', '0.9'),
  ('flow_formula_note', 'NFPA-style: Q = 29.83 * C * d^2 * sqrt(P); Q20 = Q * ((Hs-20)/(Hs-Hr))^0.54');

-- ---------- Indexes ----------

create index idx_hydrant_tests_hydrant on hydrant_tests(hydrant_id);
create index idx_hydrant_tests_session on hydrant_tests(session_id);
create index idx_hydrant_events_hydrant on hydrant_events(hydrant_id);
create index idx_hydrants_company on hydrants(company_id);
create index idx_members_company on members(company_id);

-- ---------- Row Level Security ----------
-- v1: any authenticated user can read/write. Tighten later once auth/roles are wired up
-- (admin-only writes to hydrants/members/companies/settings, everyone can write tests/events).

alter table companies enable row level security;
alter table divisions enable row level security;
alter table members enable row level security;
alter table hydrants enable row level security;
alter table sessions enable row level security;
alter table hydrant_tests enable row level security;
alter table hydrant_events enable row level security;
alter table app_settings enable row level security;

create policy "auth read companies" on companies for select using (auth.role() = 'authenticated');
create policy "auth write companies" on companies for all using (auth.role() = 'authenticated');

create policy "auth read divisions" on divisions for select using (auth.role() = 'authenticated');
create policy "auth write divisions" on divisions for all using (auth.role() = 'authenticated');

create policy "auth read members" on members for select using (auth.role() = 'authenticated');
create policy "auth write members" on members for all using (auth.role() = 'authenticated');

create policy "auth read hydrants" on hydrants for select using (auth.role() = 'authenticated');
create policy "auth write hydrants" on hydrants for all using (auth.role() = 'authenticated');

create policy "auth read sessions" on sessions for select using (auth.role() = 'authenticated');
create policy "auth write sessions" on sessions for all using (auth.role() = 'authenticated');

create policy "auth read tests" on hydrant_tests for select using (auth.role() = 'authenticated');
create policy "auth write tests" on hydrant_tests for all using (auth.role() = 'authenticated');

create policy "auth read events" on hydrant_events for select using (auth.role() = 'authenticated');
create policy "auth write events" on hydrant_events for all using (auth.role() = 'authenticated');

create policy "auth read settings" on app_settings for select using (auth.role() = 'authenticated');
create policy "auth write settings" on app_settings for all using (auth.role() = 'authenticated');
