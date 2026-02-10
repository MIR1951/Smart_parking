-- Availability + Notification pipeline
-- - Single recompute source for parking availability
-- - Reservation and live-stats triggers
-- - Notification outbox with retry-safe dispatch

create or replace function public.recompute_parking_availability(
  p_pid uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_total integer;
  v_live integer;
  v_reserved integer;
  v_available integer;
begin
  if p_pid is null then
    return;
  end if;

  select p.total_spots
    into v_total
  from public.parkings p
  where p.id = p_pid;

  if not found then
    return;
  end if;

  select coalesce(pls.live_occupancy, 0)
    into v_live
  from public.parking_live_stats pls
  where pls.parking_id = p_pid;

  select count(*)
    into v_reserved
  from public.reservations r
  where r.parking_id = p_pid
    and r.status = 'active'
    and r.end_time > now();

  v_live := greatest(coalesce(v_live, 0), 0);
  v_reserved := greatest(coalesce(v_reserved, 0), 0);
  v_available := greatest(v_total - v_live - v_reserved, 0);

  insert into public.parking_availability (
    parking_id,
    live_occupancy,
    reserved_spots,
    available_spots,
    updated_at
  )
  values (
    p_pid,
    v_live,
    v_reserved,
    v_available,
    now()
  )
  on conflict (parking_id)
  do update
  set
    live_occupancy = excluded.live_occupancy,
    reserved_spots = excluded.reserved_spots,
    available_spots = excluded.available_spots,
    updated_at = now();
end;
$$;

create or replace function public.tg_reservations_recompute_availability()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_new uuid;
  v_old uuid;
begin
  if tg_op <> 'DELETE' then
    v_new := new.parking_id;
  end if;

  if tg_op <> 'INSERT' then
    v_old := old.parking_id;
  end if;

  if v_new is not null then
    perform public.recompute_parking_availability(v_new);
  end if;

  if v_old is not null and v_old is distinct from v_new then
    perform public.recompute_parking_availability(v_old);
  end if;

  return coalesce(new, old);
end;
$$;

create or replace function public.tg_live_stats_recompute_availability()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'DELETE' then
    perform public.recompute_parking_availability(old.parking_id);
    return old;
  end if;

  perform public.recompute_parking_availability(new.parking_id);
  return new;
end;
$$;

create or replace function public.tg_parkings_recompute_availability()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.recompute_parking_availability(new.id);
  return new;
end;
$$;

-- Clean legacy trigger names to avoid duplicate recomputes.
drop trigger if exists trg_recalc_availability on public.reservations;
drop trigger if exists trg_recompute_availability on public.reservations;
drop trigger if exists trg_reservation_recalc_availability on public.reservations;
drop trigger if exists trg_reservations_recompute_availability on public.reservations;
drop trigger if exists trg_reservations_refresh_availability on public.reservations;

drop trigger if exists trg_recompute_availability_live_stats on public.parking_live_stats;
drop trigger if exists trg_parking_live_stats_recompute_availability on public.parking_live_stats;

drop trigger if exists trg_parkings_total_spots_recompute on public.parkings;

create trigger trg_reservations_recompute_availability
after insert or update of parking_id, status, start_time, end_time, actual_start_time, actual_end_time or delete
on public.reservations
for each row
execute function public.tg_reservations_recompute_availability();

create trigger trg_parking_live_stats_recompute_availability
after insert or update of live_occupancy or delete
on public.parking_live_stats
for each row
execute function public.tg_live_stats_recompute_availability();

create trigger trg_parkings_total_spots_recompute
after update of total_spots
on public.parkings
for each row
execute function public.tg_parkings_recompute_availability();

-- Notification outbox
create table if not exists public.notification_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  reservation_id uuid references public.reservations(id) on delete cascade,
  type text not null,
  payload jsonb not null default '{}'::jsonb,
  status text not null default 'pending'
    check (status in ('pending', 'dispatched', 'failed')),
  attempts integer not null default 0,
  available_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  processed_at timestamptz,
  last_error text
);

create index if not exists idx_notification_events_pending
  on public.notification_events (status, available_at, created_at);

create index if not exists idx_notification_events_user_created
  on public.notification_events (user_id, created_at desc);

create unique index if not exists uq_notification_events_reservation_type
  on public.notification_events (reservation_id, type)
  where reservation_id is not null;

-- Keep only the latest notification per (reservation_id, type) before unique index creation.
with ranked_notifications as (
  select
    n.id,
    row_number() over (
      partition by n.reservation_id, n.type
      order by n.created_at desc, n.id desc
    ) as rn
  from public.notifications n
  where n.reservation_id is not null
)
delete from public.notifications n
using ranked_notifications rn
where n.id = rn.id
  and rn.rn > 1;

create unique index if not exists uq_notifications_reservation_type
  on public.notifications (reservation_id, type)
  where reservation_id is not null;

