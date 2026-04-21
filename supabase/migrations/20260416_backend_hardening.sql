-- =============================================================================
-- Backend Hardening Migration
-- Fixes: SECURITY DEFINER view, dangerous RLS policies, auth.uid() performance,
--        duplicate indexes, missing FK index, parking_reviews bug, new RPCs
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Fix parking_status view: remove SECURITY DEFINER (ERROR)
-- ─────────────────────────────────────────────────────────────────────────────
DROP VIEW IF EXISTS public.parking_status;
CREATE VIEW public.parking_status
WITH (security_invoker = true)
AS
  SELECT
    p.id,
    p.name,
    p.address,
    p.total_spots,
    p.thumbnail_url,
    COALESCE(ls.live_occupancy, 0) AS live_occupancy,
    (SELECT count(*)::int
       FROM reservations r
      WHERE r.parking_id = p.id
        AND r.status = ANY(ARRAY['active','in_use'])
        AND r.end_time > now()) AS reserved_spots,
    (p.total_spots
      - COALESCE(ls.live_occupancy, 0)
      - (SELECT count(*)::int
           FROM reservations r
          WHERE r.parking_id = p.id
            AND r.status = ANY(ARRAY['active','in_use'])
            AND r.end_time > now())) AS available_spots
  FROM parkings p
  LEFT JOIN parking_live_stats ls ON ls.parking_id = p.id;

GRANT SELECT ON public.parking_status TO authenticated, anon;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. Drop dangerous / duplicate RLS policies
-- ─────────────────────────────────────────────────────────────────────────────

-- parking_availability: USING(true)+WITH CHECK(true) — kim bo'lsa yoza oladi
DROP POLICY IF EXISTS "Allow all on parking_availability"  ON public.parking_availability;
DROP POLICY IF EXISTS "Allow update parking_availability"  ON public.parking_availability;
DROP POLICY IF EXISTS "availability_public_read"           ON public.parking_availability;
DROP POLICY IF EXISTS "public read availability"           ON public.parking_availability;

-- users: WITH CHECK(true) — har kim ixtiyoriy user insert qila oladi
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.users;
-- users: USING(true) — barcha user ma'lumotlari hammaga ochiq
DROP POLICY IF EXISTS "Enable read access for all users"          ON public.users;
-- users: JWT email-based update — users_update_own bilan duplicate
DROP POLICY IF EXISTS "Policy with table joins"                   ON public.users;

-- parkings: to'liq duplicate SELECT policy
DROP POLICY IF EXISTS "parkings_public_read" ON public.parkings;

-- reservations: duplicate INSERT policies
DROP POLICY IF EXISTS "allow_reservation_rpc"   ON public.reservations;
-- reservations: duplicate SELECT policies
DROP POLICY IF EXISTS "select_own_reservations" ON public.reservations;
-- reservations: keraksiz UPDATE (status RPC orqali o'zgaradi)
DROP POLICY IF EXISTS "update_own_reservations" ON public.reservations;

-- notifications: ALL commands + ALL roles — boshqa aniq policylar bilan overlap
DROP POLICY IF EXISTS "Users see own" ON public.notifications;

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. auth.uid() → (select auth.uid()) — har qator uchun re-evaluation oldini olish
-- ─────────────────────────────────────────────────────────────────────────────

-- === USERS ===
DROP POLICY IF EXISTS users_select_own ON public.users;
CREATE POLICY users_select_own ON public.users
  FOR SELECT TO authenticated
  USING ((select auth.uid()) = id);

DROP POLICY IF EXISTS users_insert_own ON public.users;
CREATE POLICY users_insert_own ON public.users
  FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = id);

DROP POLICY IF EXISTS users_update_own ON public.users;
CREATE POLICY users_update_own ON public.users
  FOR UPDATE TO authenticated
  USING  ((select auth.uid()) = id)
  WITH CHECK ((select auth.uid()) = id);

