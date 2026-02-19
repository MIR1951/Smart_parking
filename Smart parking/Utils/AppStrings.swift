//
//  AppStrings.swift
//  Smart parking
//
//  Created by Smart Parking on 12/02/26.
//

import Foundation

// MARK: - String Keys
enum StringKey: String {
    // Tab Bar
    case tabHome
    case tabExplore
    case tabFavorite
    case tabBookings
    case tabProfile

    // Home
    case homeGreeting
    case homeSubtitle
    case homeSearch
    case homePopular
    case homeNearby
    case homeSeeAll
    case homeNoParking
    case homeNoResults
    case homeCheckInternet
    case homeLoadFailed
    case homeRetry
    case launchLoading
    case launchFailed
    case retry

    // Explore
    case exploreTitle
    case exploreSearch

    // Favorite
    case favoriteTitle
    case favoriteEmpty
    case favoriteEmptySubtitle

    // Bookings
    case bookingsTitle
    case bookingsActive
    case bookingsCompleted
    case bookingsCancelled
    case bookingsEmpty
    case bookingsEmptySubtitle

    // Profile
    case profileTitle
    case profileAccount
    case profileYourProfile
    case profilePaymentMethods
    case profileMyWallet
    case profilePreferences
    case profileSettings
    case profileSupport
    case profileHelpCenter
    case profilePrivacyPolicy
    case profileInviteFriends
    case profileLogout
    case profileLogoutConfirm
    case profileComingSoon

    // Profile - extra
    case profileEditProfile
    case profileMyVehicles
    case profileNotifications
    case profileLanguage
    case profileDarkMode
    case profileTermsOfService
    case profileSignOut
    case profileSignOutConfirm
    case profilePersonalInfo
    case profileUsername
    case profileEmail
    case profilePhone
    case profileSave
    case profileDone
    case profileNoVehicles
    case profileAddPayment
    case profileDefault
    case profilePushNotifications
    case profileBookingAlerts
    case profileTimeReminders
    case profilePromotions
    case profileEmailSection
    case profileEmailNotif
    case profileVersion
    case profileUsernameEmpty
    case profileSaveFailed
    case profilePaymentNotReady
    case profileOnlyUsername

    // Settings
    case settingsTitle
    case settingsLanguage
    case settingsChooseLanguage
    case settingsAppearance
    case settingsChooseTheme

    // Auth - Login
    case loginTitle
    case loginSubtitle
    case loginEmail
    case loginPassword
    case loginEmailPlaceholder
    case loginPasswordPlaceholder
    case loginForgotPassword
    case loginSignIn
    case loginSigningIn
    case loginNoAccount
    case loginSignUp
    case loginOrWith
    case loginSocialDisabled
    case loginErrorTitle

    // Auth - Register
    case registerTitle
    case registerSubtitle
    case registerName
    case registerNamePlaceholder
    case registerAgreeWith
    case registerTerms
    case registerSignUp
    case registerSigningUp
    case registerHaveAccount
    case registerSignIn
    case registerErrorTitle

    // Auth - Forgot Password
    case forgotTitle
    case forgotSubtitle
    case forgotCodeTitle
    case forgotCodeSubtitle
    case forgotNewPassTitle
    case forgotNewPassSubtitle
    case forgotSendCode
    case forgotSending
    case forgotVerify
    case forgotVerifying
    case forgotUpdatePassword
    case forgotSaving
    case forgotResendIn
    case forgotResendCode
    case forgotConfirmCode
    case forgotNewPassword
    case forgotConfirmPassword
    case forgotMinChars
    case forgotSuccessTitle
    case forgotSuccessMessage
    case forgotGoToLogin
    case forgotErrorTitle

    // Validation
    case valEmailRequired
    case valEmailInvalid
    case valPasswordRequired
    case valPasswordMin
    case valNameRequired
    case valNameMin
    case valCodeRequired
    case valCodeLength
    case valConfirmRequired
    case valPasswordMismatch

    // Password Strength
    case strengthWeak
    case strengthFair
    case strengthGood
    case strengthStrong
    case strengthVeryStrong

    // Parking Detail
    case detailTotalSpots
    case detailSpotsAvailable
    case detailDescription
    case detailNoDescription
    case detailFeatures
    case detailSecurity
    case detailCCTV
    case detailLighting
    case detailCovered
    case detailParkingInfo
    case detailAvailable
    case detailPrice
    case detailTotalPrice
    case detailBookSlot
    case detailFullyBooked
    case detailAbout
    case detailGallery
    case detailReview
    case detailNoGallery
    case detailReviews
    case detailAddReview
    case detailBasedOnReviews
    case detailCarParking
    case detailNavigate
    case detailNavigateWith
    case detailReviewEligibility
    case detailReviewRating
    case detailReviewComment
    case detailReviewCommentRequired
    case detailSubmitReview
    case detailNoReviewsYet
    case reviewNeedBookingWarning
    case reviewAlreadySubmittedWarning

    // Booking Flow
    case bookingBookSlot
    case bookingReservationInfo
    case bookingSelectDuration
    case bookingPrepaidAmount
    case bookingContinue
    case bookingProcessing
    case bookingMin
    case bookingHour
    case bookingHours

    // Select Vehicle
    case vehicleSelectTitle
    case vehicleNotFound
    case vehicleAddFirst
    case vehicleAddTitle
    case vehicleSelectBrand
    case vehicleSelectCar
    case vehicleSelectModel
    case vehiclePlateNumber
    case vehiclePlatePlaceholder
    case vehicleAdd

    // Payment Methods
    case paymentTitle
    case paymentWallet
    case paymentCreditDebit
    case paymentMoreOptions
    case paymentAddCard
    case paymentConfirm
    case paymentSelectPayment
    case paymentChange
    case paymentComingSoon
    case paymentWalletOnly

    // Review Summary
    case reviewTitle
    case reviewArrivingTime
    case reviewExitTime
    case reviewVehicle
    case reviewDuration
    case reviewAmount
    case reviewTotalHours
    case reviewFees
    case reviewTotal

    // Payment Success
    case successPayment
    case successTitle
    case successMessage
    case successReservationId
    case successViewReceipt
    case successBackToHome

    // E-Ticket / E-Receipt
    case eticketTitle
    case eticketClose
    case eticketStartTime
    case eticketEndTime
    case eticketDuration
    case eticketMinutes
    case eticketActualEntry
    case eticketActualExit
    case eticketPricePerHour
    case eticketBaseAmount
    case eticketOvertimeCharge
    case eticketOvertime
    case eticketExtraCharge
    case eticketTotal
    case receiptTitle
    case receiptDownload
    case receiptCar
    case receiptPlate
    case receiptParking
    case receiptAddress
    case receiptRate
    case receiptSubtotal
    case receiptServiceFee
    case receiptPaymentMethod
    case receiptDate
    case receiptStatus
    case receiptConfirmed

    // Bookings View
    case bookingsOngoing
    case bookingsNoBookings
    case bookingsAppearHere
    case bookingsLoadFailed
    case bookingsCancelTitle
    case bookingsCancelConfirm
    case bookingsCancelYes
    case bookingsCancelNo
    case bookingsTimer
    case bookingsCancel
    case bookingsView
    case bookingsETicket
    case bookingsViewReceipt
    case bookingsDetails
    case bookingsStart
    case bookingsEnd
    case bookingsErrorCancel

    // Bookings extra
    case bookingsYesCancel
    case bookingsNo
    case bookingsCancelMessage
    case bookingsDuration
    case bookingsActualEntry
    case bookingsActualExit
    case bookingsPricePerHour
    case bookingsBaseAmount
    case bookingsOvertimeCharge
    case bookingsOvertime
    case bookingsExtraCharge
    case bookingsRetry
    case bookingsCannotCancel
    case bookingsClose
    case bookingsPerHour
    case bookingsUnknown

    // Booking status display names (database-driven)
    case statusActive
    case statusInUse
    case statusCompleted
    case statusCancelled
    case statusExpired
    case statusNoShow

    // Time ago labels
    case timeNow
    case timeMinAgo
    case timeHourAgo
    case timeDayAgo

    // Notifications
    case notifTitle
    case notifLoading
    case notifEmpty
    case notifEmptySubtitle
    case notifToday
    case notifYesterday
    case notifOlder
    case notifMarkAllRead
    case notifNew
    case notifAllCaughtUp

