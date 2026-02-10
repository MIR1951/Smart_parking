# Supabase Backend Upgrade Pack

This folder contains production-focused migrations for business-logic correctness and backend performance.

## Migration Order

1. `20260206030000_schema_hardening.sql`
2. `20260206031000_reservation_state_machine.sql`
3. `20260206032000_availability_and_notification_pipeline.sql`
4. `20260206033000_rls_and_access_policies.sql`

## What This Adds

- Canonical `users` column mapping (`created_at`, `profile_image_url`) and stronger constraints.
- Atomic `create_reservation` RPC.
- Strict reservation status transition guard (`transition_reservation_status`).
- App-safe RPCs (`cancel_reservation`, `start_reservation`, `complete_reservation`).
- Single-source availability recomputation with deterministic triggers.
- Notification outbox + dispatch retry flow + optional cron safety net.
- RLS policies and narrowed privileges for authenticated clients.

## App Integration

After running migrations, app cancellation should call:
- `rpc("cancel_reservation", { p_reservation_id: ... })`

Direct `update reservations set status=...` should be avoided.

## Suggested Verification

```sql
select public.create_reservation('<parking_uuid>', 60);
select * from public.reservations order by created_at desc limit 5;
select * from public.parking_availability where parking_id = '<parking_uuid>';
select public.cancel_reservation('<reservation_uuid>');
select * from public.notification_events order by created_at desc limit 10;
select * from public.notifications order by created_at desc limit 10;
```
