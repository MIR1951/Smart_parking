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
            .background(isEnabled ? AppTheme.Palette.brand : AppTheme.Palette.brand.opacity(0.45))
            .clipShape(
                RoundedRectangle(cornerRadius: AppTheme.Radius.pill, style: .continuous)
            )
        }
        .disabled(!isEnabled || isLoading)
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
                .background(tint.opacity(0.12))
                .clipShape(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.pill, style: .continuous)
                )
        }
    }
}
