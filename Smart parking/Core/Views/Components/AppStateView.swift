//
//  AppStateView.swift
//  Smart parking
//
//  Unified loading/error/empty views with animations.
//

import SwiftUI

struct AppStateView: View {
    enum Kind {
        case loading(title: String)
        case empty(icon: String, title: String, subtitle: String)
        case error(title: String, subtitle: String, actionTitle: String, action: () -> Void)
    }

    let kind: Kind

    @State private var isVisible = false
    @State private var iconBounce = false

    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            switch kind {
            case .loading(let title):
                ProgressView()
                    .scaleEffect(iconBounce ? 1.1 : 1.0)
                    .animation(
                        .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                        value: iconBounce
                    )
                Text(title)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(AppTheme.Palette.textSecondary)

            case .empty(let icon, let title, let subtitle):
                Image(systemName: icon)
                    .font(.system(size: 56))
                    .foregroundColor(AppTheme.Palette.textTertiary)
                    .symbolEffect(.bounce, value: iconBounce)
                    .scaleEffect(isVisible ? 1.0 : 0.5)
                    .opacity(isVisible ? 1.0 : 0)

                Text(title)
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Palette.textPrimary)

                Text(subtitle)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(AppTheme.Palette.textSecondary)
                    .multilineTextAlignment(.center)

            case .error(let title, let subtitle, let actionTitle, let action):
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 46))
                    .foregroundColor(AppTheme.Palette.warning)
                    .scaleEffect(isVisible ? 1.0 : 0.5)
                    .opacity(isVisible ? 1.0 : 0)

                Text(title)
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Palette.textPrimary)

                Text(subtitle)
                    .font(AppTheme.Typography.subheadline)
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
        .offset(y: isVisible ? 0 : 12)
        .opacity(isVisible ? 1.0 : 0)
        .onAppear {
            withAnimation(AppTheme.Anim.spring) {
                isVisible = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                iconBounce = true
            }
        }
    }
}
