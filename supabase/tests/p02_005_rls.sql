begin;

select plan(36);

select ok((select relrowsecurity from pg_class where oid = 'public.profiles'::regclass), 'profiles RLS remains enabled');
select ok((select relrowsecurity from pg_class where oid = 'public.devices'::regclass), 'devices RLS remains enabled');
select ok((select relrowsecurity from pg_class where oid = 'public.device_keys'::regclass), 'device keys RLS remains enabled');
select ok((select relrowsecurity from pg_class where oid = 'public.device_capabilities'::regclass), 'device capabilities RLS remains enabled');
select ok((select relrowsecurity from pg_class where oid = 'public.workflows'::regclass), 'workflows RLS remains enabled');
select ok((select relrowsecurity from pg_class where oid = 'public.workflow_versions'::regclass), 'workflow versions RLS remains enabled');
select ok((select relrowsecurity from pg_class where oid = 'public.schedules'::regclass), 'schedules RLS remains enabled');
select ok((select relrowsecurity from pg_class where oid = 'public.execution_runs'::regclass), 'execution runs RLS remains enabled');
select ok((select relrowsecurity from pg_class where oid = 'public.execution_step_events'::regclass), 'execution step events RLS remains enabled');
select ok((select relrowsecurity from pg_class where oid = 'public.execution_log_chunks'::regclass), 'execution log chunks RLS remains enabled');
select ok((select relrowsecurity from pg_class where oid = 'public.execution_artifacts'::regclass), 'execution artifacts RLS remains enabled');
select ok((select relrowsecurity from pg_class where oid = 'public.approvals'::regclass), 'approvals RLS remains enabled');
select ok((select relrowsecurity from pg_class where oid = 'public.session_grants'::regclass), 'session grants RLS remains enabled');
select ok((select relrowsecurity from pg_class where oid = 'public.clipboard_items'::regclass), 'clipboard items RLS remains enabled');
select ok((select relrowsecurity from pg_class where oid = 'public.clipboard_heads'::regclass), 'clipboard heads RLS remains enabled');
select ok((select relrowsecurity from pg_class where oid = 'public.sync_changes'::regclass), 'sync changes RLS remains enabled');
select ok((select relrowsecurity from pg_class where oid = 'public.notifications'::regclass), 'notifications RLS remains enabled');
select ok((select relrowsecurity from pg_class where oid = 'public.model_packages'::regclass), 'model packages RLS remains enabled');
select ok((select relrowsecurity from pg_class where oid = 'public.model_installations'::regclass), 'model installations RLS remains enabled');
select ok((select relrowsecurity from pg_class where oid = 'public.release_artifacts'::regclass), 'release artifacts RLS remains enabled');
select ok((select relrowsecurity from pg_class where oid = 'public.learning_resources'::regclass), 'learning resources RLS remains enabled');
select ok((select relrowsecurity from pg_class where oid = 'public.audit_events'::regclass), 'audit events RLS remains enabled');

select ok((select with_check like '%revoked%' from pg_policies where schemaname = 'public' and tablename = 'devices' and policyname = 'devices_update_own'), 'device updates cannot mutate revoked devices');
select ok((select with_check like '%revoked%' from pg_policies where schemaname = 'public' and tablename = 'schedules' and policyname = 'schedules_insert_own'), 'schedule inserts reject revoked targets');
select ok((select with_check like '%revoked%' from pg_policies where schemaname = 'public' and tablename = 'schedules' and policyname = 'schedules_update_own'), 'schedule updates reject revoked targets');
select ok((select with_check like '%revoked%' from pg_policies where schemaname = 'public' and tablename = 'execution_runs' and policyname = 'execution_runs_insert_own'), 'run inserts reject revoked targets');
select ok((select with_check like '%revoked%' from pg_policies where schemaname = 'public' and tablename = 'approvals' and policyname = 'approvals_insert_own'), 'approval inserts reject revoked targets');
select ok((select with_check like '%revoked%' from pg_policies where schemaname = 'public' and tablename = 'clipboard_items' and policyname = 'clipboard_items_insert_own'), 'clipboard inserts reject revoked devices');
select ok((select with_check like '%revoked%' from pg_policies where schemaname = 'public' and tablename = 'clipboard_heads' and policyname = 'clipboard_heads_insert_own'), 'clipboard head inserts reject revoked devices');

select policies_are('public', 'devices', array['devices_delete_own', 'devices_insert_own', 'devices_select_own', 'devices_update_own'], 'device policies are owner scoped');
select policies_are('public', 'schedules', array['schedules_delete_own', 'schedules_insert_own', 'schedules_select_own', 'schedules_update_own'], 'schedule policies are owner and target scoped');
select policies_are('public', 'execution_runs', array['execution_runs_insert_own', 'execution_runs_select_own'], 'run policies are owner and target scoped');
select policies_are('public', 'approvals', array['approvals_insert_own', 'approvals_select_own'], 'approval policies are owner scoped');
select policies_are('public', 'clipboard_items', array['clipboard_items_insert_own', 'clipboard_items_select_own', 'clipboard_items_update_own'], 'clipboard policies are owner and device scoped');
select policies_are('public', 'clipboard_heads', array['clipboard_heads_insert_own', 'clipboard_heads_select_own', 'clipboard_heads_update_own'], 'clipboard pointer policies are owner and device scoped');
select policies_are('public', 'audit_events', array['audit_events_select_own'], 'audit events have no client write policy');

select * from finish();
rollback;
