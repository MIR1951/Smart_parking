-- Backend hardening: canonical columns, integrity constraints, and baseline indexes.

create extension if not exists pgcrypto;

-- Normalize users column names to snake_case used by the app model.
do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public' and table_name = 'users' and column_name = 'createdat'
  ) then
    execute 'alter table public.users rename column createdat to created_at';
  end if;

  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public' and table_name = 'users' and column_name = 'createdAt'
  ) then
    execute 'alter table public.users rename column "createdAt" to created_at';
  end if;

  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public' and table_name = 'users' and column_name = 'profileimageurl'
  ) then
    execute 'alter table public.users rename column profileimageurl to profile_image_url';
  end if;

  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public' and table_name = 'users' and column_name = 'profileImageURL'
  ) then
    execute 'alter table public.users rename column "profileImageURL" to profile_image_url';
  end if;
end $$;

-- Ensure users.id is always bound to auth.users.id values.
alter table public.users
  alter column id set not null;

alter table public.users
  alter column id drop default;

alter table public.users
  alter column created_at set default now();

update public.users
set created_at = now()
where created_at is null;

alter table public.users
  alter column created_at set not null;

-- Optional but recommended auth linkage.
do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'users_id_auth_fkey'
      and conrelid = 'public.users'::regclass
  ) then
    alter table public.users
      add constraint users_id_auth_fkey
      foreign key (id) references auth.users(id)
      on delete cascade
      not valid;
  end if;
end $$;

-- Validate if existing rows are already aligned; if not, keep NOT VALID and proceed.
do $$
begin
  alter table public.users validate constraint users_id_auth_fkey;
exception
  when others then
    raise notice 'users_id_auth_fkey left as NOT VALID. Clean orphan users rows then validate.';
end $$;

-- Drop clearly invalid reservations before enabling strict constraints.
-- Break notification FK links first to avoid migration failure on delete.
update public.notifications n
set reservation_id = null
from public.reservations r
where n.reservation_id = r.id
  and (r.user_id is null or r.parking_id is null);

delete from public.reservations
where user_id is null
   or parking_id is null;

alter table public.reservations
  alter column user_id set not null;

alter table public.reservations
  alter column parking_id set not null;

-- Booking consistency checks.
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'reservations_time_check'
      and conrelid = 'public.reservations'::regclass
  ) then
    alter table public.reservations
      add constraint reservations_time_check
      check (end_time > start_time);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'reservations_financial_check'
      and conrelid = 'public.reservations'::regclass
  ) then
    alter table public.reservations
      add constraint reservations_financial_check
      check (
        prepaid_minutes > 0
        and rate_per_hour >= 0
        and prepaid_amount >= 0
      );
  end if;
end $$;

-- Notifications defaults and null safety.
update public.notifications
set is_read = false
where is_read is null;

update public.notifications
set created_at = now()
where created_at is null;

alter table public.notifications
  alter column is_read set default false,
  alter column is_read set not null,
  alter column created_at set default now(),
  alter column created_at set not null,
  alter column user_id set not null;

-- Availability must never go below zero.
update public.parking_availability
set live_occupancy = greatest(live_occupancy, 0),
    reserved_spots = greatest(reserved_spots, 0),
    available_spots = greatest(available_spots, 0);

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'parking_availability_nonnegative_check'
      and conrelid = 'public.parking_availability'::regclass
  ) then
    alter table public.parking_availability
      add constraint parking_availability_nonnegative_check
      check (
        live_occupancy >= 0
        and reserved_spots >= 0
        and available_spots >= 0
      );
  end if;
end $$;

-- Baseline indexes for current app query patterns.
create index if not exists idx_reservations_user_created_at
  on public.reservations (user_id, created_at desc);

create index if not exists idx_reservations_user_status_end_time
  on public.reservations (user_id, status, end_time desc);

create index if not exists idx_reservations_parking_status_end_time
  on public.reservations (parking_id, status, end_time);

create index if not exists idx_notifications_user_read_created_at
  on public.notifications (user_id, is_read, created_at desc);

create index if not exists idx_notifications_user_created_at
  on public.notifications (user_id, created_at desc);

create index if not exists idx_parkings_is_popular
  on public.parkings (id)
  where is_popular = true;

create index if not exists idx_parking_availability_updated_at
  on public.parking_availability (updated_at desc);

create index if not exists idx_parking_live_stats_updated_at
  on public.parking_live_stats (updated_at desc);
