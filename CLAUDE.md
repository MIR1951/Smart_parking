# Smart Parking — iOS App

## Overview
Smart Parking — iOS mobil ilovasi. Foydalanuvchilar parking joylarini topish, band qilish va boshqarish imkoniyatiga ega. Parking egalari (owner) admin panel orqali o'z parkinglarini boshqaradi.

**3 ta foydalanuvchi roli:**
- **Unauthenticated** → `LoginView`
- **`role = 'customer'`** → `MainTabView` (5 tab: Home, Explore, Favorite, Bookings, Profile)
- **`role = 'owner'`** → `AdminTabView` (4 tab: Dashboard, Parkings, Reservations, Profile)

## Tech Stack
- **Platform:** iOS 17+ (Swift 6 strict concurrency, SwiftUI)
- **Backend:** Supabase (PostgreSQL, Auth, Realtime, Storage)
- **Architecture:** MVVM + Coordinator pattern
- **State:** `@Observable` (modern) + `ObservableObject` (legacy stores)
- **Dependencies:** supabase-swift v2.37.0 (SPM)

## Project Structure
```
Smart parking/
├── App/                          # @main entry point (Smart_parkingApp.swift)
├── Core/
│   ├── Coordinator/              # AppCoordinator — navigation singleton
│   ├── Features/
│   │   ├── Auth/                 # Login, Registration, ForgotPassword + AuthManager + SupabaseAuthService
│   │   ├── Booking/              # Multi-step booking wizard (5 steps)
│   │   ├── Admin/                # Owner admin panel (Dashboard, ParkingList, Editor, Reservations, Profile)
│   │   ├── Notifications/        # NotificationsView
│   │   └── UserProfile/          # ProfileView, SettingsView
│   ├── Root/                     # ContentView (auth gate), MainTabView
│   ├── Users/                    # UserManager, UserService, User model
│   └── Views/                    # HomeView, ExploreView, BookingsView, FavoriteView, WalletView
├── Models/                       # Parking, Reservation, Vehicle, User, ParkingReview, ParkingAvailability, PaymentMethod
├── Managers/                     # SB.swift, ReservationManager, WalletManager, LocationManager, NotificationManager
├── Services/                     # ParkingService, AdminParkingService, ParkingReviewService, UserService
├── Storage/                      # ParkingsStore, VehiclesStore, AdminStore, FavoritesStore,
│                                 # ParkingAvailabilityStore, ParkingReviewStore, ParkingCache, SupabaseStorageManager
├── Utils/                        # AppTheme, AppStrings (467 keys, uz/en/ru), AppLogger,
│                                 # LocalizationManager, AppearanceManager, UzbekistanCities
└── ViewModels/                   # BookingsViewModel (BookingsVM)
```

## Environment Injection Chain
```
Smart_parkingApp (@main)
  @State: AuthManager, UserManager, LocalizationManager, AppearanceManager
  └── ContentView
        @Environment: AuthManager, UserManager, LocalizationManager, AppearanceManager
        @StateObject: ParkingsStore, ParkingAvailabilityStore, ParkingReviewStore,
                      FavoritesStore, LocationManager, NotificationManager
        @State: AdminStore   ← owner path only
        │
        ├── (owner) AdminTabView(store: adminStore)
        │     @Bindable var store: AdminStore
        │     └── AdminDashboardView, AdminParkingListView, AdminReservationsView, AdminProfileView
        │
        └── (customer) NavigationStack → MainTabView
              @EnvironmentObject: ParkingsStore, ParkingAvailabilityStore, etc.
              └── HomeView, ExploreView, BookingsView, FavoriteView, ProfileView
```

## Architecture — Component Map

### Entry / Root
| Fayl | Vazifa |
|------|--------|
| `App/Smart_parkingApp.swift` | `@main`; 4 env object inject qiladi |
| `Core/Root/ContentView.swift` | Auth gate, launch gate, role routing, barcha store larni yaratadi |
| `Core/Root/MainTabView.swift` | 5-tab container (customer) |
| `Core/Features/Admin/AdminTabView.swift` | 4-tab container (owner), AdminStore parametr orqali qabul qiladi |

### Coordinator
| Fayl | Vazifa |
|------|--------|
| `Core/Coordinator/AppCoordinator.swift` | `@Observable singleton`; `NavigationPath` (push) + `fullScreenRoute` (full-screen cover); `push`, `pop`, `startBookingFlow`, `endBookingFlow`, `goToHome`, `goToBookings` |

