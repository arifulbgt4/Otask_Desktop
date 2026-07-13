begin;

select plan(10);

insert into auth.users (id, aud, role, email, encrypted_password, created_at, updated_at)
values ('00000000-0000-0000-0000-000000000210', 'authenticated', 'authenticated', 'p02010@example.invalid', '', now(), now());

insert into public.devices (device_id, user_id, name, platform, architecture, app_version, status)
values ('device_p02010_target', '00000000-0000-0000-0000-000000000210', 'Terminal target', 'linux', 'x64', '1.0.0', 'trusted');

insert into public.workflows (workflow_id, user_id, name)
values ('workflow_p02010_a', '00000000-0000-0000-0000-000000000210', 'Terminal workflow');

insert into public.workflow_versions (workflow_version_id, workflow_id, version, schema_version, plan, content_hash, risk_level)
values ('workflow_version_p02010_a', 'workflow_p02010_a', 1, '1.0', '{}'::jsonb, repeat('a', 64), 'low');

insert into public.execution_runs (run_id, workflow_version_id, target_device_id, state, plan_hash, idempotency_key)
values ('run_p02010_terminal', 'workflow_version_p02010_a', 'device_p02010_target', 'running', repeat('a', 64), 'p02010-terminal-idempotency');

set local role service_role;

insert into public.session_grants (
  grant_id, grant_type, user_id, device_id, run_id, plan_hash, scope,
  issued_at, expires_at, nonce, signature
) values (
  'grant_p02010_terminal', 'terminal',
  '00000000-0000-0000-0000-000000000210', 'device_p02010_target',
  'run_p02010_terminal', repeat('a', 64),
  jsonb_build_object('read_only', true, 'workspace_refs', jsonb_build_array('workspace_p02010')),
  now(), now() + interval '5 minutes', repeat('N', 32), repeat('S', 64)
);

select lives_ok($$select public.initialize_terminal_session(
  'session_p02010_terminal',
  'grant_p02010_terminal',
  '00000000-0000-0000-0000-000000000210',
  'device_p02010_target',
  'run_p02010_terminal',
  'webrtc',
  'desktop',
  jsonb_build_object('read_only', true, 'workspace_refs', jsonb_build_array('workspace_p02010'))
)$$, 'terminal session initializes from an approved terminal grant');
select is((select count(*)::integer from public.terminal_sessions where session_id = 'session_p02010_terminal'), 1, 'terminal session is persisted');
select is((select state from public.terminal_sessions where session_id = 'session_p02010_terminal'), 'requested', 'new terminal session starts requested');
select ok((select used_at is not null from public.session_grants where grant_id = 'grant_p02010_terminal'), 'terminal grant is consumed exactly once');

select lives_ok($$select public.append_terminal_signal(
  'signal_p02010_offer',
  'session_p02010_terminal',
  '00000000-0000-0000-0000-000000000210',
  'client',
  'offer',
  jsonb_build_object('sdp', 'v=0', 'type', 'offer'),
  repeat('a', 64)
)$$, 'offer signal appends');
select is((select sequence from public.terminal_signals where signal_id = 'signal_p02010_offer'), 1::bigint, 'first signal receives sequence one');
select lives_ok($$select public.append_terminal_signal(
  'signal_p02010_close',
  'session_p02010_terminal',
  '00000000-0000-0000-0000-000000000210',
  'client',
  'close',
  jsonb_build_object('reason', 'user_cancelled'),
  repeat('b', 64)
)$$, 'close signal appends');
select is((select state from public.terminal_sessions where session_id = 'session_p02010_terminal'), 'closing', 'close signal moves session to closing');
select throws_ok($$select public.initialize_terminal_session(
  'session_p02010_replay',
  'grant_p02010_terminal',
  '00000000-0000-0000-0000-000000000210',
  'device_p02010_target',
  'run_p02010_terminal',
  'webrtc',
  'desktop',
  jsonb_build_object('read_only', true, 'workspace_refs', jsonb_build_array('workspace_p02010'))
)$$, '42501', NULL, 'consumed terminal grant cannot initialize a second session');
select throws_ok($$select public.append_terminal_signal(
  'signal_p02010_foreign',
  'session_p02010_terminal',
  '00000000-0000-0000-0000-000000000211',
  'client',
  'answer',
  jsonb_build_object('sdp', 'foreign'),
  repeat('c', 64)
)$$, '42501', NULL, 'foreign owner cannot append terminal signals');

reset role;
select * from finish();
rollback;
