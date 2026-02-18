//
//  AppButton.swift
//  Smart parking
//
//  Shared button styles.
//

import SwiftUI

struct AppPrimaryButton: View {
    let title: String
    var isLoading = false
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.small) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(
                Group {
                    if isEnabled {
                        AppTheme.Gradient.brand
                    } else {
                        AppTheme.Palette.brand.opacity(0.45)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.pill, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.pill, style: .continuous)
                    .stroke(Color.white.opacity(0.16), lineWidth: 1)
            )
            .shadow(color: AppTheme.Palette.brand.opacity(0.28), radius: 12, x: 0, y: 8)
        }
        .disabled(!isEnabled || isLoading)
        .pressStyle()
    }
}

struct AppGhostButton: View {
    let title: String
    var tint: Color = AppTheme.Palette.brand
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .fontWeight(.semibold)
                .foregroundColor(tint)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(tint.opacity(0.11))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.pill, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.pill, style: .continuous)
                        .stroke(tint.opacity(0.22), lineWidth: 1)
                )
        }
        .pressStyle()
    }
}
