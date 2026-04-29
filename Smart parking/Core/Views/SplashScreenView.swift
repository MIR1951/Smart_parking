//
//  SplashScreenView.swift
//  Smart parking
//
//  Kreativ launch screen: mashina parking joyga kirib to'xtaydi.
//

import SwiftUI

struct SplashScreenView: View {
    private let loc = LocalizationManager.shared

    // Stage progression
    @State private var carProgress: CGFloat = 0       // 0 → 1: left edge → parking spot
    @State private var carVisible = false
    @State private var wheelRotation: Double = 0
    @State private var headlightIntensity: Double = 0
    @State private var parkingSpotReveal: CGFloat = 0 // 0 → 1: lines draw in
    @State private var pBadgeScale: CGFloat = 0
    @State private var pBadgeRotation: Double = -90
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 20
    @State private var taglineOpacity: Double = 0
    @State private var radarPulse: CGFloat = 0
    @State private var radarOpacity: Double = 0
    @State private var roadOffset: CGFloat = 0
    @State private var backgroundGlow: Double = 0

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let roadY = height * 0.58
            let carSize: CGFloat = 90
            let spotX = width * 0.78
            let startX = -carSize
            let carX = startX + (spotX - startX) * carProgress

            ZStack {
                backgroundLayer
                ambientGlow(height: height)
                roadLayer(width: width, y: roadY)
                parkingSpot(x: spotX, y: roadY)
                carView(at: CGPoint(x: carX, y: roadY - 18), size: carSize)
                textContent(height: height)
            }
            .frame(width: width, height: height)
            .ignoresSafeArea()
            .onAppear { runAnimation() }
        }
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        LinearGradient(
            colors: [
                Color(hex: "#1A1240"),
                Color(hex: "#2D1B69"),
                Color(hex: "#1A1240"),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func ambientGlow(height: CGFloat) -> some View {
        RadialGradient(
            colors: [
                Color(hex: "#7C5CFF").opacity(0.35 * backgroundGlow),
                Color.clear,
            ],
            center: .center,
            startRadius: 40,
            endRadius: 380
        )
        .offset(y: height * -0.1)
        .blur(radius: 24)
    }

    // MARK: - Road with moving lane stripes

    private func roadLayer(width: CGFloat, y: CGFloat) -> some View {
        ZStack {
            // Road surface
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.black.opacity(0.55), Color.black.opacity(0.15)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: width, height: 90)
                .offset(y: y - 45 + 90)

            // Lane stripes scrolling right-to-left (parallax motion)
            HStack(spacing: 28) {
                ForEach(0..<12, id: \.self) { _ in
                    Capsule()
                        .fill(Color.white.opacity(0.55))
                        .frame(width: 36, height: 4)
                }
            }
            .offset(x: roadOffset, y: y + 46)
            .mask(
                Rectangle().frame(width: width, height: 8).offset(y: y + 46)
            )
        }
    }

    // MARK: - Parking spot (P badge + lines)

    private func parkingSpot(x: CGFloat, y: CGFloat) -> some View {
        ZStack {
            // Parking outline lines drawing in
            ParkingSpotShape()
                .trim(from: 0, to: parkingSpotReveal)
                .stroke(
                    Color(hex: "#7C5CFF").opacity(0.85),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                )
                .frame(width: 110, height: 120)
                .offset(x: x, y: y - 22)
                .shadow(color: Color(hex: "#7C5CFF").opacity(0.6), radius: 12)

            // Radar pulse ring when car arrives
            Circle()
                .stroke(Color(hex: "#9B82FF").opacity(radarOpacity), lineWidth: 2)
                .frame(width: 160, height: 160)
                .scaleEffect(radarPulse)
                .offset(x: x, y: y - 18)

            // P badge
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#9B82FF"), Color(hex: "#6246EA")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                    .shadow(color: Color(hex: "#7C5CFF").opacity(0.6), radius: 16, y: 4)

                Text("P")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
            }
            .scaleEffect(pBadgeScale)
            .rotationEffect(.degrees(pBadgeRotation))
            .offset(x: x, y: y - 88)
        }
    }

    // MARK: - Car

    private func carView(at point: CGPoint, size: CGFloat, _ opacity: Double = 1) -> some View {
        ZStack {
            // Headlight cone
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.55 * headlightIntensity),
                            Color.clear,
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 120, height: 40)
                .offset(x: size * 0.65, y: 2)
                .blur(radius: 8)

            // Car body
            CarShape()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#A78BFA"), Color(hex: "#7C5CFF")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size, height: size * 0.55)
                .shadow(color: Color.black.opacity(0.5), radius: 6, y: 4)
                .overlay(
                    // Window tint
                    CarWindowShape()
                        .fill(Color(hex: "#1A1240").opacity(0.55))
                        .frame(width: size, height: size * 0.55)
                )

            // Wheels
            HStack(spacing: size * 0.42) {
                wheel(diameter: size * 0.22)
                wheel(diameter: size * 0.22)
            }
            .offset(y: size * 0.25)
        }
        .position(point)
        .opacity(carVisible ? opacity : 0)
    }

    private func wheel(diameter: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(Color.black)
            Circle()
                .stroke(Color(hex: "#3B2E5C"), lineWidth: 2)
                .padding(3)
            // Spokes
            ForEach(0..<4, id: \.self) { i in
                Capsule()
                    .fill(Color(hex: "#9B82FF").opacity(0.8))
                    .frame(width: 2, height: diameter * 0.5)
                    .rotationEffect(.degrees(Double(i) * 45))
            }
        }
        .frame(width: diameter, height: diameter)
        .rotationEffect(.degrees(wheelRotation))
    }

    // MARK: - Text

    private func textContent(height: CGFloat) -> some View {
        VStack(spacing: 12) {
            Spacer()

            VStack(spacing: 8) {
                Text("Smart Parking")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color(hex: "#BBA9FF")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(y: titleOffset)
                    .opacity(titleOpacity)

                Text(loc.str(.splashTagline))
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .tracking(3)
                    .textCase(.uppercase)
                    .opacity(taglineOpacity)
            }
            .padding(.bottom, height * 0.12)
        }
    }

    // MARK: - Animation choreography

    private func runAnimation() {
        // Ambient glow on
        withAnimation(.easeOut(duration: 1.0)) {
            backgroundGlow = 1.0
        }

        // Stage 1 (0.0–0.15s): Parking spot lines draw in
        withAnimation(.easeOut(duration: 0.9).delay(0.15)) {
            parkingSpotReveal = 1.0
        }

        // Stage 2 (0.3s): Car appears
        withAnimation(.easeIn(duration: 0.2).delay(0.3)) {
            carVisible = true
            headlightIntensity = 1.0
        }

        // Lane stripes & wheels spin while car moves
        withAnimation(.linear(duration: 1.6).delay(0.3)) {
            roadOffset = -280
        }
        withAnimation(.linear(duration: 1.6).delay(0.3)) {
            wheelRotation = 720
        }

        // Stage 3 (0.3–1.9s): Car drives to parking spot
        withAnimation(.timingCurve(0.25, 0.1, 0.2, 1.0, duration: 1.6).delay(0.3)) {
            carProgress = 1.0
        }

        // Stage 4 (1.9s): Car parked — radar pulse + P badge pops in
        withAnimation(.easeOut(duration: 0.5).delay(1.9)) {
            radarPulse = 1.8
            radarOpacity = 0.9
        }
        withAnimation(.easeOut(duration: 0.4).delay(2.2)) {
            radarOpacity = 0
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.55).delay(2.0)) {
            pBadgeScale = 1.0
            pBadgeRotation = 0
        }

        // Stage 5 (2.2s): Text
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(2.2)) {
            titleOpacity = 1.0
            titleOffset = 0
        }
        withAnimation(.easeIn(duration: 0.5).delay(2.5)) {
            taglineOpacity = 1.0
        }
    }
}

