//
//  ProfileView.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 23/01/26.
//

import SwiftUI

struct ProfileView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(UserManager.self) private var userManager
    @Environment(LocalizationManager.self) private var loc
    @Environment(AppCoordinator.self) private var coordinator
    @State private var showLogoutAlert = false
    @State private var showEditProfile = false
    @State private var showPaymentMethods = false
    @State private var showInfoAlert = false
    @State private var infoMessage = ""

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xLarge) {

                // MARK: - Avatar Header
                profileHeader

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
                            icon: "wallet.pass", title: loc.str(.profileMyWallet),
                            color: AppTheme.Palette.warning
                        ) {
                            showComingSoon(loc.str(.profileComingSoon))
                        },
                    ])

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
                    ])

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
                    ])

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
                .padding(.horizontal)
                .padding(.bottom, AppTheme.Spacing.large)
            }
        }
        .background(AppTheme.Palette.pageBackground.ignoresSafeArea())
        .navigationTitle(loc.str(.profileTitle))
        .task {
            await userManager.fetchCurrentUser()
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView()
        }
        .sheet(isPresented: $showPaymentMethods) {
            PaymentMethodsSettingsView()
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

    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [AppTheme.Palette.brand, AppTheme.Palette.brandDark],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 100, height: 100)

                Circle()
                    .fill(AppTheme.Palette.brandSoft)
                    .frame(width: 90, height: 90)
                    .overlay {
                        Text(userInitial)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.Palette.brand)
                    }
            }

            Text(userManager.currentUser?.username ?? "User")
                .font(AppTheme.Typography.title2)
                .foregroundColor(AppTheme.Palette.textPrimary)

            Text(userManager.currentUser?.email ?? "")
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Palette.textSecondary)
        }
        .padding(.top, 20)
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
                        ProfileRow(icon: row.icon, title: row.title, color: row.color)
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
}

// MARK: - Profile Row Data

struct ProfileRowData {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    init(icon: String, title: String, color: Color, action: @escaping () -> Void = {}) {
        self.icon = icon
        self.title = title
        self.color = color
        self.action = action
    }
}

// MARK: - Profile Row View

struct ProfileRow: View {
    let icon: String
    let title: String
    var color: Color = AppTheme.Palette.textPrimary

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(color)
                .frame(width: 34, height: 34)
                .background(color.opacity(0.1))
                .clipShape(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.xSmall, style: .continuous))

            Text(title)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Palette.textPrimary)

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
