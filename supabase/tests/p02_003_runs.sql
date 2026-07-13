begin;

select plan(18);

select has_table('public', 'execution_runs', 'execution_runs table exists');
select has_table('public', 'execution_step_events', 'execution_step_events table exists');
select has_table('public', 'execution_log_chunks', 'execution_log_chunks table exists');
select has_table('public', 'execution_artifacts', 'execution_artifacts table exists');
select has_table('public', 'approvals', 'approvals table exists');
select has_table('public', 'session_grants', 'session_grants table exists');

select ok((select relrowsecurity from pg_class where oid = 'public.execution_runs'::regclass), 'runs RLS enabled');
select ok((select relrowsecurity from pg_class where oid = 'public.execution_step_events'::regclass), 'events RLS enabled');
select ok((select relrowsecurity from pg_class where oid = 'public.execution_log_chunks'::regclass), 'logs RLS enabled');
select ok((select relrowsecurity from pg_class where oid = 'public.execution_artifacts'::regclass), 'artifacts RLS enabled');
select ok((select relrowsecurity from pg_class where oid = 'public.approvals'::regclass), 'approvals RLS enabled');
select ok((select relrowsecurity from pg_class where oid = 'public.session_grants'::regclass), 'grants RLS enabled');

select policies_are('public', 'execution_runs', array['execution_runs_insert_own', 'execution_runs_select_own'], 'runs owner policies');
select policies_are('public', 'execution_step_events', array['execution_step_events_select_own'], 'events are append-only to service');
select policies_are('public', 'execution_log_chunks', array['execution_log_chunks_select_own'], 'logs are append-only to service');
select policies_are('public', 'execution_artifacts', array['execution_artifacts_select_own'], 'artifacts are append-only to service');
select policies_are('public', 'approvals', array['approvals_insert_own', 'approvals_select_own'], 'approvals owner policies');
select policies_are('public', 'session_grants', array['session_grants_select_own'], 'grants are issued by trusted service');

select * from finish();
rollback;
