-- push_op: the one door the phone uses to send a change to the server.
--
-- Called with: op_id (unique per change), entity ('inspection' | 'answer'),
-- payload (the row as JSON). Everything below runs in ONE transaction.
--
-- Returns JSON:
--   {"status":"duplicate"}                    op already applied before → nothing done
--   {"status":"applied","version":N}          change saved (N = new inspection version)
--   {"status":"applied"}                      answer saved
--   {"status":"conflict","server":{...}}      server copy is newer → server wins
--
-- "security invoker" = runs as the calling user, so RLS still applies:
-- nobody can push into another user's rows.

create or replace function public.push_op(op_id uuid, entity text, payload jsonb)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  server_row  public.inspections;
  new_version integer;
begin
  -- 1. Same op sent twice (e.g. app killed before it got our answer): skip it.
  if exists (select 1 from public.processed_ops p where p.op_id = push_op.op_id) then
    return jsonb_build_object('status', 'duplicate');
  end if;

  if entity = 'inspection' then
    -- 2. Version check. "for update" locks the row until we finish.
    select * into server_row
      from public.inspections i
     where i.id = (payload->>'id')::uuid
       for update;

    if found and server_row.version > (payload->>'version')::integer then
      -- Someone changed it on the server after the phone's copy: server wins.
      insert into public.processed_ops (op_id) values (push_op.op_id);
      return jsonb_build_object('status', 'conflict', 'server', to_jsonb(server_row));
    end if;

    -- 3. Apply: create or update, and raise the version by one.
    new_version := coalesce(server_row.version, 0) + 1;
    insert into public.inspections (id, asset_code, status, note, version, updated_at)
    values (
      (payload->>'id')::uuid,
      payload->>'asset_code',
      payload->>'status',
      coalesce(payload->>'note', ''),
      new_version,
      (payload->>'updated_at')::timestamptz
    )
    on conflict (id) do update set
      asset_code = excluded.asset_code,
      status     = excluded.status,
      note       = excluded.note,
      version    = excluded.version,
      updated_at = excluded.updated_at;

    insert into public.processed_ops (op_id) values (push_op.op_id);
    return jsonb_build_object('status', 'applied', 'version', new_version);

  elsif entity = 'answer' then
    -- Answers have no version: the latest answer wins.
    insert into public.answers (id, inspection_id, question, ok)
    values (
      payload->>'id',
      (payload->>'inspection_id')::uuid,
      payload->>'question',
      (payload->>'ok')::boolean
    )
    on conflict (id) do update set ok = excluded.ok;

    insert into public.processed_ops (op_id) values (push_op.op_id);
    return jsonb_build_object('status', 'applied');

  else
    raise exception 'push_op: unknown entity %', entity;
  end if;
end;
$$;

-- Only logged-in users may call it.
revoke execute on function public.push_op(uuid, text, jsonb) from public, anon;
grant  execute on function public.push_op(uuid, text, jsonb) to authenticated;