-- === RESERVATIONS ===
-- Eski ikki SELECT policy o'rniga bitta — customer + owner ikkalasini qoplaydi
DROP POLICY IF EXISTS reservations_select_own          ON public.reservations;
DROP POLICY IF EXISTS owners_view_parking_reservations ON public.reservations;
CREATE POLICY reservations_select ON public.reservations
  FOR SELECT TO authenticated
  USING (
    user_id = (select auth.uid())
    OR parking_id IN (
      SELECT id FROM parkings WHERE owner_id = (select auth.uid())
    )
  );

DROP POLICY IF EXISTS insert_reservation_rpc ON public.reservations;
CREATE POLICY insert_reservation_rpc ON public.reservations
  FOR INSERT TO authenticated
  WITH CHECK (user_id = (select auth.uid()));

-- === NOTIFICATIONS ===
DROP POLICY IF EXISTS notifications_select_own ON public.notifications;
CREATE POLICY notifications_select_own ON public.notifications
  FOR SELECT TO authenticated
  USING (user_id = (select auth.uid()));

DROP POLICY IF EXISTS notifications_update_own ON public.notifications;
CREATE POLICY notifications_update_own ON public.notifications
  FOR UPDATE TO authenticated
  USING  (user_id = (select auth.uid()))
  WITH CHECK (user_id = (select auth.uid()));

-- === USER_WALLETS ===
DROP POLICY IF EXISTS user_wallets_select ON public.user_wallets;
CREATE POLICY user_wallets_select ON public.user_wallets
  FOR SELECT TO authenticated
  USING (user_id = (select auth.uid()));

DROP POLICY IF EXISTS user_wallets_insert ON public.user_wallets;
CREATE POLICY user_wallets_insert ON public.user_wallets
  FOR INSERT TO authenticated
  WITH CHECK (user_id = (select auth.uid()));

DROP POLICY IF EXISTS user_wallets_update ON public.user_wallets;
CREATE POLICY user_wallets_update ON public.user_wallets
  FOR UPDATE TO authenticated
  USING  (user_id = (select auth.uid()))
  WITH CHECK (user_id = (select auth.uid()));

-- === WALLET_TRANSACTIONS ===
DROP POLICY IF EXISTS wallet_transactions_select ON public.wallet_transactions;
CREATE POLICY wallet_transactions_select ON public.wallet_transactions
  FOR SELECT TO authenticated
  USING (user_id = (select auth.uid()));

DROP POLICY IF EXISTS wallet_transactions_insert ON public.wallet_transactions;
CREATE POLICY wallet_transactions_insert ON public.wallet_transactions
  FOR INSERT TO authenticated
  WITH CHECK (user_id = (select auth.uid()));

-- === USER_VEHICLES ===
DROP POLICY IF EXISTS user_vehicles_select ON public.user_vehicles;
CREATE POLICY user_vehicles_select ON public.user_vehicles
  FOR SELECT TO authenticated
  USING (user_id = (select auth.uid()));

DROP POLICY IF EXISTS user_vehicles_insert ON public.user_vehicles;
CREATE POLICY user_vehicles_insert ON public.user_vehicles
  FOR INSERT TO authenticated
  WITH CHECK (user_id = (select auth.uid()));

DROP POLICY IF EXISTS user_vehicles_update ON public.user_vehicles;
CREATE POLICY user_vehicles_update ON public.user_vehicles
  FOR UPDATE TO authenticated
  USING (user_id = (select auth.uid()));

DROP POLICY IF EXISTS user_vehicles_delete ON public.user_vehicles;
CREATE POLICY user_vehicles_delete ON public.user_vehicles
  FOR DELETE TO authenticated
  USING (user_id = (select auth.uid()));

-- === PARKING_REVIEWS: Bug fix + (select auth.uid()) ===
-- BUG was: r.parking_id = r.parking_id (always true — any reservation passed check)
DROP POLICY IF EXISTS parking_reviews_insert_eligible ON public.parking_reviews;
CREATE POLICY parking_reviews_insert_eligible ON public.parking_reviews
  FOR INSERT TO authenticated
  WITH CHECK (
    (select auth.uid()) = user_id
    AND EXISTS (
      SELECT 1 FROM reservations r
       WHERE r.id = reservation_id
         AND r.user_id  = (select auth.uid())
         AND r.parking_id = parking_reviews.parking_id
         AND r.status = ANY(ARRAY['completed','expired'])
    )
  );

