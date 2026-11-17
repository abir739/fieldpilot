-- FieldPilot server tables.
-- Same tables as the phone (Drift), plus the owner of each row.
-- Row Level Security (RLS): a user can only see and change their own rows.

-- One inspection of one asset.
create table public.inspections (
  id          uuid primary key,                       -- made on the phone
  owner_id    uuid not null default auth.uid() references auth.users on delete cascade,
  asset_code  text not null,
  status      text not null default 'draft',          -- 'draft' or 'done'
  note        text not null default '',
  version     integer not null default 0,             -- +1 on every server change
  updated_at  timestamptz not null default now()
);

-- Answer to one checklist question. id = '<inspection id>|<question>'.
create table public.answers (
  id             text primary key,
  owner_id       uuid not null default auth.uid() references auth.users on delete cascade,
  inspection_id  uuid not null references public.inspections on delete cascade,
  question       text not null,
  ok             boolean not null
);

-- A photo file in Supabase Storage (uploaded from the phone).
create table public.photos (
  id             uuid primary key,
  owner_id       uuid not null default auth.uid() references auth.users on delete cascade,
  inspection_id  uuid not null references public.inspections on delete cascade,
  storage_path   text not null
);

-- A problem suggested by the AI and approved (or not) by the user.
create table public.findings (
  id             uuid primary key,
  owner_id       uuid not null default auth.uid() references auth.users on delete cascade,
  inspection_id  uuid not null references public.inspections on delete cascade,
  description    text not null,
  approved       boolean not null default false
);

-- Every change the phone sent, so the same change is never applied twice.
create table public.processed_ops (
  op_id         uuid primary key,
  owner_id      uuid not null default auth.uid() references auth.users on delete cascade,
  processed_at  timestamptz not null default now()
);

-- Turn on RLS and allow each user to use only their own rows.
alter table public.inspections   enable row level security;
alter table public.answers       enable row level security;
alter table public.photos        enable row level security;
alter table public.findings      enable row level security;
alter table public.processed_ops enable row level security;

create policy "own rows" on public.inspections   for all to authenticated
  using (owner_id = (select auth.uid())) with check (owner_id = (select auth.uid()));
create policy "own rows" on public.answers       for all to authenticated
  using (owner_id = (select auth.uid())) with check (owner_id = (select auth.uid()));
create policy "own rows" on public.photos        for all to authenticated
  using (owner_id = (select auth.uid())) with check (owner_id = (select auth.uid()));
create policy "own rows" on public.findings      for all to authenticated
  using (owner_id = (select auth.uid())) with check (owner_id = (select auth.uid()));
create policy "own rows" on public.processed_ops for all to authenticated
  using (owner_id = (select auth.uid())) with check (owner_id = (select auth.uid()));

-- Indexes for "all rows of this inspection" and "all my rows" lookups.
create index on public.inspections (owner_id);
create index on public.answers (inspection_id);
create index on public.photos (inspection_id);
create index on public.findings (inspection_id);
