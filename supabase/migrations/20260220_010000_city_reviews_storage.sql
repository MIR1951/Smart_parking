-- City filter + reviews + parking-images storage bucket

-- 1) Parkings city column
ALTER TABLE public.parkings
ADD COLUMN IF NOT EXISTS city text;

UPDATE public.parkings
SET city = CASE
    WHEN city IS NOT NULL AND btrim(city) <> '' THEN city
    WHEN lower(coalesce(address, '')) LIKE '%urganch%'
      OR lower(coalesce(address, '')) LIKE '%urgench%'
      OR lower(coalesce(address, '')) LIKE '%khorezm%'
      OR lower(coalesce(address, '')) LIKE '%xorazm%'
    THEN 'Urganch'
    ELSE 'Tashkent'
END;

ALTER TABLE public.parkings
ALTER COLUMN city SET DEFAULT 'Tashkent';

UPDATE public.parkings
SET city = 'Tashkent'
WHERE city IS NULL OR btrim(city) = '';

ALTER TABLE public.parkings
ALTER COLUMN city SET NOT NULL;

CREATE INDEX IF NOT EXISTS idx_parkings_city
ON public.parkings (city);

-- 2) Parking reviews
CREATE TABLE IF NOT EXISTS public.parking_reviews (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    parking_id uuid NOT NULL REFERENCES public.parkings(id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    reservation_id uuid NOT NULL REFERENCES public.reservations(id) ON DELETE CASCADE,
    rating int NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment text NOT NULL CHECK (char_length(btrim(comment)) > 0),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT parking_reviews_unique_reservation UNIQUE (reservation_id)
);

CREATE INDEX IF NOT EXISTS idx_parking_reviews_parking_created
ON public.parking_reviews (parking_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_parking_reviews_user_created
ON public.parking_reviews (user_id, created_at DESC);

ALTER TABLE public.parking_reviews ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS parking_reviews_select_all ON public.parking_reviews;
CREATE POLICY parking_reviews_select_all
ON public.parking_reviews
FOR SELECT
USING (true);

DROP POLICY IF EXISTS parking_reviews_insert_eligible ON public.parking_reviews;
CREATE POLICY parking_reviews_insert_eligible
ON public.parking_reviews
FOR INSERT
TO authenticated
WITH CHECK (
    auth.uid() = user_id
    AND EXISTS (
        SELECT 1
        FROM public.reservations r
        WHERE r.id = reservation_id
          AND r.user_id = auth.uid()
          AND r.parking_id = parking_id
          AND r.status IN ('completed', 'expired')
    )
);

DROP POLICY IF EXISTS parking_reviews_update_own ON public.parking_reviews;
CREATE POLICY parking_reviews_update_own
ON public.parking_reviews
FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS parking_reviews_delete_own ON public.parking_reviews;
CREATE POLICY parking_reviews_delete_own
ON public.parking_reviews
FOR DELETE
TO authenticated
USING (auth.uid() = user_id);

GRANT SELECT ON public.parking_reviews TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON public.parking_reviews TO authenticated;

CREATE OR REPLACE FUNCTION public.tg_set_updated_at_parking_reviews()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_set_updated_at_parking_reviews ON public.parking_reviews;
CREATE TRIGGER trg_set_updated_at_parking_reviews
BEFORE UPDATE ON public.parking_reviews
FOR EACH ROW
EXECUTE FUNCTION public.tg_set_updated_at_parking_reviews();

-- 3) Rating recompute from reviews
CREATE OR REPLACE FUNCTION public.recompute_parking_rating(p_parking_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_avg double precision;
BEGIN
    SELECT round(avg(r.rating)::numeric, 2)::double precision
      INTO v_avg
    FROM public.parking_reviews r
    WHERE r.parking_id = p_parking_id;

    UPDATE public.parkings
    SET rating = COALESCE(v_avg, 0)
    WHERE id = p_parking_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.tg_parking_reviews_recompute_rating()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        PERFORM public.recompute_parking_rating(OLD.parking_id);
        RETURN OLD;
    END IF;

    PERFORM public.recompute_parking_rating(NEW.parking_id);

    IF TG_OP = 'UPDATE' AND OLD.parking_id <> NEW.parking_id THEN
        PERFORM public.recompute_parking_rating(OLD.parking_id);
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_parking_reviews_recompute_rating ON public.parking_reviews;
CREATE TRIGGER trg_parking_reviews_recompute_rating
AFTER INSERT OR UPDATE OR DELETE
ON public.parking_reviews
FOR EACH ROW
EXECUTE FUNCTION public.tg_parking_reviews_recompute_rating();

DO $$
DECLARE
    r record;
BEGIN
    FOR r IN SELECT id FROM public.parkings LOOP
        PERFORM public.recompute_parking_rating(r.id);
    END LOOP;
END;
$$;

-- 4) Storage bucket for parking images
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'parking-images',
    'parking-images',
    true,
    5242880,
    ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE
SET public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

DROP POLICY IF EXISTS parking_images_public_read ON storage.objects;
CREATE POLICY parking_images_public_read
ON storage.objects
FOR SELECT
TO anon, authenticated
USING (bucket_id = 'parking-images');

DROP POLICY IF EXISTS parking_images_auth_insert ON storage.objects;
CREATE POLICY parking_images_auth_insert
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'parking-images');

DROP POLICY IF EXISTS parking_images_auth_update ON storage.objects;
CREATE POLICY parking_images_auth_update
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'parking-images')
WITH CHECK (bucket_id = 'parking-images');

DROP POLICY IF EXISTS parking_images_auth_delete ON storage.objects;
CREATE POLICY parking_images_auth_delete
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'parking-images');
