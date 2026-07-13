-- P02-009 issues short-lived, signed grants only after the immutable plan,
-- target device, and a matching non-revoked approval have been checked.

alter table public.session_grants
  add column if not exists used_at timestamptz;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'session_grants_expiry_after_issue'
      and conrelid = 'public.session_grants'::regclass
  ) then
    alter table public.session_grants
      add constraint session_grants_expiry_after_issue
      check (expires_at > issued_at);
  end if;
end;
$$;

create unique index if not exists session_grants_device_nonce_unique_idx
  on public.session_grants (device_id, nonce);
create index if not exists session_grants_active_lookup_idx
  on public.session_grants (grant_id, device_id, nonce)
  where revoked_at is null and used_at is null;

create or replace function public.issue_run_grant(
  p_grant_id text,
  p_user_id uuid,
  p_device_id text,
  p_run_id text,
  p_plan_hash text,
  p_scope jsonb,
  p_issued_at timestamptz,
  p_expires_at timestamptz,
  p_nonce text,
  p_signature text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_now timestamptz := timezone('utc', now());
  v_run record;
  v_approval_id text;
begin
  if p_grant_id is null or p_grant_id !~ '^grant_[A-Za-z0-9][A-Za-z0-9_-]{7,95}$' then
    raise exception 'grant id is invalid' using errcode = '22023';
  end if;
  if p_user_id is null then
    raise exception 'grant user is required' using errcode = '22023';
  end if;
  if p_device_id is null or p_device_id !~ '^device_[A-Za-z0-9][A-Za-z0-9_-]{7,95}$' then
    raise exception 'grant device is invalid' using errcode = '22023';
  end if;
  if p_run_id is null or p_run_id !~ '^run_[A-Za-z0-9][A-Za-z0-9_-]{7,95}$' then
    raise exception 'grant run is invalid' using errcode = '22023';
  end if;
  if p_plan_hash is null or p_plan_hash !~ '^[a-f0-9]{64}$' then
    raise exception 'grant plan hash is invalid' using errcode = '22023';
  end if;
  if p_scope is null or jsonb_typeof(p_scope) <> 'object' then
    raise exception 'grant scope must be an object' using errcode = '22023';
  end if;
  if p_scope->>'run_id' is distinct from p_run_id
     or p_scope->>'target_device_id' is distinct from p_device_id
     or p_scope->>'plan_hash' is distinct from p_plan_hash then
    raise exception 'grant scope is not target bound' using errcode = '42501';
  end if;
  if p_issued_at is null or p_expires_at is null or p_expires_at <= p_issued_at then
    raise exception 'grant expiry is invalid' using errcode = '22023';
  end if;
  if p_issued_at > v_now + interval '30 seconds'
     or p_expires_at <= v_now
     or p_expires_at > p_issued_at + interval '10 minutes' then
    raise exception 'grant lifetime is invalid' using errcode = '22023';
  end if;
  if p_nonce is null or p_nonce !~ '^[A-Za-z0-9_-]{16,128}$' then
    raise exception 'grant nonce is invalid' using errcode = '22023';
  end if;
  if p_signature is null
     or char_length(p_signature) not between 43 and 256
     or p_signature !~ '^[A-Za-z0-9_-]+$' then
    raise exception 'grant signature is invalid' using errcode = '22023';
  end if;

  select r.run_id,
         r.workflow_version_id,
         r.target_device_id,
         r.plan_hash,
         d.user_id as device_user_id,
         d.status as device_status,
         w.user_id as workflow_user_id,
         v.content_hash
    into v_run
    from public.execution_runs r
    join public.workflow_versions v on v.workflow_version_id = r.workflow_version_id
    join public.workflows w on w.workflow_id = v.workflow_id
    join public.devices d on d.device_id = r.target_device_id
   where r.run_id = p_run_id
   for update of r;

  if not found then
    raise exception 'run was not found' using errcode = '42501';
  end if;
  if v_run.workflow_user_id <> p_user_id or v_run.device_user_id <> p_user_id then
    raise exception 'run is not owned by user' using errcode = '42501';
  end if;
  if v_run.target_device_id <> p_device_id then
    raise exception 'grant target does not match run' using errcode = '42501';
  end if;
  if v_run.device_status not in ('trusted', 'offline') then
    raise exception 'target device is not trusted' using errcode = '42501';
  end if;
  if v_run.plan_hash <> p_plan_hash or v_run.content_hash <> p_plan_hash then
    raise exception 'grant plan hash does not match immutable plan' using errcode = '42501';
  end if;

  select a.approval_id
    into v_approval_id
    from public.approvals a
   where a.run_id = p_run_id
     and a.decided_by = p_user_id
     and a.decision = 'approved'
     and a.scope in ('run', 'plan_version')
     and a.step_id is null
     and a.plan_hash = p_plan_hash
     and not a.revoked
     and a.expires_at > v_now
   order by a.decided_at desc
   limit 1;

  if v_approval_id is null then
    raise exception 'active approval is required' using errcode = '42501';
  end if;

  insert into public.session_grants (
    grant_id, grant_type, user_id, device_id, run_id, plan_hash, scope,
    issued_at, expires_at, nonce, signature
  ) values (
    p_grant_id, 'run', p_user_id, p_device_id, p_run_id, p_plan_hash, p_scope,
    p_issued_at, p_expires_at, p_nonce, p_signature
  );

  insert into public.audit_events (
    audit_event_id, user_id, device_id, actor_type, event_type, entity_type,
    entity_id, outcome, metadata, retention_until, occurred_at
  ) values (
    'audit_' || replace(gen_random_uuid()::text, '-', ''), p_user_id,
    p_device_id, 'service', 'run.grant.issued', 'run_grant', p_grant_id,
    'accepted', jsonb_build_object(
      'run_id', p_run_id,
      'plan_hash', p_plan_hash,
      'approval_id', v_approval_id,
      'expires_at', p_expires_at
    ), v_expires_at + interval '365 days', v_now
  );

  return jsonb_build_object(
    'grant_id', p_grant_id,
    'grant_type', 'run',
    'user_id', p_user_id,
    'device_id', p_device_id,
    'run_id', p_run_id,
    'plan_hash', p_plan_hash,
    'scope', p_scope,
    'issued_at', p_issued_at,
    'expires_at', p_expires_at,
    'nonce', p_nonce,
    'signature', p_signature
  );
end;
$$;

create or replace function public.consume_run_grant(
  p_grant_id text,
  p_device_id text,
  p_nonce text,
  p_signature text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_now timestamptz := timezone('utc', now());
  v_grant public.session_grants%rowtype;
  v_device_status text;
begin
  select *
    into v_grant
    from public.session_grants
   where grant_id = p_grant_id
   for update;

  if not found then
    raise exception 'grant was not found' using errcode = '42501';
  end if;
  if v_grant.grant_type <> 'run'
     or v_grant.device_id <> p_device_id
     or v_grant.nonce <> p_nonce
     or v_grant.signature <> p_signature then
    raise exception 'grant proof does not match' using errcode = '42501';
  end if;
  if v_grant.revoked_at is not null then
    raise exception 'grant is revoked' using errcode = '42501';
  end if;
  if v_grant.used_at is not null then
    raise exception 'grant has already been consumed' using errcode = '40001';
  end if;
  if v_grant.expires_at <= v_now then
    raise exception 'grant has expired' using errcode = '22023';
  end if;

  select d.status
    into v_device_status
    from public.devices d
   where d.device_id = v_grant.device_id
     and d.user_id = v_grant.user_id;
  if v_device_status is null or v_device_status not in ('trusted', 'offline') then
    raise exception 'grant target device is not trusted' using errcode = '42501';
  end if;

  update public.session_grants
     set used_at = v_now
   where grant_id = v_grant.grant_id
     and used_at is null;
  if not found then
    raise exception 'grant has already been consumed' using errcode = '40001';
  end if;

  insert into public.audit_events (
    audit_event_id, user_id, device_id, actor_type, event_type, entity_type,
    entity_id, outcome, metadata, retention_until, occurred_at
  ) values (
    'audit_' || replace(gen_random_uuid()::text, '-', ''), v_grant.user_id,
    v_grant.device_id, 'service', 'run.grant.consumed', 'run_grant', v_grant.grant_id,
    'accepted', jsonb_build_object('run_id', v_grant.run_id),
    v_now + interval '365 days', v_now
  );

  return jsonb_build_object(
    'grant_id', v_grant.grant_id,
    'run_id', v_grant.run_id,
    'device_id', v_grant.device_id,
    'plan_hash', v_grant.plan_hash,
    'scope', v_grant.scope,
    'consumed_at', v_now
  );
end;
$$;

revoke execute on function public.issue_run_grant(text, uuid, text, text, text, jsonb, timestamptz, timestamptz, text, text) from public, anon, authenticated;
revoke execute on function public.consume_run_grant(text, text, text, text) from public, anon, authenticated;
grant execute on function public.issue_run_grant(text, uuid, text, text, text, jsonb, timestamptz, timestamptz, text, text) to service_role;
grant execute on function public.consume_run_grant(text, text, text, text) to service_role;
grant select, insert, update on public.session_grants to service_role;
grant select on public.devices, public.device_keys, public.device_pairing_challenges to service_role;
grant insert on public.devices, public.device_keys, public.device_pairing_challenges to service_role;
grant update on public.devices, public.device_pairing_challenges to service_role;

comment on column public.session_grants.used_at is 'One-time consumption marker; a consumed grant cannot be replayed.';
comment on function public.issue_run_grant(text, uuid, text, text, text, jsonb, timestamptz, timestamptz, text, text) is 'Service-only atomic issuance of a short-lived, approved, target-bound run grant.';
comment on function public.consume_run_grant(text, text, text, text) is 'Service-only one-time grant consumption with expiry, revocation, target, nonce, and signature checks.';
