-- Admin panel: role system va parking ownership
-- Users ga role ustun, parkings ga owner_id qo'shish
-- Owner lar o'z parkinglarini boshqara oladi

-- 1) Users jadvaliga role ustun
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS role TEXT NOT NULL DEFAULT 'customer';

-- 2) Parkings jadvaliga owner_id ustun
ALTER TABLE public.parkings ADD COLUMN IF NOT EXISTS owner_id UUID REFERENCES public.users(id);

-- 3) Users role update huquqi
GRANT UPDATE (role) ON public.users TO authenticated;

-- 4) Parkings uchun owner CRUD policies

-- Owner o'z parkinglarini update qila oladi
DROP POLICY IF EXISTS owners_update_own_parkings ON public.parkings;
CREATE POLICY owners_update_own_parkings
ON public.parkings
FOR UPDATE
TO authenticated
USING (owner_id = auth.uid())
WITH CHECK (owner_id = auth.uid());

-- Owner yangi parking qo'sha oladi
DROP POLICY IF EXISTS owners_insert_parkings ON public.parkings;
CREATE POLICY owners_insert_parkings
ON public.parkings
FOR INSERT
TO authenticated
WITH CHECK (
    owner_id = auth.uid()
    AND EXISTS (
        SELECT 1 FROM public.users
        WHERE id = auth.uid() AND role = 'owner'
    )
);

-- Owner o'z parkingini o'chira oladi
DROP POLICY IF EXISTS owners_delete_own_parkings ON public.parkings;
CREATE POLICY owners_delete_own_parkings
ON public.parkings
FOR DELETE
TO authenticated
USING (
    owner_id = auth.uid()
    AND EXISTS (
        SELECT 1 FROM public.users
        WHERE id = auth.uid() AND role = 'owner'
    )
);

-- Grant insert/update/delete on parkings for authenticated (RLS will enforce ownership)
GRANT INSERT, UPDATE, DELETE ON public.parkings TO authenticated;

-- 5) Owner o'z parkinglaridagi rezervatsiyalarni ko'ra oladi
DROP POLICY IF EXISTS owners_view_parking_reservations ON public.reservations;
CREATE POLICY owners_view_parking_reservations
ON public.reservations
FOR SELECT
TO authenticated
USING (
    user_id = auth.uid()
    OR parking_id IN (
        SELECT id FROM public.parkings WHERE owner_id = auth.uid()
    )
);

-- 6) Owner parking_availability ni ham ko'ra oladi (allaqachon select all bor)
-- Qo'shimcha policy kerak emas

-- 7) Owner parking_live_stats ni update qila oladi
DROP POLICY IF EXISTS owners_update_live_stats ON public.parking_live_stats;
CREATE POLICY owners_update_live_stats
ON public.parking_live_stats
FOR UPDATE
TO authenticated
USING (
    parking_id IN (
        SELECT id FROM public.parkings WHERE owner_id = auth.uid()
    )
);

GRANT UPDATE ON public.parking_live_stats TO authenticated;

-- 8) Admin analytics uchun RPC: owner parkinglarining daromadini hisoblash
CREATE OR REPLACE FUNCTION get_owner_dashboard_stats()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_result JSON;
BEGIN
    SELECT json_build_object(
        'total_parkings', (
            SELECT COUNT(*) FROM public.parkings WHERE owner_id = v_user_id
        ),
        'total_spots', (
            SELECT COALESCE(SUM(total_spots), 0) FROM public.parkings WHERE owner_id = v_user_id
        ),
        'active_reservations', (
            SELECT COUNT(*) FROM public.reservations r
            JOIN public.parkings p ON r.parking_id = p.id
            WHERE p.owner_id = v_user_id AND r.status IN ('active', 'in_use')
        ),
        'today_reservations', (
            SELECT COUNT(*) FROM public.reservations r
            JOIN public.parkings p ON r.parking_id = p.id
            WHERE p.owner_id = v_user_id
            AND r.start_time::date = CURRENT_DATE
        ),
        'total_completed', (
            SELECT COUNT(*) FROM public.reservations r
            JOIN public.parkings p ON r.parking_id = p.id
            WHERE p.owner_id = v_user_id AND r.status = 'completed'
        )
    ) INTO v_result;

    RETURN v_result;
END;
$$;
