//
//  AppTheme.swift
//  Smart parking
//
//  Shared design tokens and reusable modifiers.
//  Premium Sky-Blue/Teal glassmorphism design system.
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

    // MARK: - Colors (Adaptive) — Sky-Blue/Teal Palette
    enum Palette {
        // Brand — Sky Blue gradient
        static let brand = Color(hex: "#0EA5E9")
        static let brandDark = Color(hex: "#0284C7")
        static let brandLight = Color(hex: "#38BDF8")
        static let brandSoft = Color(lightHex: "#E0F2FE", darkHex: "#0C1929")

        // Accent — Teal
        static let accent = Color(hex: "#00CEC9")
        static let accentSoft = Color(lightHex: "#E0FFFE", darkHex: "#0A2928")

        // Surfaces
        static let surface = Color(lightHex: "#FFFFFF", darkHex: "#0F172A")
        static let surfaceSecondary = Color(lightHex: "#F0F9FF", darkHex: "#1E293B")
        static let surfaceGlass = Color(
            light: .white.opacity(0.72),
            dark: Color(hex: "#1E293B").opacity(0.65)
        )
        static let pageBackground = Color(lightHex: "#F8FAFC", darkHex: "#020617")

        // Border
        static let border = Color(
            light: Color(hex: "#0EA5E9").opacity(0.10),
            dark: .white.opacity(0.10)
        )
        static let borderGlass = Color(
            light: .white.opacity(0.6),
            dark: .white.opacity(0.12)
        )

        // Text
        static let textPrimary = Color(lightHex: "#0F172A", darkHex: "#F0F9FF")
        static let textSecondary = Color(lightHex: "#64748B", darkHex: "#94A3B8")
        static let textTertiary = Color(lightHex: "#9CA3AF", darkHex: "#6B7280")

        // Semantic
        static let success = Color(hex: "#00B894")
        static let successSoft = Color(lightHex: "#D5FFF5", darkHex: "#052E22")
        static let warning = Color(hex: "#FDCB6E")
        static let warningSoft = Color(lightHex: "#FFF8E1", darkHex: "#3D2E05")
        static let danger = Color(hex: "#FF7675")
        static let dangerSoft = Color(lightHex: "#FFE0E0", darkHex: "#3D0A0A")
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
        static func small(_ color: Color = Color(hex: "#0EA5E9").opacity(0.08)) -> (
            color: Color, radius: CGFloat, x: CGFloat, y: CGFloat
        ) {
            (color, 6, 0, 3)
        }
        static func medium(_ color: Color = Color(hex: "#0EA5E9").opacity(0.12)) -> (
            color: Color, radius: CGFloat, x: CGFloat, y: CGFloat
        ) {
            (color, 14, 0, 6)
        }
        static func large(_ color: Color = Color(hex: "#0EA5E9").opacity(0.18)) -> (
            color: Color, radius: CGFloat, x: CGFloat, y: CGFloat
        ) {
            (color, 24, 0, 10)
        }
        static func glow(_ color: Color = Color(hex: "#0EA5E9").opacity(0.35)) -> (
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
                colors: [Color(hex: "#0369A1"), Palette.brand, Palette.brandLight],
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
                colors: [.clear, .clear, Color(hex: "#020617").opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
        }

        static var cardOverlay: LinearGradient {
            LinearGradient(
                colors: [.clear, Color(hex: "#020617").opacity(0.45)],
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
                    Color(hex: "#0EA5E9").opacity(0.20),
                    Color(hex: "#38BDF8").opacity(0.12),
                    Color(hex: "#00CEC9").opacity(0.08),
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
                color: colorScheme == .dark
                    ? Color(hex: "#0EA5E9").opacity(0.15)
                    : Color(hex: "#0EA5E9").opacity(0.08),
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
                color: colorScheme == .dark
                    ? Color(hex: "#0EA5E9").opacity(0.18)
                    : Color(hex: "#0EA5E9").opacity(0.06),
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

extension View {
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
