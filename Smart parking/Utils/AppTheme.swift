//
//  AppTheme.swift
//  Smart parking
//
//  Shared design tokens and reusable modifiers.
//  Racing Red + Carbon glassmorphism design system.
//  Supports both Light and Dark mode via adaptive colors.
//

import SwiftUI

#if canImport(UIKit)
    import UIKit
#endif

// MARK: - Adaptive Color Helper

extension Color {
    /// Create an adaptive color that switches between light and dark mode.
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

    /// Adaptive color from raw Color values.
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

// MARK: - Color Themes

enum AppColorTheme: String, CaseIterable, Identifiable {
    case carbon = "carbon"
    case ocean = "ocean"
    case forest = "forest"
    case sunset = "sunset"

    var id: String { rawValue }

    var brand: Color {
        switch self {
        case .carbon: Color(lightHex: "#111827", darkHex: "#F9FAFB")
        case .ocean:  Color(lightHex: "#0C4A6E", darkHex: "#BAE6FD")
        case .forest: Color(lightHex: "#14532D", darkHex: "#BBF7D0")
        case .sunset: Color(lightHex: "#7C2D12", darkHex: "#FED7AA")
        }
    }
    var brandLight: Color {
        switch self {
        case .carbon: Color(lightHex: "#374151", darkHex: "#D1D5DB")
        case .ocean:  Color(lightHex: "#0369A1", darkHex: "#7DD3FC")
        case .forest: Color(lightHex: "#166534", darkHex: "#86EFAC")
        case .sunset: Color(lightHex: "#9A3412", darkHex: "#FDBA74")
        }
    }
    var brandDark: Color {
        switch self {
        case .carbon: Color(lightHex: "#030712", darkHex: "#E5E7EB")
        case .ocean:  Color(lightHex: "#082F49", darkHex: "#E0F2FE")
        case .forest: Color(lightHex: "#052E16", darkHex: "#DCFCE7")
        case .sunset: Color(lightHex: "#431407", darkHex: "#FFEDD5")
        }
    }
    var brandSoft: Color {
        switch self {
        case .carbon: Color(lightHex: "#F3F4F6", darkHex: "#1F2937")
        case .ocean:  Color(lightHex: "#E0F2FE", darkHex: "#082F49")
        case .forest: Color(lightHex: "#DCFCE7", darkHex: "#052E16")
        case .sunset: Color(lightHex: "#FFEDD5", darkHex: "#431407")
        }
    }
    var accent: Color {
        switch self {
        case .carbon: Color(lightHex: "#DC2626", darkHex: "#EF4444")
        case .ocean:  Color(lightHex: "#2563EB", darkHex: "#60A5FA")
        case .forest: Color(lightHex: "#16A34A", darkHex: "#4ADE80")
        case .sunset: Color(lightHex: "#EA580C", darkHex: "#FB923C")
        }
    }
    var accentSoft: Color {
        switch self {
        case .carbon: Color(lightHex: "#FEE2E2", darkHex: "#450A0A")
        case .ocean:  Color(lightHex: "#DBEAFE", darkHex: "#1E3A5F")
        case .forest: Color(lightHex: "#DCFCE7", darkHex: "#052E16")
        case .sunset: Color(lightHex: "#FFEDD5", darkHex: "#431407")
        }
    }
    var previewColor: Color {
        switch self {
        case .carbon: Color(hex: "#111827")
        case .ocean:  Color(hex: "#0C4A6E")
        case .forest: Color(hex: "#14532D")
        case .sunset: Color(hex: "#EA580C")
        }
    }
}

enum AppTheme {

    // MARK: - Colors (Adaptive) — Dynamic Theme + Fixed Tokens
    enum Palette {
        // Brand — theme-driven dynamic tokens
        static var brand: Color    { AppearanceManager.shared.currentColorTheme.brand }
        static var brandDark: Color { AppearanceManager.shared.currentColorTheme.brandDark }
        static var brandLight: Color { AppearanceManager.shared.currentColorTheme.brandLight }
        static var brandSoft: Color { AppearanceManager.shared.currentColorTheme.brandSoft }

        // Accent — theme-driven
        static var accent: Color    { AppearanceManager.shared.currentColorTheme.accent }
        static var accentSoft: Color { AppearanceManager.shared.currentColorTheme.accentSoft }

