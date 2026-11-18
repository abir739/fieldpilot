-- Idempotency done fully: a repeated op gets the SAME answer as the first time.
--
-- Why: if the app is killed after the server applied a change but before the
-- phone got the answer, the phone sends the op again. Answering only
-- "duplicate" would leave the phone with an old version number, and its next
-- edit would look like a conflict. So we store each answer and replay it.

alter table public.processed_ops add column result jsonb;

create or replace function public.push_op(op_id uuid, entity text, payload jsonb)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  server_row  public.inspections;
  new_version integer;
  answer      jsonb;
begin
  -- 1. Seen this op before: give back the answer we gave the first time.
  select p.result into answer from public.processed_ops p where p.op_id = push_op.op_id;
  if found then
    return coalesce(answer, jsonb_build_object('status', 'duplicate'));
  end if;

  if entity = 'inspection' then
    -- 2. Version check. "for update" locks the row until we finish.
    select * into server_row
      from public.inspections i
     where i.id = (payload->>'id')::uuid
       for update;

    if found and server_row.version > (payload->>'version')::integer then
      -- Someone changed it on the server after the phone's copy: server wins.
      answer := jsonb_build_object('status', 'conflict', 'server', to_jsonb(server_row));
    else
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
      answer := jsonb_build_object('status', 'applied', 'version', new_version);
    end if;

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
    answer := jsonb_build_object('status', 'applied');

  else
    raise exception 'push_op: unknown entity %', entity;
  end if;

  -- Remember the op AND our answer, in the same transaction as the change.
  insert into public.processed_ops (op_id, result) values (push_op.op_id, answer);
  return answer;
end;
$$;
