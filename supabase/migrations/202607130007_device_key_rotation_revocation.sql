create or replace function public.rotate_device_key(
  p_device_id text,
  p_user_id uuid,
  p_current_version integer,
  p_new_public_key text,
  p_new_version integer
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  current_key public.device_keys%rowtype;
  new_key_id text := 'device_key_' || replace(gen_random_uuid()::text, '-', '');
begin
  if p_new_public_key is null or char_length(p_new_public_key) not between 43 and 256 or p_new_public_key !~ '^[A-Za-z0-9_-]+$' then
    raise exception 'new public key is invalid' using errcode = '22023';
  end if;
  if p_new_version <= p_current_version then
    raise exception 'new key version must increase' using errcode = '22023';
  end if;

  select k.*
    into current_key
    from public.device_keys k
    join public.devices d on d.device_id = k.device_id
   where k.device_id = p_device_id
     and k.version = p_current_version
     and k.revoked_at is null
     and d.device_id = p_device_id
     and d.user_id = p_user_id
     and d.status <> 'revoked'
   for update of k;
  if not found then
    raise exception 'active device key not found' using errcode = '42501';
  end if;

  update public.device_keys
     set rotated_at = timezone('utc', now())
   where key_id = current_key.key_id;

  insert into public.device_keys (key_id, device_id, public_key, algorithm, version)
  values (new_key_id, p_device_id, p_new_public_key, 'ed25519', p_new_version);

  update public.devices
     set key_version = p_new_version
   where device_id = p_device_id
     and user_id = p_user_id
     and status <> 'revoked';

  insert into public.audit_events (
    audit_event_id, user_id, device_id, actor_type, event_type, entity_type,
    entity_id, outcome, metadata, retention_until
  ) values (
    'audit_' || replace(gen_random_uuid()::text, '-', ''), p_user_id,
    p_device_id, 'service', 'device.key.rotated', 'device', p_device_id,
    'accepted', jsonb_build_object('from_version', p_current_version, 'to_version', p_new_version),
    timezone('utc', now()) + interval '365 days'
  );

  return jsonb_build_object('device_id', p_device_id, 'key_version', p_new_version, 'status', 'trusted');
end;
$$;

create or replace function public.revoke_device(
  p_device_id text,
  p_user_id uuid,
  p_reason text default ''
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_revoked_at timestamptz := timezone('utc', now());
  device_user uuid;
begin
  if char_length(coalesce(p_reason, '')) > 500 then
    raise exception 'revocation reason is too long' using errcode = '22023';
  end if;

  select user_id into device_user from public.devices where device_id = p_device_id;
  if device_user is null or device_user <> p_user_id then
    raise exception 'device is not owned by user' using errcode = '42501';
  end if;

  update public.device_keys k
     set revoked_at = coalesce(k.revoked_at, v_revoked_at)
   where k.device_id = p_device_id;

  update public.session_grants g
     set revoked_at = coalesce(g.revoked_at, v_revoked_at)
   where g.device_id = p_device_id;

  update public.device_pairing_challenges c
     set consumed_at = v_revoked_at
   where c.device_id = p_device_id
     and c.consumed_at is null;

  update public.devices
     set status = 'revoked', updated_at = v_revoked_at
   where device_id = p_device_id
     and user_id = p_user_id;

  insert into public.audit_events (
    audit_event_id, user_id, device_id, actor_type, event_type, entity_type,
    entity_id, outcome, metadata, retention_until, occurred_at
  ) values (
    'audit_' || replace(gen_random_uuid()::text, '-', ''), p_user_id,
    p_device_id, 'service', 'device.revoked', 'device', p_device_id,
    'accepted', jsonb_build_object('reason', coalesce(p_reason, '')),
    v_revoked_at + interval '365 days', v_revoked_at
  );

  return jsonb_build_object('device_id', p_device_id, 'status', 'revoked', 'revoked_at', v_revoked_at);
end;
$$;

revoke execute on function public.rotate_device_key(text, uuid, integer, text, integer) from public, anon, authenticated;
revoke execute on function public.revoke_device(text, uuid, text) from public, anon, authenticated;
grant execute on function public.rotate_device_key(text, uuid, integer, text, integer) to service_role;
grant execute on function public.revoke_device(text, uuid, text) to service_role;

comment on function public.rotate_device_key(text, uuid, integer, text, integer) is 'Service-only atomic Ed25519 key rotation after current-key proof.';
comment on function public.revoke_device(text, uuid, text) is 'Service-only device revocation that invalidates keys, grants, pairing, and future dispatch.';