        // Surfaces
        static let surface = Color(lightHex: "#FFFFFF", darkHex: "#171717")
        static let surfaceSecondary = Color(lightHex: "#F5F5F4", darkHex: "#262626")
        static let surfaceGlass = Color(
            light: .white.opacity(0.72),
            dark: Color(hex: "#1C1C1E").opacity(0.65)
        )
        static let pageBackground = Color(lightHex: "#FAFAF9", darkHex: "#0A0A0A")

        // Border
        static let border = Color(
            light: Color(hex: "#111827").opacity(0.10),
            dark: .white.opacity(0.10)
        )
        static let borderGlass = Color(
            light: .white.opacity(0.6),
            dark: .white.opacity(0.12)
        )

        // Text
        static let textPrimary = Color(lightHex: "#111827", darkHex: "#F9FAFB")
        static let textSecondary = Color(lightHex: "#525252", darkHex: "#A3A3A3")
        static let textTertiary = Color(lightHex: "#A3A3A3", darkHex: "#737373")

        // Semantic
        static let success = Color(lightHex: "#059669", darkHex: "#10B981")
        static let successSoft = Color(lightHex: "#D1FAE5", darkHex: "#064E3B")
        static let warning = Color(lightHex: "#EAB308", darkHex: "#FACC15")
        static let warningSoft = Color(lightHex: "#FEF9C3", darkHex: "#422006")
        static let danger = Color(lightHex: "#B91C1C", darkHex: "#DC2626")
        static let dangerSoft = Color(lightHex: "#FEE2E2", darkHex: "#450A0A")

        // Section accents — har tab alohida identifikatsiya
        static let homeAccent = Color(lightHex: "#F97316", darkHex: "#FB923C")
        static let homeAccentSoft = Color(lightHex: "#FFEDD5", darkHex: "#431407")
        static let bookingAccent = Color(lightHex: "#10B981", darkHex: "#34D399")
        static let bookingAccentSoft = Color(lightHex: "#D1FAE5", darkHex: "#064E3B")
        static let profileAccent = Color(lightHex: "#6366F1", darkHex: "#818CF8")
        static let profileAccentSoft = Color(lightHex: "#EEF2FF", darkHex: "#1E1B4B")
        static let adminAccent = Color(lightHex: "#374151", darkHex: "#9CA3AF")
        static let adminAccentSoft = Color(lightHex: "#F3F4F6", darkHex: "#1F2937")
        static let walletAccent = Color(lightHex: "#EAB308", darkHex: "#FACC15")
        static let walletAccentSoft = Color(lightHex: "#FEF9C3", darkHex: "#422006")
        static let favoriteAccent = Color(lightHex: "#E11D48", darkHex: "#FB7185")
        static let favoriteAccentSoft = Color(lightHex: "#FFE4E6", darkHex: "#4C0519")
    }

    // MARK: - Typography
    enum Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let title = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 17, weight: .regular, design: .rounded)
        static let callout = Font.system(size: 16, weight: .regular, design: .rounded)
        static let subheadline = Font.system(size: 15, weight: .regular, design: .rounded)
        static let footnote = Font.system(size: 13, weight: .regular, design: .rounded)
        static let caption = Font.system(size: 12, weight: .regular, design: .rounded)
        static let captionBold = Font.system(size: 12, weight: .semibold, design: .rounded)
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
        static func small(_ color: Color = Color.black.opacity(0.08)) -> (
            color: Color, radius: CGFloat, x: CGFloat, y: CGFloat
        ) {
            (color, 6, 0, 3)
        }
        static func medium(_ color: Color = Color.black.opacity(0.12)) -> (
            color: Color, radius: CGFloat, x: CGFloat, y: CGFloat
        ) {
            (color, 14, 0, 6)
        }
        static func large(_ color: Color = Color.black.opacity(0.18)) -> (
            color: Color, radius: CGFloat, x: CGFloat, y: CGFloat
        ) {
            (color, 24, 0, 10)
        }
        static func glow(_ color: Color = Color(hex: "#DC2626").opacity(0.35)) -> (
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
        static let quick = Animation.easeOut(duration: 0.15)
        static let morph = Animation.spring(response: 0.55, dampingFraction: 0.82)
    }

