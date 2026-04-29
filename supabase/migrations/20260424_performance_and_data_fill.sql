-- ============================================================
-- Smart Parking — Performance & Data Fill Migration
-- 2026-04-24
-- ============================================================
-- 1. Schema additiv ustunlar
-- 2. Index tozalash + yangi indekslar
-- 3. Spatial extension + index
-- 4. get_parkings_by_city va get_nearby_parkings RPC
-- 5. Test row o'chirish
-- 6. Barcha 18 parking — 5 ta rasm + to'liq metadata
-- ============================================================

-- ── 1. SCHEMA ──────────────────────────────────────────────
ALTER TABLE public.parkings
  ADD COLUMN IF NOT EXISTS working_hours text DEFAULT '24/7',
  ADD COLUMN IF NOT EXISTS phone        text,
  ADD COLUMN IF NOT EXISTS covered      boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS max_height_cm integer;

-- ── 2. INDEX TOZALASH ──────────────────────────────────────
-- Duplicate: idx_parkings_is_popular va idx_parkings_popular bir xil
DROP INDEX IF EXISTS public.idx_parkings_is_popular;
-- Duplicate: parking_availability da 2 xil nom, bir xil ustun
DROP INDEX IF EXISTS public.idx_parking_availability_updated;

-- Yangi composite: city filtri + popular sort (HomeView uchun)
CREATE INDEX IF NOT EXISTS idx_parkings_city_popular
  ON public.parkings(city) WHERE is_popular = true;

-- Yangi: city + created_at (admin list sort uchun)
CREATE INDEX IF NOT EXISTS idx_parkings_city_created
  ON public.parkings(city, created_at DESC);

-- ── 3. EARTHDISTANCE (yaqin parking) ───────────────────────
CREATE EXTENSION IF NOT EXISTS cube;
CREATE EXTENSION IF NOT EXISTS earthdistance;

CREATE INDEX IF NOT EXISTS idx_parkings_earth
  ON public.parkings USING gist (ll_to_earth(latitude, longitude));

-- ── 4. RPC: get_parkings_by_city ───────────────────────────
CREATE OR REPLACE FUNCTION public.get_parkings_by_city(
  p_city    text,
  p_limit   int DEFAULT 100,
  p_offset  int DEFAULT 0
)
RETURNS TABLE (
  id             uuid,
  name           text,
  city           text,
  address        text,
  latitude       double precision,
  longitude      double precision,
  price_per_hour numeric,
  rating         double precision,
  thumbnail_url  text,
  total_spots    integer,
  description    text,
  is_popular     boolean,
  images         text[],
  features       text[],
  owner_id       uuid,
  working_hours  text,
  phone          text,
  covered        boolean,
  max_height_cm  integer,
  live_occupancy integer
)
LANGUAGE sql STABLE SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT
    p.id, p.name, p.city, p.address,
    p.latitude, p.longitude,
    p.price_per_hour, p.rating, p.thumbnail_url,
    p.total_spots, p.description, p.is_popular,
    p.images, p.features, p.owner_id,
    p.working_hours, p.phone, p.covered, p.max_height_cm,
    COALESCE(pls.live_occupancy, 0) AS live_occupancy
  FROM public.parkings p
  LEFT JOIN public.parking_live_stats pls ON pls.parking_id = p.id
  WHERE p.city = p_city
  ORDER BY p.is_popular DESC NULLS LAST, p.rating DESC NULLS LAST
  LIMIT  p_limit
  OFFSET p_offset
$$;

GRANT EXECUTE ON FUNCTION public.get_parkings_by_city(text, int, int)
  TO authenticated, anon;

