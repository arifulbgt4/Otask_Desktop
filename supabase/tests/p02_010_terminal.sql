begin;

select plan(11);

select has_table('public', 'terminal_sessions', 'terminal sessions table exists');
select has_table('public', 'terminal_signals', 'terminal signals table exists');
select ok((select relrowsecurity from pg_class where oid = 'public.terminal_sessions'::regclass), 'terminal sessions RLS enabled');
select ok((select relrowsecurity from pg_class where oid = 'public.terminal_signals'::regclass), 'terminal signals RLS enabled');
select ok((select to_regclass('public.terminal_signals_session_idx') is not null), 'signals indexed by session sequence');
select ok((select to_regclass('public.terminal_sessions_device_idx') is not null), 'sessions indexed by target state and expiry');
select ok(has_function_privilege('service_role', 'public.initialize_terminal_session(text, text, uuid, text, text, text, text, jsonb)', 'EXECUTE'), 'service role can initialize terminal sessions');
select ok(not has_function_privilege('authenticated', 'public.initialize_terminal_session(text, text, uuid, text, text, text, text, jsonb)', 'EXECUTE'), 'authenticated clients cannot initialize sessions directly');
select ok(has_function_privilege('service_role', 'public.append_terminal_signal(text, text, uuid, text, text, jsonb, text)', 'EXECUTE'), 'service role can append terminal signals');
select ok(not has_function_privilege('authenticated', 'public.append_terminal_signal(text, text, uuid, text, text, jsonb, text)', 'EXECUTE'), 'authenticated clients cannot append signals directly');
select ok((select prosecdef from pg_proc where oid = 'public.initialize_terminal_session(text, text, uuid, text, text, text, text, jsonb)'::regprocedure), 'terminal initialization is security definer');

select * from finish();
rollback;
