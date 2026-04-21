//
//  AppTheme.swift
//  Smart parking
//
//  Shared design tokens and reusable modifiers.
//  Light-first purple design system. Supports Light and Dark mode.
//

import SwiftUI

#if canImport(UIKit)
    import UIKit
#endif

// MARK: - Adaptive Color Helper

extension Color {
    init(lightHex: String, darkHex: String) {
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

    init(light: Color, dark: Color) {
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

// MARK: - AppTheme

enum AppTheme {

    // MARK: - Colors (Adaptive)
    enum Palette {
        // Brand — purple
        static let brand        = Color(lightHex: "#7C5CFF", darkHex: "#9B82FF")
        static let brandDeep    = Color(lightHex: "#6246EA", darkHex: "#7C5CFF")
        static let brandLight   = Color(lightHex: "#9B82FF", darkHex: "#BBA9FF")
        static let brandSoft    = Color(lightHex: "#EDE9FE", darkHex: "#2D2455")

        // Accent (secondary purple tint, used in subtle highlights)
        static let accent       = Color(lightHex: "#7C5CFF", darkHex: "#9B82FF")
        static let accentSoft   = Color(lightHex: "#EDE9FE", darkHex: "#2D2455")

        // Surfaces
        static let surface          = Color(lightHex: "#FFFFFF", darkHex: "#17171E")
        static let surfaceSecondary = Color(lightHex: "#F5F5F7", darkHex: "#1F1F27")
        static let surfaceMuted     = Color(lightHex: "#F5F5F7", darkHex: "#1F1F27")
        static let surfaceGlass     = Color(lightHex: "#FFFFFF", darkHex: "#17171E")
        static let pageBackground   = Color(lightHex: "#FFFFFF", darkHex: "#0B0B10")

        // Border
        static let border = Color(
            light: Color(hex: "#E5E7EB"),
            dark: Color(hex: "#2A2A35")
        )
        static let borderGlass = Color(
            light: Color(hex: "#E5E7EB"),
            dark: Color(hex: "#2A2A35")
        )

        // Text
        static let textPrimary   = Color(lightHex: "#0F172A", darkHex: "#F8FAFC")
        static let textSecondary = Color(lightHex: "#6B7280", darkHex: "#9CA3AF")
        static let textTertiary  = Color(lightHex: "#9CA3AF", darkHex: "#6B7280")

        // Semantic
        static let success      = Color(lightHex: "#059669", darkHex: "#10B981")
        static let successSoft  = Color(lightHex: "#D1FAE5", darkHex: "#064E3B")
        static let warning      = Color(lightHex: "#EAB308", darkHex: "#FACC15")
        static let warningSoft  = Color(lightHex: "#FEF9C3", darkHex: "#422006")
        static let danger       = Color(lightHex: "#EF4444", darkHex: "#F87171")
        static let dangerSoft   = Color(lightHex: "#FEE2E2", darkHex: "#450A0A")

        // Rating
        static let ratingYellow = Color(lightHex: "#F5B400", darkHex: "#FBBF24")

        // Section accents — all converge to purple brand
        static let homeAccent        = brand
        static let homeAccentSoft    = brandSoft
        static let bookingAccent     = brand
        static let bookingAccentSoft = brandSoft
        static let profileAccent     = brand
        static let profileAccentSoft = brandSoft
        static let adminAccent       = brand
        static let adminAccentSoft   = brandSoft
        static let walletAccent      = Color(lightHex: "#EAB308", darkHex: "#FACC15")
        static let walletAccentSoft  = Color(lightHex: "#FEF9C3", darkHex: "#422006")
        static let favoriteAccent    = danger
        static let favoriteAccentSoft = dangerSoft
    }

    // MARK: - Typography
    enum Typography {
        static let largeTitle  = Font.system(size: 34, weight: .bold)
        static let title       = Font.system(size: 28, weight: .bold)
        static let title2      = Font.system(size: 22, weight: .semibold)
        static let title3      = Font.system(size: 20, weight: .semibold)
        static let headline    = Font.system(size: 17, weight: .semibold)
        static let body        = Font.system(size: 17, weight: .regular)
        static let callout     = Font.system(size: 16, weight: .regular)
        static let subheadline = Font.system(size: 15, weight: .regular)
        static let footnote    = Font.system(size: 13, weight: .regular)
        static let caption     = Font.system(size: 12, weight: .regular)
        static let captionBold = Font.system(size: 12, weight: .semibold)
    }

    // MARK: - Radius
    enum Radius {
        static let xSmall: CGFloat = 8
        static let small: CGFloat = 12
        static let medium: CGFloat = 16
        static let large: CGFloat = 20
        static let xLarge: CGFloat = 28
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
        static func small(_ color: Color = Color.black.opacity(0.06)) -> (
            color: Color, radius: CGFloat, x: CGFloat, y: CGFloat
        ) {
            (color, 8, 0, 3)
        }
        static func medium(_ color: Color = Color.black.opacity(0.08)) -> (
            color: Color, radius: CGFloat, x: CGFloat, y: CGFloat
        ) {
            (color, 16, 0, 6)
        }
        static func large(_ color: Color = Color.black.opacity(0.12)) -> (
            color: Color, radius: CGFloat, x: CGFloat, y: CGFloat
        ) {
            (color, 24, 0, 10)
        }
        static func cardSoft(_ colorScheme: ColorScheme = .light) -> (
            color: Color, radius: CGFloat, x: CGFloat, y: CGFloat
        ) {
            colorScheme == .dark
                ? (Color.black.opacity(0.40), 16, 0, 6)
                : (Color.black.opacity(0.06), 20, 0, 8)
        }
        static func glow(_ color: Color = Color(hex: "#7C5CFF").opacity(0.30)) -> (
            color: Color, radius: CGFloat, x: CGFloat, y: CGFloat
        ) {
            (color, 20, 0, 0)
        }
    }

    // MARK: - Animation
    enum Anim {
        static let spring = Animation.spring(response: 0.45, dampingFraction: 0.72)
        static let snappy = Animation.spring(response: 0.3, dampingFraction: 0.78)
        static let bouncy = Animation.spring(response: 0.35, dampingFraction: 0.65)
        static let smooth = Animation.easeOut(duration: 0.3)
        static let gentle = Animation.easeInOut(duration: 0.5)
        static let quick  = Animation.easeOut(duration: 0.15)
        static let morph  = Animation.spring(response: 0.55, dampingFraction: 0.82)
    }

    // MARK: - Gradient
    enum Gradient {
        static var brand: LinearGradient {
            LinearGradient(
                colors: [Palette.brand, Palette.brandDeep],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        static var brandDeep: LinearGradient {
            LinearGradient(
                colors: [Palette.brandDeep, Palette.brand, Palette.brandLight],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        static var brandAccent: LinearGradient {
            LinearGradient(
                colors: [Palette.brand, Palette.brandLight],
                startPoint: .leading,
                endPoint: .trailing
            )
        }

        static var imageOverlay: LinearGradient {
            LinearGradient(
                colors: [.clear, .clear, Color.black.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )
        }

        static var cardOverlay: LinearGradient {
            LinearGradient(
                colors: [.clear, Color.black.opacity(0.35)],
                startPoint: .center,
                endPoint: .bottom
            )
        }

        static var aurora: LinearGradient {
            LinearGradient(
                colors: [
                    Palette.brand.opacity(0.08),
                    Palette.brandLight.opacity(0.04),
                    Palette.pageBackground,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        static var mesh: LinearGradient {
            LinearGradient(
                colors: [
                    Palette.brand.opacity(0.10),
                    Palette.brandLight.opacity(0.05),
                    Palette.pageBackground,
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }

        static var glassBorder: LinearGradient {
            LinearGradient(
                colors: [
                    Palette.border,
                    Palette.border.opacity(0.5),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
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

// MARK: - App Card Modifier (Solid soft-shadow card)

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
                    ? Color.black.opacity(0.40)
                    : Color.black.opacity(0.06),
                radius: colorScheme == .dark ? 12 : 20,
                x: 0,
                y: colorScheme == .dark ? 4 : 8
            )
    }
}

// MARK: - Glass Card Modifier — redirects to solid card (legacy compat)

struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = AppTheme.Radius.large
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(AppTheme.Palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AppTheme.Palette.border, lineWidth: 1)
            )
            .shadow(
                color: colorScheme == .dark
                    ? Color.black.opacity(0.40)
                    : Color.black.opacity(0.06),
                radius: colorScheme == .dark ? 12 : 20,
                x: 0,
                y: colorScheme == .dark ? 4 : 8
            )
    }
}

// MARK: - Press Scale Button Style

struct PressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
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

// MARK: - Gradient Overlay Modifier

struct ImageGradientOverlay: ViewModifier {
    func body(content: Content) -> some View {
        content.overlay(AppTheme.Gradient.imageOverlay)
    }
}

// MARK: - Reveal on Appear

struct RevealOnAppearModifier: ViewModifier {
    let delay: Double
    @State private var didAppear = false

    func body(content: Content) -> some View {
        content
            .opacity(didAppear ? 1 : 0)
            .offset(y: didAppear ? 0 : 20)
            .scaleEffect(didAppear ? 1 : 0.97)
            .animation(
                .spring(response: 0.5, dampingFraction: 0.82).delay(delay),
                value: didAppear
            )
            .onAppear {
                guard !didAppear else { return }
                didAppear = true
            }
    }
}

// MARK: - Animated Background (simple page bg — no orbs)

struct AppAnimatedBackground: View {
    var body: some View {
        AppTheme.Palette.pageBackground
            .ignoresSafeArea()
    }
}

// MARK: - Gradient Branded Button

struct GradientButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.Typography.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppTheme.Gradient.brand)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.pill, style: .continuous))
            .shadow(
                color: AppTheme.Palette.brand.opacity(configuration.isPressed ? 0.15 : 0.28),
                radius: configuration.isPressed ? 4 : 12,
                y: configuration.isPressed ? 2 : 6
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(AppTheme.Anim.quick, value: configuration.isPressed)
    }
}

// MARK: - Shake Modifier

struct ShakeModifier: ViewModifier {
    let trigger: Bool

    func body(content: Content) -> some View {
        content
            .keyframeAnimator(initialValue: 0.0, trigger: trigger) { view, offset in
                view.offset(x: offset)
            } keyframes: { _ in
                KeyframeTrack {
                    LinearKeyframe(0, duration: 0.04)
                    LinearKeyframe(-8, duration: 0.08)
                    LinearKeyframe(8, duration: 0.08)
                    LinearKeyframe(-6, duration: 0.08)
                    LinearKeyframe(6, duration: 0.06)
                    LinearKeyframe(-3, duration: 0.06)
                    LinearKeyframe(0, duration: 0.06)
                }
            }
    }
}

// MARK: - View Extensions

extension View {
    func shakeEffect(trigger: Bool) -> some View {
        modifier(ShakeModifier(trigger: trigger))
    }

    func appCard() -> some View {
        modifier(AppCardModifier())
    }

    func glassCard(cornerRadius: CGFloat = AppTheme.Radius.large) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }

    func pressStyle() -> some View {
        buttonStyle(PressButtonStyle())
    }

    func gradientButton() -> some View {
        buttonStyle(GradientButtonStyle())
    }

    func appShadow(_ preset: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat)) -> some View {
        modifier(AppShadowModifier(shadow: preset))
    }

    func imageGradient() -> some View {
        modifier(ImageGradientOverlay())
    }

    func appReveal(_ delay: Double = 0) -> some View {
        modifier(RevealOnAppearModifier(delay: delay))
    }

    func brandGlow() -> some View {
        shadow(color: AppTheme.Palette.brand.opacity(0.28), radius: 16, y: 6)
    }
}