    // Explore extra
    case exploreNoResults
    case exploreChangeSearch
    case exploreFilterInfo
    case mapZoomIn
    case mapZoomOut

    // Home extra
    case homeLocation
    case homeSearchParking
    case homePopularParking
    case homeNearbyParking
    case homeCityLabel
    case homeSearchNoResults
    case homeSearchNoResultsSub

    // Favorite extra
    case favoriteRemoveTitle
    case favoriteCancel
    case favoriteYesRemove
    case favoriteNoFavorites
    case favoriteNoFavoritesSub

    // Wallet
    case walletTitle
    case walletBalance
    case walletTopUp
    case walletQuickTopUp
    case walletTransactions
    case walletNoTransactions
    case walletEnterAmount
    case walletTopUpDone
    case walletInsufficientBalance
    case walletInvalidAmount
    case walletPaymentFor
    case walletCurrency

    // Common
    case ok
    case cancel
    case error
    case info
    case unknown
    case back

    func localized(_ lang: AppLanguage) -> String {
        switch lang {
        case .uz: return uz
        case .en: return en
        case .ru: return ru
        }
    }

    // MARK: - Uzbek
    private var uz: String {
        switch self {
        // Tab
        case .tabHome: return "Bosh sahifa"
        case .tabExplore: return "Xarita"
        case .tabFavorite: return "Sevimlilar"
        case .tabBookings: return "Buyurtmalar"
        case .tabProfile: return "Profil"

        // Home
        case .homeGreeting: return "Salom"
        case .homeSubtitle: return "Parking joyingizni toping"
        case .homeSearch: return "Parking qidirish..."
        case .homePopular: return "Ommabop parkinglar"
        case .homeNearby: return "Yaqin atrofdagi"
        case .homeSeeAll: return "Barchasi"
        case .homeNoParking: return "Parking topilmadi"
        case .homeNoResults: return "Natija topilmadi"
        case .homeCheckInternet: return "Internet yoki joylashuvni tekshirib ko'ring."
        case .homeLoadFailed: return "Parkinglar yuklanmadi"
        case .homeRetry: return "Qayta urinish"
        case .launchLoading: return "Ma'lumotlar yuklanmoqda..."
        case .launchFailed: return "Ilovani ishga tushirib bo'lmadi"
        case .retry: return "Qayta urinish"

        // Explore
        case .exploreTitle: return "Xarita"
        case .exploreSearch: return "Manzil qidirish..."

        // Favorite
        case .favoriteTitle: return "Sevimlilar"
        case .favoriteEmpty: return "Sevimlilar yo'q"
        case .favoriteEmptySubtitle: return "Parkinglarni sevimlilarga qo'shing."

        // Bookings
        case .bookingsTitle: return "Buyurtmalar"
        case .bookingsActive: return "Faol"
        case .bookingsCompleted: return "Tugallangan"
        case .bookingsCancelled: return "Bekor qilingan"
        case .bookingsEmpty: return "Buyurtmalar yo'q"
        case .bookingsEmptySubtitle: return "Hali birorta buyurtma bermadingiz."

        // Profile
        case .profileTitle: return "Profil"
        case .profileAccount: return "Hisob"
        case .profileYourProfile: return "Profilingiz"
        case .profilePaymentMethods: return "To'lov usullari"
        case .profileMyWallet: return "Hamyon"
        case .profilePreferences: return "Sozlamalar"
        case .profileSettings: return "Sozlamalar"
        case .profileSupport: return "Yordam"
        case .profileHelpCenter: return "Yordam markazi"
        case .profilePrivacyPolicy: return "Maxfiylik siyosati"
        case .profileInviteFriends: return "Do'stlarni taklif qilish"
        case .profileLogout: return "Chiqish"
        case .profileLogoutConfirm: return "Haqiqatan ham chiqmoqchimisiz?"
        case .profileComingSoon: return "Keyingi versiyada ochiladi."

        // Profile extra
        case .profileEditProfile: return "Profilni tahrirlash"
        case .profileMyVehicles: return "Transport vositalarim"
        case .profileNotifications: return "Bildirishnomalar"
        case .profileLanguage: return "Til"
        case .profileDarkMode: return "Qorong'u rejim"
        case .profileTermsOfService: return "Foydalanish shartlari"
        case .profileSignOut: return "Chiqish"
        case .profileSignOutConfirm: return "Haqiqatan ham chiqmoqchimisiz?"
        case .profilePersonalInfo: return "Shaxsiy ma'lumotlar"
        case .profileUsername: return "Foydalanuvchi nomi"
        case .profileEmail: return "Email"
        case .profilePhone: return "Telefon"
        case .profileSave: return "Saqlash"
        case .profileDone: return "Tayyor"
        case .profileNoVehicles: return "Transport vositalar qo'shilmagan"
        case .profileAddPayment: return "To'lov usulini qo'shish"
        case .profileDefault: return "Asosiy"
        case .profilePushNotifications: return "Push bildirishnomalar"
        case .profileBookingAlerts: return "Buyurtma ogohlantirishlari"
        case .profileTimeReminders: return "Vaqt eslatmalari"
        case .profilePromotions: return "Aksiya va takliflar"
        case .profileEmailSection: return "Email"
        case .profileEmailNotif: return "Email bildirishnomalar"
        case .profileVersion: return "Versiya 1.0.0"
        case .profileUsernameEmpty: return "Foydalanuvchi nomi bo'sh bo'lishi mumkin emas."
        case .profileSaveFailed: return "Profilni saqlab bo'lmadi"
        case .profilePaymentNotReady: return "To'lov usulini qo'shish hali mavjud emas."
        case .profileOnlyUsername: return "Hozircha faqat foydalanuvchi nomi yangilanadi."

        // Settings
        case .settingsTitle: return "Sozlamalar"
        case .settingsLanguage: return "Til"
        case .settingsChooseLanguage: return "Tilni tanlang"
        case .settingsAppearance: return "Mavzu"
        case .settingsChooseTheme: return "Mavzuni tanlang"

        // Login
        case .loginTitle: return "Kirish"
        case .loginSubtitle: return "Xush kelibsiz! Sizni sog'indik"
        case .loginEmail: return "Email"
        case .loginPassword: return "Parol"
        case .loginEmailPlaceholder: return "example@gmail.com"
        case .loginPasswordPlaceholder: return "**********"
        case .loginForgotPassword: return "Parolni unutdingizmi?"
        case .loginSignIn: return "Kirish"
        case .loginSigningIn: return "Kirilmoqda..."
        case .loginNoAccount: return "Hisobingiz yo'qmi?"
        case .loginSignUp: return "Ro'yxatdan o'tish"
        case .loginOrWith: return "Yoki quyidagilar bilan"
        case .loginSocialDisabled: return "Social kirish hozircha yoqilmagan."
        case .loginErrorTitle: return "Kirish xatosi"

        // Register
        case .registerTitle: return "Hisob yaratish"
        case .registerSubtitle:
            return "Ma'lumotlaringizni kiriting yoki ijtimoiy tarmoq orqali ro'yxatdan o'ting."
        case .registerName: return "Ism"
        case .registerNamePlaceholder: return "Masalan: Anvar Toshmatov"
        case .registerAgreeWith: return "Roziman"
        case .registerTerms: return "Foydalanish shartlari"
        case .registerSignUp: return "Ro'yxatdan o'tish"
        case .registerSigningUp: return "Ro'yxatdan o'tilmoqda..."
        case .registerHaveAccount: return "Hisobingiz bormi?"
        case .registerSignIn: return "Kirish"
        case .registerErrorTitle: return "Ro'yxatdan o'tish xatosi"

        // Forgot
        case .forgotTitle: return "Parolni tiklash"
        case .forgotSubtitle: return "Emailingizni kiriting, parolni tiklash uchun kod yuboramiz."
        case .forgotCodeTitle: return "Kodni kiriting"
        case .forgotCodeSubtitle: return "emailiga 8 xonali kod yuborildi."
        case .forgotNewPassTitle: return "Yangi parol"
        case .forgotNewPassSubtitle: return "Yangi parolni kiriting va tasdiqlang."
        case .forgotSendCode: return "Kod yuborish"
        case .forgotSending: return "Yuborilmoqda..."
        case .forgotVerify: return "Tasdiqlash"
        case .forgotVerifying: return "Tekshirilmoqda..."
        case .forgotUpdatePassword: return "Parolni yangilash"
        case .forgotSaving: return "Saqlanmoqda..."
        case .forgotResendIn: return "Qayta yuborish"
        case .forgotResendCode: return "Kodni qayta yuborish"
        case .forgotConfirmCode: return "Tasdiqlash kodi"
        case .forgotNewPassword: return "Yangi parol"
        case .forgotConfirmPassword: return "Parolni tasdiqlang"
        case .forgotMinChars: return "Kamida 6 ta belgi"
        case .forgotSuccessTitle: return "Muvaffaqiyat!"
        case .forgotSuccessMessage:
            return "Parolingiz muvaffaqiyatli yangilandi. Endi yangi parol bilan kiring."
        case .forgotGoToLogin: return "Kirish sahifasiga"
        case .forgotErrorTitle: return "Xatolik"

        // Validation
        case .valEmailRequired: return "Email kiritilishi shart"
        case .valEmailInvalid: return "Email formati noto'g'ri"
        case .valPasswordRequired: return "Parol kiritilishi shart"
        case .valPasswordMin: return "Parol kamida 6 ta belgi bo'lishi kerak"
        case .valNameRequired: return "Ism kiritilishi shart"
        case .valNameMin: return "Ism kamida 2 ta belgi bo'lishi kerak"
        case .valCodeRequired: return "Kodni kiriting"
        case .valCodeLength: return "Kod 8 ta raqamdan iborat"
        case .valConfirmRequired: return "Parolni tasdiqlang"
        case .valPasswordMismatch: return "Parollar mos kelmayapti"

        // Strength
        case .strengthWeak: return "Zaif"
        case .strengthFair: return "O'rtacha"
        case .strengthGood: return "Yaxshi"
        case .strengthStrong: return "Kuchli"
        case .strengthVeryStrong: return "Juda kuchli"

        // Parking Detail
        case .detailTotalSpots: return "jami joy"
        case .detailSpotsAvailable: return "joy mavjud"
        case .detailDescription: return "Tavsif"
        case .detailNoDescription: return "Bu parking haqida tavsif mavjud emas."
        case .detailFeatures: return "Xususiyatlar"
        case .detailSecurity: return "24/7 Qo'riqlash"
        case .detailCCTV: return "CCTV"
        case .detailLighting: return "Yaxshi yoritish"
        case .detailCovered: return "Yopiq parking"
        case .detailParkingInfo: return "Parking ma'lumotlari"
        case .detailAvailable: return "Mavjud"
        case .detailPrice: return "Narx"
        case .detailTotalPrice: return "Umumiy narx"
        case .detailBookSlot: return "Band qilish"
        case .detailFullyBooked: return "Joy yo'q"
        case .detailAbout: return "Haqida"
        case .detailGallery: return "Galereya"
        case .detailReview: return "Sharhlar"
        case .detailNoGallery: return "Galereya rasmlari mavjud emas"
        case .detailReviews: return "Sharhlar"
        case .detailAddReview: return "Sharh qo'shish"
        case .detailBasedOnReviews: return "Sharhlar asosida"
        case .detailCarParking: return "Avtoturargoh"
        case .detailNavigate: return "Yo'nalish olish"
        case .detailNavigateWith: return "Qaysi ilova orqali ochilsin?"
        case .detailReviewEligibility: return "Faqat yakunlangan buyurtma asosida sharh qoldira olasiz."
        case .detailReviewRating: return "Baholash"
        case .detailReviewComment: return "Fikr"
        case .detailReviewCommentRequired: return "Iltimos, sharh matnini kiriting."
        case .detailSubmitReview: return "Sharhni yuborish"
        case .detailNoReviewsYet: return "Hozircha sharhlar yo'q"
        case .reviewNeedBookingWarning: return "Avval shu parkingdan joy band qiling."
        case .reviewAlreadySubmittedWarning:
            return "Mavjud yakunlangan buyurtmalar bo'yicha sharh allaqachon qoldirilgan."

        // Booking Flow
        case .bookingBookSlot: return "Band qilish"
        case .bookingReservationInfo:
            return "Band qilish hozir boshlanadi. Qancha vaqt kerakligini tanlang."
        case .bookingSelectDuration: return "Vaqtni tanlang"
        case .bookingPrepaidAmount: return "Oldindan to'lov"
        case .bookingContinue: return "Davom etish"
        case .bookingProcessing: return "Jarayonda..."
        case .bookingMin: return "daq"
        case .bookingHour: return "soat"
        case .bookingHours: return "soat"

        // Select Vehicle
        case .vehicleSelectTitle: return "Mashina tanlash"
        case .vehicleNotFound: return "Mashina topilmadi"
        case .vehicleAddFirst: return "Davom etish uchun avval mashina qo'shing."
        case .vehicleAddTitle: return "Mashina qo'shish"
        case .vehicleSelectBrand: return "Brend tanlash"
        case .vehicleSelectCar: return "Mashina tanlash"
        case .vehicleSelectModel: return "Model tanlash"
        case .vehiclePlateNumber: return "Davlat raqami"
        case .vehiclePlatePlaceholder: return "Masalan: 01 A 123 AA"
        case .vehicleAdd: return "Mashina qo'shish"

        // Payment
        case .paymentTitle: return "To'lov usullari"
        case .paymentWallet: return "Hamyon"
        case .paymentCreditDebit: return "Kredit va debet karta"
        case .paymentMoreOptions: return "Boshqa to'lov usullari"
        case .paymentAddCard: return "Karta qo'shish"
        case .paymentConfirm: return "To'lovni tasdiqlash"
        case .paymentSelectPayment: return "To'lov usulini tanlang"
        case .paymentChange: return "O'zgartirish"
        case .paymentComingSoon: return "Bu to'lov usuli keyingi versiyalarda qo'shiladi."
        case .paymentWalletOnly: return "Hozircha faqat hamyon orqali to'lov qo'llab-quvvatlanadi."

        // Review Summary
        case .reviewTitle: return "Xulosa"
        case .reviewArrivingTime: return "Kelish vaqti"
        case .reviewExitTime: return "Chiqish vaqti"
        case .reviewVehicle: return "Mashina"
        case .reviewDuration: return "Davomiylik"
        case .reviewAmount: return "Narx"
        case .reviewTotalHours: return "Jami soat"
        case .reviewFees: return "Xizmat haqqi"
        case .reviewTotal: return "Jami"

        // Payment Success
        case .successPayment: return "To'lov"
        case .successTitle: return "To'lov muvaffaqiyatli!"
        case .successMessage:
            return
                "Parking joyingiz muvaffaqiyatli band qilindi.\nBuyurtmangizni bosh sahifada tekshirishingiz mumkin."
        case .successReservationId: return "Band raqami:"
        case .successViewReceipt: return "Elektron chekni ko'rish"
        case .successBackToHome: return "Bosh sahifaga"

        // E-Ticket / E-Receipt
        case .eticketTitle: return "E-Chipta"
        case .eticketClose: return "Yopish"
        case .eticketStartTime: return "Boshlanish vaqti"
        case .eticketEndTime: return "Tugash vaqti"
        case .eticketDuration: return "Davomiylik"
        case .eticketMinutes: return "daqiqa"
        case .eticketActualEntry: return "Haqiqiy kirish"
        case .eticketActualExit: return "Haqiqiy chiqish"
        case .eticketPricePerHour: return "Soatlik narx"
        case .eticketBaseAmount: return "Asosiy summa"
        case .eticketOvertimeCharge: return "Qo'shimcha to'lov"
        case .eticketOvertime: return "Vaqt o'tdi!"
        case .eticketExtraCharge: return "Qo'shimcha to'lov:"
        case .eticketTotal: return "Jami"
        case .receiptTitle: return "Elektron chek"
        case .receiptDownload: return "Elektron chekni yuklab olish"
        case .receiptCar: return "Mashina"
        case .receiptPlate: return "Davlat raqami"
        case .receiptParking: return "Parking"
        case .receiptAddress: return "Manzil"
        case .receiptRate: return "Tarif"
        case .receiptSubtotal: return "Oraliq summa"
        case .receiptServiceFee: return "Xizmat haqqi"
        case .receiptPaymentMethod: return "To'lov usuli"
        case .receiptDate: return "Sana"
        case .receiptStatus: return "Holat"
        case .receiptConfirmed: return "Tasdiqlangan ✓"

        // Bookings View
        case .bookingsOngoing: return "Faol"
        case .bookingsNoBookings: return "bandlar yo'q"
        case .bookingsAppearHere: return "bandlaringiz shu yerda ko'rinadi"
        case .bookingsLoadFailed: return "Bandlar yuklanmadi"
        case .bookingsCancelTitle: return "Bandni bekor qilish"
        case .bookingsCancelConfirm: return "Ushbu bandni bekor qilmoqchimisiz?"
        case .bookingsCancelYes: return "Ha, bekor qilish"
        case .bookingsCancelNo: return "Yo'q"
        case .bookingsTimer: return "Taymer"
        case .bookingsCancel: return "Bekor qilish"
        case .bookingsView: return "Ko'rish"
        case .bookingsETicket: return "E-Chipta"
        case .bookingsViewReceipt: return "Chekni ko'rish"
        case .bookingsDetails: return "Tafsilotlar"
        case .bookingsStart: return "Boshlanish"
        case .bookingsEnd: return "Tugash"
        case .bookingsErrorCancel: return "Bekor qilib bo'lmadi:"

        // Bookings extra
        case .bookingsYesCancel: return "Ha, bekor qilish"
        case .bookingsNo: return "Yo'q"
        case .bookingsCancelMessage: return "Bu buyurtmani bekor qilmoqchimisiz?"
        case .bookingsDuration: return "Davomiyligi"
        case .bookingsActualEntry: return "Haqiqiy kirish"
        case .bookingsActualExit: return "Haqiqiy chiqish"
        case .bookingsPricePerHour: return "Soatiga narx"
        case .bookingsBaseAmount: return "Asosiy summa"
        case .bookingsOvertimeCharge: return "Ortiqcha vaqt to'lovi"
        case .bookingsOvertime: return "Ortiqcha vaqt!"
        case .bookingsExtraCharge: return "Qo'shimcha to'lov"
        case .bookingsRetry: return "Qaytadan"
        case .bookingsCannotCancel: return "Bekor qilib bo'lmadi"
        case .bookingsClose: return "Yopish"
        case .bookingsPerHour: return "/soat"
        case .bookingsUnknown: return "Noma'lum"

        // Status display names
        case .statusActive: return "Faol"
        case .statusInUse: return "Foydalanilmoqda"
        case .statusCompleted: return "Tugallangan"
        case .statusCancelled: return "Bekor qilingan"
        case .statusExpired: return "Muddati o'tgan"
        case .statusNoShow: return "Kelmadi"

        // Time ago
        case .timeNow: return "hozir"
        case .timeMinAgo: return "daq"
        case .timeHourAgo: return "soat"
        case .timeDayAgo: return "kun"

        // Notifications
        case .notifTitle: return "Bildirishnomalar"
        case .notifLoading: return "Bildirishnomalar yuklanmoqda..."
        case .notifEmpty: return "Bildirishnomalar yo'q"
        case .notifEmptySubtitle: return "Hamma narsa ko'rib chiqilgan!"
        case .notifToday: return "BUGUN"
        case .notifYesterday: return "KECHA"
        case .notifOlder: return "OLDINGI"
        case .notifMarkAllRead: return "Hammasini o'qilgan deb belgilash"
        case .notifNew: return "YANGI"
        case .notifAllCaughtUp: return "Hamma bildirishnomalar o'qilgan!"

        // Explore extra
        case .exploreNoResults: return "Natija topilmadi"
        case .exploreChangeSearch: return "Qidiruv matnini o'zgartirib ko'ring."
        case .exploreFilterInfo: return "Filter bo'limi keyingi versiyada qo'shiladi."
        case .mapZoomIn: return "Yaqinlashtirish"
        case .mapZoomOut: return "Uzoqlashtirish"

        // Home extra
        case .homeLocation: return "Joylashuv"
        case .homeSearchParking: return "Parking qidirish"
        case .homePopularParking: return "Ommabop parkinglar"
        case .homeNearbyParking: return "Yaqin atrofdagi parkinglar"
        case .homeCityLabel: return "Shahar"
        case .homeSearchNoResults: return "Natija topilmadi"
        case .homeSearchNoResultsSub: return "Boshqa nom yoki manzil bilan qidirib ko'ring."

        // Favorite extra
        case .favoriteRemoveTitle: return "Sevimlilardan o'chirish?"
        case .favoriteCancel: return "Bekor qilish"
        case .favoriteYesRemove: return "Ha, o'chirish"
        case .favoriteNoFavorites: return "Sevimlilar yo'q"
        case .favoriteNoFavoritesSub: return "Yoqtirgan parkinglaringiz shu yerda chiqadi."

        // Wallet
        case .walletTitle: return "Hamyon"
        case .walletBalance: return "Joriy balans"
        case .walletTopUp: return "To'ldirish"
        case .walletQuickTopUp: return "Tez to'ldirish"
        case .walletTransactions: return "Tranzaksiyalar"
        case .walletNoTransactions: return "Tranzaksiyalar yo'q"
        case .walletEnterAmount: return "Ixtiyoriy summa kiriting"
        case .walletTopUpDone: return "Hamyon to'ldirildi"
        case .walletInsufficientBalance: return "Hamyonda mablag' yetarli emas"
        case .walletInvalidAmount: return "Noto'g'ri summa"
        case .walletPaymentFor: return "Parking to'lovi"
        case .walletCurrency: return "so'm"

        // Common
        case .ok: return "OK"
        case .cancel: return "Bekor qilish"
        case .error: return "Xatolik"
        case .info: return "Ma'lumot"
        case .unknown: return "Noma'lum"
        case .back: return "Orqaga"
        }
    }