// MARK: - Shapes

private struct CarShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // Body silhouette: side view
        path.move(to: CGPoint(x: w * 0.05, y: h * 0.7))
        path.addLine(to: CGPoint(x: w * 0.05, y: h * 0.45))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.28, y: h * 0.15),
            control: CGPoint(x: w * 0.1, y: h * 0.15)
        )
        path.addLine(to: CGPoint(x: w * 0.68, y: h * 0.15))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.88, y: h * 0.45),
            control: CGPoint(x: w * 0.82, y: h * 0.2)
        )
        path.addLine(to: CGPoint(x: w * 0.95, y: h * 0.5))
        path.addLine(to: CGPoint(x: w * 0.95, y: h * 0.7))
        path.closeSubpath()

        return path
    }
}

private struct CarWindowShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: w * 0.22, y: h * 0.4))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.32, y: h * 0.22),
            control: CGPoint(x: w * 0.22, y: h * 0.22)
        )
        path.addLine(to: CGPoint(x: w * 0.64, y: h * 0.22))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.74, y: h * 0.4),
            control: CGPoint(x: w * 0.74, y: h * 0.22)
        )
        path.closeSubpath()
        return path
    }
}

private struct ParkingSpotShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // U-shaped parking slot: left side + top + right side
        path.move(to: CGPoint(x: 0, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        return path
    }
}

#Preview {
    SplashScreenView()
}
