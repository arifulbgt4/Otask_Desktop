create extension if not exists pgcrypto;

create table if not exists public.profiles (
  user_id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null default '' check (char_length(display_name) <= 120),
  preferences jsonb not null default '{}'::jsonb check (jsonb_typeof(preferences) = 'object'),
  revision bigint not null default 0 check (revision >= 0),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.devices (
  device_id text primary key check (device_id ~ '^device_[A-Za-z0-9][A-Za-z0-9_-]{7,95}$'),
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null check (char_length(name) between 1 and 120),
  platform text not null check (platform in ('macos', 'windows', 'linux', 'android', 'ios')),
  architecture text not null check (architecture in ('x64', 'arm64', 'armv7')),
  app_version text not null check (app_version ~ '^[0-9]+[.][0-9]+[.][0-9]+$'),
  status text not null default 'pairing' check (status in ('pairing', 'trusted', 'offline', 'revoked')),
  last_seen_at timestamptz,
  key_version integer not null default 1 check (key_version >= 1),
  capabilities jsonb not null default '{}'::jsonb check (jsonb_typeof(capabilities) = 'object'),
  revision bigint not null default 0 check (revision >= 0),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.device_keys (
  key_id text primary key check (key_id ~ '^device_key_[A-Za-z0-9][A-Za-z0-9_-]{7,95}$'),
  device_id text not null references public.devices (device_id) on delete cascade,
  public_key text not null check (char_length(public_key) between 32 and 4096),
  algorithm text not null check (algorithm in ('ed25519')),
  version integer not null check (version >= 1),
  created_at timestamptz not null default timezone('utc', now()),
  rotated_at timestamptz,
  revoked_at timestamptz
);

create table if not exists public.device_capabilities (
  capability_id text primary key check (capability_id ~ '^capability_[A-Za-z0-9][A-Za-z0-9_-]{7,95}$'),
  device_id text not null references public.devices (device_id) on delete cascade,
  capability text not null check (capability in ('workflow_execution', 'pty', 'webrtc', 'clipboard')),
  granted boolean not null default false,
  policy_revision bigint not null default 0 check (policy_revision >= 0),
  created_at timestamptz not null default timezone('utc', now()),
  unique (device_id, capability)
);

create index if not exists devices_user_id_idx on public.devices (user_id);
create index if not exists device_keys_device_id_idx on public.device_keys (device_id);
create index if not exists device_capabilities_device_id_idx on public.device_capabilities (device_id);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists devices_set_updated_at on public.devices;
create trigger devices_set_updated_at
before update on public.devices
for each row execute function public.set_updated_at();

alter table public.profiles enable row level security;
alter table public.devices enable row level security;
alter table public.device_keys enable row level security;
alter table public.device_capabilities enable row level security;

drop policy if exists profiles_select_own on public.profiles;
create policy profiles_select_own on public.profiles
for select to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own on public.profiles
for update to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

drop policy if exists devices_select_own on public.devices;
create policy devices_select_own on public.devices
for select to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists devices_insert_own on public.devices;
create policy devices_insert_own on public.devices
for insert to authenticated
with check ((select auth.uid()) = user_id and status = 'pairing');

drop policy if exists devices_update_own on public.devices;
create policy devices_update_own on public.devices
for update to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

drop policy if exists devices_delete_own on public.devices;
create policy devices_delete_own on public.devices
for delete to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists device_keys_select_own on public.device_keys;
create policy device_keys_select_own on public.device_keys
for select to authenticated
using (
  exists (
    select 1 from public.devices d
    where d.device_id = device_keys.device_id
      and d.user_id = (select auth.uid())
  )
);

drop policy if exists device_capabilities_select_own on public.device_capabilities;
create policy device_capabilities_select_own on public.device_capabilities
for select to authenticated
using (
  exists (
    select 1 from public.devices d
    where d.device_id = device_capabilities.device_id
      and d.user_id = (select auth.uid())
  )
);

comment on table public.profiles is 'User-owned preferences; never contains auth secrets.';
comment on table public.devices is 'Trusted desktop/mobile identities and capability summary.';
comment on table public.device_keys is 'Versioned public keys; private keys never enter Supabase.';
comment on table public.device_capabilities is 'Normalized capabilities controlled by trusted pairing/revocation flows.';