    // MARK: - English
    private var en: String {
        switch self {
        // Tab
        case .tabHome: return "Home"
        case .tabExplore: return "Explore"
        case .tabFavorite: return "Favorites"
        case .tabBookings: return "Bookings"
        case .tabProfile: return "Profile"

        // Home
        case .homeGreeting: return "Hello"
        case .homeSubtitle: return "Find your parking spot"
        case .homeSearch: return "Search parking..."
        case .homePopular: return "Popular parking"
        case .homeNearby: return "Nearby"
        case .homeSeeAll: return "See all"
        case .homeNoParking: return "No parking found"
        case .homeNoResults: return "No results found"
        case .homeCheckInternet: return "Check your internet or location settings."
        case .homeLoadFailed: return "Failed to load parking"
        case .homeRetry: return "Retry"
        case .launchLoading: return "Loading data..."
        case .launchFailed: return "Unable to launch app"
        case .retry: return "Retry"

        // Explore
        case .exploreTitle: return "Explore"
        case .exploreSearch: return "Search address..."

        // Favorite
        case .favoriteTitle: return "Favorites"
        case .favoriteEmpty: return "No favorites"
        case .favoriteEmptySubtitle: return "Add parking spots to your favorites."

        // Bookings
        case .bookingsTitle: return "Bookings"
        case .bookingsActive: return "Active"
        case .bookingsCompleted: return "Completed"
        case .bookingsCancelled: return "Cancelled"
        case .bookingsEmpty: return "No bookings"
        case .bookingsEmptySubtitle: return "You haven't made any bookings yet."

        // Profile
        case .profileTitle: return "Profile"
        case .profileAccount: return "Account"
        case .profileYourProfile: return "Your Profile"
        case .profilePaymentMethods: return "Payment Methods"
        case .profileMyWallet: return "My Wallet"
        case .profilePreferences: return "Preferences"
        case .profileSettings: return "Settings"
        case .profileSupport: return "Support"
        case .profileHelpCenter: return "Help Center"
        case .profilePrivacyPolicy: return "Privacy Policy"
        case .profileInviteFriends: return "Invite Friends"
        case .profileLogout: return "Log out"
        case .profileLogoutConfirm: return "Are you sure you want to log out?"
        case .profileComingSoon: return "Coming soon in the next update."

        // Profile extra
        case .profileEditProfile: return "Edit Profile"
        case .profileMyVehicles: return "My Vehicles"
        case .profileNotifications: return "Notifications"
        case .profileLanguage: return "Language"
        case .profileDarkMode: return "Dark Mode"
        case .profileTermsOfService: return "Terms of Service"
        case .profileSignOut: return "Sign Out"
        case .profileSignOutConfirm: return "Are you sure you want to sign out?"
        case .profilePersonalInfo: return "Personal Information"
        case .profileUsername: return "Username"
        case .profileEmail: return "Email"
        case .profilePhone: return "Phone"
        case .profileSave: return "Save"
        case .profileDone: return "Done"
        case .profileNoVehicles: return "No vehicles added"
        case .profileAddPayment: return "Add Payment Method"
        case .profileDefault: return "Default"
        case .profilePushNotifications: return "Push Notifications"
        case .profileBookingAlerts: return "Booking Alerts"
        case .profileTimeReminders: return "Time Reminders"
        case .profilePromotions: return "Promotions & Offers"
        case .profileEmailSection: return "Email"
        case .profileEmailNotif: return "Email Notifications"
        case .profileVersion: return "Version 1.0.0"
        case .profileUsernameEmpty: return "Username cannot be empty."
        case .profileSaveFailed: return "Failed to save profile"
        case .profilePaymentNotReady: return "Adding payment method is not yet available."
        case .profileOnlyUsername: return "Currently only the username can be updated."

        // Settings
        case .settingsTitle: return "Settings"
        case .settingsLanguage: return "Language"
        case .settingsChooseLanguage: return "Choose language"
        case .settingsAppearance: return "Appearance"
        case .settingsChooseTheme: return "Choose theme"

        // Login
        case .loginTitle: return "Sign In"
        case .loginSubtitle: return "Hi! Welcome back, you've been missed"
        case .loginEmail: return "Email"
        case .loginPassword: return "Password"
        case .loginEmailPlaceholder: return "example@gmail.com"
        case .loginPasswordPlaceholder: return "**********"
        case .loginForgotPassword: return "Forgot Password?"
        case .loginSignIn: return "Sign In"
        case .loginSigningIn: return "Signing In..."
        case .loginNoAccount: return "Don't have an account?"
        case .loginSignUp: return "Sign Up"
        case .loginOrWith: return "Or sign in with"
        case .loginSocialDisabled: return "Social sign in is not available yet."
        case .loginErrorTitle: return "Sign In Error"

        // Register
        case .registerTitle: return "Create Account"
        case .registerSubtitle:
            return "Fill your information below or register with your social account."
        case .registerName: return "Name"
        case .registerNamePlaceholder: return "Ex. John Doe"
        case .registerAgreeWith: return "Agree with"
        case .registerTerms: return "Terms & Conditions"
        case .registerSignUp: return "Sign Up"
        case .registerSigningUp: return "Signing Up..."
        case .registerHaveAccount: return "Already have an account?"
        case .registerSignIn: return "Sign In"
        case .registerErrorTitle: return "Sign Up Error"

        // Forgot
        case .forgotTitle: return "Reset Password"
        case .forgotSubtitle: return "Enter your email, we'll send you a reset code."
        case .forgotCodeTitle: return "Enter Code"
        case .forgotCodeSubtitle: return "An 8-digit code was sent to your email."
        case .forgotNewPassTitle: return "New Password"
        case .forgotNewPassSubtitle: return "Enter and confirm your new password."
        case .forgotSendCode: return "Send Code"
        case .forgotSending: return "Sending..."
        case .forgotVerify: return "Verify"
        case .forgotVerifying: return "Verifying..."
        case .forgotUpdatePassword: return "Update Password"
        case .forgotSaving: return "Saving..."
        case .forgotResendIn: return "Resend in"
        case .forgotResendCode: return "Resend Code"
        case .forgotConfirmCode: return "Verification Code"
        case .forgotNewPassword: return "New Password"
        case .forgotConfirmPassword: return "Confirm Password"
        case .forgotMinChars: return "At least 6 characters"
        case .forgotSuccessTitle: return "Success!"
        case .forgotSuccessMessage:
            return "Your password has been updated. Sign in with your new password."
        case .forgotGoToLogin: return "Go to Sign In"
        case .forgotErrorTitle: return "Error"

        // Validation
        case .valEmailRequired: return "Email is required"
        case .valEmailInvalid: return "Invalid email format"
        case .valPasswordRequired: return "Password is required"
        case .valPasswordMin: return "Password must be at least 6 characters"
        case .valNameRequired: return "Name is required"
        case .valNameMin: return "Name must be at least 2 characters"
        case .valCodeRequired: return "Enter the code"
        case .valCodeLength: return "Code must be 8 digits"
        case .valConfirmRequired: return "Please confirm your password"
        case .valPasswordMismatch: return "Passwords don't match"

        // Strength
        case .strengthWeak: return "Weak"
        case .strengthFair: return "Fair"
        case .strengthGood: return "Good"
        case .strengthStrong: return "Strong"
        case .strengthVeryStrong: return "Very Strong"

        // Parking Detail
        case .detailTotalSpots: return "total spots"
        case .detailSpotsAvailable: return "Spots Available"
        case .detailDescription: return "Description"
        case .detailNoDescription: return "No description available for this parking location."
        case .detailFeatures: return "Features"
        case .detailSecurity: return "24/7 Security"
        case .detailCCTV: return "CCTV"
        case .detailLighting: return "Good Lighting"
        case .detailCovered: return "Covered Parking"
        case .detailParkingInfo: return "Parking Info"
        case .detailAvailable: return "Available"
        case .detailPrice: return "Price"
        case .detailTotalPrice: return "Total Price"
        case .detailBookSlot: return "Book Slot"
        case .detailFullyBooked: return "Fully Booked"
        case .detailAbout: return "About"
        case .detailGallery: return "Gallery"
        case .detailReview: return "Review"
        case .detailNoGallery: return "No gallery images available"
        case .detailReviews: return "Reviews"
        case .detailAddReview: return "Add Review"
        case .detailBasedOnReviews: return "Based on reviews"
        case .detailCarParking: return "Car Parking"
        case .detailNavigate: return "Get Directions"
        case .detailNavigateWith: return "Open with"
        case .detailReviewEligibility: return "Only users with completed bookings can submit a review."
        case .detailReviewRating: return "Rating"
        case .detailReviewComment: return "Comment"
        case .detailReviewCommentRequired: return "Please enter your review comment."
        case .detailSubmitReview: return "Submit Review"
        case .detailNoReviewsYet: return "No reviews yet"
        case .reviewNeedBookingWarning: return "Book a slot at this parking first to leave a review."
        case .reviewAlreadySubmittedWarning:
            return "You already submitted reviews for your eligible bookings."

        // Booking Flow
        case .bookingBookSlot: return "Book Slot"
        case .bookingReservationInfo:
            return "Reservation starts now. Select how long you need the parking spot."
        case .bookingSelectDuration: return "Select duration"
        case .bookingPrepaidAmount: return "Prepaid amount"
        case .bookingContinue: return "Continue"
        case .bookingProcessing: return "Processing..."
        case .bookingMin: return "min"
        case .bookingHour: return "hour"
        case .bookingHours: return "hours"

        // Select Vehicle
        case .vehicleSelectTitle: return "Select Vehicle"
        case .vehicleNotFound: return "No vehicles found"
        case .vehicleAddFirst: return "Add a vehicle first to continue."
        case .vehicleAddTitle: return "Add Vehicle"
        case .vehicleSelectBrand: return "Select Brand"
        case .vehicleSelectCar: return "Select Car"
        case .vehicleSelectModel: return "Select model"
        case .vehiclePlateNumber: return "Car Number Plate"
        case .vehiclePlatePlaceholder: return "Ex. GR 789-IJKL"
        case .vehicleAdd: return "Add Vehicle"

        // Payment
        case .paymentTitle: return "Payment Methods"
        case .paymentWallet: return "Wallet"
        case .paymentCreditDebit: return "Credit & Debit Card"
        case .paymentMoreOptions: return "More Payment Options"
        case .paymentAddCard: return "Add Card"
        case .paymentConfirm: return "Confirm Payment"
        case .paymentSelectPayment: return "Select Payment"
        case .paymentChange: return "Change"
        case .paymentComingSoon: return "This payment method will be available in the next version."
        case .paymentWalletOnly: return "Only wallet payment is supported for now."

        // Review Summary
        case .reviewTitle: return "Review Summary"
        case .reviewArrivingTime: return "Arriving Time"
        case .reviewExitTime: return "Exit Time"
        case .reviewVehicle: return "Vehicle"
        case .reviewDuration: return "Duration"
        case .reviewAmount: return "Amount"
        case .reviewTotalHours: return "Total Hours"
        case .reviewFees: return "Fees"
        case .reviewTotal: return "Total"

        // Payment Success
        case .successPayment: return "Payment"
        case .successTitle: return "Payment Successful!"
        case .successMessage:
            return
                "Your Parking Slot Successfully Booked.\nYou can check your booking on Home Menu."
        case .successReservationId: return "Reservation ID:"
        case .successViewReceipt: return "View E-Receipt"
        case .successBackToHome: return "Back to Home"

        // E-Ticket / E-Receipt
        case .eticketTitle: return "E-Ticket"
        case .eticketClose: return "Close"
        case .eticketStartTime: return "Start Time"
        case .eticketEndTime: return "End Time"
        case .eticketDuration: return "Duration"
        case .eticketMinutes: return "min"
        case .eticketActualEntry: return "Actual Entry"
        case .eticketActualExit: return "Actual Exit"
        case .eticketPricePerHour: return "Price/Hour"
        case .eticketBaseAmount: return "Base Amount"
        case .eticketOvertimeCharge: return "Overtime Charge"
        case .eticketOvertime: return "Overtime!"
        case .eticketExtraCharge: return "Extra Charge:"
        case .eticketTotal: return "Total"
        case .receiptTitle: return "E-Receipt"
        case .receiptDownload: return "Download E-Receipt"
        case .receiptCar: return "Car"
        case .receiptPlate: return "Car Number Plate"
        case .receiptParking: return "Parking"
        case .receiptAddress: return "Address"
        case .receiptRate: return "Rate"
        case .receiptSubtotal: return "Subtotal"
        case .receiptServiceFee: return "Service Fee"
        case .receiptPaymentMethod: return "Payment Method"
        case .receiptDate: return "Date"
        case .receiptStatus: return "Status"
        case .receiptConfirmed: return "Confirmed ✓"

        // Bookings View
        case .bookingsOngoing: return "Ongoing"
        case .bookingsNoBookings: return "Bookings"
        case .bookingsAppearHere: return "bookings will appear here"
        case .bookingsLoadFailed: return "Failed to load bookings"
        case .bookingsCancelTitle: return "Cancel Booking"
        case .bookingsCancelConfirm: return "Are you sure you want to cancel this booking?"
        case .bookingsCancelYes: return "Yes, Cancel"
        case .bookingsCancelNo: return "No"
        case .bookingsTimer: return "Timer"
        case .bookingsCancel: return "Cancel"
        case .bookingsView: return "View"
        case .bookingsETicket: return "E-Ticket"
        case .bookingsViewReceipt: return "View Receipt"
        case .bookingsDetails: return "Details"
        case .bookingsStart: return "Start"
        case .bookingsEnd: return "End"
        case .bookingsErrorCancel: return "Failed to cancel:"

        // Bookings extra
        case .bookingsYesCancel: return "Yes, Cancel"
        case .bookingsNo: return "No"
        case .bookingsCancelMessage: return "Are you sure you want to cancel this booking?"
        case .bookingsDuration: return "Duration"
        case .bookingsActualEntry: return "Actual Entry"
        case .bookingsActualExit: return "Actual Exit"
        case .bookingsPricePerHour: return "Price per Hour"
        case .bookingsBaseAmount: return "Base Amount"
        case .bookingsOvertimeCharge: return "Overtime Charge"
        case .bookingsOvertime: return "Overtime!"
        case .bookingsExtraCharge: return "Extra charge"
        case .bookingsRetry: return "Retry"
        case .bookingsCannotCancel: return "Cannot cancel"
        case .bookingsClose: return "Close"
        case .bookingsPerHour: return "/hr"
        case .bookingsUnknown: return "Unknown"

        // Status display names
        case .statusActive: return "Active"
        case .statusInUse: return "In Use"
        case .statusCompleted: return "Completed"
        case .statusCancelled: return "Cancelled"
        case .statusExpired: return "Expired"
        case .statusNoShow: return "No Show"

        // Time ago
        case .timeNow: return "now"
        case .timeMinAgo: return "m"
        case .timeHourAgo: return "h"
        case .timeDayAgo: return "d"

        // Notifications
        case .notifTitle: return "Notifications"
        case .notifLoading: return "Loading notifications..."
        case .notifEmpty: return "No Notifications"
        case .notifEmptySubtitle: return "You're all caught up!"
        case .notifToday: return "TODAY"
        case .notifYesterday: return "YESTERDAY"
        case .notifOlder: return "OLDER"
        case .notifMarkAllRead: return "Mark all read"
        case .notifNew: return "NEW"
        case .notifAllCaughtUp: return "You're all caught up!"

        // Explore extra
        case .exploreNoResults: return "No results found"
        case .exploreChangeSearch: return "Try a different search term."
        case .exploreFilterInfo: return "Filter section coming in next update."
        case .mapZoomIn: return "Zoom in"
        case .mapZoomOut: return "Zoom out"

        // Home extra
        case .homeLocation: return "Location"
        case .homeSearchParking: return "Search parking"
        case .homePopularParking: return "Popular parking"
        case .homeNearbyParking: return "Nearby parking"
        case .homeCityLabel: return "City"
        case .homeSearchNoResults: return "No results found"
        case .homeSearchNoResultsSub: return "Try searching with a different name or address."

        // Favorite extra
        case .favoriteRemoveTitle: return "Remove from favorites?"
        case .favoriteCancel: return "Cancel"
        case .favoriteYesRemove: return "Yes, Remove"
        case .favoriteNoFavorites: return "No Favorites"
        case .favoriteNoFavoritesSub: return "Your favorite parking spots will appear here."

        // Wallet
        case .walletTitle: return "Wallet"
        case .walletBalance: return "Current balance"
        case .walletTopUp: return "Top Up"
        case .walletQuickTopUp: return "Quick Top Up"
        case .walletTransactions: return "Transactions"
        case .walletNoTransactions: return "No transactions"
        case .walletEnterAmount: return "Enter custom amount"
        case .walletTopUpDone: return "Wallet topped up"
        case .walletInsufficientBalance: return "Insufficient balance"
        case .walletInvalidAmount: return "Invalid amount"
        case .walletPaymentFor: return "Parking payment"
        case .walletCurrency: return "so'm"

        // Common
        case .ok: return "OK"
        case .cancel: return "Cancel"
        case .error: return "Error"
        case .info: return "Info"
        case .unknown: return "Unknown"
        case .back: return "Back"
        }
    }

