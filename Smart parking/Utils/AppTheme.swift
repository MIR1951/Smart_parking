//
//  AppTheme.swift
//  Smart parking
//
//  Shared design tokens and reusable modifiers.
//

import SwiftUI

enum AppTheme {
    enum Palette {
        static let brand = Color(hex: "#2F6BFF")
        static let brandSoft = Color(hex: "#EAF0FF")
        static let surface = Color.white
        static let pageBackground = Color(hex: "#F5F7FB")
        static let border = Color.black.opacity(0.08)
        static let textPrimary = Color(hex: "#111827")
        static let textSecondary = Color(hex: "#6B7280")
        static let success = Color(hex: "#16A34A")
        static let warning = Color(hex: "#D97706")
        static let danger = Color(hex: "#DC2626")
    }

    enum Radius {
        static let small: CGFloat = 10
        static let medium: CGFloat = 14
        static let large: CGFloat = 18
        static let pill: CGFloat = 999
    }

    enum Spacing {
        static let xSmall: CGFloat = 6
        static let small: CGFloat = 10
        static let medium: CGFloat = 14
        static let large: CGFloat = 18
        static let xLarge: CGFloat = 24
    }
}

struct AppCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppTheme.Palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                    .stroke(AppTheme.Palette.border, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
    }
}

extension View {
    func appCard() -> some View {
        modifier(AppCardModifier())
    }
}
