-- Add images and features columns to parkings table
ALTER TABLE public.parkings ADD COLUMN IF NOT EXISTS images text[] DEFAULT '{}';
ALTER TABLE public.parkings ADD COLUMN IF NOT EXISTS features text[] DEFAULT '{}';

-- Upsert 10 Tashkent parkings with full data
-- Using ON CONFLICT to update existing or insert new

INSERT INTO public.parkings (id, name, address, latitude, longitude, price_per_hour, rating, thumbnail_url, total_spots, description, is_popular, images, features)
VALUES
  -- 1. Tashkent City Mall Parking
  (
    gen_random_uuid(),
    'Tashkent City Mall Parking',
    'Tashkent City, Shaykhontohur tumani',
    41.3111, 69.2797,
    3.50, 4.8,
    'https://images.unsplash.com/photo-1590674899484-d5640e854abe?w=600',
    250,
    'Tashkent City yonidagi zamonaviy ko''p qavatli parking. 24 soat xizmati, CCTV kameralar, lift xizmati mavjud.',
    true,
    ARRAY[
      'https://images.unsplash.com/photo-1590674899484-d5640e854abe?w=800',
      'https://images.unsplash.com/photo-1573348722427-f1d6819fdf98?w=800',
      'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?w=800',
      'https://images.unsplash.com/photo-1621929747188-0b4dc28498d6?w=800'
    ],
    ARRAY['CCTV', '24/7', 'Lift', 'Security', 'EV Charging', 'Covered']
  ),

  -- 2. Chorsu Bozor Parking
  (
    gen_random_uuid(),
    'Chorsu Bozor Parking',
    'Chorsu bozori, Shaykhontohur tumani',
    41.3267, 69.2292,
    2.00, 4.2,
    'https://images.unsplash.com/photo-1573348722427-f1d6819fdf98?w=600',
    120,
    'Chorsu bozori yonidagi qulay parking. Bozorga yaqin joylashuv, narxi arzon.',
    true,
    ARRAY[
      'https://images.unsplash.com/photo-1573348722427-f1d6819fdf98?w=800',
      'https://images.unsplash.com/photo-1590674899484-d5640e854abe?w=800',
      'https://images.unsplash.com/photo-1470224114660-3f6686c562eb?w=800'
    ],
    ARRAY['Security', 'Lighting', 'CCTV']
  ),

  -- 3. Amir Temur Square Parking
  (
    gen_random_uuid(),
    'Amir Temur Square Parking',
    'Amir Temur xiyoboni, Mirzo Ulugbek tumani',
    41.3116, 69.2787,
    4.00, 4.9,
    'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?w=600',
    80,
    'Shahar markazidagi premium yer osti parking. Yuqori xavfsizlik, avtomatik kirish/chiqish tizimi.',
    true,
    ARRAY[
      'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?w=800',
      'https://images.unsplash.com/photo-1621929747188-0b4dc28498d6?w=800',
      'https://images.unsplash.com/photo-1590674899484-d5640e854abe?w=800'
    ],
    ARRAY['Security', 'CCTV', '24/7', 'Covered', 'Disabled Access', 'Elevator']
  ),

  -- 4. Minor Metro Parking
  (
    gen_random_uuid(),
    'Minor Metro Parking',
    'Minor masjidi yonida, Mirzo Ulugbek tumani',
    41.3180, 69.2680,
    2.50, 4.5,
    'https://images.unsplash.com/photo-1470224114660-3f6686c562eb?w=600',
    60,
    'Minor masjidi yaqinidagi ochiq turdagi parking. Metro bekatiga 5 daqiqa yurish masofasida.',
    false,
    ARRAY[
      'https://images.unsplash.com/photo-1470224114660-3f6686c562eb?w=800',
      'https://images.unsplash.com/photo-1573348722427-f1d6819fdf98?w=800'
    ],
    ARRAY['Security', 'Lighting', 'CCTV']
  ),

  -- 5. Samarqand Darvoza Parking
  (
    gen_random_uuid(),
    'Samarqand Darvoza Parking',
    'Samarqand Darvoza, Toshkent shahri',
    41.3050, 69.2600,
    3.00, 4.6,
    'https://images.unsplash.com/photo-1621929747188-0b4dc28498d6?w=600',
    150,
    'Samarqand Darvoza savdo markazining yopiq parkingi. Sovuq va issiq ob-havoda qulay.',
    true,
    ARRAY[
      'https://images.unsplash.com/photo-1621929747188-0b4dc28498d6?w=800',
      'https://images.unsplash.com/photo-1590674899484-d5640e854abe?w=800',
      'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?w=800',
      'https://images.unsplash.com/photo-1573348722427-f1d6819fdf98?w=800'
    ],
    ARRAY['CCTV', 'Security', 'Covered', '24/7', 'Elevator', 'Car Wash']
  ),

  -- 6. Mega Planet Parking
  (
    gen_random_uuid(),
    'Mega Planet Parking',
    'Mega Planet, Sergeli tumani',
    41.2500, 69.2100,
    2.50, 4.3,
    'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=600',
    200,
    'Mega Planet savdo markazi parkingi. Keng joy, oson kirish va chiqish.',
    true,
    ARRAY[
      'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=800',
      'https://images.unsplash.com/photo-1590674899484-d5640e854abe?w=800',
      'https://images.unsplash.com/photo-1470224114660-3f6686c562eb?w=800'
    ],
    ARRAY['CCTV', 'Security', 'Lighting', 'Disabled Access', 'Covered']
  ),

  -- 7. Navoiy Theatre Parking
  (
    gen_random_uuid(),
    'Navoiy Theatre Parking',
    'Alisher Navoiy teatri, Amir Temur ko''chasi',
    41.3145, 69.2730,
    3.50, 4.7,
    'https://images.unsplash.com/photo-1567449303078-57ad995bd329?w=600',
    45,
    'Navoiy teatri oldidagi premium parking. Kechki tadbirlar vaqtida qulaylik.',
    false,
    ARRAY[
      'https://images.unsplash.com/photo-1567449303078-57ad995bd329?w=800',
      'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?w=800'
    ],
    ARRAY['Security', 'Lighting', 'CCTV', 'Valet']
  ),

  -- 8. Magic City Parking
  (
    gen_random_uuid(),
    'Magic City Parking',
    'Magic City, Yashnobod tumani',
    41.3400, 69.3350,
    2.00, 4.4,
    'https://images.unsplash.com/photo-1545179605-1296651e9c43?w=600',
    300,
    'Magic City ko''ngilochar markazi yonidagi keng parking. Oila bilan kelish uchun qulay.',
    true,
    ARRAY[
      'https://images.unsplash.com/photo-1545179605-1296651e9c43?w=800',
      'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=800',
      'https://images.unsplash.com/photo-1573348722427-f1d6819fdf98?w=800'
    ],
    ARRAY['Security', 'CCTV', 'Lighting', '24/7', 'Disabled Access']
  ),

  -- 9. Milliy Stadion Parking
  (
    gen_random_uuid(),
    'Milliy Stadion Parking',
    'Bunyodkor stadioni, Mirzo Ulugbek tumani',
    41.3220, 69.2910,
    1.50, 4.1,
    'https://images.unsplash.com/photo-1611348586755-53860f7ae57a?w=600',
    500,
    'Bunyodkor stadioni yonidagi katta ochiq maydonli parking. O''yinlar vaqtida katta sig''im.',
    false,
    ARRAY[
      'https://images.unsplash.com/photo-1611348586755-53860f7ae57a?w=800',
      'https://images.unsplash.com/photo-1545179605-1296651e9c43?w=800'
    ],
    ARRAY['Lighting', 'Security']
  ),

  -- 10. IT Park Parking
  (
    gen_random_uuid(),
    'IT Park Parking',
    'IT Park, Mirzo Ulugbek tumani',
    41.3395, 69.2865,
    3.00, 4.6,
    'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=600',
    100,
    'IT Park texnologik markazining zamonaviy parkingi. EV zaryadlash stansiyalari mavjud.',
    true,
    ARRAY[
      'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=800',
      'https://images.unsplash.com/photo-1590674899484-d5640e854abe?w=800',
      'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?w=800'
    ],
    ARRAY['CCTV', 'Security', '24/7', 'EV Charging', 'Covered', 'Elevator']
  );

-- Create parking_availability for new parkings using the recompute function
-- (parking_availability does NOT have total_spots; it's computed from parkings.total_spots)
INSERT INTO public.parking_availability (parking_id, live_occupancy, reserved_spots, available_spots, updated_at)
SELECT p.id, 0, 0, p.total_spots, now()
FROM public.parkings p
WHERE NOT EXISTS (
  SELECT 1 FROM public.parking_availability pa WHERE pa.parking_id = p.id
);

INSERT INTO public.parking_live_stats (parking_id, live_occupancy)
SELECT p.id, 0
FROM public.parkings p
WHERE NOT EXISTS (
  SELECT 1 FROM public.parking_live_stats pls WHERE pls.parking_id = p.id
);