    // MARK: - Russian
    private var ru: String {
        switch self {
        // Tab
        case .tabHome: return "Главная"
        case .tabExplore: return "Карта"
        case .tabFavorite: return "Избранное"
        case .tabBookings: return "Бронирования"
        case .tabProfile: return "Профиль"

        // Home
        case .homeGreeting: return "Привет"
        case .homeSubtitle: return "Найдите место для парковки"
        case .homeSearch: return "Поиск парковки..."
        case .homePopular: return "Популярные парковки"
        case .homeNearby: return "Поблизости"
        case .homeSeeAll: return "Все"
        case .homeNoParking: return "Парковка не найдена"
        case .homeNoResults: return "Ничего не найдено"
        case .homeCheckInternet: return "Проверьте интернет или настройки геолокации."
        case .homeLoadFailed: return "Не удалось загрузить парковки"
        case .homeRetry: return "Повторить"
        case .launchLoading: return "Загрузка данных..."
        case .launchFailed: return "Не удалось запустить приложение"
        case .retry: return "Повторить"

        // Explore
        case .exploreTitle: return "Карта"
        case .exploreSearch: return "Поиск адреса..."

        // Favorite
        case .favoriteTitle: return "Избранное"
        case .favoriteEmpty: return "Нет избранных"
        case .favoriteEmptySubtitle: return "Добавьте парковки в избранное."

        // Bookings
        case .bookingsTitle: return "Бронирования"
        case .bookingsActive: return "Активные"
        case .bookingsCompleted: return "Завершённые"
        case .bookingsCancelled: return "Отменённые"
        case .bookingsEmpty: return "Нет бронирований"
        case .bookingsEmptySubtitle: return "Вы ещё не бронировали."

        // Profile
        case .profileTitle: return "Профиль"
        case .profileAccount: return "Аккаунт"
        case .profileYourProfile: return "Ваш профиль"
        case .profilePaymentMethods: return "Способы оплаты"
        case .profileMyWallet: return "Кошелёк"
        case .profilePreferences: return "Настройки"
        case .profileSettings: return "Настройки"
        case .profileSupport: return "Поддержка"
        case .profileHelpCenter: return "Центр помощи"
        case .profilePrivacyPolicy: return "Политика конфиденциальности"
        case .profileInviteFriends: return "Пригласить друзей"
        case .profileLogout: return "Выйти"
        case .profileLogoutConfirm: return "Вы действительно хотите выйти?"
        case .profileComingSoon: return "Скоро будет доступно."

        // Profile extra
        case .profileEditProfile: return "Редактировать профиль"
        case .profileMyVehicles: return "Мои автомобили"
        case .profileNotifications: return "Уведомления"
        case .profileLanguage: return "Язык"
        case .profileDarkMode: return "Тёмный режим"
        case .profileTermsOfService: return "Условия использования"
        case .profileSignOut: return "Выйти"
        case .profileSignOutConfirm: return "Вы уверены, что хотите выйти?"
        case .profilePersonalInfo: return "Личная информация"
        case .profileUsername: return "Имя пользователя"
        case .profileEmail: return "Электронная почта"
        case .profilePhone: return "Телефон"
        case .profileSave: return "Сохранить"
        case .profileDone: return "Готово"
        case .profileNoVehicles: return "Транспортные средства не добавлены"
        case .profileAddPayment: return "Добавить способ оплаты"
        case .profileDefault: return "По умолчанию"
        case .profilePushNotifications: return "Push-уведомления"
        case .profileBookingAlerts: return "Уведомления о бронировании"
        case .profileTimeReminders: return "Напоминания о времени"
        case .profilePromotions: return "Акции и предложения"
        case .profileEmailSection: return "Email"
        case .profileEmailNotif: return "Email уведомления"
        case .profileVersion: return "Версия 1.0.0"
        case .profileUsernameEmpty: return "Имя пользователя не может быть пустым."
        case .profileSaveFailed: return "Не удалось сохранить профиль"
        case .profilePaymentNotReady: return "Добавление способа оплаты пока недоступно."
        case .profileOnlyUsername:
            return "В настоящее время можно обновить только имя пользователя."

        // Settings
        case .settingsTitle: return "Настройки"
        case .settingsLanguage: return "Язык"
        case .settingsChooseLanguage: return "Выберите язык"
        case .settingsAppearance: return "Тема"
        case .settingsChooseTheme: return "Выберите тему"

        // Login
        case .loginTitle: return "Вход"
        case .loginSubtitle: return "Привет! С возвращением, мы скучали"
        case .loginEmail: return "Email"
        case .loginPassword: return "Пароль"
        case .loginEmailPlaceholder: return "example@gmail.com"
        case .loginPasswordPlaceholder: return "**********"
        case .loginForgotPassword: return "Забыли пароль?"
        case .loginSignIn: return "Войти"
        case .loginSigningIn: return "Вход..."
        case .loginNoAccount: return "Нет аккаунта?"
        case .loginSignUp: return "Регистрация"
        case .loginOrWith: return "Или войдите через"
        case .loginSocialDisabled: return "Вход через соцсети пока недоступен."
        case .loginErrorTitle: return "Ошибка входа"

        // Register
        case .registerTitle: return "Создать аккаунт"
        case .registerSubtitle: return "Заполните данные или зарегистрируйтесь через соцсети."
        case .registerName: return "Имя"
        case .registerNamePlaceholder: return "Например: Иван Иванов"
        case .registerAgreeWith: return "Согласен с"
        case .registerTerms: return "Условиями использования"
        case .registerSignUp: return "Регистрация"
        case .registerSigningUp: return "Регистрация..."
        case .registerHaveAccount: return "Уже есть аккаунт?"
        case .registerSignIn: return "Войти"
        case .registerErrorTitle: return "Ошибка регистрации"

        // Forgot
        case .forgotTitle: return "Сброс пароля"
        case .forgotSubtitle: return "Введите email, мы отправим код для сброса."
        case .forgotCodeTitle: return "Введите код"
        case .forgotCodeSubtitle: return "8-значный код отправлен на ваш email."
        case .forgotNewPassTitle: return "Новый пароль"
        case .forgotNewPassSubtitle: return "Введите и подтвердите новый пароль."
        case .forgotSendCode: return "Отправить код"
        case .forgotSending: return "Отправка..."
        case .forgotVerify: return "Подтвердить"
        case .forgotVerifying: return "Проверка..."
        case .forgotUpdatePassword: return "Обновить пароль"
        case .forgotSaving: return "Сохранение..."
        case .forgotResendIn: return "Отправить снова"
        case .forgotResendCode: return "Отправить код повторно"
        case .forgotConfirmCode: return "Код подтверждения"
        case .forgotNewPassword: return "Новый пароль"
        case .forgotConfirmPassword: return "Подтвердите пароль"
        case .forgotMinChars: return "Минимум 6 символов"
        case .forgotSuccessTitle: return "Успех!"
        case .forgotSuccessMessage: return "Пароль обновлён. Войдите с новым паролем."
        case .forgotGoToLogin: return "Перейти ко входу"
        case .forgotErrorTitle: return "Ошибка"

        // Validation
        case .valEmailRequired: return "Введите email"
        case .valEmailInvalid: return "Неверный формат email"
        case .valPasswordRequired: return "Введите пароль"
        case .valPasswordMin: return "Пароль должен быть не менее 6 символов"
        case .valNameRequired: return "Введите имя"
        case .valNameMin: return "Имя должно быть не менее 2 символов"
        case .valCodeRequired: return "Введите код"
        case .valCodeLength: return "Код состоит из 8 цифр"
        case .valConfirmRequired: return "Подтвердите пароль"
        case .valPasswordMismatch: return "Пароли не совпадают"

        // Strength
        case .strengthWeak: return "Слабый"
        case .strengthFair: return "Средний"
        case .strengthGood: return "Хороший"
        case .strengthStrong: return "Сильный"
        case .strengthVeryStrong: return "Очень сильный"

        // Parking Detail
        case .detailTotalSpots: return "всего мест"
        case .detailSpotsAvailable: return "мест свободно"
        case .detailDescription: return "Описание"
        case .detailNoDescription: return "Описание для этой парковки отсутствует."
        case .detailFeatures: return "Особенности"
        case .detailSecurity: return "Охрана 24/7"
        case .detailCCTV: return "Видеонаблюдение"
        case .detailLighting: return "Хорошее освещение"
        case .detailCovered: return "Крытая парковка"
        case .detailParkingInfo: return "О парковке"
        case .detailAvailable: return "Свободно"
        case .detailPrice: return "Цена"
        case .detailTotalPrice: return "Общая цена"
        case .detailBookSlot: return "Забронировать"
        case .detailFullyBooked: return "Мест нет"
        case .detailAbout: return "О месте"
        case .detailGallery: return "Галерея"
        case .detailReview: return "Отзывы"
        case .detailNoGallery: return "Изображения галереи отсутствуют"
        case .detailReviews: return "Отзывы"
        case .detailAddReview: return "Добавить отзыв"
        case .detailBasedOnReviews: return "На основе отзывов"
        case .detailCarParking: return "Автопарковка"
        case .detailNavigate: return "Построить маршрут"
        case .detailNavigateWith: return "Открыть через"
        case .detailReviewEligibility: return "Оставить отзыв можно только по завершенному бронированию."
        case .detailReviewRating: return "Оценка"
        case .detailReviewComment: return "Комментарий"
        case .detailReviewCommentRequired: return "Пожалуйста, введите текст отзыва."
        case .detailSubmitReview: return "Отправить отзыв"
        case .detailNoReviewsYet: return "Пока нет отзывов"
        case .reviewNeedBookingWarning:
            return "Сначала забронируйте место на этой парковке, чтобы оставить отзыв."
        case .reviewAlreadySubmittedWarning:
            return "По вашим завершённым бронированиям отзывы уже отправлены."

        // Booking Flow
        case .bookingBookSlot: return "Забронировать"
        case .bookingReservationInfo:
            return "Бронирование начинается сейчас. Выберите продолжительность."
        case .bookingSelectDuration: return "Выберите время"
        case .bookingPrepaidAmount: return "Предоплата"
        case .bookingContinue: return "Продолжить"
        case .bookingProcessing: return "Обработка..."
        case .bookingMin: return "мин"
        case .bookingHour: return "час"
        case .bookingHours: return "часов"

        // Select Vehicle
        case .vehicleSelectTitle: return "Выбрать авто"
        case .vehicleNotFound: return "Авто не найдено"
        case .vehicleAddFirst: return "Сначала добавьте автомобиль."
        case .vehicleAddTitle: return "Добавить авто"
        case .vehicleSelectBrand: return "Выбрать марку"
        case .vehicleSelectCar: return "Выбрать авто"
        case .vehicleSelectModel: return "Выбрать модель"
        case .vehiclePlateNumber: return "Гос. номер"
        case .vehiclePlatePlaceholder: return "Напр. А 123 БВ"
        case .vehicleAdd: return "Добавить авто"

        // Payment
        case .paymentTitle: return "Способы оплаты"
        case .paymentWallet: return "Кошелёк"
        case .paymentCreditDebit: return "Кредитная и дебетовая карта"
        case .paymentMoreOptions: return "Другие способы оплаты"
        case .paymentAddCard: return "Добавить карту"
        case .paymentConfirm: return "Подтвердить оплату"
        case .paymentSelectPayment: return "Выберите оплату"
        case .paymentChange: return "Изменить"
        case .paymentComingSoon: return "Этот способ оплаты появится в следующей версии."
        case .paymentWalletOnly: return "Сейчас поддерживается только оплата через кошелёк."

        // Review Summary
        case .reviewTitle: return "Итог бронирования"
        case .reviewArrivingTime: return "Время прибытия"
        case .reviewExitTime: return "Время выезда"
        case .reviewVehicle: return "Автомобиль"
        case .reviewDuration: return "Продолжительность"
        case .reviewAmount: return "Сумма"
        case .reviewTotalHours: return "Всего часов"
        case .reviewFees: return "Комиссия"
        case .reviewTotal: return "Итого"

        // Payment Success
        case .successPayment: return "Оплата"
        case .successTitle: return "Оплата успешна!"
        case .successMessage:
            return "Ваше место успешно забронировано.\nПроверьте бронирование в главном меню."
        case .successReservationId: return "Номер брони:"
        case .successViewReceipt: return "Посмотреть чек"
        case .successBackToHome: return "На главную"

        // E-Ticket / E-Receipt
        case .eticketTitle: return "Э-Билет"
        case .eticketClose: return "Закрыть"
        case .eticketStartTime: return "Время начала"
        case .eticketEndTime: return "Время окончания"
        case .eticketDuration: return "Продолжительность"
        case .eticketMinutes: return "мин"
        case .eticketActualEntry: return "Фактический въезд"
        case .eticketActualExit: return "Фактический выезд"
        case .eticketPricePerHour: return "Цена/час"
        case .eticketBaseAmount: return "Базовая сумма"
        case .eticketOvertimeCharge: return "Доп. оплата"
        case .eticketOvertime: return "Переработка!"
        case .eticketExtraCharge: return "Доп. оплата:"
        case .eticketTotal: return "Итого"
        case .receiptTitle: return "Эл. чек"
        case .receiptDownload: return "Скачать эл. чек"
        case .receiptCar: return "Автомобиль"
        case .receiptPlate: return "Гос. номер"
        case .receiptParking: return "Парковка"
        case .receiptAddress: return "Адрес"
        case .receiptRate: return "Тариф"
        case .receiptSubtotal: return "Подитог"
        case .receiptServiceFee: return "Сервисный сбор"
        case .receiptPaymentMethod: return "Способ оплаты"
        case .receiptDate: return "Дата"
        case .receiptStatus: return "Статус"
        case .receiptConfirmed: return "Подтверждено ✓"

        // Bookings View
        case .bookingsOngoing: return "Текущие"
        case .bookingsNoBookings: return "бронирований нет"
        case .bookingsAppearHere: return "бронирования появятся здесь"
        case .bookingsLoadFailed: return "Не удалось загрузить бронирования"
        case .bookingsCancelTitle: return "Отменить бронь"
        case .bookingsCancelConfirm: return "Вы уверены, что хотите отменить бронирование?"
        case .bookingsCancelYes: return "Да, отменить"
        case .bookingsCancelNo: return "Нет"
        case .bookingsTimer: return "Таймер"
        case .bookingsCancel: return "Отмена"
        case .bookingsView: return "Просмотр"
        case .bookingsETicket: return "Э-Билет"
        case .bookingsViewReceipt: return "Посмотреть чек"
        case .bookingsDetails: return "Подробности"
        case .bookingsStart: return "Начало"
        case .bookingsEnd: return "Конец"
        case .bookingsErrorCancel: return "Не удалось отменить:"

        // Bookings extra
        case .bookingsYesCancel: return "Да, отменить"
        case .bookingsNo: return "Нет"
        case .bookingsCancelMessage: return "Вы уверены, что хотите отменить эту бронь?"
        case .bookingsDuration: return "Продолжительность"
        case .bookingsActualEntry: return "Фактический въезд"
        case .bookingsActualExit: return "Фактический выезд"
        case .bookingsPricePerHour: return "Цена за час"
        case .bookingsBaseAmount: return "Основная сумма"
        case .bookingsOvertimeCharge: return "Плата за перестой"
        case .bookingsOvertime: return "Перестой!"
        case .bookingsExtraCharge: return "Дополнительная плата"
        case .bookingsRetry: return "Повторить"
        case .bookingsCannotCancel: return "Не удалось отменить"
        case .bookingsClose: return "Закрыть"
        case .bookingsPerHour: return "/час"
        case .bookingsUnknown: return "Неизвестно"

        // Status display names
        case .statusActive: return "Активный"
        case .statusInUse: return "Используется"
        case .statusCompleted: return "Завершено"
        case .statusCancelled: return "Отменено"
        case .statusExpired: return "Истекло"
        case .statusNoShow: return "Неявка"

        // Time ago
        case .timeNow: return "сейчас"
        case .timeMinAgo: return "мин"
        case .timeHourAgo: return "ч"
        case .timeDayAgo: return "д"

        // Notifications
        case .notifTitle: return "Уведомления"
        case .notifLoading: return "Загрузка уведомлений..."
        case .notifEmpty: return "Нет уведомлений"
        case .notifEmptySubtitle: return "Вы всё просмотрели!"
        case .notifToday: return "СЕГОДНЯ"
        case .notifYesterday: return "ВЧЕРА"
        case .notifOlder: return "РАНЕЕ"
        case .notifMarkAllRead: return "Прочитать все"
        case .notifNew: return "НОВОЕ"
        case .notifAllCaughtUp: return "Все уведомления прочитаны!"

        // Explore extra
        case .exploreNoResults: return "Ничего не найдено"
        case .exploreChangeSearch: return "Попробуйте другой запрос."
        case .exploreFilterInfo: return "Раздел фильтров появится в следующем обновлении."
        case .mapZoomIn: return "Увеличить"
        case .mapZoomOut: return "Уменьшить"

        // Home extra
        case .homeLocation: return "Местоположение"
        case .homeSearchParking: return "Поиск парковки"
        case .homePopularParking: return "Популярные парковки"
        case .homeNearbyParking: return "Парковки рядом"
        case .homeCityLabel: return "Город"
        case .homeSearchNoResults: return "Ничего не найдено"
        case .homeSearchNoResultsSub: return "Попробуйте другое название или адрес."

        // Favorite extra
        case .favoriteRemoveTitle: return "Удалить из избранного?"
        case .favoriteCancel: return "Отмена"
        case .favoriteYesRemove: return "Да, удалить"
        case .favoriteNoFavorites: return "Нет избранных"
        case .favoriteNoFavoritesSub: return "Ваши избранные парковки появятся здесь."

        // Wallet
        case .walletTitle: return "Кошелёк"
        case .walletBalance: return "Текущий баланс"
        case .walletTopUp: return "Пополнить"
        case .walletQuickTopUp: return "Быстрое пополнение"
        case .walletTransactions: return "Транзакции"
        case .walletNoTransactions: return "Нет транзакций"
        case .walletEnterAmount: return "Введите сумму"
        case .walletTopUpDone: return "Кошелёк пополнен"
        case .walletInsufficientBalance: return "Недостаточно средств"
        case .walletInvalidAmount: return "Неверная сумма"
        case .walletPaymentFor: return "Оплата парковки"
        case .walletCurrency: return "сум"

        // Common
        case .ok: return "ОК"
        case .cancel: return "Отмена"
        case .error: return "Ошибка"
        case .info: return "Информация"
        case .unknown: return "Неизвестно"
        case .back: return "Назад"
        }
    }
}
