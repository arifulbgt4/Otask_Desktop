-- P02-010 stores only terminal-session control state and bounded signaling.
-- Terminal bytes never transit Postgres; WebRTC/relay transport remains a
-- separate authenticated data channel.

create table if not exists public.terminal_sessions (
  session_id text primary key check (session_id ~ '^session_[A-Za-z0-9][A-Za-z0-9_-]{7,95}$'),
  grant_id text not null unique references public.session_grants (grant_id) on delete restrict,
  user_id uuid not null references auth.users (id) on delete cascade,
  device_id text not null references public.devices (device_id) on delete restrict,
  run_id text not null references public.execution_runs (run_id) on delete restrict,
  transport text not null check (transport in ('webrtc', 'relay')),
  initiated_by text not null check (initiated_by in ('desktop', 'mobile', 'web')),
  state text not null default 'requested' check (state in ('requested', 'offering', 'answering', 'connected', 'closing', 'closed', 'rejected', 'expired', 'cancelled')),
  scope jsonb not null check (jsonb_typeof(scope) = 'object' and scope ? 'read_only'),
  created_at timestamptz not null default timezone('utc', now()),
  expires_at timestamptz not null,
  connected_at timestamptz,
  closed_at timestamptz,
  close_reason text not null default '' check (char_length(close_reason) <= 500),
  revision bigint not null default 0 check (revision >= 0),
  check (expires_at > created_at),
  check (connected_at is null or connected_at >= created_at),
  check (closed_at is null or closed_at >= created_at)
);

create table if not exists public.terminal_signals (
  signal_id text primary key check (signal_id ~ '^signal_[A-Za-z0-9][A-Za-z0-9_-]{7,95}$'),
  session_id text not null references public.terminal_sessions (session_id) on delete cascade,
  sequence bigint not null check (sequence >= 1),
  sender text not null check (sender in ('client', 'device', 'service')),
  signal_type text not null check (signal_type in ('offer', 'answer', 'ice_candidate', 'renegotiate', 'close')),
  payload jsonb not null check (jsonb_typeof(payload) = 'object'),
  payload_hash text not null check (payload_hash ~ '^[a-f0-9]{64}$'),
  created_at timestamptz not null default timezone('utc', now()),
  expires_at timestamptz not null,
  unique (session_id, sequence),
  check (expires_at > created_at)
);

create index if not exists terminal_sessions_user_idx
  on public.terminal_sessions (user_id, created_at desc);
create index if not exists terminal_sessions_device_idx
  on public.terminal_sessions (device_id, state, expires_at);
create index if not exists terminal_signals_session_idx
  on public.terminal_signals (session_id, sequence);
create index if not exists terminal_signals_expiry_idx
  on public.terminal_signals (expires_at);

create or replace function public.prevent_terminal_signal_mutation()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  raise exception 'terminal_signals are append-only; create a new signal';
end;
$$;

drop trigger if exists terminal_signals_append_only on public.terminal_signals;
create trigger terminal_signals_append_only
before update or delete on public.terminal_signals
for each row execute function public.prevent_terminal_signal_mutation();

alter table public.terminal_sessions enable row level security;
alter table public.terminal_signals enable row level security;

drop policy if exists terminal_sessions_select_own on public.terminal_sessions;
create policy terminal_sessions_select_own on public.terminal_sessions
for select to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists terminal_signals_select_own on public.terminal_signals;
create policy terminal_signals_select_own on public.terminal_signals
for select to authenticated
using (
  exists (
    select 1 from public.terminal_sessions s
    where s.session_id = terminal_signals.session_id
      and s.user_id = (select auth.uid())
  )
);

