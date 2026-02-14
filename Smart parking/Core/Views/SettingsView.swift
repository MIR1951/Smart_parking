//
//  SettingsView.swift
//  Smart parking
//
//  Created by Smart Parking on 12/02/26.
//

import SwiftUI

struct SettingsView: View {
    @Environment(LocalizationManager.self) private var loc
    @Environment(AppearanceManager.self) private var appearance

    var body: some View {
        let lang = loc.currentLanguage

        List {
            // MARK: - Language Section
            Section {
                ForEach(AppLanguage.allCases) { language in
                    Button {
                        withAnimation(AppTheme.Anim.smooth) {
                            loc.currentLanguage = language
                        }
                        AppTheme.Haptic.light()
                    } label: {
                        HStack(spacing: 14) {
                            Text(language.flag)
                                .font(.title2)

                            Text(language.displayName)
                                .font(AppTheme.Typography.body)
                                .foregroundColor(AppTheme.Palette.textPrimary)

                            Spacer()

                            if loc.currentLanguage == language {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(AppTheme.Palette.brand)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Label(loc.str(.settingsLanguage), systemImage: "globe")
                    .font(AppTheme.Typography.captionBold)
                    .foregroundColor(AppTheme.Palette.textSecondary)
                    .textCase(nil)
            }

            // MARK: - Appearance Section
            Section {
                ForEach(AppAppearance.allCases) { mode in
                    Button {
                        withAnimation(AppTheme.Anim.smooth) {
                            appearance.currentAppearance = mode
                        }
                        AppTheme.Haptic.light()
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: mode.icon)
                                .font(.title3)
                                .foregroundColor(iconColor(for: mode))
                                .frame(width: 28)

                            Text(mode.displayName(lang))
                                .font(AppTheme.Typography.body)
                                .foregroundColor(AppTheme.Palette.textPrimary)

                            Spacer()

                            if appearance.currentAppearance == mode {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(AppTheme.Palette.brand)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Label(loc.str(.settingsAppearance), systemImage: "paintbrush")
                    .font(AppTheme.Typography.captionBold)
                    .foregroundColor(AppTheme.Palette.textSecondary)
                    .textCase(nil)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppTheme.Palette.pageBackground.ignoresSafeArea())
        .navigationTitle(loc.str(.settingsTitle))
        .navigationBarTitleDisplayMode(.large)
    }

    private func iconColor(for mode: AppAppearance) -> Color {
        switch mode {
        case .system: return AppTheme.Palette.brand
        case .light: return .orange
        case .dark: return .indigo
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environment(LocalizationManager.shared)
            .environment(AppearanceManager.shared)
    }
}
