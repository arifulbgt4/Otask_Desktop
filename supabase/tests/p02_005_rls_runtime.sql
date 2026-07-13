begin;

select plan(9);

insert into auth.users (id, aud, role, email, encrypted_password, created_at, updated_at)
values
  ('00000000-0000-0000-0000-000000000a05', 'authenticated', 'authenticated', 'p02005-a@example.invalid', '', now(), now()),
  ('00000000-0000-0000-0000-000000000b05', 'authenticated', 'authenticated', 'p02005-b@example.invalid', '', now(), now());

insert into public.devices (device_id, user_id, name, platform, architecture, app_version, status)
values
  ('device_p02005_active', '00000000-0000-0000-0000-000000000a05', 'Active test device', 'linux', 'x64', '1.0.0', 'trusted'),
  ('device_p02005_revoked', '00000000-0000-0000-0000-000000000a05', 'Revoked test device', 'linux', 'x64', '1.0.0', 'revoked');

insert into public.workflows (workflow_id, user_id, name)
values ('workflow_p02005_a', '00000000-0000-0000-0000-000000000a05', 'RLS test workflow');

insert into public.workflow_versions (workflow_version_id, workflow_id, version, schema_version, plan, content_hash, risk_level)
values ('workflow_version_p02005_a', 'workflow_p02005_a', 1, '1.0', '{}'::jsonb, repeat('a', 64), 'low');

set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000a05', true);

select is((select count(*)::integer from public.devices), 2, 'owner sees both active and historical revoked devices');
select is((select count(*)::integer from public.workflows), 1, 'owner sees own workflow');
select lives_ok($$insert into public.devices (device_id, user_id, name, platform, architecture, app_version, status) values ('device_p02005_new', '00000000-0000-0000-0000-000000000a05', 'New device', 'linux', 'x64', '1.0.0', 'pairing')$$, 'owner can register a pairing device');

select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000b05', true);
select is((select count(*)::integer from public.devices), 0, 'cross-user device rows are hidden');
select is((select count(*)::integer from public.workflows), 0, 'cross-user workflows are hidden');
select throws_ok($$insert into public.devices (device_id, user_id, name, platform, architecture, app_version, status) values ('device_p02005_cross', '00000000-0000-0000-0000-000000000a05', 'Cross user', 'linux', 'x64', '1.0.0', 'pairing')$$, '42501', NULL, 'cross-user device insert is rejected');

select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000a05', true);
select throws_ok($$insert into public.clipboard_items (clipboard_id, user_id, device_id, content_hash, payload_ref, expires_at) values ('clipboard_p02005_revoked', '00000000-0000-0000-0000-000000000a05', 'device_p02005_revoked', repeat('b', 64), 'storage://clipboard/p02005.txt', now() + interval '1 hour')$$, '42501', NULL, 'revoked device clipboard write is rejected');
select throws_ok($$insert into public.execution_runs (run_id, workflow_version_id, target_device_id, plan_hash, idempotency_key) values ('run_p02005_revoked', 'workflow_version_p02005_a', 'device_p02005_revoked', repeat('a', 64), 'p02005-revoked-run')$$, '42501', NULL, 'revoked device run dispatch is rejected');
select throws_ok($$insert into public.schedules (schedule_id, workflow_version_id, target_device_id, timezone, trigger, approval_mode, lateness_policy) values ('schedule_p02005_revoked', 'workflow_version_p02005_a', 'device_p02005_revoked', 'UTC', '{}'::jsonb, 'always', 'skip')$$, '42501', NULL, 'revoked device schedule target is rejected');

reset role;
select * from finish();
rollback;
