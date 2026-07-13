begin;

select plan(10);

select ok(has_function_privilege('service_role', 'public.rotate_device_key(text, uuid, integer, text, integer)', 'EXECUTE'), 'service role can rotate keys');
select ok(not has_function_privilege('authenticated', 'public.rotate_device_key(text, uuid, integer, text, integer)', 'EXECUTE'), 'authenticated clients cannot rotate keys directly');
select ok(has_function_privilege('service_role', 'public.revoke_device(text, uuid, text)', 'EXECUTE'), 'service role can revoke devices');
select ok(not has_function_privilege('authenticated', 'public.revoke_device(text, uuid, text)', 'EXECUTE'), 'authenticated clients cannot revoke through the SQL function');

select has_table('public', 'device_keys', 'device keys table exists for rotation');
select has_table('public', 'session_grants', 'session grants table exists for revocation');
select has_table('public', 'audit_events', 'audit events table exists for revocation audit');
select ok((select relrowsecurity from pg_class where oid = 'public.audit_events'::regclass), 'audit events remain RLS protected');
select ok((select prosecdef from pg_proc where oid = 'public.revoke_device(text, uuid, text)'::regprocedure), 'revoke function is security definer');
select ok((select prosecdef from pg_proc where oid = 'public.rotate_device_key(text, uuid, integer, text, integer)'::regprocedure), 'rotation function is security definer');

select * from finish();
rollback;
