-- P02-005 hardens owner policies so a revoked device cannot perform new
-- device-bound actions. Historical rows remain readable to their owner unless
-- the table contains a grant or payload reference that should be hidden.

drop policy if exists devices_update_own on public.devices;
create policy devices_update_own on public.devices
for update to authenticated
using ((select auth.uid()) = user_id and status <> 'revoked')
with check ((select auth.uid()) = user_id and status <> 'revoked');

drop policy if exists schedules_insert_own on public.schedules;
create policy schedules_insert_own on public.schedules
for insert to authenticated
with check (
  exists (
    select 1
    from public.workflow_versions v
    join public.workflows w on w.workflow_id = v.workflow_id
    join public.devices d on d.device_id = schedules.target_device_id
    where v.workflow_version_id = schedules.workflow_version_id
      and w.user_id = (select auth.uid())
      and d.user_id = (select auth.uid())
      and d.status <> 'revoked'
  )
);

drop policy if exists schedules_update_own on public.schedules;
create policy schedules_update_own on public.schedules
for update to authenticated
using (
  exists (
    select 1
    from public.workflow_versions v
    join public.workflows w on w.workflow_id = v.workflow_id
    join public.devices d on d.device_id = schedules.target_device_id
    where v.workflow_version_id = schedules.workflow_version_id
      and w.user_id = (select auth.uid())
      and d.user_id = (select auth.uid())
      and d.status <> 'revoked'
  )
)
with check (
  exists (
    select 1
    from public.workflow_versions v
    join public.workflows w on w.workflow_id = v.workflow_id
    join public.devices d on d.device_id = schedules.target_device_id
    where v.workflow_version_id = schedules.workflow_version_id
      and w.user_id = (select auth.uid())
      and d.user_id = (select auth.uid())
      and d.status <> 'revoked'
  )
);

drop policy if exists execution_runs_insert_own on public.execution_runs;
create policy execution_runs_insert_own on public.execution_runs
for insert to authenticated
with check (
  exists (
    select 1
    from public.workflow_versions v
    join public.workflows w on w.workflow_id = v.workflow_id
    join public.devices d on d.device_id = execution_runs.target_device_id
    where v.workflow_version_id = execution_runs.workflow_version_id
      and w.user_id = (select auth.uid())
      and d.user_id = (select auth.uid())
      and d.status <> 'revoked'
  )
);

drop policy if exists approvals_insert_own on public.approvals;
create policy approvals_insert_own on public.approvals
for insert to authenticated
with check (
  (select auth.uid()) = decided_by
  and exists (
    select 1
    from public.execution_runs r
    join public.devices d on d.device_id = r.target_device_id
    where r.run_id = approvals.run_id
      and d.user_id = (select auth.uid())
      and d.status <> 'revoked'
  )
);

drop policy if exists session_grants_select_own on public.session_grants;
create policy session_grants_select_own on public.session_grants
for select to authenticated
using (
  (select auth.uid()) = user_id
  and exists (
    select 1 from public.devices d
    where d.device_id = session_grants.device_id
      and d.user_id = (select auth.uid())
      and d.status <> 'revoked'
  )
);

drop policy if exists clipboard_items_insert_own on public.clipboard_items;
create policy clipboard_items_insert_own on public.clipboard_items
for insert to authenticated
with check (
  (select auth.uid()) = user_id
  and exists (
    select 1 from public.devices d
    where d.device_id = clipboard_items.device_id
      and d.user_id = (select auth.uid())
      and d.status <> 'revoked'
  )
);

drop policy if exists clipboard_items_update_own on public.clipboard_items;
create policy clipboard_items_update_own on public.clipboard_items
for update to authenticated
using (
  (select auth.uid()) = user_id
  and exists (
    select 1 from public.devices d
    where d.device_id = clipboard_items.device_id
      and d.user_id = (select auth.uid())
      and d.status <> 'revoked'
  )
)
with check (
  (select auth.uid()) = user_id
  and exists (
    select 1 from public.devices d
    where d.device_id = clipboard_items.device_id
      and d.user_id = (select auth.uid())
      and d.status <> 'revoked'
  )
);

drop policy if exists clipboard_heads_insert_own on public.clipboard_heads;
create policy clipboard_heads_insert_own on public.clipboard_heads
for insert to authenticated
with check (
  (select auth.uid()) = user_id
  and exists (
    select 1 from public.devices d
    where d.device_id = clipboard_heads.device_id
      and d.user_id = (select auth.uid())
      and d.status <> 'revoked'
  )
);

drop policy if exists clipboard_heads_update_own on public.clipboard_heads;
create policy clipboard_heads_update_own on public.clipboard_heads
for update to authenticated
using (
  (select auth.uid()) = user_id
  and exists (
    select 1 from public.devices d
    where d.device_id = clipboard_heads.device_id
      and d.user_id = (select auth.uid())
      and d.status <> 'revoked'
  )
)
with check (
  (select auth.uid()) = user_id
  and exists (
    select 1 from public.devices d
    where d.device_id = clipboard_heads.device_id
      and d.user_id = (select auth.uid())
      and d.status <> 'revoked'
  )
);

comment on policy devices_update_own on public.devices is 'Owners may edit active devices; revocation is service-controlled.';
comment on policy schedules_insert_own on public.schedules is 'Only active owner devices can receive new schedules.';
comment on policy execution_runs_insert_own on public.execution_runs is 'Only active owner devices can receive new runs.';
comment on policy approvals_insert_own on public.approvals is 'Approvals cannot be issued for a revoked target device.';
comment on policy clipboard_items_insert_own on public.clipboard_items is 'Clipboard writes require an active owner device.';
comment on policy clipboard_heads_insert_own on public.clipboard_heads is 'Clipboard pointer writes require an active owner device.';

-- RLS filters rows; these grants define which authenticated roles may attempt
-- an operation. Service-owned tables intentionally receive no client write
-- grants, so their policies cannot be bypassed by an API client.
grant select on all tables in schema public to authenticated;
grant select on public.model_packages, public.release_artifacts, public.learning_resources to anon;
grant update on public.profiles to authenticated;
grant insert, update, delete on public.devices to authenticated;
grant insert, update, delete on public.workflows to authenticated;
grant insert on public.workflow_versions to authenticated;
grant insert, update, delete on public.schedules to authenticated;
grant insert on public.execution_runs to authenticated;
grant insert on public.approvals to authenticated;
grant insert, update on public.clipboard_items to authenticated;
grant insert, update on public.clipboard_heads to authenticated;
grant update on public.notifications to authenticated;
