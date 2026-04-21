//
//  AdminProfileView.swift
//  Smart parking
//
//  Admin profil — statistika, sozlamalar va chiqish
//

import SwiftUI

struct AdminProfileView: View {
    @Bindable var store: AdminStore
    @Environment(AuthManager.self) private var authManager
    @Environment(UserManager.self) private var userManager
    @Environment(LocalizationManager.self) private var loc
    @Environment(AppearanceManager.self) private var appearance

    @State private var showLogoutConfirm = false
    @State private var showLanguagePicker = false
    @State private var showAppearancePicker = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                profileHeader
                    .appReveal(0)

                statisticsSection
                    .appReveal(0.05)

                settingsSection
                    .appReveal(0.1)

                logoutButton
                    .appReveal(0.15)
            }
            .padding()
            .padding(.bottom, 24)
        }
        .background(AppAnimatedBackground())
        .navigationBarHidden(true)
        .alert(loc.str(.adminSignOutTitle), isPresented: $showLogoutConfirm) {
            Button(loc.str(.adminCancel), role: .cancel) {}
            Button(loc.str(.adminSignOutTitle), role: .destructive) {
                Task { await authManager.signOut() }
            }
        } message: {
            Text(loc.str(.adminSignOutConfirm))
        }
        .sheet(isPresented: $showLanguagePicker) {
            languagePickerSheet
        }
        .sheet(isPresented: $showAppearancePicker) {
            appearancePickerSheet
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.Palette.brand, AppTheme.Palette.brandLight],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                if let urlString = userManager.currentUser?.profileImageURL,
                   let url = URL(string: urlString) {
                    CachedAsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Image(systemName: "person.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.fill")
                        .font(.title)
                        .foregroundColor(.white)
                }
            }

            Text(userManager.currentUser?.username ?? "Admin")
                .font(AppTheme.Typography.title3)
                .fontWeight(.bold)

            Text(userManager.currentUser?.email ?? "")
                .font(AppTheme.Typography.subheadline)
                .foregroundColor(AppTheme.Palette.textSecondary)

            // Owner badge
            HStack(spacing: 4) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.caption)
                Text(loc.str(.adminOwnerBadge))
                    .font(AppTheme.Typography.caption)
                    .fontWeight(.semibold)
            }
            .foregroundColor(AppTheme.Palette.brand)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(AppTheme.Palette.brandSoft)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .glassCard()
    }

    // MARK: - Statistics

    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(loc.str(.adminStatistics))
                .font(AppTheme.Typography.headline)

            HStack(spacing: 10) {
                miniStatCard(
                    icon: "car.fill",
                    value: "\(store.ownedParkings.count)",
                    label: loc.str(.adminStatParkings),
                    color: AppTheme.Palette.brand
                )
                miniStatCard(
                    icon: "checkmark.circle.fill",
                    value: "\(store.dashboardStats?.total_completed ?? 0)",
                    label: loc.str(.adminStatCompleted),
                    color: AppTheme.Palette.success
                )
                miniStatCard(
                    icon: "clock.fill",
                    value: "\(store.dashboardStats?.active_reservations ?? 0)",
                    label: loc.str(.adminStatActive),
                    color: .orange
                )
            }
        }
    }

    private func miniStatCard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(value)
                .font(AppTheme.Typography.title2)
                .fontWeight(.bold)

            Text(label)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Palette.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .glassCard()
    }

    // MARK: - Settings

    private var settingsSection: some View {
        VStack(spacing: 2) {
            Button { showLanguagePicker = true } label: {
                settingsRow(
                    icon: "globe",
                    title: loc.str(.adminLanguageLabel),
                    subtitle: loc.currentLanguage.displayName,
                    color: .blue
                )
            }
            .buttonStyle(.plain)

            Button { showAppearancePicker = true } label: {
                settingsRow(
                    icon: appearance.currentAppearance.icon,
                    title: loc.str(.adminAppearanceLabel),
                    subtitle: appearance.currentAppearance.displayName(loc.currentLanguage),
                    color: .purple
                )
            }
            .buttonStyle(.plain)

            settingsRow(
                icon: "info.circle",
                title: loc.str(.adminVersionLabel),
                subtitle: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
                color: .gray
            )
        }
        .glassCard()
    }

    private func settingsRow(icon: String, title: String, subtitle: String, color: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            Text(title)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Palette.textPrimary)

            Spacer()

            Text(subtitle)
                .font(AppTheme.Typography.subheadline)
                .foregroundColor(AppTheme.Palette.textSecondary)

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(AppTheme.Palette.textTertiary)
        }
        .padding()
    }

    // MARK: - Language Picker

    private var languagePickerSheet: some View {
        NavigationStack {
            List(AppLanguage.allCases) { lang in
                Button {
                    loc.currentLanguage = lang
                    showLanguagePicker = false
                } label: {
                    HStack {
                        Text(lang.flag)
                            .font(.title3)

                        Text(lang.displayName)
                            .foregroundColor(AppTheme.Palette.textPrimary)

                        Spacer()

                        if loc.currentLanguage == lang {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppTheme.Palette.brand)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(loc.str(.adminSelectLanguage))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(loc.str(.adminClose)) { showLanguagePicker = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Appearance Picker

    private var appearancePickerSheet: some View {
        NavigationStack {
            List(AppAppearance.allCases) { mode in
                Button {
                    appearance.currentAppearance = mode
                    showAppearancePicker = false
                } label: {
                    HStack {
                        Image(systemName: mode.icon)
                            .font(.title3)
                            .foregroundColor(.primary)
                            .frame(width: 28)

                        Text(mode.displayName(loc.currentLanguage))
                            .foregroundColor(AppTheme.Palette.textPrimary)

                        Spacer()

                        if appearance.currentAppearance == mode {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppTheme.Palette.brand)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(loc.str(.adminSelectAppearance))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(loc.str(.adminClose)) { showAppearancePicker = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Logout

    private var logoutButton: some View {
        Button {
            showLogoutConfirm = true
        } label: {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text(loc.str(.adminSignOutTitle))
            }
            .font(AppTheme.Typography.body)
            .fontWeight(.semibold)
            .foregroundColor(AppTheme.Palette.danger)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(AppTheme.Palette.dangerSoft)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
        }
        .pressStyle()
        .padding(.top, 4)
    }
}
