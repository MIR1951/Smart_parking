-- Reservation business logic hardening:
-- - Atomic reservation creation
-- - Controlled status transitions
-- - RPC wrappers for app-safe operations

create or replace function public.is_valid_reservation_transition(
  p_from text,
  p_to text
)
returns boolean
language sql
immutable
as $$
  select case
    when p_from = p_to then true
    when p_from = 'active' and p_to in ('in_use', 'canceled', 'expired', 'no_show') then true
    when p_from = 'in_use' and p_to in ('completed', 'expired') then true
    else false
  end;
$$;

create or replace function public.transition_reservation_status(
  p_reservation_id uuid,
  p_to_status text
)
returns public.reservations
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row public.reservations%rowtype;
  v_uid uuid;
begin
  v_uid := auth.uid();

  if v_uid is null and auth.role() <> 'service_role' then
    raise exception 'NOT_AUTHENTICATED' using errcode = '28000';
  end if;

  select *
    into v_row
  from public.reservations
  where id = p_reservation_id
  for update;

  if not found then
    raise exception 'RESERVATION_NOT_FOUND';
  end if;

  if auth.role() <> 'service_role' and v_row.user_id <> v_uid then
    raise exception 'FORBIDDEN' using errcode = '42501';
  end if;

  if not public.is_valid_reservation_transition(v_row.status, p_to_status) then
    raise exception 'INVALID_STATUS_TRANSITION: % -> %', v_row.status, p_to_status;
  end if;

  update public.reservations
  set
    status = p_to_status,
    actual_start_time = case
      when p_to_status = 'in_use' and actual_start_time is null then now()
      else actual_start_time
    end,
    actual_end_time = case
      when p_to_status in ('completed', 'expired', 'no_show', 'canceled')
           and actual_end_time is null then now()
      else actual_end_time
    end
  where id = v_row.id
  returning * into v_row;

  return v_row;
end;
$$;

create or replace function public.create_reservation(
  p_parking_id uuid,
  p_duration_minutes integer
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid;
  v_now timestamptz;
  v_end timestamptz;
  v_rate numeric;
  v_amount numeric;
  v_reservation_id uuid;
  v_parking public.parkings%rowtype;
  v_live_occupancy integer;
  v_spot_reserved boolean := false;
begin
  v_uid := auth.uid();

  if v_uid is null then
    raise exception 'NOT_AUTHENTICATED' using errcode = '28000';
  end if;

  if p_duration_minutes is null or p_duration_minutes <= 0 or p_duration_minutes > 1440 then
    raise exception 'INVALID_DURATION_MINUTES';
  end if;

  v_now := now();

  select *
    into v_parking
  from public.parkings
  where id = p_parking_id
  for update;

  if not found then
    raise exception 'PARKING_NOT_FOUND';
  end if;

  select coalesce(pls.live_occupancy, 0)
    into v_live_occupancy
  from public.parking_live_stats pls
  where pls.parking_id = p_parking_id;

  insert into public.parking_availability (
    parking_id,
    live_occupancy,
    reserved_spots,
    available_spots,
    updated_at
  )
  values (
    p_parking_id,
    coalesce(v_live_occupancy, 0),
    0,
    greatest(v_parking.total_spots - coalesce(v_live_occupancy, 0), 0),
    now()
  )
  on conflict (parking_id) do nothing;

  -- Lock availability row and reserve atomically.
  update public.parking_availability pa
  set
    reserved_spots = pa.reserved_spots + 1,
    available_spots = greatest(pa.available_spots - 1, 0),
    updated_at = now()
  where pa.parking_id = p_parking_id
    and pa.available_spots > 0;

  if not found then
    raise exception 'NO_SPOTS_AVAILABLE';
  end if;

  v_spot_reserved := true;

  v_end := v_now + make_interval(mins => p_duration_minutes);
  v_rate := coalesce(v_parking.price_per_hour, 0);
  v_amount := round((v_rate * (p_duration_minutes::numeric / 60.0))::numeric, 2);

  insert into public.reservations (
    parking_id,
    user_id,
    start_time,
    end_time,
    status,
    prepaid_minutes,
    rate_per_hour,
    prepaid_amount
  )
  values (
    p_parking_id,
    v_uid,
    v_now,
    v_end,
    'active',
    p_duration_minutes,
    v_rate,
    v_amount
  )
  returning id into v_reservation_id;

  return v_reservation_id;
exception
  when others then
    -- In case of failure after spot reservation, rollback reserved counter.
    if v_spot_reserved then
      update public.parking_availability pa
      set
        reserved_spots = greatest(pa.reserved_spots - 1, 0),
        available_spots = pa.available_spots + 1,
        updated_at = now()
      where pa.parking_id = p_parking_id;
    end if;
    raise;
end;
$$;

-- Existing environments may already have wrapper functions with different return types.
-- Drop them explicitly to avoid "cannot change return type" errors during migration.
drop function if exists public.cancel_reservation(uuid);
drop function if exists public.start_reservation(uuid);
drop function if exists public.complete_reservation(uuid);

create or replace function public.cancel_reservation(
  p_reservation_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.transition_reservation_status(p_reservation_id, 'canceled');
end;
$$;

create or replace function public.start_reservation(
  p_reservation_id uuid
)
returns public.reservations
language plpgsql
security definer
set search_path = public
as $$
begin
  return public.transition_reservation_status(p_reservation_id, 'in_use');
end;
$$;

create or replace function public.complete_reservation(
  p_reservation_id uuid
)
returns public.reservations
language plpgsql
security definer
set search_path = public
as $$
begin
  return public.transition_reservation_status(p_reservation_id, 'completed');
end;
$$;

revoke all on function public.is_valid_reservation_transition(text, text) from public;
revoke all on function public.transition_reservation_status(uuid, text) from public;
revoke all on function public.create_reservation(uuid, integer) from public;
revoke all on function public.cancel_reservation(uuid) from public;
revoke all on function public.start_reservation(uuid) from public;
revoke all on function public.complete_reservation(uuid) from public;

grant execute on function public.create_reservation(uuid, integer) to authenticated;
grant execute on function public.cancel_reservation(uuid) to authenticated;
grant execute on function public.start_reservation(uuid) to authenticated;
grant execute on function public.complete_reservation(uuid) to authenticated;