DROP POLICY IF EXISTS parking_reviews_update_own ON public.parking_reviews;
CREATE POLICY parking_reviews_update_own ON public.parking_reviews
  FOR UPDATE TO authenticated
  USING  ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS parking_reviews_delete_own ON public.parking_reviews;
CREATE POLICY parking_reviews_delete_own ON public.parking_reviews
  FOR DELETE TO authenticated
  USING ((select auth.uid()) = user_id);

-- === PARKINGS (owner policies) ===
DROP POLICY IF EXISTS owners_update_own_parkings ON public.parkings;
CREATE POLICY owners_update_own_parkings ON public.parkings
  FOR UPDATE TO authenticated
  USING  (owner_id = (select auth.uid()))
  WITH CHECK (owner_id = (select auth.uid()));

DROP POLICY IF EXISTS owners_insert_parkings ON public.parkings;
CREATE POLICY owners_insert_parkings ON public.parkings
  FOR INSERT TO authenticated
  WITH CHECK (
    owner_id = (select auth.uid())
    AND EXISTS (
      SELECT 1 FROM users
       WHERE id = (select auth.uid()) AND role = 'owner'
    )
  );

DROP POLICY IF EXISTS owners_delete_own_parkings ON public.parkings;
CREATE POLICY owners_delete_own_parkings ON public.parkings
  FOR DELETE TO authenticated
  USING (
    owner_id = (select auth.uid())
    AND EXISTS (
      SELECT 1 FROM users
       WHERE id = (select auth.uid()) AND role = 'owner'
    )
  );

-- === PARKING_LIVE_STATS ===
DROP POLICY IF EXISTS owners_update_live_stats ON public.parking_live_stats;
CREATE POLICY owners_update_live_stats ON public.parking_live_stats
  FOR UPDATE TO authenticated
  USING (
    parking_id IN (
      SELECT id FROM parkings WHERE owner_id = (select auth.uid())
    )
  );

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. Indexes: add missing FK index, drop duplicate indexes
-- ─────────────────────────────────────────────────────────────────────────────

-- Missing FK index on parkings.owner_id
CREATE INDEX IF NOT EXISTS idx_parkings_owner_id
  ON public.parkings (owner_id);

-- Drop duplicate indexes (shorter-named equivalents kept)
DROP INDEX IF EXISTS public.idx_reservations_user_created_at;         -- dup of idx_reservations_user_created
DROP INDEX IF EXISTS public.idx_reservations_parking_status_end_time; -- dup of idx_reservations_parking_status_end
DROP INDEX IF EXISTS public.idx_reservations_user_status_end_time;    -- dup of idx_reservations_user_status_end
DROP INDEX IF EXISTS public.idx_notifications_user_read_created_at;   -- dup of idx_notifications_user_read_created

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. Fix function search_path (SQL injection prevention)
-- ─────────────────────────────────────────────────────────────────────────────

-- Core RPCs
ALTER FUNCTION public.wallet_top_up(bigint, text)
  SET search_path = public, pg_catalog;
ALTER FUNCTION public.wallet_deduct(bigint, text)
  SET search_path = public, pg_catalog;
ALTER FUNCTION public.create_reservation(uuid, integer)
  SET search_path = public, pg_catalog;
ALTER FUNCTION public.cancel_reservation(uuid)
  SET search_path = public, pg_catalog;
ALTER FUNCTION public.start_reservation(uuid)
  SET search_path = public, pg_catalog;
ALTER FUNCTION public.complete_reservation(uuid)
  SET search_path = public, pg_catalog;
ALTER FUNCTION public.get_owner_dashboard_stats()
  SET search_path = public, pg_catalog;
ALTER FUNCTION public.transition_reservation_status(uuid, text)
  SET search_path = public, pg_catalog;
ALTER FUNCTION public.check_in_reservation(uuid)
  SET search_path = public, pg_catalog;
ALTER FUNCTION public.complete_reservation_with_payment(uuid)
  SET search_path = public, pg_catalog;
