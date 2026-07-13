begin;

select plan(10);

insert into auth.users (id, aud, role, email, encrypted_password, created_at, updated_at)
values ('00000000-0000-0000-0000-000000000209', 'authenticated', 'authenticated', 'p02009@example.invalid', '', now(), now());

insert into public.devices (device_id, user_id, name, platform, architecture, app_version, status)
values
  ('device_p02009_target', '00000000-0000-0000-0000-000000000209', 'Run grant target', 'linux', 'x64', '1.0.0', 'trusted'),
  ('device_p02009_other', '00000000-0000-0000-0000-000000000209', 'Other target', 'linux', 'x64', '1.0.0', 'trusted');

insert into public.workflows (workflow_id, user_id, name)
values ('workflow_p02009_a', '00000000-0000-0000-0000-000000000209', 'Run grant workflow');

insert into public.workflow_versions (workflow_version_id, workflow_id, version, schema_version, plan, content_hash, risk_level)
values ('workflow_version_p02009_a', 'workflow_p02009_a', 1, '1.0', '{}'::jsonb, repeat('a', 64), 'low');

insert into public.execution_runs (run_id, workflow_version_id, target_device_id, state, plan_hash, idempotency_key)
values ('run_p02009_grant', 'workflow_version_p02009_a', 'device_p02009_target', 'awaiting_approval', repeat('a', 64), 'p02009-grant-idempotency');

insert into public.approvals (approval_id, run_id, decided_by, decision, scope, plan_hash, expires_at)
values ('approval_p02009_grant', 'run_p02009_grant', '00000000-0000-0000-0000-000000000209', 'approved', 'run', repeat('a', 64), now() + interval '1 hour');

set local role service_role;

select lives_ok($$select public.issue_run_grant(
  'grant_p02009_signed',
  '00000000-0000-0000-0000-000000000209',
  'device_p02009_target',
  'run_p02009_grant',
  repeat('a', 64),
  jsonb_build_object('run_id', 'run_p02009_grant', 'target_device_id', 'device_p02009_target', 'plan_hash', repeat('a', 64), 'capabilities', jsonb_build_array('workflow_execution')),
  now(),
  now() + interval '5 minutes',
  repeat('N', 32),
  repeat('S', 64)
)$$, 'approved target-bound run grant issues atomically');
select is((select count(*)::integer from public.session_grants where grant_id = 'grant_p02009_signed'), 1, 'issued grant is persisted');
select lives_ok($$select public.consume_run_grant('grant_p02009_signed', 'device_p02009_target', repeat('N', 32), repeat('S', 64))$$, 'valid grant is consumed');
select ok((select used_at is not null from public.session_grants where grant_id = 'grant_p02009_signed'), 'consumed grant records used_at');
select throws_ok($$select public.consume_run_grant('grant_p02009_signed', 'device_p02009_target', repeat('N', 32), repeat('S', 64))$$, '40001', NULL, 'replayed grant is rejected');

select lives_ok($$select public.issue_run_grant(
  'grant_p02009_tampered',
  '00000000-0000-0000-0000-000000000209',
  'device_p02009_target',
  'run_p02009_grant',
  repeat('a', 64),
  jsonb_build_object('run_id', 'run_p02009_grant', 'target_device_id', 'device_p02009_target', 'plan_hash', repeat('a', 64)),
  now(),
  now() + interval '5 minutes',
  repeat('T', 32),
  repeat('U', 64)
)$$, 'second grant issues for tamper proof fixture');
select throws_ok($$select public.consume_run_grant('grant_p02009_tampered', 'device_p02009_target', repeat('T', 32), repeat('V', 64))$$, '42501', NULL, 'tampered grant proof is rejected');

insert into public.session_grants (grant_id, grant_type, user_id, device_id, run_id, plan_hash, scope, issued_at, expires_at, nonce, signature)
values ('grant_p02009_expired', 'run', '00000000-0000-0000-0000-000000000209', 'device_p02009_target', 'run_p02009_grant', repeat('a', 64), jsonb_build_object('run_id', 'run_p02009_grant', 'target_device_id', 'device_p02009_target', 'plan_hash', repeat('a', 64)), now() - interval '10 minutes', now() - interval '5 minutes', repeat('E', 32), repeat('F', 64));
select throws_ok($$select public.consume_run_grant('grant_p02009_expired', 'device_p02009_target', repeat('E', 32), repeat('F', 64))$$, '22023', NULL, 'expired grant is rejected');

select throws_ok($$select public.issue_run_grant(
  'grant_p02009_wrong_target',
  '00000000-0000-0000-0000-000000000209',
  'device_p02009_other',
  'run_p02009_grant',
  repeat('a', 64),
  jsonb_build_object('run_id', 'run_p02009_grant', 'target_device_id', 'device_p02009_other', 'plan_hash', repeat('a', 64)),
  now(),
  now() + interval '5 minutes',
  repeat('W', 32),
  repeat('X', 64)
)$$, '42501', NULL, 'wrong target device cannot receive the grant');

insert into public.execution_runs (run_id, workflow_version_id, target_device_id, state, plan_hash, idempotency_key)
values ('run_p02009_noapproval', 'workflow_version_p02009_a', 'device_p02009_target', 'awaiting_approval', repeat('a', 64), 'p02009-no-approval-idempotency');
select throws_ok($$select public.issue_run_grant(
  'grant_p02009_noapproval',
  '00000000-0000-0000-0000-000000000209',
  'device_p02009_target',
  'run_p02009_noapproval',
  repeat('a', 64),
  jsonb_build_object('run_id', 'run_p02009_noapproval', 'target_device_id', 'device_p02009_target', 'plan_hash', repeat('a', 64)),
  now(),
  now() + interval '5 minutes',
  repeat('Y', 32),
  repeat('Z', 64)
)$$, '42501', NULL, 'run without an active approval cannot receive a grant');

reset role;
select * from finish();
rollback;
