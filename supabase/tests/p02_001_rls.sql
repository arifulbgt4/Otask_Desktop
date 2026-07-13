begin;

select plan(12);

select has_table('public', 'profiles', 'profiles table exists');
select has_table('public', 'devices', 'devices table exists');
select has_table('public', 'device_keys', 'device_keys table exists');
select has_table('public', 'device_capabilities', 'device_capabilities table exists');

select ok((select relrowsecurity from pg_class where oid = 'public.profiles'::regclass), 'profiles RLS enabled');
select ok((select relrowsecurity from pg_class where oid = 'public.devices'::regclass), 'devices RLS enabled');
select ok((select relrowsecurity from pg_class where oid = 'public.device_keys'::regclass), 'device_keys RLS enabled');
select ok((select relrowsecurity from pg_class where oid = 'public.device_capabilities'::regclass), 'device_capabilities RLS enabled');

select policies_are('public', 'profiles', array['profiles_select_own', 'profiles_update_own'], 'profiles has owner policies');
select policies_are('public', 'devices', array['devices_delete_own', 'devices_insert_own', 'devices_select_own', 'devices_update_own'], 'devices has owner policies');
select policies_are('public', 'device_keys', array['device_keys_select_own'], 'device_keys is read-only to owners');
select policies_are('public', 'device_capabilities', array['device_capabilities_select_own'], 'capabilities are read-only to owners');

select * from finish();
rollback;
