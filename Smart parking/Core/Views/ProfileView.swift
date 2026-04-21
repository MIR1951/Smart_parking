//
//  ProfileView.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 23/01/26.
//

import SwiftUI
import PhotosUI
import os

struct ProfileView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(UserManager.self) private var userManager
    @Environment(LocalizationManager.self) private var loc
    @Environment(AppCoordinator.self) private var coordinator
    @State private var showLogoutAlert = false
    @State private var showEditProfile = false
    @State private var showPaymentMethods = false
    @State private var showMyVehicles = false
    @State private var showInfoAlert = false
    @State private var infoMessage = ""
    @State private var scrollOffset: CGFloat = 0
    @State private var showPhotoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedAvatarImage: Image?
    @State private var isUploadingAvatar = false

    private var headerProgress: CGFloat {
        min(max(scrollOffset / 250, 0), 1)
    }

    var body: some View {
        ZStack {
            AppAnimatedBackground()

            VStack(spacing: 0) {
                // MARK: - Sticky Profile Header
                profileHeader
                    .padding(.bottom, 8)

                // MARK: - Scrollable Content
                ScrollView(showsIndicators: false) {
                    // Scroll offset o'lchash uchun
                    GeometryReader { geo in
                        Color.clear
                            .preference(
                                key: ScrollOffsetPreferenceKey.self,
                                value: -geo.frame(in: .named("profileScroll")).minY
                            )
                    }
                    .frame(height: 0)

                    VStack(spacing: AppTheme.Spacing.xLarge) {

                        // MARK: - Account Section
                        sectionCard(
                            title: loc.str(.profileAccount),
                            rows: [
                                ProfileRowData(
                                    icon: "person", title: loc.str(.profileYourProfile),
                                    color: AppTheme.Palette.brand
                                ) {
                                    showEditProfile = true
                                },
                                ProfileRowData(
                                    icon: "creditcard", title: loc.str(.profilePaymentMethods),
                                    color: AppTheme.Palette.brand
                                ) {
                                    showPaymentMethods = true
                                },
                                ProfileRowData(
                                    icon: "car.fill",
                                    title: loc.str(.profileMyVehicles),
                                    color: AppTheme.Palette.accent
                                ) {
                                    showMyVehicles = true
                                },
                                ProfileRowData(
                                    icon: "wallet.pass", title: loc.str(.profileMyWallet),
                                    color: AppTheme.Palette.warning,
                                    subtitle: WalletManager.shared.formattedBalance
                                ) {
                                    coordinator.showWallet()
                                },
                            ]
                        )
                        .appReveal(0.06)

                        // MARK: - Preferences Section
                        sectionCard(
                            title: loc.str(.profilePreferences),
                            rows: [
                                ProfileRowData(
                                    icon: "gearshape", title: loc.str(.profileSettings),
                                    color: AppTheme.Palette.textSecondary
                                ) {
                                    coordinator.showSettings()
                                }
                            ]
                        )
                        .appReveal(0.10)

                        // MARK: - Support Section
                        sectionCard(
                            title: loc.str(.profileSupport),
                            rows: [
                                ProfileRowData(
                                    icon: "questionmark.circle", title: loc.str(.profileHelpCenter),
                                    color: AppTheme.Palette.success
                                ) {
                                    showComingSoon(loc.str(.profileComingSoon))
                                },
                                ProfileRowData(
                                    icon: "lock.shield", title: loc.str(.profilePrivacyPolicy),
                                    color: AppTheme.Palette.textSecondary
                                ) {
                                    showComingSoon(loc.str(.profileComingSoon))
                                },
                                ProfileRowData(
                                    icon: "person.2", title: loc.str(.profileInviteFriends),
                                    color: AppTheme.Palette.brand
                                ) {
                                    showComingSoon(loc.str(.profileComingSoon))
                                },
                            ]
                        )
                        .appReveal(0.14)

                        // MARK: - Log Out
                        Button {
                            AppTheme.Haptic.medium()
                            showLogoutAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "arrow.right.square")
                                    .font(.body)
                                Text(loc.str(.profileLogout))
                                    .font(AppTheme.Typography.headline)
                            }
                            .foregroundColor(AppTheme.Palette.danger)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.Palette.dangerSoft)
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: AppTheme.Radius.medium, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .pressStyle()
                        .appReveal(0.18)
                        .padding(.horizontal)
                        .padding(.bottom, AppTheme.Spacing.large)
                    }
                }
                .coordinateSpace(name: "profileScroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    withAnimation(.easeOut(duration: 0.15)) {
                        scrollOffset = value
                    }
                }
            }
        }
        .task {
            await userManager.fetchCurrentUser()
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showEditProfile) {
            EditProfileView()
        }
        .sheet(isPresented: $showPaymentMethods) {
            PaymentMethodsSettingsView()
        }
        .sheet(isPresented: $showMyVehicles) {
            MyVehiclesView()
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotoItem)
        .task(id: selectedPhotoItem) {
            await onProfilePhotoSelected()
        }
        .alert(loc.str(.info), isPresented: $showInfoAlert) {
            Button(loc.str(.ok)) {}
        } message: {
            Text(infoMessage)
        }
        .alert(loc.str(.profileLogout), isPresented: $showLogoutAlert) {
            Button(loc.str(.cancel), role: .cancel) {}

            Button(loc.str(.profileLogout), role: .destructive) {
                Task {
                    await authManager.signOut()
                }
            }
        } message: {
            Text(loc.str(.profileLogoutConfirm))
        }
    }

    // MARK: - Profile Header (sticky, animatsion bilan kichrayadi)
    private var profileHeader: some View {
        let avatarSize: CGFloat = 100 - (headerProgress * 20)  // 100 → 80
        let nameSize: CGFloat = 22 - (headerProgress * 2)    // 22 → 20
        let showEmail = headerProgress < 0.5

        return HStack(spacing: 14) {
            // Avatar
            ZStack {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [AppTheme.Palette.brand, AppTheme.Palette.brandDark],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3 - headerProgress
                    )
                    .frame(width: avatarSize, height: avatarSize)

                Group {
                    if let selectedAvatarImage {
                        selectedAvatarImage
                            .resizable()
                            .scaledToFill()
                    } else if let avatarURL = userManager.currentUser?.profileImageURL,
                        let url = URL(string: avatarURL)
                    {
                        CachedAsyncImage(url: url) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            avatarPlaceholder(size: avatarSize - 10)
                        }
                    } else {
                        avatarPlaceholder(size: avatarSize - 10)
                    }
                }
                .frame(width: avatarSize - 10, height: avatarSize - 10)
                .clipShape(Circle())

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            showPhotoPicker = true
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.Palette.brand)
                                if isUploadingAvatar {
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(0.65)
                                } else {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(width: max(24, avatarSize * 0.25), height: max(24, avatarSize * 0.25))
                            .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(width: avatarSize, height: avatarSize)
            }
            .onTapGesture {
                showPhotoPicker = true
            }

            // Ism va email (compact holatda gorizontal)
            VStack(alignment: headerProgress > 0.3 ? .leading : .center, spacing: 2) {
                Text(userManager.currentUser?.username ?? "User")
                    .font(.system(size: nameSize, weight: .semibold, design: .rounded))
                    .foregroundColor(AppTheme.Palette.textPrimary)

                if showEmail {
                    Text(userManager.currentUser?.email ?? "")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Palette.textSecondary)
                        .transition(.opacity.combined(with: .scale))
                }
            }
            .frame(
                maxWidth: headerProgress > 0.3 ? .infinity : nil,
                alignment: headerProgress > 0.3 ? .leading : .center)

            if headerProgress > 0.3 { Spacer() }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
        .padding(.top, headerProgress > 0.3 ? 8 : 20)
        .padding(.bottom, 4)
        .background(
            Group {
                if headerProgress > 0.3 {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Rectangle()
                                .fill(AppTheme.Palette.surface.opacity(headerProgress * 0.6))
                        )
                } else {
                    Color.clear
                }
            }
        )
    }

    private func avatarPlaceholder(size: CGFloat) -> some View {
        Circle()
            .fill(AppTheme.Palette.brandSoft)
            .frame(width: size, height: size)
            .overlay {
                Text(userInitial)
                    .font(.system(size: size * 0.4, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.Palette.brand)
            }
    }

    // MARK: - Section Card Builder
    private func sectionCard(title: String, rows: [ProfileRowData]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(AppTheme.Typography.captionBold)
                .foregroundColor(AppTheme.Palette.textTertiary)
                .textCase(.uppercase)
                .padding(.horizontal)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                ForEach(rows.indices, id: \.self) { index in
                    let row = rows[index]
                    Button {
                        AppTheme.Haptic.light()
                        row.action()
                    } label: {
                        ProfileRow(
                            icon: row.icon, title: row.title, color: row.color,
                            subtitle: row.subtitle)
                    }
                    .buttonStyle(.plain)

                    if index < rows.count - 1 {
                        Divider().padding(.leading, 56)
                    }
                }
            }
            .appCard()
        }
        .padding(.horizontal)
    }

    private var userInitial: String {
        let source = userManager.currentUser?.username ?? userManager.currentUser?.email ?? "U"
        return String(source.prefix(1)).uppercased()
    }

    private func showComingSoon(_ message: String) {
        infoMessage = message
        showInfoAlert = true
    }

    private func onProfilePhotoSelected() async {
        guard let item = selectedPhotoItem else { return }
        guard let user = userManager.currentUser else { return }

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data) else { return }

            selectedAvatarImage = Image(uiImage: uiImage)
            isUploadingAvatar = true

            // HEIC/PNG → JPEG konvertatsiya (iOS default HEIC formatini qo'llab-quvvatlash)
            let jpegData: Data
            if let d = uiImage.jpegData(compressionQuality: 0.85), d.count <= 5 * 1024 * 1024 {
                jpegData = d
            } else if let d = uiImage.jpegData(compressionQuality: 0.6), d.count <= 5 * 1024 * 1024 {
                jpegData = d
            } else if let d = uiImage.jpegData(compressionQuality: 0.4) {
                jpegData = d
            } else {
                throw StorageError.invalidImageFormat
            }

            let uploadedURL = try await SupabaseStorageManager().uploadProfilePhoto(
                for: user,
                imageData: jpegData
            )
            try await userManager.updateProfileImageURL(uploadedURL)
            isUploadingAvatar = false
        } catch {
            selectedAvatarImage = nil
            selectedPhotoItem = nil
            isUploadingAvatar = false
            infoMessage = loc.str(.profilePhotoUploadFailed)
            showInfoAlert = true
            Logger.auth.error("Avatar upload failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - Profile Row Data

struct ProfileRowData {
    let icon: String
    let title: String
    let color: Color
    var subtitle: String? = nil
    let action: () -> Void

    init(
        icon: String, title: String, color: Color, subtitle: String? = nil,
        action: @escaping () -> Void = {}
    ) {
        self.icon = icon
        self.title = title
        self.color = color
        self.subtitle = subtitle
        self.action = action
    }
}

// MARK: - Profile Row View

struct ProfileRow: View {
    let icon: String
    let title: String
    var color: Color = AppTheme.Palette.textPrimary
    var subtitle: String? = nil

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(color)
                .frame(width: 36, height: 36)
                .background(
                    LinearGradient(
                        colors: [color.opacity(0.15), color.opacity(0.05)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.small, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Palette.textPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Palette.textSecondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(AppTheme.Palette.textTertiary)
        }
        .padding(.horizontal)
        .padding(.vertical, 13)
        .contentShape(Rectangle())
    }
}
