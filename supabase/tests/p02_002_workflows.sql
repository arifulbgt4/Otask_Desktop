begin;

select plan(10);

select has_table('public', 'workflows', 'workflows table exists');
select has_table('public', 'workflow_versions', 'workflow_versions table exists');
select has_table('public', 'schedules', 'schedules table exists');

select ok((select relrowsecurity from pg_class where oid = 'public.workflows'::regclass), 'workflows RLS enabled');
select ok((select relrowsecurity from pg_class where oid = 'public.workflow_versions'::regclass), 'workflow_versions RLS enabled');
select ok((select relrowsecurity from pg_class where oid = 'public.schedules'::regclass), 'schedules RLS enabled');

select policies_are('public', 'workflows', array['workflows_delete_own', 'workflows_insert_own', 'workflows_select_own', 'workflows_update_own'], 'workflows owner policies');
select policies_are('public', 'workflow_versions', array['workflow_versions_insert_own', 'workflow_versions_select_own'], 'workflow versions are immutable to clients');
select policies_are('public', 'schedules', array['schedules_delete_own', 'schedules_insert_own', 'schedules_select_own', 'schedules_update_own'], 'schedules bind owner and device');
select has_trigger('public', 'workflow_versions', 'workflow_versions_immutable', 'workflow versions have immutable trigger');

select * from finish();
rollback;
