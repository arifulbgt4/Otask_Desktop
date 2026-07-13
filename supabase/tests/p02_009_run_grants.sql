begin;

select plan(10);

select has_column('public', 'session_grants', 'used_at', 'session grants have a one-time consumption marker');
select ok((select to_regclass('public.session_grants_device_nonce_unique_idx') is not null), 'grant nonce uniqueness is indexed per device');
select ok((select conname = 'session_grants_expiry_after_issue' from pg_constraint where conrelid = 'public.session_grants'::regclass and conname = 'session_grants_expiry_after_issue'), 'grant expiry must be after issue time');
select ok(has_function_privilege('service_role', 'public.issue_run_grant(text, uuid, text, text, text, jsonb, timestamptz, timestamptz, text, text)', 'EXECUTE'), 'service role can issue run grants');
select ok(not has_function_privilege('authenticated', 'public.issue_run_grant(text, uuid, text, text, text, jsonb, timestamptz, timestamptz, text, text)', 'EXECUTE'), 'authenticated clients cannot issue grants directly');
select ok(has_function_privilege('service_role', 'public.consume_run_grant(text, text, text, text)', 'EXECUTE'), 'service role can consume run grants');
select ok(not has_function_privilege('authenticated', 'public.consume_run_grant(text, text, text, text)', 'EXECUTE'), 'authenticated clients cannot consume grants directly');
select ok((select prosecdef from pg_proc where oid = 'public.issue_run_grant(text, uuid, text, text, text, jsonb, timestamptz, timestamptz, text, text)'::regprocedure), 'issue function is security definer');
select ok((select prosecdef from pg_proc where oid = 'public.consume_run_grant(text, text, text, text)'::regprocedure), 'consume function is security definer');
select ok((select relrowsecurity from pg_class where oid = 'public.session_grants'::regclass), 'grant table remains RLS protected');

select * from finish();
rollback;
