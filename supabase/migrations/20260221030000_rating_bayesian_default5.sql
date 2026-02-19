-- Smart Parking
-- Rating default + Bayesian smoothing recompute

ALTER TABLE public.parkings
ALTER COLUMN rating SET DEFAULT 5;

UPDATE public.parkings
SET rating = 5
WHERE rating IS NULL OR rating <= 0;

CREATE OR REPLACE FUNCTION public.recompute_parking_rating(p_parking_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_avg double precision;
    v_count integer;
    v_score double precision;
BEGIN
    SELECT
        COALESCE(avg(r.rating)::double precision, 5.0),
        count(*)::integer
    INTO v_avg, v_count
    FROM public.parking_reviews r
    WHERE r.parking_id = p_parking_id;

    v_score := ((v_avg * v_count) + (5.0 * 3.0)) / (v_count + 3.0);
    v_score := round(LEAST(GREATEST(v_score, 1.0), 5.0)::numeric, 2)::double precision;

    UPDATE public.parkings
    SET rating = v_score
    WHERE id = p_parking_id;
END;
$$;

DO $$
DECLARE
    r record;
BEGIN
    FOR r IN SELECT id FROM public.parkings LOOP
        PERFORM public.recompute_parking_rating(r.id);
    END LOOP;
END;
$$;
