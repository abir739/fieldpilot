-- Table permissions for logged-in users only.
-- New Supabase projects give no table access by default.
-- Two locks: GRANT opens the table to the role, then RLS limits it to the
-- user's own rows. Not-logged-in users (anon) get nothing.

grant select, insert, update, delete on public.inspections   to authenticated;
grant select, insert, update, delete on public.answers       to authenticated;
grant select, insert, update, delete on public.photos        to authenticated;
grant select, insert, update, delete on public.findings      to authenticated;
grant select, insert                 on public.processed_ops to authenticated;