### Auth Layer
| Fayl | Vazifa |
|------|--------|
| `Core/Features/Auth/Manager/AuthManager.swift` | `@Observable @MainActor`; `currentUserID: String?`; delegates to SupabaseAuthService |
| `Core/Features/Auth/Service/SupabaseAuthService.swift` | Supabase auth API: signIn, signUp, signOut, resetPassword, verifyOTP, updatePassword |
| `Core/Features/Auth/Views/LoginView.swift` | Login UI, email+password validation |
| `Core/Features/Auth/Views/RegistrationView.swift` | Signup UI, terms acceptance |
| `Core/Features/Auth/Views/ForgotPasswordView.swift` | 3-step: email → OTP → new password |

### User Layer
| Fayl | Vazifa |
|------|--------|
| `Core/Users/Managers/UserManager.swift` | `@Observable @MainActor`; `currentUser: User?`; `isOwner: Bool` |
| `Core/Users/Services/UserServices.swift` | Supabase users table: fetch, update profile_image_url, update username |
| `Core/Users/Models/User.swift` | `id, email, username, profileImageURL, role: UserRole` |

### Booking Flow
| Fayl | Vazifa |
|------|--------|
| `Core/Features/Booking/BookingFlowView.swift` | 5-step wizard orchestrator |
| `Core/Features/Booking/EReceiptView.swift` | PDF receipt; **start_time parametr sifatida kelishi kerak** |
| Nested sub-views | BookingDurationStepView, SelectVehicleView, PaymentMethodsView, ReviewSummaryView, PaymentSuccessView, AddVehicleView |

### Admin Panel
| Fayl | Vazifa |
|------|--------|
| `Core/Features/Admin/AdminDashboardView.swift` | Statistika: parkinglar, joylar, faol/bugungi reservations |
| `Core/Features/Admin/AdminParkingListView.swift` | Parking CRUD list + search |
| `Core/Features/Admin/AdminParkingEditorView.swift` | Create/Edit form: map pin, image upload, features |
| `Core/Features/Admin/AdminReservationsView.swift` | Reservation list + cancel |
| `Core/Features/Admin/AdminProfileView.swift` | Owner profil, til, ko'rinish, logout |

### Managers
| Fayl | Vazifa |
|------|--------|
| `Managers/SB.swift` | `SupabaseClient` singleton — `SB.shared.client` |
| `Managers/ReservationManager.swift` | RPC: `create_reservation`, `cancel_reservation`, `fetchReservation` |
| `Managers/WalletManager.swift` | `@MainActor ObservableObject`; balance + transactions; RPC: `wallet_top_up`, `wallet_deduct` |
| `Managers/LocationManager.swift` | `CLLocationManager` wrapper; `location: CLLocation?`, `placeName: String?` |
| `Managers/NotificationManager.swift` | Realtime notifications; load, startRealtime, stopRealtime, resetState |

### Services
| Fayl | Vazifa |
|------|--------|
| `Services/ParkingService.swift` | Parkinglarni shahar bo'yicha fetch; nested `parking_live_stats` join |
| `Services/AdminParkingService.swift` | Owner CRUD + `get_owner_dashboard_stats` RPC |
| `Services/ParkingReviewService.swift` | Review eligibility check + submit |

### Storage
| Fayl | Vazifa |
|------|--------|
| `Storage/ParkingsStore.swift` | `@MainActor ObservableObject`; shahar filtrlangan parking list + realtime; `ParkingCache` bilan TTL caching |
| `Storage/ParkingAvailabilityStore.swift` | Har slot uchun real-time availability |
| `Storage/AdminStore.swift` | `@Observable @MainActor`; owner parkinglar + stats + reservations + realtime |
| `Storage/VehiclesStore.swift` | `@MainActor ObservableObject singleton`; Supabase + UserDefaults fallback; optimistic updates with rollback |
| `Storage/FavoritesStore.swift` | UserDefaults scoped per user; faqat local |
| `Storage/ParkingReviewStore.swift` | Per-parking review cache + eligibility |
| `Storage/ParkingCache.swift` | File-based cache; TTL 5 daqiqa |
| `Storage/SupabaseStorageManager.swift` | Image upload/download; 5MB JPEG limit |

## State Management — Qachon Qaysi Wrapper

