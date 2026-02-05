//
//  AppStateView.swift
//  Smart parking
//
//  Unified loading/error/empty views.
//

import SwiftUI

struct AppStateView: View {
    enum Kind {
        case loading(title: String)
        case empty(icon: String, title: String, subtitle: String)
        case error(title: String, subtitle: String, actionTitle: String, action: () -> Void)
    }

    let kind: Kind

    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            switch kind {
            case let .loading(title):
                ProgressView()
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.Palette.textSecondary)

            case let .empty(icon, title, subtitle):
                Image(systemName: icon)
                    .font(.system(size: 56))
                    .foregroundColor(AppTheme.Palette.textSecondary.opacity(0.55))
                Text(title)
                    .font(.headline)
                    .foregroundColor(AppTheme.Palette.textPrimary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.Palette.textSecondary)
                    .multilineTextAlignment(.center)

            case let .error(title, subtitle, actionTitle, action):
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 46))
                    .foregroundColor(AppTheme.Palette.warning)
                Text(title)
                    .font(.headline)
                    .foregroundColor(AppTheme.Palette.textPrimary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.Palette.textSecondary)
                    .multilineTextAlignment(.center)

                Button(actionTitle, action: action)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, AppTheme.Spacing.large)
                    .padding(.vertical, 10)
                    .background(AppTheme.Palette.brand)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, AppTheme.Spacing.xLarge)
        .frame(maxWidth: .infinity)
    }
}