create or replace function public.initialize_terminal_session(
  p_session_id text,
  p_grant_id text,
  p_user_id uuid,
  p_device_id text,
  p_run_id text,
  p_transport text,
  p_initiated_by text,
  p_scope jsonb
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
  v_target_device text;
begin
  if p_session_id is null or p_session_id !~ '^session_[A-Za-z0-9][A-Za-z0-9_-]{7,95}$' then
    raise exception 'session id is invalid' using errcode = '22023';
  end if;
  if p_transport not in ('webrtc', 'relay') or p_initiated_by not in ('desktop', 'mobile', 'web') then
    raise exception 'terminal session transport or initiator is invalid' using errcode = '22023';
  end if;
  if p_scope is null or jsonb_typeof(p_scope) <> 'object' or not (p_scope ? 'read_only') then
    raise exception 'terminal scope must include read_only' using errcode = '22023';
  end if;

  select * into v_grant
    from public.session_grants
   where grant_id = p_grant_id
   for update;
  if not found then
    raise exception 'terminal grant was not found' using errcode = '42501';
  end if;
  if v_grant.grant_type <> 'terminal'
     or v_grant.user_id <> p_user_id
     or v_grant.device_id <> p_device_id
     or v_grant.run_id <> p_run_id
     or v_grant.scope is distinct from p_scope then
    raise exception 'terminal grant binding does not match session' using errcode = '42501';
  end if;
  if v_grant.revoked_at is not null or v_grant.used_at is not null or v_grant.expires_at <= v_now then
    raise exception 'terminal grant is unavailable' using errcode = '42501';
  end if;

  select d.status into v_device_status
    from public.devices d
   where d.device_id = p_device_id
     and d.user_id = p_user_id;
  if v_device_status not in ('trusted', 'offline') then
    raise exception 'terminal target device is not trusted' using errcode = '42501';
  end if;

  select r.target_device_id into v_target_device
    from public.execution_runs r
   where r.run_id = p_run_id;
  if v_target_device is distinct from p_device_id then
    raise exception 'terminal run target does not match device' using errcode = '42501';
  end if;

  insert into public.terminal_sessions (
    session_id, grant_id, user_id, device_id, run_id, transport, initiated_by,
    scope, expires_at
  ) values (
    p_session_id, p_grant_id, p_user_id, p_device_id, p_run_id, p_transport,
    p_initiated_by, p_scope, v_grant.expires_at
  );

  update public.session_grants
     set used_at = v_now
   where grant_id = p_grant_id and used_at is null;

  insert into public.audit_events (
    audit_event_id, user_id, device_id, actor_type, event_type, entity_type,
    entity_id, outcome, metadata, retention_until, occurred_at
  ) values (
    'audit_' || replace(gen_random_uuid()::text, '-', ''), p_user_id,
    p_device_id, 'service', 'terminal.session.initialized', 'terminal_session',
    p_session_id, 'accepted', jsonb_build_object(
      'grant_id', p_grant_id, 'run_id', p_run_id, 'transport', p_transport
    ), v_grant.expires_at + interval '365 days', v_now
  );

  return jsonb_build_object(
    'session_id', p_session_id,
    'grant_id', p_grant_id,
    'device_id', p_device_id,
    'run_id', p_run_id,
    'transport', p_transport,
    'state', 'requested',
    'scope', p_scope,
    'expires_at', v_grant.expires_at
  );
end;
$$;

create or replace function public.append_terminal_signal(
  p_signal_id text,
  p_session_id text,
  p_user_id uuid,
  p_sender text,
  p_signal_type text,
  p_payload jsonb,
  p_payload_hash text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_now timestamptz := timezone('utc', now());
  v_session public.terminal_sessions%rowtype;
  v_sequence bigint;
  v_signal_expiry timestamptz;
begin
  if p_signal_id is null or p_signal_id !~ '^signal_[A-Za-z0-9][A-Za-z0-9_-]{7,95}$' then
    raise exception 'signal id is invalid' using errcode = '22023';
  end if;
  if p_sender not in ('client', 'device', 'service')
     or p_signal_type not in ('offer', 'answer', 'ice_candidate', 'renegotiate', 'close') then
    raise exception 'signal sender or type is invalid' using errcode = '22023';
  end if;
  if p_payload is null or jsonb_typeof(p_payload) <> 'object' then
    raise exception 'signal payload must be an object' using errcode = '22023';
  end if;
  if p_payload_hash is null or char_length(p_payload_hash) <> 64 or p_payload_hash !~ '^[a-f0-9]{64}$' then
    raise exception 'signal payload hash is invalid' using errcode = '22023';
  end if;

  select * into v_session
    from public.terminal_sessions
   where session_id = p_session_id
   for update;
  if not found or v_session.user_id <> p_user_id then
    raise exception 'terminal session is not owned by user' using errcode = '42501';
  end if;
  if v_session.state in ('closed', 'rejected', 'expired', 'cancelled') or v_session.expires_at <= v_now then
    raise exception 'terminal session is no longer accepting signals' using errcode = '42501';
  end if;

  select coalesce(max(sequence), 0) + 1 into v_sequence
    from public.terminal_signals
   where session_id = p_session_id;
  v_signal_expiry := least(v_session.expires_at, v_now + interval '5 minutes');

  insert into public.terminal_signals (
    signal_id, session_id, sequence, sender, signal_type, payload,
    payload_hash, expires_at
  ) values (
    p_signal_id, p_session_id, v_sequence, p_sender, p_signal_type, p_payload,
    p_payload_hash, v_signal_expiry
  );

  if p_signal_type = 'close' then
    update public.terminal_sessions
       set state = 'closing', revision = revision + 1
     where session_id = p_session_id;
  end if;

  return jsonb_build_object(
    'signal_id', p_signal_id,
    'session_id', p_session_id,
    'sequence', v_sequence,
    'signal_type', p_signal_type,
    'expires_at', v_signal_expiry
  );
end;
$$;

revoke execute on function public.initialize_terminal_session(text, text, uuid, text, text, text, text, jsonb) from public, anon, authenticated;
revoke execute on function public.append_terminal_signal(text, text, uuid, text, text, jsonb, text) from public, anon, authenticated;
grant execute on function public.initialize_terminal_session(text, text, uuid, text, text, text, text, jsonb) to service_role;
grant execute on function public.append_terminal_signal(text, text, uuid, text, text, jsonb, text) to service_role;
grant select, insert, update on public.terminal_sessions, public.terminal_signals to service_role;

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'terminal_sessions'
  ) then
    alter publication supabase_realtime add table public.terminal_sessions;
  end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'terminal_signals'
  ) then
    alter publication supabase_realtime add table public.terminal_signals;
  end if;
end;
$$;

comment on table public.terminal_sessions is 'Owner-scoped WebRTC/relay control state; terminal bytes stay off the database.';
comment on table public.terminal_signals is 'Short-lived append-only signaling envelopes for Realtime transport negotiation.';
