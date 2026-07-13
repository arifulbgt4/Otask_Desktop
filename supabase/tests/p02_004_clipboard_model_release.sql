begin;

select plan(29);

select has_table('public', 'clipboard_items', 'clipboard_items table exists');
select has_table('public', 'clipboard_heads', 'clipboard_heads table exists');
select has_table('public', 'sync_changes', 'sync_changes table exists');
select has_table('public', 'notifications', 'notifications table exists');
select has_table('public', 'model_packages', 'model_packages table exists');
select has_table('public', 'model_installations', 'model_installations table exists');
select has_table('public', 'release_artifacts', 'release_artifacts table exists');
select has_table('public', 'learning_resources', 'learning_resources table exists');
select has_table('public', 'audit_events', 'audit_events table exists');

select ok((select relrowsecurity from pg_class where oid = 'public.clipboard_items'::regclass), 'clipboard_items RLS enabled');
select ok((select relrowsecurity from pg_class where oid = 'public.clipboard_heads'::regclass), 'clipboard_heads RLS enabled');
select ok((select relrowsecurity from pg_class where oid = 'public.sync_changes'::regclass), 'sync_changes RLS enabled');
select ok((select relrowsecurity from pg_class where oid = 'public.notifications'::regclass), 'notifications RLS enabled');
select ok((select relrowsecurity from pg_class where oid = 'public.model_packages'::regclass), 'model_packages RLS enabled');
select ok((select relrowsecurity from pg_class where oid = 'public.model_installations'::regclass), 'model_installations RLS enabled');
select ok((select relrowsecurity from pg_class where oid = 'public.release_artifacts'::regclass), 'release_artifacts RLS enabled');
select ok((select relrowsecurity from pg_class where oid = 'public.learning_resources'::regclass), 'learning_resources RLS enabled');
select ok((select relrowsecurity from pg_class where oid = 'public.audit_events'::regclass), 'audit_events RLS enabled');

select policies_are('public', 'clipboard_items', array['clipboard_items_insert_own', 'clipboard_items_select_own', 'clipboard_items_update_own'], 'clipboard items are owner scoped');
select policies_are('public', 'clipboard_heads', array['clipboard_heads_insert_own', 'clipboard_heads_select_own', 'clipboard_heads_update_own'], 'clipboard heads are owner scoped');
select policies_are('public', 'sync_changes', array['sync_changes_select_own'], 'sync changes are service-written and owner-readable');
select policies_are('public', 'notifications', array['notifications_select_own', 'notifications_update_own'], 'notifications are owner scoped');
select policies_are('public', 'model_packages', array['model_packages_select_approved'], 'only approved model manifests are public');
select policies_are('public', 'model_installations', array['model_installations_select_own'], 'model installations are device-owner readable');
select policies_are('public', 'release_artifacts', array['release_artifacts_select_published'], 'only published release artifacts are public');
select policies_are('public', 'learning_resources', array['learning_resources_select_authenticated', 'learning_resources_select_public'], 'published learning access is explicit');
select policies_are('public', 'audit_events', array['audit_events_select_own'], 'audit events are owner-readable only');

select has_trigger('public', 'sync_changes', 'sync_changes_append_only', 'sync changes are append-only');
select has_trigger('public', 'audit_events', 'audit_events_append_only', 'audit events are append-only');

select * from finish();
rollback;