-- ── 4b. RPC: get_nearby_parkings ───────────────────────────
CREATE OR REPLACE FUNCTION public.get_nearby_parkings(
  p_lat       double precision,
  p_lng       double precision,
  p_radius_km double precision DEFAULT 5,
  p_limit     int DEFAULT 20
)
RETURNS TABLE (
  id             uuid,
  name           text,
  city           text,
  address        text,
  latitude       double precision,
  longitude      double precision,
  price_per_hour numeric,
  rating         double precision,
  thumbnail_url  text,
  total_spots    integer,
  description    text,
  is_popular     boolean,
  images         text[],
  features       text[],
  owner_id       uuid,
  working_hours  text,
  phone          text,
  covered        boolean,
  max_height_cm  integer,
  live_occupancy integer,
  distance_km    double precision
)
LANGUAGE sql STABLE SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT
    p.id, p.name, p.city, p.address,
    p.latitude, p.longitude,
    p.price_per_hour, p.rating, p.thumbnail_url,
    p.total_spots, p.description, p.is_popular,
    p.images, p.features, p.owner_id,
    p.working_hours, p.phone, p.covered, p.max_height_cm,
    COALESCE(pls.live_occupancy, 0) AS live_occupancy,
    ROUND(
      (earth_distance(
         ll_to_earth(p.latitude, p.longitude),
         ll_to_earth(p_lat, p_lng)
       ) / 1000.0)::numeric,
      2
    )::double precision AS distance_km
  FROM public.parkings p
  LEFT JOIN public.parking_live_stats pls ON pls.parking_id = p.id
  WHERE earth_box(ll_to_earth(p_lat, p_lng), p_radius_km * 1000)
          @> ll_to_earth(p.latitude, p.longitude)
    AND earth_distance(
          ll_to_earth(p.latitude, p.longitude),
          ll_to_earth(p_lat, p_lng)
        ) <= p_radius_km * 1000
  ORDER BY ll_to_earth(p.latitude, p.longitude)
             <-> ll_to_earth(p_lat, p_lng)
  LIMIT p_limit
$$;

GRANT EXECUTE ON FUNCTION public.get_nearby_parkings(double precision, double precision, double precision, int)
  TO authenticated, anon;

-- ── 5. TEST ROW O'CHIRISH ───────────────────────────────────
DELETE FROM public.parkings WHERE name = 'As' AND city = 'Urganch';

