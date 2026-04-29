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
    case profilePhotoUploadFailed
    case profilePaymentNotReady
    case profileOnlyUsername

    // Settings
    case settingsTitle
    case settingsLanguage
    case settingsChooseLanguage
    case settingsAppearance
    case settingsChooseTheme
    case settingsColorTheme
    case themeCarbon
    case themeOcean
    case themeForest
    case themeSunset

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
    case detailAdditionalInfo
    case detailWorkingHours
    case detailPhone
    case detailMaxHeight
    case yesLabel
    case noLabel
    case splashTagline
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
    case vehicleDeleteTitle
    case vehicleDeleteConfirm
    case vehicleDelete

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

    // Admin - Editor
    case adminSaving
    case adminSave
    case adminEdit
    case adminNewParking
    case adminAddParking
    case adminError
    case adminCancel
    case adminBasicInfo
    case adminParkingName
    case adminSelectCity
    case adminAddress
    case adminLocation
    case adminSearchLocation
    case adminTapMapHint
    case adminPriceCapacity
    case adminPricePerHour
    case adminTotalSpots
    case adminDescription
    case adminFeatures
    case adminImages
    case adminAddImage
    case adminImageHint
    case adminDropHint

    // Admin - Dashboard
    case adminDashboard
    case adminTotalParkings
    case adminTotalRevenue
    case adminTotalReservations
    case adminActiveNow
    case adminQuickActions
    case adminViewReports
    case adminGreetingMorning
    case adminGreetingDay
    case adminGreetingEvening
    case adminGreetingNight

    // Admin - Parking List
    case adminMyParkings
    case adminSearchParkings
    case adminEditParking
    case adminDeleteParking
    case adminDeleteConfirm
    case adminDeleteYes
    case adminDeleteNo
    case adminNoParkings
    case adminNoParkingsSub

    // Admin - Reservations
    case adminReservations
    case adminAllParkings
    case adminAllStatuses
    case adminNoReservations
    case adminFilterByParking
    case adminCancelReservation
    case adminCancelReservationConfirm

    // Admin - Profile
    case adminProfile
    case adminRealtimeConnected
    case adminRealtimeDisconnected
    case adminManageParkings
    case adminStatsParkings
    case adminStatsReservations
    case adminOwnerBadge
    case adminStatistics
    case adminStatParkings
    case adminStatCompleted
    case adminStatActive
    case adminLanguageLabel
    case adminAppearanceLabel
    case adminVersionLabel
    case adminClose
    case adminSelectLanguage
    case adminSelectAppearance
    case adminSignOutTitle
    case adminSignOutConfirm

    func localized(_ lang: AppLanguage) -> String {
        switch lang {
        case .uz: return uz
        case .en: return en
        case .ru: return ru
        }
    }
}