create or replace function public.enqueue_notification_event(
  p_user_id uuid,
  p_type text,
  p_reservation_id uuid default null,
  p_payload jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
begin
  insert into public.notification_events (
    user_id,
    type,
    reservation_id,
    payload
  )
  values (
    p_user_id,
    p_type,
    p_reservation_id,
    coalesce(p_payload, '{}'::jsonb)
  )
  on conflict (reservation_id, type)
  where reservation_id is not null
  do update
    set payload = excluded.payload,
        status = 'pending',
        available_at = now(),
        last_error = null
  returning id into v_id;

  return v_id;
end;
$$;

create or replace function public.dispatch_pending_notification_events(
  p_limit integer default 100
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count integer := 0;
  v_title text;
  v_message text;
  v_status text;
  rec record;
begin
  for rec in
    select ne.*
    from public.notification_events ne
    where ne.status = 'pending'
      and ne.available_at <= now()
    order by ne.created_at asc
    for update skip locked
    limit greatest(coalesce(p_limit, 100), 1)
  loop
    begin
      v_status := coalesce(rec.payload ->> 'status', '');

      case rec.type
        when 'booking_created' then
          v_title := 'Booking Confirmed!';
          v_message := 'Your parking spot has been successfully reserved.';
        when 'booking_canceled' then
          v_title := 'Booking Canceled';
          v_message := 'Your reservation was canceled.';
        when 'booking_started' then
          v_title := 'Parking Started';
          v_message := 'Your parking session has started.';
        when 'booking_completed' then
          v_title := 'Parking Completed';
          v_message := 'Your parking session is complete.';
        when 'time_warning_15' then
          v_title := '15 Minutes Left';
          v_message := 'Your parking session ends in 15 minutes.';
        when 'time_warning_5' then
          v_title := '5 Minutes Left';
          v_message := 'Your parking session ends in 5 minutes.';
        when 'time_expired' then
          v_title := 'Parking Time Expired';
          v_message := 'Your prepaid parking time has expired.';
        else
          v_title := coalesce(nullif(rec.payload ->> 'title', ''), 'Notification');
          v_message := coalesce(nullif(rec.payload ->> 'message', ''), 'You have a new update.');
      end case;

      insert into public.notifications (
        user_id,
        type,
        title,
        message,
        reservation_id
      )
      values (
        rec.user_id,
        rec.type,
        v_title,
        v_message,
        rec.reservation_id
      )
      on conflict (reservation_id, type)
      where reservation_id is not null
      do nothing;

      update public.notification_events
      set
        status = 'dispatched',
        attempts = attempts + 1,
        processed_at = now(),
        last_error = null
      where id = rec.id;

      v_count := v_count + 1;
    exception
      when others then
        update public.notification_events
        set
          attempts = attempts + 1,
          status = case when attempts + 1 >= 10 then 'failed' else 'pending' end,
          available_at = now() + make_interval(secs => least(60 * (attempts + 1), 600)),
          last_error = left(sqlerrm, 4000)
        where id = rec.id;
    end;
  end loop;

  return v_count;
end;
$$;

create or replace function public.tg_reservations_enqueue_notifications()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_type text;
begin
  if tg_op = 'INSERT' then
    if new.status = 'active' then
      perform public.enqueue_notification_event(
        new.user_id,
        'booking_created',
        new.id,
        jsonb_build_object('status', new.status)
      );
    end if;
    return new;
  end if;

  if tg_op = 'UPDATE' and new.status is distinct from old.status then
    v_type := case new.status
      when 'canceled' then 'booking_canceled'
      when 'in_use' then 'booking_started'
      when 'completed' then 'booking_completed'
      when 'expired' then 'time_expired'
      when 'no_show' then 'booking_canceled'
      else null
    end;

    if v_type is not null then
      perform public.enqueue_notification_event(
        new.user_id,
        v_type,
        new.id,
        jsonb_build_object(
          'from_status', old.status,
          'status', new.status
        )
      );
    end if;
  end if;

  return new;
end;
$$;

create or replace function public.tg_notification_events_dispatch()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.dispatch_pending_notification_events(200);
  return null;
end;
$$;

-- Replace old direct-notification trigger names if present.
drop trigger if exists trg_notify_booking_created on public.reservations;
drop trigger if exists trg_notify_reservation_created on public.reservations;
drop trigger if exists trg_reservations_enqueue_notifications on public.reservations;

create trigger trg_reservations_enqueue_notifications
after insert or update of status
on public.reservations
for each row
execute function public.tg_reservations_enqueue_notifications();

drop trigger if exists trg_notification_events_dispatch on public.notification_events;
create trigger trg_notification_events_dispatch
after insert on public.notification_events
for each statement
execute function public.tg_notification_events_dispatch();

-- Optional cron dispatch safety net (if pg_cron is available).
do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    begin
      if not exists (select 1 from cron.job where jobname = 'dispatch-notification-events') then
        perform cron.schedule(
          'dispatch-notification-events',
          '* * * * *',
          $job$select public.dispatch_pending_notification_events(500);$job$
        );
      end if;
    exception
      when others then
        raise notice 'pg_cron detected but schedule creation failed: %', sqlerrm;
    end;
  end if;
exception
  when undefined_table then
    raise notice 'cron.job metadata table not accessible; skipping schedule setup.';
end $$;

revoke all on function public.recompute_parking_availability(uuid) from public;
revoke all on function public.tg_reservations_recompute_availability() from public;
revoke all on function public.tg_live_stats_recompute_availability() from public;
revoke all on function public.tg_parkings_recompute_availability() from public;
revoke all on function public.enqueue_notification_event(uuid, text, uuid, jsonb) from public;
revoke all on function public.dispatch_pending_notification_events(integer) from public;
revoke all on function public.tg_reservations_enqueue_notifications() from public;
revoke all on function public.tg_notification_events_dispatch() from public;
