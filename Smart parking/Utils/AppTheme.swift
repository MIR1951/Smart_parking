//
//  AppTheme.swift
//  Smart parking
//
//  Shared design tokens and reusable modifiers.
//  Supports both Light and Dark mode via adaptive colors.
//

import SwiftUI

#if canImport(UIKit)
    import UIKit
#endif

// MARK: - Adaptive Color Helper

extension Color {
    /// Create an adaptive color that switches between light and dark mode.
    fileprivate init(lightHex: String, darkHex: String) {
        #if canImport(UIKit)
            self.init(
                uiColor: UIColor { traits in
                    traits.userInterfaceStyle == .dark
                        ? UIColor(Color(hex: darkHex))
                        : UIColor(Color(hex: lightHex))
                })
        #else
            self.init(hex: lightHex)
        #endif
    }

    /// Adaptive color from raw Color values.
    fileprivate init(light: Color, dark: Color) {
        #if canImport(UIKit)
            self.init(
                uiColor: UIColor { traits in
                    traits.userInterfaceStyle == .dark
                        ? UIColor(dark)
                        : UIColor(light)
                })
        #else
            self = light
        #endif
    }
}

enum AppTheme {

    // MARK: - Colors (Adaptive)
    enum Palette {
        // Brand
        static let brand = Color(hex: "#2F6BFF")
        static let brandDark = Color(hex: "#1A4FE0")
        static let brandSoft = Color(lightHex: "#EAF0FF", darkHex: "#1A2744")

        // Surfaces
        static let surface = Color(lightHex: "#FFFFFF", darkHex: "#1C1C1E")
        static let surfaceSecondary = Color(lightHex: "#F9FAFB", darkHex: "#2C2C2E")
        static let pageBackground = Color(lightHex: "#F5F7FB", darkHex: "#000000")

        // Border
        static let border = Color(
            light: .black.opacity(0.08),
            dark: .white.opacity(0.12)
        )

        // Text
        static let textPrimary = Color(lightHex: "#111827", darkHex: "#F9FAFB")
        static let textSecondary = Color(lightHex: "#6B7280", darkHex: "#9CA3AF")
        static let textTertiary = Color(lightHex: "#9CA3AF", darkHex: "#6B7280")

        // Semantic
        static let success = Color(hex: "#16A34A")
        static let successSoft = Color(lightHex: "#DCFCE7", darkHex: "#052E16")
        static let warning = Color(hex: "#D97706")
        static let warningSoft = Color(lightHex: "#FEF3C7", darkHex: "#451A03")
        static let danger = Color(hex: "#DC2626")
        static let dangerSoft = Color(lightHex: "#FEE2E2", darkHex: "#450A0A")
    }

    // MARK: - Typography
    enum Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let title = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 17, weight: .semibold)
        static let body = Font.system(size: 17, weight: .regular)
        static let callout = Font.system(size: 16, weight: .regular)
        static let subheadline = Font.system(size: 15, weight: .regular)
        static let footnote = Font.system(size: 13, weight: .regular)
        static let caption = Font.system(size: 12, weight: .regular)
        static let captionBold = Font.system(size: 12, weight: .semibold)
    }

    // MARK: - Radius
    enum Radius {
        static let xSmall: CGFloat = 6
        static let small: CGFloat = 10
        static let medium: CGFloat = 14
        static let large: CGFloat = 18
        static let xLarge: CGFloat = 24
        static let pill: CGFloat = 999
    }

    // MARK: - Spacing
    enum Spacing {
        static let xSmall: CGFloat = 6
        static let small: CGFloat = 10
        static let medium: CGFloat = 14
        static let large: CGFloat = 18
        static let xLarge: CGFloat = 24
        static let xxLarge: CGFloat = 32
    }

    // MARK: - Shadow
    enum Shadow {
        static func small(_ color: Color = .black.opacity(0.04)) -> (
            color: Color, radius: CGFloat, x: CGFloat, y: CGFloat
        ) {
            (color, 4, 0, 2)
        }
        static func medium(_ color: Color = .black.opacity(0.06)) -> (
            color: Color, radius: CGFloat, x: CGFloat, y: CGFloat
        ) {
            (color, 10, 0, 4)
        }
        static func large(_ color: Color = .black.opacity(0.10)) -> (
            color: Color, radius: CGFloat, x: CGFloat, y: CGFloat
        ) {
            (color, 20, 0, 8)
        }
    }

    // MARK: - Animation
    enum Anim {
        static let spring = Animation.spring(response: 0.4, dampingFraction: 0.75)
        static let snappy = Animation.spring(response: 0.3, dampingFraction: 0.8)
        static let smooth = Animation.easeOut(duration: 0.3)
        static let gentle = Animation.easeInOut(duration: 0.5)
        static let quick = Animation.easeOut(duration: 0.15)
    }

    // MARK: - Gradient
    enum Gradient {
        static var brand: LinearGradient {
            LinearGradient(
                colors: [Palette.brand, Palette.brandDark],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        static var imageOverlay: LinearGradient {
            LinearGradient(
                colors: [.clear, .clear, .black.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )
        }

        static var cardOverlay: LinearGradient {
            LinearGradient(
                colors: [.clear, .black.opacity(0.35)],
                startPoint: .center,
                endPoint: .bottom
            )
        }
    }

    // MARK: - Haptics
    enum Haptic {
        #if canImport(UIKit)
            static func light() {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            static func medium() {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
            static func heavy() {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            }
            static func success() {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
            static func error() {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
            static func selection() {
                UISelectionFeedbackGenerator().selectionChanged()
            }
        #endif
    }
}

// MARK: - App Card Modifier (Adaptive)

struct AppCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(AppTheme.Palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                    .stroke(AppTheme.Palette.border, lineWidth: 1)
            )
            .shadow(
                color: colorScheme == .dark
                    ? Color.black.opacity(0.25)
                    : Color.black.opacity(0.04),
                radius: colorScheme == .dark ? 6 : 10,
                x: 0,
                y: colorScheme == .dark ? 2 : 4
            )
    }
}

// MARK: - Press Scale Button Style

struct PressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(AppTheme.Anim.quick, value: configuration.isPressed)
    }
}

// MARK: - Shadow Modifier

struct AppShadowModifier: ViewModifier {
    let shadow: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat)
    func body(content: Content) -> some View {
        content.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}

// MARK: - Gradient Overlay Modifier (for card images)

struct ImageGradientOverlay: ViewModifier {
    func body(content: Content) -> some View {
        content.overlay(AppTheme.Gradient.imageOverlay)
    }
}

// MARK: - View Extensions

extension View {
    func appCard() -> some View {
        modifier(AppCardModifier())
    }

    func pressStyle() -> some View {
        buttonStyle(PressButtonStyle())
    }

    func appShadow(_ preset: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat)) -> some View {
        modifier(AppShadowModifier(shadow: preset))
    }

    func imageGradient() -> some View {
        modifier(ImageGradientOverlay())
    }
}
