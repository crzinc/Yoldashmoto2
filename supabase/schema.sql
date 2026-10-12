-- YoldashMoto · Supabase schema (Postgres + PostGIS + RLS)
-- Stage 1 MVP. Run in Supabase SQL editor. Requires: pgcrypto, postgis.

create extension if not exists pgcrypto;
create extension if not exists postgis;

-- ---------- profiles (one account, many roles) ----------
create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null,
  phone text unique not null,
  photo_url text,
  riding_type text default 'personal', -- personal | courier | both
  lang text default 'az',              -- az | ru | en
  is_admin boolean default false,
  role text default 'rider',           -- rider | mechanic | tow
  visible_on_map boolean default true,
  sos_radius_km int default 5,
  crash_on boolean default true,
  blocked boolean default false,
  created_at timestamptz default now()
);

-- ---------- bikes (My Garage) ----------
create table bikes (
  id uuid primary key default gen_random_uuid(),
  owner uuid references profiles(id) on delete cascade,
  make text not null, model text not null,
  year int not null, cc int, color text, plate text, photo_url text,
  created_at timestamptz default now()
);

-- ---------- reference data (3 langs, admin-managed) ----------
create table problem_types (
  id text primary key, az text not null, ru text not null, en text not null
);
insert into problem_types(id,az,ru,en) values
 ('chain','Zəncir','Цепь','Chain'),('fuel','Yanacaq bitdi','Кончился бензин','Out of fuel'),
 ('tire','Təkər','Шина','Flat tire'),('battery','Akkumulyator','Аккумулятор','Battery'),
 ('brake','Əyləc','Тормоза','Brakes'),('engine','Mühərrik','Двигатель','Engine'),
 ('accident','Qəza','Авария','Accident'),('other','Digər','Другое','Other');

create table service_types (
  id text primary key, az text not null, ru text not null, en text not null
);

create table app_settings (
  key text primary key, value jsonb not null
);
insert into app_settings(key,value) values
 ('sos_radii','[2,5,10,25]'),
 ('crash','{"speed_kmh":15,"g":3.5,"countdown_sec":15}'),
 ('matching','{"mode":"broadcast","timeout_sec":60,"widen_km":10}');

-- ---------- mechanics / tow ----------
create table mechanic_profiles (
  id uuid primary key default gen_random_uuid(),
  owner uuid references profiles(id) on delete cascade,
  kind text not null, -- mobile | garage | both
  status text default 'review', -- review|approved|rejected|suspended
  status_reason text,
  specs text[] default '{}', services text[] default '{}',
  area text, addr_lat double precision, addr_lng double precision,
  hours text, phone text, online boolean default false,
  cur_lat double precision, cur_lng double precision,
  rating numeric default 5.0, orders_done int default 0,
  created_at timestamptz default now()
);

create table tow_profiles (
  id uuid primary key default gen_random_uuid(),
  owner uuid references profiles(id) on delete cascade,
  name text not null, truck_type text, area text,
  price_lines text[] default '{}', hours text, phone text,
  available_now boolean default true, verified boolean default false,
  cur_lat double precision, cur_lng double precision,
  rating numeric default 5.0, created_at timestamptz default now()
);

-- ---------- SOS ----------
create table sos_events (
  id uuid primary key default gen_random_uuid(),
  sender uuid references profiles(id) on delete set null,
  problem_id text references problem_types(id),
  comment text, landmark text, can_move boolean default true,
  geom geography(Point,4326) not null,
  status text default 'active', -- active|responded|resolved|expired|escalated
  created_at timestamptz default now(), closed_at timestamptz
);
create index sos_geo_idx on sos_events using gist ((geom::geometry));

create table sos_responders (
  sos uuid references sos_events(id) on delete cascade,
  rider uuid references profiles(id) on delete cascade,
  created_at timestamptz default now(),
  primary key (sos, rider)
);

-- ---------- mechanic orders (broadcast MVP) ----------
create table mechanic_orders (
  id uuid primary key default gen_random_uuid(),
  rider uuid references profiles(id) on delete set null,
  problem_id text references problem_types(id),
  bike uuid references bikes(id) on delete set null,
  geom geography(Point,4326) not(null),
  status text default 'searching',
  mechanic uuid references mechanic_profiles(id) on delete set null,
  price_approx int default 15, price_final int,
  created_at timestamptz default now(), updated_at timestamptz default now()
);

-- Atomic claim: first to accept wins (prevents double-accept).
create or replace function claim_order(o uuid, m uuid) returns boolean
language plpgsql security definer as $$
begin
  update mechanic_orders set mechanic = m, status='accepted', updated_at=now()
  where id = o and status = 'searching' and mechanic is null;
  return found;
end $$;

-- ---------- marketplace ----------
create table listings (
  id uuid primary key default gen_random_uuid(),
  seller uuid references profiles(id) on delete cascade,
  type text not null, -- moto|moped|scooter|electro
  title text not null, year int, mileage int, cc int,
  price_azn int not null, city text default 'Baku',
  description text, color text, phone text,
  photos text[] default '{}', vip boolean default false,
  inspected boolean default false, blocked boolean default false,
  created_at timestamptz default now()
);

create table favorites (listing uuid references listings(id) on delete cascade,
  user_id uuid references profiles(id) on delete cascade,
  primary key (listing, user_id));

create table reviews (
  id uuid primary key default gen_random_uuid(),
  author uuid references profiles(id) on delete set null,
  target_mechanic uuid references mechanic_profiles(id) on delete cascade,
  target_tow uuid references tow_profiles(id) on delete cascade,
  stars int check (stars between 1 and 5), text text, tags text[] default '{}',
  created_at timestamptz default now()
);

create table complaints (
  id uuid primary key default gen_random_uuid(),
  author uuid references profiles(id) on delete set null,
  ref_type text, ref_id text, text text, status text default 'open',
  created_at timestamptz default now()
);

create table admin_logs (
  id uuid primary key default gen_random_uuid(),
  admin uuid references profiles(id) on delete set null,
  action text not null, ref text, created_at timestamptz default now()
);

-- ---------- RLS (strict, server-checked) ----------
alter table profiles enable row level security;
alter table bikes enable row level security;
alter table mechanic_profiles enable row level security;
alter table tow_profiles enable row level security;
alter table sos_events enable row level security;
alter table mechanic_orders enable row level security;
alter table listings enable row level security;

-- public read for directory; write own rows; admin via is_admin flag.
create policy "public read approved mechanics" on mechanic_profiles
  for select using (status='approved');
create policy "own mechanic rows" on mechanic_profiles
  for all using (auth.uid() = owner) with check (auth.uid() = owner);
create policy "public read tow" on tow_profiles for select using (true);
create policy "own tow rows" on tow_profiles
  for all using (auth.uid() = owner) with check (auth.uid() = owner);
create policy "own bikes" on bikes
  for all using (auth.uid() = owner) with check (auth.uid() = owner);
create policy "sos readable auth" on sos_events
  for select using (auth.role() = 'authenticated');
create policy "sos insert auth" on sos_events
  for insert with check (auth.uid() = sender);
create policy "orders own" on mechanic_orders for all
  using (auth.uid() = rider) with check (auth.uid() = rider);
create policy "listings public" on listings
  for select using (blocked = false);

-- Storage buckets (create in dashboard): avatars, sos-photos, listings, docs.
-- Realtime: enable for sos_events, sos_responders, mechanic_orders.
