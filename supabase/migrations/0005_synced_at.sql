-- Pull support: "give me everything that changed since my last pull".
--
-- updated_at comes from the phone's clock, so it cannot be trusted for this.
-- synced_at is set by the SERVER every time a row is written. The phone keeps
-- the newest synced_at it has seen and asks only for rows after it.

alter table public.inspections add column synced_at timestamptz not null default clock_timestamp();
alter table public.answers     add column synced_at timestamptz not null default clock_timestamp();

create function public.touch_synced_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.synced_at := clock_timestamp(); -- real time of this write, not of the transaction start
  return new;
end;
$$;

create trigger touch_synced_at before insert or update on public.inspections
  for each row execute function public.touch_synced_at();
create trigger touch_synced_at before insert or update on public.answers
  for each row execute function public.touch_synced_at();

-- Fast "my rows changed after X" lookups.
create index on public.inspections (owner_id, synced_at);
create index on public.answers (owner_id, synced_at);
