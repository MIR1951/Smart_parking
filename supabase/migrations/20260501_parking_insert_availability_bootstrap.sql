-- Yangi parking yaratilganda parking_live_stats va parking_availability
-- avtomatik default qator bilan to'ldiriladi. Aks holda create_reservation RPC
-- "null value in column live_occupancy" xatosi bilan tushadi.

create or replace function public.tg_parkings_bootstrap_availability()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.parking_live_stats (parking_id, live_occupancy)
  values (new.id, 0)
  on conflict (parking_id) do nothing;

  perform public.recompute_parking_availability(new.id);
  return new;
end;
$$;

drop trigger if exists trg_parkings_bootstrap_availability on public.parkings;

create trigger trg_parkings_bootstrap_availability
after insert on public.parkings
for each row
execute function public.tg_parkings_bootstrap_availability();

-- Backfill: trigger qo'shilgunga qadar yaratilgan parkinglarni ham tuzatamiz.
insert into public.parking_live_stats (parking_id, live_occupancy)
select p.id, 0
from public.parkings p
left join public.parking_live_stats pls on pls.parking_id = p.id
where pls.parking_id is null;

do $$
declare
  r record;
begin
  for r in
    select p.id
    from public.parkings p
    left join public.parking_availability pa on pa.parking_id = p.id
    where pa.parking_id is null
  loop
    perform public.recompute_parking_availability(r.id);
  end loop;
end$$;