-- ── 6. DATA UPDATE ─────────────────────────────────────────
-- 5 ta rasm + working_hours + phone + covered + max_height_cm
-- thumbnail_url = images[1] bilan to'g'rilandi (Urganch storage → Unsplash)
--
-- Unsplash URL pool (existing seed'dan tasdiqlangan):
--  P1 = photo-1590674899484-d5640e854abe  (parking building)
--  P2 = photo-1573348722427-f1d6819fdf98  (parking lot)
--  P3 = photo-1506521781263-d8422e82f27a  (garage inside)
--  P4 = photo-1621929747188-0b4dc28498d6  (parking structure)
--  P5 = photo-1558618666-fcd25c85f82e    (covered garage)
--  P6 = photo-1470224114660-3f6686c562eb  (aerial parking)
--  P7 = photo-1545179605-1296651e9c43    (parking facility)
--  P8 = photo-1611348586755-53860f7ae57a  (stadium parking)
--  P9 = photo-1567449303078-57ad995bd329  (premium parking)
-- P10 = photo-1486406146926-c627a92ad1ab  (modern building)

-- ── TASHKENT ───────────────────────────────────────────────

-- Amir Temur Square Parking (existing: 3 img → 5)
UPDATE public.parkings SET
  images = ARRAY[
    'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?w=800&q=80',
    'https://images.unsplash.com/photo-1621929747188-0b4dc28498d6?w=800&q=80',
    'https://images.unsplash.com/photo-1590674899484-d5640e854abe?w=800&q=80',
    'https://images.unsplash.com/photo-1567449303078-57ad995bd329?w=800&q=80',
    'https://images.unsplash.com/photo-1573348722427-f1d6819fdf98?w=800&q=80'
  ],
  features      = ARRAY['CCTV', 'Qo''riqchi', '24/7', 'Yopiq', 'Nogironlar joyi', 'Lift', 'Avtomatik kirish'],
  working_hours = '24/7',
  phone         = '+998 71 200-11-22',
  covered       = true,
  max_height_cm = 200
WHERE id = '1637f2d7-c3d5-41d5-b879-014fb704c2a3';

-- Chorsu Bozor Parking (existing: 3 img → 5)
UPDATE public.parkings SET
  images = ARRAY[
    'https://images.unsplash.com/photo-1573348722427-f1d6819fdf98?w=800&q=80',
    'https://images.unsplash.com/photo-1590674899484-d5640e854abe?w=800&q=80',
    'https://images.unsplash.com/photo-1470224114660-3f6686c562eb?w=800&q=80',
    'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?w=800&q=80',
    'https://images.unsplash.com/photo-1621929747188-0b4dc28498d6?w=800&q=80'
  ],
  features      = ARRAY['Qo''riqchi', 'Yoritilgan', 'CCTV', 'Bozorga yaqin', 'Arzon narx'],
  working_hours = '06:00–22:00',
  phone         = '+998 71 244-33-11',
  covered       = false,
  max_height_cm = NULL
WHERE id = '43870a7e-1bcf-4c4e-aaed-c3791aab81e9';

-- IT Park Parking (existing: 3 img → 5)
UPDATE public.parkings SET
  images = ARRAY[
    'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=800&q=80',
    'https://images.unsplash.com/photo-1590674899484-d5640e854abe?w=800&q=80',
    'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?w=800&q=80',
    'https://images.unsplash.com/photo-1573348722427-f1d6819fdf98?w=800&q=80',
    'https://images.unsplash.com/photo-1621929747188-0b4dc28498d6?w=800&q=80'
  ],
  features      = ARRAY['CCTV', 'Qo''riqchi', '24/7', 'EV Zaryadlash', 'Yopiq', 'Lift', 'Tez Internet'],
  working_hours = '07:00–22:00',
  phone         = '+998 71 202-33-44',
  covered       = true,
  max_height_cm = 210
WHERE id = 'd7f5c2c5-8d0c-4e02-a82a-67d40f60995e';

-- Magic City Parking (existing: 3 img → 5)
UPDATE public.parkings SET
  images = ARRAY[
    'https://images.unsplash.com/photo-1545179605-1296651e9c43?w=800&q=80',
    'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=800&q=80',
    'https://images.unsplash.com/photo-1573348722427-f1d6819fdf98?w=800&q=80',
    'https://images.unsplash.com/photo-1590674899484-d5640e854abe?w=800&q=80',
    'https://images.unsplash.com/photo-1470224114660-3f6686c562eb?w=800&q=80'
  ],
  features      = ARRAY['Qo''riqchi', 'CCTV', 'Yoritilgan', '24/7', 'Nogironlar joyi', 'Oilaviy zona'],
  working_hours = '08:00–23:00',
  phone         = '+998 71 220-55-66',
  covered       = false,
  max_height_cm = NULL
WHERE id = '0ff8f967-0d2d-4cfc-bee8-b5422fa582e1';

-- Mega Planet Parking (existing: 3 img → 5)
UPDATE public.parkings SET
  images = ARRAY[
    'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=800&q=80',
    'https://images.unsplash.com/photo-1590674899484-d5640e854abe?w=800&q=80',
    'https://images.unsplash.com/photo-1470224114660-3f6686c562eb?w=800&q=80',
    'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?w=800&q=80',
    'https://images.unsplash.com/photo-1573348722427-f1d6819fdf98?w=800&q=80'
  ],
  features      = ARRAY['CCTV', 'Qo''riqchi', 'Yoritilgan', 'Nogironlar joyi', 'Yopiq', 'Keng maydon'],
  working_hours = '08:00–22:00',
  phone         = '+998 71 230-44-55',
  covered       = true,
  max_height_cm = 195
WHERE id = '3f9f2bb8-d2e0-405d-9147-d8ea50fa53ea';

-- Milliy Stadion Parking (existing: 2 img → 5)
UPDATE public.parkings SET
  images = ARRAY[
    'https://images.unsplash.com/photo-1611348586755-53860f7ae57a?w=800&q=80',
    'https://images.unsplash.com/photo-1545179605-1296651e9c43?w=800&q=80',
    'https://images.unsplash.com/photo-1590674899484-d5640e854abe?w=800&q=80',
    'https://images.unsplash.com/photo-1573348722427-f1d6819fdf98?w=800&q=80',
    'https://images.unsplash.com/photo-1470224114660-3f6686c562eb?w=800&q=80'
  ],
  features      = ARRAY['Yoritilgan', 'Qo''riqchi', 'Katta sig''im', 'Bepul Wi-Fi'],
  working_hours = '06:00–23:00',
  phone         = '+998 71 255-88-99',
  covered       = false,
  max_height_cm = NULL
WHERE id = 'ea397ca8-a83e-4afd-b0a0-2d3b45846cdc';

-- Minor Metro Parking (existing: 2 img → 5)
UPDATE public.parkings SET
  images = ARRAY[
    'https://images.unsplash.com/photo-1470224114660-3f6686c562eb?w=800&q=80',
    'https://images.unsplash.com/photo-1573348722427-f1d6819fdf98?w=800&q=80',
    'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?w=800&q=80',
    'https://images.unsplash.com/photo-1621929747188-0b4dc28498d6?w=800&q=80',
    'https://images.unsplash.com/photo-1590674899484-d5640e854abe?w=800&q=80'
  ],
  features      = ARRAY['Qo''riqchi', 'Yoritilgan', 'CCTV', 'Metro yaqin', 'Qulay joylashuv'],
  working_hours = '06:00–23:00',
  phone         = '+998 71 288-11-00',
  covered       = false,
  max_height_cm = NULL
WHERE id = '5f88af06-b210-415c-8256-938fca37246b';

-- Navoiy Theatre Parking (existing: 2 img → 5)
UPDATE public.parkings SET
  images = ARRAY[
    'https://images.unsplash.com/photo-1567449303078-57ad995bd329?w=800&q=80',
    'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?w=800&q=80',
    'https://images.unsplash.com/photo-1590674899484-d5640e854abe?w=800&q=80',
    'https://images.unsplash.com/photo-1621929747188-0b4dc28498d6?w=800&q=80',
    'https://images.unsplash.com/photo-1470224114660-3f6686c562eb?w=800&q=80'
  ],
  features      = ARRAY['Qo''riqchi', 'Yoritilgan', 'CCTV', 'Valet', 'Teatr yaqin'],
  working_hours = '09:00–23:00',
  phone         = '+998 71 233-77-88',
  covered       = false,
  max_height_cm = NULL
WHERE id = 'cd9351e0-2ff2-4754-a676-ca5d7000a256';

-- Samarqand Darvoza Parking (existing: 4 img → 5)
UPDATE public.parkings SET
  images = ARRAY[
    'https://images.unsplash.com/photo-1621929747188-0b4dc28498d6?w=800&q=80',
    'https://images.unsplash.com/photo-1590674899484-d5640e854abe?w=800&q=80',
    'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?w=800&q=80',
    'https://images.unsplash.com/photo-1573348722427-f1d6819fdf98?w=800&q=80',
    'https://images.unsplash.com/photo-1470224114660-3f6686c562eb?w=800&q=80'
  ],
  features      = ARRAY['CCTV', 'Qo''riqchi', 'Yopiq', '24/7', 'Lift', 'Avto yuvish'],
  working_hours = '24/7',
  phone         = '+998 71 246-22-33',
  covered       = true,
  max_height_cm = 205
WHERE id = '674b60c6-cab4-4d5a-9f32-689853ed3eaa';

-- Tashkent City Mall Parking (existing: 4 img → 5)
UPDATE public.parkings SET
  images = ARRAY[
    'https://images.unsplash.com/photo-1590674899484-d5640e854abe?w=800&q=80',
    'https://images.unsplash.com/photo-1573348722427-f1d6819fdf98?w=800&q=80',
    'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?w=800&q=80',
    'https://images.unsplash.com/photo-1621929747188-0b4dc28498d6?w=800&q=80',
    'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=800&q=80'
  ],
  features      = ARRAY['CCTV', '24/7', 'Lift', 'Qo''riqchi', 'EV Zaryadlash', 'Yopiq', 'Nogironlar joyi'],
  working_hours = '24/7',
  phone         = '+998 71 207-00-00',
  covered       = true,
  max_height_cm = 215
WHERE id = 'd71de747-2e5c-47f0-9d51-afb7d5362127';

-- ── URGANCH (Supabase storage → Unsplash, 5 ta rasm) ───────

-- Urganch City Center Parking
UPDATE public.parkings SET
  thumbnail_url = 'https://images.unsplash.com/photo-1590674899484-d5640e854abe?w=600&q=80',
  images = ARRAY[
    'https://images.unsplash.com/photo-1590674899484-d5640e854abe?w=800&q=80',
    'https://images.unsplash.com/photo-1573348722427-f1d6819fdf98?w=800&q=80',
    'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?w=800&q=80',
    'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=800&q=80',
    'https://images.unsplash.com/photo-1621929747188-0b4dc28498d6?w=800&q=80'
  ],
  features      = ARRAY['CCTV', 'Qo''riqchi', 'Yopiq', '24/7', 'Yoritilgan', 'Shahar markazi'],
  working_hours = '24/7',
  phone         = '+998 62 224-11-22',
  covered       = true,
  max_height_cm = 200
WHERE id = '0aee9f67-e2d4-4cf8-b257-cfdcb9157b01';

-- Al-Beruniy Mall Parking
UPDATE public.parkings SET
  thumbnail_url = 'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=600&q=80',
  images = ARRAY[
    'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=800&q=80',
    'https://images.unsplash.com/photo-1470224114660-3f6686c562eb?w=800&q=80',
    'https://images.unsplash.com/photo-1545179605-1296651e9c43?w=800&q=80',
    'https://images.unsplash.com/photo-1590674899484-d5640e854abe?w=800&q=80',
    'https://images.unsplash.com/photo-1573348722427-f1d6819fdf98?w=800&q=80'
  ],
  features      = ARRAY['CCTV', 'Qo''riqchi', 'Nogironlar joyi', 'Yoritilgan', 'Mall yaqin'],
  working_hours = '08:00–22:00',
  phone         = '+998 62 225-33-44',
  covered       = false,
  max_height_cm = NULL
WHERE id = '0aee9f67-e2d4-4cf8-b257-cfdcb9157b02';

-- Urganch Railway Parking
UPDATE public.parkings SET
  thumbnail_url = 'https://images.unsplash.com/photo-1470224114660-3f6686c562eb?w=600&q=80',
  images = ARRAY[
    'https://images.unsplash.com/photo-1470224114660-3f6686c562eb?w=800&q=80',
    'https://images.unsplash.com/photo-1573348722427-f1d6819fdf98?w=800&q=80',
    'https://images.unsplash.com/photo-1590674899484-d5640e854abe?w=800&q=80',
    'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?w=800&q=80',
    'https://images.unsplash.com/photo-1611348586755-53860f7ae57a?w=800&q=80'
  ],
  features      = ARRAY['Qo''riqchi', 'Yoritilgan', '24/7', 'Vokzal yaqin', 'Uzoq muddatli'],
  working_hours = '24/7',
  phone         = '+998 62 223-55-66',
  covered       = false,
  max_height_cm = NULL
WHERE id = '0aee9f67-e2d4-4cf8-b257-cfdcb9157b03';

-- Xorazm Arena Parking
UPDATE public.parkings SET
  thumbnail_url = 'https://images.unsplash.com/photo-1611348586755-53860f7ae57a?w=600&q=80',
  images = ARRAY[
    'https://images.unsplash.com/photo-1611348586755-53860f7ae57a?w=800&q=80',
    'https://images.unsplash.com/photo-1545179605-1296651e9c43?w=800&q=80',
    'https://images.unsplash.com/photo-1590674899484-d5640e854abe?w=800&q=80',
    'https://images.unsplash.com/photo-1573348722427-f1d6819fdf98?w=800&q=80',
    'https://images.unsplash.com/photo-1470224114660-3f6686c562eb?w=800&q=80'
  ],
  features      = ARRAY['Qo''riqchi', 'Yoritilgan', 'Ochiq maydon', 'Katta sig''im', 'Tadbir parkingi'],
  working_hours = '06:00–23:00',
  phone         = '+998 62 226-77-88',
  covered       = false,
  max_height_cm = NULL
WHERE id = '0aee9f67-e2d4-4cf8-b257-cfdcb9157b04';

-- Urganch International Hotel Parking
UPDATE public.parkings SET
  thumbnail_url = 'https://images.unsplash.com/photo-1567449303078-57ad995bd329?w=600&q=80',
  images = ARRAY[
    'https://images.unsplash.com/photo-1567449303078-57ad995bd329?w=800&q=80',
    'https://images.unsplash.com/photo-1590674899484-d5640e854abe?w=800&q=80',
    'https://images.unsplash.com/photo-1621929747188-0b4dc28498d6?w=800&q=80',
    'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=800&q=80',
    'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?w=800&q=80'
  ],
  features      = ARRAY['Valet', 'CCTV', 'Qo''riqchi', 'Yopiq', '24/7', 'Mehmonxona mijozlari'],
  working_hours = '24/7',
  phone         = '+998 62 228-99-00',
  covered       = true,
  max_height_cm = 210
WHERE id = '0aee9f67-e2d4-4cf8-b257-cfdcb9157b05';

-- Urganch University Parking
UPDATE public.parkings SET
  thumbnail_url = 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=600&q=80',
  images = ARRAY[
    'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=800&q=80',
    'https://images.unsplash.com/photo-1573348722427-f1d6819fdf98?w=800&q=80',
    'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?w=800&q=80',
    'https://images.unsplash.com/photo-1470224114660-3f6686c562eb?w=800&q=80',
    'https://images.unsplash.com/photo-1545179605-1296651e9c43?w=800&q=80'
  ],
  features      = ARRAY['Yoritilgan', 'Qo''riqchi', 'Ochiq maydon', 'Talabalar uchun', 'Kunlik narx'],
  working_hours = '07:00–21:00',
  phone         = '+998 62 227-44-55',
  covered       = false,
  max_height_cm = NULL
WHERE id = '0aee9f67-e2d4-4cf8-b257-cfdcb9157b06';

-- Urganch Airport Express Parking
UPDATE public.parkings SET
  thumbnail_url = 'https://images.unsplash.com/photo-1621929747188-0b4dc28498d6?w=600&q=80',
  images = ARRAY[
    'https://images.unsplash.com/photo-1621929747188-0b4dc28498d6?w=800&q=80',
    'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=800&q=80',
    'https://images.unsplash.com/photo-1590674899484-d5640e854abe?w=800&q=80',
    'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?w=800&q=80',
    'https://images.unsplash.com/photo-1573348722427-f1d6819fdf98?w=800&q=80'
  ],
  features      = ARRAY['CCTV', 'Qo''riqchi', '24/7', 'Yopiq', 'EV Zaryadlash', 'Aeroport transfer'],
  working_hours = '24/7',
  phone         = '+998 62 222-33-00',
  covered       = true,
  max_height_cm = 200
WHERE id = '0aee9f67-e2d4-4cf8-b257-cfdcb9157b07';

-- Navruz Park Parking Urganch
UPDATE public.parkings SET
  thumbnail_url = 'https://images.unsplash.com/photo-1545179605-1296651e9c43?w=600&q=80',
  images = ARRAY[
    'https://images.unsplash.com/photo-1545179605-1296651e9c43?w=800&q=80',
    'https://images.unsplash.com/photo-1470224114660-3f6686c562eb?w=800&q=80',
    'https://images.unsplash.com/photo-1573348722427-f1d6819fdf98?w=800&q=80',
    'https://images.unsplash.com/photo-1590674899484-d5640e854abe?w=800&q=80',
    'https://images.unsplash.com/photo-1621929747188-0b4dc28498d6?w=800&q=80'
  ],
  features      = ARRAY['Yoritilgan', 'Qo''riqchi', 'Oilaviy', 'Park yaqin', 'Qulay narx'],
  working_hours = '07:00–22:00',
  phone         = '+998 62 229-66-77',
  covered       = false,
  max_height_cm = NULL
WHERE id = '0aee9f67-e2d4-4cf8-b257-cfdcb9157b08';
