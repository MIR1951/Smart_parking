-- RLS and permission hardening for app-facing tables.

alter table public.users enable row level security;
alter table public.reservations enable row level security;
alter table public.notifications enable row level security;
alter table public.parkings enable row level security;
alter table public.parking_availability enable row level security;
alter table public.parking_live_stats enable row level security;
alter table public.notification_events enable row level security;

-- USERS

drop policy if exists users_select_own on public.users;
create policy users_select_own
on public.users
for select
to authenticated
using (id = auth.uid());

drop policy if exists users_insert_own on public.users;
create policy users_insert_own
on public.users
for insert
to authenticated
with check (id = auth.uid());

drop policy if exists users_update_own on public.users;
create policy users_update_own
on public.users
for update
to authenticated
using (id = auth.uid())
with check (id = auth.uid());

-- RESERVATIONS

drop policy if exists reservations_select_own on public.reservations;
create policy reservations_select_own
on public.reservations
for select
to authenticated
using (user_id = auth.uid());

-- No direct insert/update/delete policy for authenticated users.
-- Mutations must go through SECURITY DEFINER RPCs.

-- NOTIFICATIONS

drop policy if exists notifications_select_own on public.notifications;
create policy notifications_select_own
on public.notifications
for select
to authenticated
using (user_id = auth.uid());

drop policy if exists notifications_update_own on public.notifications;
create policy notifications_update_own
on public.notifications
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

-- PARKINGS + AVAILABILITY (read-only for app users)

drop policy if exists parkings_select_all on public.parkings;
create policy parkings_select_all
on public.parkings
for select
to authenticated
using (true);

drop policy if exists parking_availability_select_all on public.parking_availability;
create policy parking_availability_select_all
on public.parking_availability
for select
to authenticated
using (true);

drop policy if exists parking_live_stats_select_all on public.parking_live_stats;
create policy parking_live_stats_select_all
on public.parking_live_stats
for select
to authenticated
using (true);

-- Optional anonymous read (remove if app always authenticated).
drop policy if exists parkings_select_anon on public.parkings;
create policy parkings_select_anon
on public.parkings
for select
to anon
using (true);

drop policy if exists parking_availability_select_anon on public.parking_availability;
create policy parking_availability_select_anon
on public.parking_availability
for select
to anon
using (true);

-- Keep notification outbox internal-only.
revoke all on public.notification_events from anon, authenticated;

-- Table privileges aligned with RLS intent.
revoke all on public.users from anon;
grant select, insert on public.users to authenticated;
revoke update on public.users from authenticated;
grant update (username, profile_image_url) on public.users to authenticated;

revoke all on public.reservations from anon;
revoke insert, update, delete on public.reservations from authenticated;
grant select on public.reservations to authenticated;

grant select on public.notifications to authenticated;
revoke update on public.notifications from authenticated;
grant update (is_read) on public.notifications to authenticated;

grant select on public.parkings to anon, authenticated;
grant select on public.parking_availability to anon, authenticated;
grant select on public.parking_live_stats to authenticated;
