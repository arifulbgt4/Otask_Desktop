create table if not exists public.device_pairing_challenges (
  challenge_id text primary key check (challenge_id ~ '^pairing_[A-Za-z0-9][A-Za-z0-9_-]{7,95}$'),
  device_id text not null references public.devices (device_id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  challenge_hash text not null check (challenge_hash ~ '^[a-f0-9]{64}$'),
  expires_at timestamptz not null,
  consumed_at timestamptz,
  attempt_count integer not null default 0 check (attempt_count between 0 and 5),
  created_at timestamptz not null default timezone('utc', now()),
  check (expires_at > created_at),
  check (consumed_at is null or consumed_at >= created_at)
);

create index if not exists device_pairing_challenges_device_idx
  on public.device_pairing_challenges (device_id, expires_at desc);
create index if not exists device_pairing_challenges_user_idx
  on public.device_pairing_challenges (user_id, created_at desc);

alter table public.device_pairing_challenges enable row level security;

drop policy if exists device_pairing_challenges_select_own on public.device_pairing_challenges;
create policy device_pairing_challenges_select_own on public.device_pairing_challenges
for select to authenticated
using ((select auth.uid()) = user_id);

grant select on public.device_pairing_challenges to authenticated;

comment on table public.device_pairing_challenges is 'Short-lived, single-use same-user pairing proofs; challenge plaintext is never stored.';