    // MARK: - Gradient
    enum Gradient {
        static var brand: LinearGradient {
            LinearGradient(
                colors: [Palette.brand, Palette.brandLight],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        static var brandDeep: LinearGradient {
            LinearGradient(
                colors: [Palette.brandDark, Palette.brand, Palette.brandLight],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        static var brandAccent: LinearGradient {
            LinearGradient(
                colors: [Palette.brand, Palette.accent],
                startPoint: .leading,
                endPoint: .trailing
            )
        }

        static var imageOverlay: LinearGradient {
            LinearGradient(
                colors: [.clear, .clear, Color.black.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
        }

        static var cardOverlay: LinearGradient {
            LinearGradient(
                colors: [.clear, Color.black.opacity(0.45)],
                startPoint: .center,
                endPoint: .bottom
            )
        }

        static var aurora: LinearGradient {
            LinearGradient(
                colors: [
                    Palette.brand.opacity(0.15),
                    Palette.brandLight.opacity(0.08),
                    Palette.accent.opacity(0.06),
                    Palette.pageBackground,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        static var mesh: LinearGradient {
            LinearGradient(
                colors: [
                    Palette.accent.opacity(0.20),
                    Palette.brand.opacity(0.12),
                    Palette.brandLight.opacity(0.08),
                    Palette.pageBackground,
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }

        static var glassBorder: LinearGradient {
            LinearGradient(
                colors: [
                    .white.opacity(0.3),
                    .white.opacity(0.05),
                    .white.opacity(0.15),
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

// MARK: - Glass Card Modifier (Glassmorphism)

struct GlassCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    var cornerRadius: CGFloat = AppTheme.Radius.large

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(AppTheme.Palette.surfaceGlass)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(colorScheme == .dark ? 0.15 : 0.5),
                                .white.opacity(colorScheme == .dark ? 0.03 : 0.1),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.30 : 0.08),
                radius: 16,
                x: 0,
                y: 6
            )
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
                color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.06),
                radius: colorScheme == .dark ? 8 : 14,
                x: 0,
                y: colorScheme == .dark ? 3 : 5
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

// MARK: - Gradient Overlay Modifier (for card images)

struct ImageGradientOverlay: ViewModifier {
    func body(content: Content) -> some View {
        content.overlay(AppTheme.Gradient.imageOverlay)
    }
}

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

// MARK: - Animated Background (Premium Aurora Mesh)

struct AppAnimatedBackground: View {
    @State private var animate = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            AppTheme.Palette.pageBackground

            // Top-left indigo orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            AppTheme.Palette.brand.opacity(colorScheme == .dark ? 0.25 : 0.15),
                            AppTheme.Palette.brand.opacity(0),
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 160
                    )
                )
                .frame(width: 320, height: 320)
                .offset(x: animate ? -80 : -120, y: animate ? -60 : -100)
                .animation(
                    .easeInOut(duration: 8).repeatForever(autoreverses: true),
                    value: animate
                )

            // Bottom-right teal orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            AppTheme.Palette.accent.opacity(colorScheme == .dark ? 0.18 : 0.10),
                            AppTheme.Palette.accent.opacity(0),
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 140
                    )
                )
                .frame(width: 280, height: 280)
                .offset(x: animate ? 100 : 70, y: animate ? 120 : 80)
                .animation(
                    .easeInOut(duration: 10).repeatForever(autoreverses: true),
                    value: animate
                )

            // Center subtle purple glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            AppTheme.Palette.brandLight.opacity(colorScheme == .dark ? 0.08 : 0.05),
                            .clear,
                        ],
                        center: .center,
                        startRadius: 30,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .offset(x: animate ? 20 : -20, y: animate ? -30 : 30)
                .animation(
                    .easeInOut(duration: 12).repeatForever(autoreverses: true),
                    value: animate
                )
        }
        .ignoresSafeArea()
        .onAppear { animate = true }
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
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
            .shadow(
                color: AppTheme.Palette.brand.opacity(configuration.isPressed ? 0.15 : 0.3),
                radius: configuration.isPressed ? 4 : 12,
                y: configuration.isPressed ? 2 : 6
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(AppTheme.Anim.quick, value: configuration.isPressed)
    }
}

// MARK: - View Extensions

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
        shadow(color: AppTheme.Palette.brand.opacity(0.3), radius: 16, y: 6)
    }
}
