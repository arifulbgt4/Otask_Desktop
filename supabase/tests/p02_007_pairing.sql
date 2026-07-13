begin;

select plan(6);

select has_table('public', 'device_pairing_challenges', 'pairing challenge table exists');
select ok((select relrowsecurity from pg_class where oid = 'public.device_pairing_challenges'::regclass), 'pairing challenges RLS enabled');
select policies_are('public', 'device_pairing_challenges', array['device_pairing_challenges_select_own'], 'pairing challenges are owner-readable only');
select ok((select to_regclass('public.device_pairing_challenges_device_idx') is not null), 'pairing challenges indexed by device and expiry');
select ok((select to_regclass('public.device_pairing_challenges_user_idx') is not null), 'pairing challenges indexed by owner and creation time');
select ok((select has_table_privilege('authenticated', 'public.device_pairing_challenges', 'SELECT')), 'authenticated role can only read challenge status through RLS');

select * from finish();
rollback;