| Vaziyat | To'g'ri wrapper |
|---------|----------------|
| `@Observable` object, bir view hierarchy da yashaydi | `@State` |
| `@Observable` object, environment orqali inject | `@Environment` |
| `@Observable` object ga two-way binding kerak | `@Bindable` |
| `ObservableObject`, re-render da saqlanishi kerak | `@StateObject` |
| `ObservableObject`, yuqoridan inject | `@EnvironmentObject` |
| Yangi singleton (`@Observable`) | `@State` in `@main` App, inject via `@Environment` |

**Muhim qoida:** `AdminStore` (`@Observable`) — `ContentView` da `@State` sifatida yaratiladi va `AdminTabView` ga parametr orqali uzatiladi. Hech qachon `AdminTabView` ichida `@State private var adminStore = AdminStore()` qilmang — re-render da store yo'qoladi.

## Key Patterns

### Localization
```swift
// To'g'ri:
Text(loc.str(.loginTitle))
// Xato (hech qachon hardcode qilmang):
Text("Kirish")
```
- `LocalizationManager.shared.str(.key)` yoki view ichida `@Environment` orqali `loc.str(.key)`
- `StringKey` enum — `Utils/AppStrings.swift` da 467+ key
- 3 til: **uz** (Uzbek), **en** (English), **ru** (Russian)
- Yangi key qo'shganda barcha 3 til blokiga tarjima qo'shing

### Theme & UI
```swift
// Barcha yangi view lar:
AppAnimatedBackground()   // orqa fon
.glassCard()              // karta effekti
AppTheme.Palette.brand    // asosiy rang
AppTheme.Typography.body  // matn turi
```
- Glassmorphism: `.glassCard()` modifier
- Ranglar: `AppTheme.Palette.*` (light/dark adaptive)
- Matn: `AppTheme.Typography.*` (12 weight sinf)
- Animatsiya: `AppTheme.Anim.spring`, `.snappy`, `.bouncy`
- Haptics: `AppTheme.Haptics.light()`, `.success()`, `.error()`

### Logging
```swift
// To'g'ri:
Logger.auth.info("User signed in: \(userID)")
Logger.booking.error("Reservation failed: \(error)")
// Hech qachon:
print("debug")
```
Kategoriyalar: `Logger.auth`, `.wallet`, `.vehicles`, `.storage`, `.booking`, `.parking`, `.admin`

### Supabase Mutations
```swift
// State-changing operatsiyalar — FAQAT RPC orqali:
ReservationManager.shared.createReservation(parkingId:, durationMinutes:)
ReservationManager.shared.cancelReservation(_:)
WalletManager.shared.topUp(amount:)
WalletManager.shared.deduct(amount:)

// Direct table mutation faqat owner-scoped data uchun:
SB.shared.client.from("user_vehicles").insert(dto).execute()
SB.shared.client.from("users").update(["username": value]).eq("id", value: uid).execute()
```

### Concurrency (Swift 6 Strict)
```swift
// Barcha store/manager — @MainActor
// Async work sync context dan:
Task { await someStore.load() }
// UI update background task dan:
await MainActor.run { self.items = newItems }
// Cross-actor parameters:
struct Params: Sendable { ... }
```

### Navigation
```swift
// Push:
AppCoordinator.shared.push(.parkingDetail(parking))
// Full-screen (booking):
AppCoordinator.shared.startBookingFlow(parking)  // ← har safar UUID yangilanadi
// Dismiss:
AppCoordinator.shared.endBookingFlow()
AppCoordinator.shared.pop()
// Tab:
AppCoordinator.shared.goToHome()
```
Hech qachon deep view dan to'g'ridan-to'g'ri `NavigationLink` ishlatmang.

### Image Upload
```swift
// Profil rasmi:
SupabaseStorageManager.shared.uploadProfilePhoto(image, for: user)
// Parking rasmi:
SupabaseStorageManager.shared.uploadParkingImage(image, city: city, parkingName: name)
// Validatsiya: 5MB max, JPEG only — service ichida tekshiriladi
```

## Database