ALTER FUNCTION public.calculate_exit_payment(uuid)
  SET search_path = public, pg_catalog;

-- Availability RPCs
ALTER FUNCTION public.recompute_parking_availability(uuid)
  SET search_path = public, pg_catalog;
ALTER FUNCTION public.recalc_availability(uuid)
  SET search_path = public, pg_catalog;
ALTER FUNCTION public.refresh_availability_time_based()
  SET search_path = public, pg_catalog;
ALTER FUNCTION public.expire_old_reservations_and_recompute()
  SET search_path = public, pg_catalog;
ALTER FUNCTION public.update_expired_reservations()
  SET search_path = public, pg_catalog;

-- Rating RPCs
ALTER FUNCTION public.recompute_parking_rating(uuid)
  SET search_path = public, pg_catalog;
ALTER FUNCTION public.round_up_12_minutes(integer)
  SET search_path = public, pg_catalog;
ALTER FUNCTION public.round_up_to_12(integer)
  SET search_path = public, pg_catalog;

-- Notification RPCs
ALTER FUNCTION public.enqueue_notification_event(uuid, text, uuid, jsonb)
  SET search_path = public, pg_catalog;
ALTER FUNCTION public.dispatch_pending_notification_events(integer)
  SET search_path = public, pg_catalog;

-- Validation helpers
ALTER FUNCTION public.is_valid_reservation_transition(text, text)
  SET search_path = public, pg_catalog;

-- Trigger functions
ALTER FUNCTION public.tg_reservations_recompute_availability()
  SET search_path = public, pg_catalog;
ALTER FUNCTION public.tg_live_stats_recompute_availability()
  SET search_path = public, pg_catalog;
ALTER FUNCTION public.tg_parkings_recompute_availability()
  SET search_path = public, pg_catalog;
ALTER FUNCTION public.tg_reservations_enqueue_notifications()
  SET search_path = public, pg_catalog;
ALTER FUNCTION public.tg_notification_events_dispatch()
  SET search_path = public, pg_catalog;
ALTER FUNCTION public.tg_set_updated_at_parking_reviews()
  SET search_path = public, pg_catalog;
ALTER FUNCTION public.tg_parking_reviews_recompute_rating()
  SET search_path = public, pg_catalog;
ALTER FUNCTION public.notify_booking_created()
  SET search_path = public, pg_catalog;
ALTER FUNCTION public.check_reservation_status_update()
  SET search_path = public, pg_catalog;
ALTER FUNCTION public.trg_live_stats_recalc()
  SET search_path = public, pg_catalog;
ALTER FUNCTION public.trg_recompute_from_live_stats()
  SET search_path = public, pg_catalog;
ALTER FUNCTION public.trg_recompute_from_reservations()
  SET search_path = public, pg_catalog;
ALTER FUNCTION public.trg_reservations_recalc()
  SET search_path = public, pg_catalog;

-- ─────────────────────────────────────────────────────────────────────────────
-- 6. New RPCs to eliminate N+1 patterns in Swift
-- ─────────────────────────────────────────────────────────────────────────────

-- 6a. get_distinct_cities: replaces full-table scan + client-side dedup
CREATE OR REPLACE FUNCTION public.get_distinct_cities()
RETURNS TABLE(city TEXT)
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
  SELECT DISTINCT city
    FROM parkings
   WHERE city IS NOT NULL
   ORDER BY city;
$$;
GRANT EXECUTE ON FUNCTION public.get_distinct_cities() TO authenticated;

-- 6b. get_owner_reservations: replaces N queries (one per parking) with 1
CREATE OR REPLACE FUNCTION public.get_owner_reservations(p_limit INT DEFAULT 200)
RETURNS SETOF reservations
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
  SELECT r.*
    FROM reservations r
    JOIN parkings p ON p.id = r.parking_id
   WHERE p.owner_id = (select auth.uid())
   ORDER BY r.start_time DESC
   LIMIT p_limit;
$$;
GRANT EXECUTE ON FUNCTION public.get_owner_reservations(INT) TO authenticated;
