-- ResQNet core schema
create extension if not exists "pgcrypto";

create table if not exists public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  phone text,
  role text not null default 'citizen' check (role in ('citizen', 'authority')),
  created_at timestamptz not null default now()
);

create table if not exists public.disaster_events (
  id uuid primary key default gen_random_uuid(),
  type text not null check (type in ('flood', 'fire', 'earthquake')),
  latitude double precision not null,
  longitude double precision not null,
  confidence_score double precision not null check (confidence_score >= 0 and confidence_score <= 1),
  created_at timestamptz not null default now()
);

create table if not exists public.sos_reports (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  disaster_id uuid not null references public.disaster_events(id) on delete restrict,
  latitude double precision not null,
  longitude double precision not null,
  people_count int not null check (people_count > 0),
  injury_status text not null,
  status text not null default 'pending' check (status in ('pending', 'assigned', 'resolved')),
  created_at timestamptz not null default now()
);

create table if not exists public.rescue_units (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  latitude double precision not null,
  longitude double precision not null,
  status text not null default 'available' check (status in ('available', 'busy')),
  capacity int not null check (capacity > 0)
);

create table if not exists public.shelters (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  latitude double precision not null,
  longitude double precision not null,
  capacity int not null check (capacity > 0),
  available_slots int not null check (available_slots >= 0 and available_slots <= capacity)
);

create index if not exists idx_disaster_events_created_at on public.disaster_events(created_at desc);
create index if not exists idx_sos_reports_user_id_created_at on public.sos_reports(user_id, created_at desc);
create index if not exists idx_rescue_units_status on public.rescue_units(status);

alter table public.users enable row level security;
alter table public.disaster_events enable row level security;
alter table public.sos_reports enable row level security;
alter table public.rescue_units enable row level security;
alter table public.shelters enable row level security;

-- Citizens can read everything required by the mobile app.
create policy if not exists "users_can_read_users"
  on public.users for select to authenticated
  using (true);

create policy if not exists "users_can_insert_own_profile"
  on public.users for insert to authenticated
  with check (id = auth.uid());

create policy if not exists "users_can_update_own_profile"
  on public.users for update to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

create policy if not exists "read_disaster_events"
  on public.disaster_events for select to authenticated
  using (true);

create policy if not exists "read_shelters"
  on public.shelters for select to authenticated
  using (true);

create policy if not exists "read_rescue_units"
  on public.rescue_units for select to authenticated
  using (true);

create policy if not exists "create_own_sos"
  on public.sos_reports for insert to authenticated
  with check (user_id = auth.uid());

create policy if not exists "read_own_sos"
  on public.sos_reports for select to authenticated
  using (user_id = auth.uid());

create policy if not exists "authority_manage_sos"
  on public.sos_reports for update to authenticated
  using (exists (
    select 1 from public.users u
    where u.id = auth.uid() and u.role = 'authority'
  ));

alter publication supabase_realtime add table public.sos_reports;
alter publication supabase_realtime add table public.disaster_events;
alter publication supabase_realtime add table public.rescue_units;