### Tablalar
| Jadval | Asosiy maqsad |
|--------|--------------|
| `users` | id (auth.uid), email, username, profile_image_url, role, created_at |
| `parkings` | Parking ma'lumotlari; owner_id FK |
| `parking_live_stats` | Real-time band/bo'sh joy soni |
| `parking_availability` | Computed view: live + reserved + available |
| `reservations` | Booking; FSM status |
| `user_wallets` | Foydalanuvchi hisobi (bigint so'm) |
| `wallet_transactions` | Top-up / payment tarixi |
| `user_vehicles` | Avtomobillar |
| `parking_reviews` | Baholash (UNIQUE reservation_id) |
| `notifications` | In-app bildirishnomalar |
| `notification_events` | Outbox pattern — reliable delivery |

### Reservation Status FSM
```
active ──→ in_use ──→ completed
  │           │
  ↓           ↓
cancelled   expired
  │
  ↓
no_show
```
- `active`: Yaratildi, hali kirilmadi
- `in_use`: Foydalanuvchi kirdi (`actual_start_time` set)
- `completed`: Chiqdi (`actual_end_time` set)
- `cancelled`: Bekor qilindi
- `expired`: Vaqt tugadi, kelmadi
- `no_show`: Hech kelmadi

### RPC Listi
| RPC | Parametrlar | Natija |
|-----|-------------|--------|
| `create_reservation` | `p_parking_id, p_duration_minutes` | `UUID` (reservation id) |
| `cancel_reservation` | `p_reservation_id` | void |
| `start_reservation` | `p_reservation_id` | void |
| `complete_reservation` | `p_reservation_id` | void |
| `wallet_top_up` | `p_amount, p_description` | new balance |
| `wallet_deduct` | `p_amount, p_description` | new balance |
| `get_owner_dashboard_stats` | — | JSON stats |
| `recompute_parking_availability` | `parking_id` | void |
| `recompute_parking_rating` | `parking_id` | void |

### Migratsiyalar
`supabase/migrations/` — SQL fayllar tartibi:
1. `20260206030000_schema_hardening.sql` — constraints, indexes
2. `20260206031000_reservation_state_machine.sql` — booking FSM RPCs
3. `20260206032000_availability_and_notification_pipeline.sql` — real-time triggers
4. `20260206033000_rls_and_access_policies.sql` — Row Level Security
5. `20260218_parking_expansion.sql` — Toshkent seed data (10 parking)
6. `20260219_wallet_vehicles.sql` — wallet + vehicles schema
7. `20260220_010000_city_reviews_storage.sql` — reviews + storage bucket
8. `20260221020000_urganch_seed.sql` — Urganch seed data (8 parking)
9. `20260221030000_rating_bayesian_default5.sql` — Bayesian rating
10. `20260412_admin_panel.sql` — owner role + RLS policies

## Build & Run
```bash
# Xcode 15.4+ kerak (Swift 6 uchun)
open "Smart parking.xcodeproj"
# iOS 17.0+ Simulator, Cmd+R
```

**Credentials:** `Smart parking/Smart-parking-Info.plist`
- `SUPABASE_URL` — Supabase project URL
- `SUPABASE_ANON_KEY` — anon public key

```bash
# Test:
xcodebuild test -project "Smart parking.xcodeproj" -scheme "Smart parking" \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Developer Rules (Majburiy)

1. **Localization:** Barcha user-facing matn `loc.str(.key)` orqali — hech qachon hardcode qilmang (Uzbekcha ham, Ruscha ham, Inglizcha ham)
2. **Yangi string key:** `StringKey` enum ga qo'shing + `AppStrings.swift` da barcha 3 til blokiga tarjima yozing
3. **Yangi view:** `AppAnimatedBackground()` + `.glassCard()` + `AppTheme` rang/matn
4. **Logging:** `Logger.<category>` — hech qachon `print()` ishlatmang
5. **Supabase mutations:** Rezervatsiya va wallet uchun FAQAT RPC — to'g'ridan-to'g'ri `insert/update` qilmang
6. **AdminStore:** `ContentView` da `@State private var adminStore = AdminStore()` sifatida yaratiladi, `AdminTabView(store: adminStore)` ga uzatiladi — `AdminTabView` ichida HECH QACHON yangi `AdminStore()` yaratmang
7. **Force-unwrap:** URL uchun `guard let url = URL(string:) else { fatalError("...") }` — `!` ishlatmang
8. **Credentials:** `Smart-parking-Info.plist` ni hech qachon real secret bilan commit qilmang
9. **Image upload:** 5MB max, JPEG only — `SupabaseStorageManager` orqali
10. **Concurrency:** `@MainActor` annotation, `Task {}` async work, `Sendable` cross-actor params
11. **VehiclesStore mutations:** Har doim `let snapshot = vehicles` olb, `catch` da `vehicles = snapshot` bilan rollback qiling
12. **Navigation:** `AppCoordinator` orqali — deep view lardan to'g'ridan-to'g'ri `NavigationLink` ishlatmang
