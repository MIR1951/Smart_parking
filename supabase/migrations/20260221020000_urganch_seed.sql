-- Seed 8 Urganch parkings (Supabase Storage image URL format)

INSERT INTO public.parkings (
    id,
    name,
    city,
    address,
    latitude,
    longitude,
    price_per_hour,
    rating,
    thumbnail_url,
    total_spots,
    description,
    is_popular,
    images,
    features
)
VALUES
(
    '0aee9f67-e2d4-4cf8-b257-cfdcb9157b01',
    'Urganch City Center Parking',
    'Urganch',
    'Al-Xorazmiy ko''chasi, Urganch markazi',
    41.5537,
    60.6313,
    3.20,
    4.7,
    'https://eaanopqupsfwxvqkiqor.supabase.co/storage/v1/object/public/parking-images/urganch/urganch-city-center/cover.jpg',
    180,
    'Shahar markazidagi yopiq va xavfsiz parking. Savdo hududlariga yaqin.',
    true,
    ARRAY[
        'https://eaanopqupsfwxvqkiqor.supabase.co/storage/v1/object/public/parking-images/urganch/urganch-city-center/1.jpg',
        'https://eaanopqupsfwxvqkiqor.supabase.co/storage/v1/object/public/parking-images/urganch/urganch-city-center/2.jpg',
        'https://eaanopqupsfwxvqkiqor.supabase.co/storage/v1/object/public/parking-images/urganch/urganch-city-center/3.jpg'
    ],
    ARRAY['CCTV', 'Security', 'Covered', '24/7', 'Lighting']
),
(
    '0aee9f67-e2d4-4cf8-b257-cfdcb9157b02',
    'Al-Beruniy Mall Parking',
    'Urganch',
    'Beruniy shoh ko''chasi, Urganch',
    41.5529,
    60.6402,
    2.80,
    4.5,
    'https://eaanopqupsfwxvqkiqor.supabase.co/storage/v1/object/public/parking-images/urganch/al-beruniy-mall/cover.jpg',
    140,
    'Savdo markazi yonidagi qulay parking. Oila uchun xavfsiz va keng maydon.',
    true,
    ARRAY[
        'https://eaanopqupsfwxvqkiqor.supabase.co/storage/v1/object/public/parking-images/urganch/al-beruniy-mall/1.jpg',
        'https://eaanopqupsfwxvqkiqor.supabase.co/storage/v1/object/public/parking-images/urganch/al-beruniy-mall/2.jpg',
        'https://eaanopqupsfwxvqkiqor.supabase.co/storage/v1/object/public/parking-images/urganch/al-beruniy-mall/3.jpg'
    ],
    ARRAY['CCTV', 'Security', 'Disabled Access', 'Lighting']
),
(
    '0aee9f67-e2d4-4cf8-b257-cfdcb9157b03',
    'Urganch Railway Parking',
    'Urganch',
    'Temir yo''l vokzali hududi, Urganch',
    41.5488,
    60.6204,
    2.10,
    4.3,
    'https://eaanopqupsfwxvqkiqor.supabase.co/storage/v1/object/public/parking-images/urganch/urganch-railway/cover.jpg',
    220,
    'Vokzalga yaqin ochiq parking. Qisqa va uzoq muddatli to''xtashga mos.',
    false,
    ARRAY[
        'https://eaanopqupsfwxvqkiqor.supabase.co/storage/v1/object/public/parking-images/urganch/urganch-railway/1.jpg',
        'https://eaanopqupsfwxvqkiqor.supabase.co/storage/v1/object/public/parking-images/urganch/urganch-railway/2.jpg'
    ],
    ARRAY['Security', 'Lighting', '24/7']
),
(
    '0aee9f67-e2d4-4cf8-b257-cfdcb9157b04',
    'Xorazm Arena Parking',
    'Urganch',
    'Xorazm Arena majmuasi, Urganch',
    41.5605,
    60.6474,
    1.90,
    4.2,
    'https://eaanopqupsfwxvqkiqor.supabase.co/storage/v1/object/public/parking-images/urganch/xorazm-arena/cover.jpg',
    320,
    'Katta sig''imli tadbir parkingi. O''yin va konsert kunlari faol ishlaydi.',
    false,
    ARRAY[
        'https://eaanopqupsfwxvqkiqor.supabase.co/storage/v1/object/public/parking-images/urganch/xorazm-arena/1.jpg',
        'https://eaanopqupsfwxvqkiqor.supabase.co/storage/v1/object/public/parking-images/urganch/xorazm-arena/2.jpg'
    ],
    ARRAY['Security', 'Lighting', 'Open Area']
),
(
    '0aee9f67-e2d4-4cf8-b257-cfdcb9157b05',
    'Urganch International Hotel Parking',
    'Urganch',
    'Mustaqillik ko''chasi, Urganch',
    41.5568,
    60.6355,
    4.10,
    4.8,
    'https://eaanopqupsfwxvqkiqor.supabase.co/storage/v1/object/public/parking-images/urganch/international-hotel/cover.jpg',
    95,
    'Mehmonxona yonidagi premium parking. Valet va 24/7 xavfsizlik mavjud.',
    true,
    ARRAY[
        'https://eaanopqupsfwxvqkiqor.supabase.co/storage/v1/object/public/parking-images/urganch/international-hotel/1.jpg',
        'https://eaanopqupsfwxvqkiqor.supabase.co/storage/v1/object/public/parking-images/urganch/international-hotel/2.jpg',
        'https://eaanopqupsfwxvqkiqor.supabase.co/storage/v1/object/public/parking-images/urganch/international-hotel/3.jpg'
    ],
    ARRAY['Valet', 'CCTV', 'Security', 'Covered', '24/7']
),
(
    '0aee9f67-e2d4-4cf8-b257-cfdcb9157b06',
    'Urganch University Parking',
    'Urganch',
    'Urganch davlat universiteti hududi',
    41.5650,
    60.6297,
    1.60,
    4.1,
    'https://eaanopqupsfwxvqkiqor.supabase.co/storage/v1/object/public/parking-images/urganch/university/cover.jpg',
    260,
    'Talabalar va professor-o''qituvchilar uchun qulay kundalik parking.',
    false,
    ARRAY[
        'https://eaanopqupsfwxvqkiqor.supabase.co/storage/v1/object/public/parking-images/urganch/university/1.jpg',
        'https://eaanopqupsfwxvqkiqor.supabase.co/storage/v1/object/public/parking-images/urganch/university/2.jpg'
    ],
    ARRAY['Lighting', 'Security', 'Open Area']
),
(
    '0aee9f67-e2d4-4cf8-b257-cfdcb9157b07',
    'Urganch Airport Express Parking',
    'Urganch',
    'Urganch aeroport yo''li, transfer zonasi',
    41.5844,
    60.6422,
    3.60,
    4.6,
    'https://eaanopqupsfwxvqkiqor.supabase.co/storage/v1/object/public/parking-images/urganch/airport-express/cover.jpg',
    170,
    'Aeroportga tez chiqish uchun mo''ljallangan parking. Transfer xizmatlariga yaqin.',
    true,
    ARRAY[
        'https://eaanopqupsfwxvqkiqor.supabase.co/storage/v1/object/public/parking-images/urganch/airport-express/1.jpg',
        'https://eaanopqupsfwxvqkiqor.supabase.co/storage/v1/object/public/parking-images/urganch/airport-express/2.jpg',
        'https://eaanopqupsfwxvqkiqor.supabase.co/storage/v1/object/public/parking-images/urganch/airport-express/3.jpg'
    ],
    ARRAY['CCTV', 'Security', '24/7', 'Covered', 'EV Charging']
),
(
    '0aee9f67-e2d4-4cf8-b257-cfdcb9157b08',
    'Navruz Park Parking Urganch',
    'Urganch',
    'Navruz bog''i atrof hududi, Urganch',
    41.5495,
    60.6498,
    2.40,
    4.4,
    'https://eaanopqupsfwxvqkiqor.supabase.co/storage/v1/object/public/parking-images/urganch/navruz-park/cover.jpg',
    150,
    'Dam olish maskani yonidagi oilaviy parking. Kechki payt ham yoritilgan.',
    false,
    ARRAY[
        'https://eaanopqupsfwxvqkiqor.supabase.co/storage/v1/object/public/parking-images/urganch/navruz-park/1.jpg',
        'https://eaanopqupsfwxvqkiqor.supabase.co/storage/v1/object/public/parking-images/urganch/navruz-park/2.jpg'
    ],
    ARRAY['Lighting', 'Security', 'Family Friendly']
)
ON CONFLICT (id) DO UPDATE
SET
    name = EXCLUDED.name,
    city = EXCLUDED.city,
    address = EXCLUDED.address,
    latitude = EXCLUDED.latitude,
    longitude = EXCLUDED.longitude,
    price_per_hour = EXCLUDED.price_per_hour,
    rating = EXCLUDED.rating,
    thumbnail_url = EXCLUDED.thumbnail_url,
    total_spots = EXCLUDED.total_spots,
    description = EXCLUDED.description,
    is_popular = EXCLUDED.is_popular,
    images = EXCLUDED.images,
    features = EXCLUDED.features;

INSERT INTO public.parking_availability (parking_id, live_occupancy, reserved_spots, available_spots, updated_at)
SELECT p.id, 0, 0, p.total_spots, now()
FROM public.parkings p
WHERE p.city = 'Urganch'
  AND NOT EXISTS (
    SELECT 1
    FROM public.parking_availability pa
    WHERE pa.parking_id = p.id
  );

INSERT INTO public.parking_live_stats (parking_id, live_occupancy)
SELECT p.id, 0
FROM public.parkings p
WHERE p.city = 'Urganch'
  AND NOT EXISTS (
    SELECT 1
    FROM public.parking_live_stats pls
    WHERE pls.parking_id = p.id
  );
