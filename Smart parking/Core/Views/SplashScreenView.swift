//
//  SplashScreenView.swift
//  Smart parking
//
//  Premium animated splash screen with indigo gradient mesh
//

internal import Combine
import SwiftUI

struct SplashScreenView: View {
    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0
    @State private var titleOffset: CGFloat = 50
    @State private var titleOpacity: Double = 0
    @State private var ringRotation: Double = 0
    @State private var ringScale: CGFloat = 0.5
    @State private var ringOpacity: Double = 0
    @State private var orbAnimate = false
    @State private var dotsOpacity: Double = 0
    @State private var activeDot: Int = 0
    @State private var subtitleOpacity: Double = 0

    private let dotTimer = Timer.publish(every: 0.35, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // Deep indigo gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "#020617"),
                    Color(hex: "#0C1929"),
                    Color(hex: "#0F293E"),
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Animated floating orbs
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "#0EA5E9").opacity(0.35),
                            Color.clear,
                        ]),
                        center: .center,
                        startRadius: 10,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .offset(x: orbAnimate ? -100 : -140, y: orbAnimate ? -220 : -260)
                .animation(
                    .easeInOut(duration: 6).repeatForever(autoreverses: true),
                    value: orbAnimate
                )

            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "#00CEC9").opacity(0.20),
                            Color.clear,
                        ]),
                        center: .center,
                        startRadius: 10,
                        endRadius: 180
                    )
                )
                .frame(width: 350, height: 350)
                .offset(x: orbAnimate ? 110 : 140, y: orbAnimate ? 260 : 300)
                .animation(
                    .easeInOut(duration: 8).repeatForever(autoreverses: true),
                    value: orbAnimate
                )

            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "#38BDF8").opacity(0.15),
                            Color.clear,
                        ]),
                        center: .center,
                        startRadius: 10,
                        endRadius: 150
                    )
                )
                .frame(width: 300, height: 300)
                .offset(x: orbAnimate ? 60 : 30, y: orbAnimate ? -80 : -40)
                .animation(
                    .easeInOut(duration: 7).repeatForever(autoreverses: true),
                    value: orbAnimate
                )

            VStack(spacing: 28) {
                Spacer()

                // Logo with animated rings
                ZStack {
                    // Rotating gradient ring
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [
                                    Color(hex: "#0EA5E9"),
                                    Color(hex: "#38BDF8"),
                                    Color(hex: "#00CEC9"),
                                    Color(hex: "#38BDF8"),
                                    Color(hex: "#0EA5E9"),
                                ],
                                center: .center
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 130, height: 130)
                        .scaleEffect(ringScale)
                        .opacity(ringOpacity)
                        .rotationEffect(.degrees(ringRotation))

                    // Outer glow ring
                    Circle()
                        .stroke(Color(hex: "#0EA5E9").opacity(0.2), lineWidth: 1.5)
                        .frame(width: 150, height: 150)
                        .scaleEffect(ringScale)
                        .opacity(ringOpacity * 0.6)

                    // Glass icon circle
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "#0EA5E9").opacity(0.4),
                                        Color(hex: "#0EA5E9").opacity(0.15),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 105, height: 105)
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [.white.opacity(0.4), .white.opacity(0.05)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.5
                                    )
                            )

                        Image(systemName: "car.fill")
                            .font(.system(size: 42, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, Color(hex: "#38BDF8")],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    .shadow(color: Color(hex: "#0EA5E9").opacity(0.5), radius: 30, y: 8)
                }

                // App title
                VStack(spacing: 10) {
                    Text("Smart Parking")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(hex: "#38BDF8")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("Find • Book • Park")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                        .tracking(4)
                        .opacity(subtitleOpacity)
                }
                .offset(y: titleOffset)
                .opacity(titleOpacity)

                Spacer()

                // Loading dots with gradient
                HStack(spacing: 10) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(
                                activeDot == index
                                    ? LinearGradient(
                                        colors: [Color(hex: "#0EA5E9"), Color(hex: "#38BDF8")],
                                        startPoint: .top, endPoint: .bottom)
                                    : LinearGradient(
                                        colors: [.white.opacity(0.3), .white.opacity(0.15)],
                                        startPoint: .top, endPoint: .bottom)
                            )
                            .frame(
                                width: activeDot == index ? 10 : 7,
                                height: activeDot == index ? 10 : 7
                            )
                            .shadow(
                                color: activeDot == index
                                    ? Color(hex: "#0EA5E9").opacity(0.6) : .clear, radius: 6
                            )
                            .animation(
                                .spring(response: 0.3, dampingFraction: 0.5),
                                value: activeDot
                            )
                    }
                }
                .opacity(dotsOpacity)
                .padding(.bottom, 60)
            }
        }
        .onReceive(dotTimer) { _ in
            activeDot = (activeDot + 1) % 3
        }
        .onAppear {
            orbAnimate = true

            // Step 1: Logo appears with bounce
            withAnimation(.spring(response: 0.6, dampingFraction: 0.65).delay(0.2)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }

            // Step 2: Ring appears and starts rotating
            withAnimation(.easeOut(duration: 0.6).delay(0.4)) {
                ringScale = 1.0
                ringOpacity = 1.0
            }

            // Step 3: Continuous ring rotation
            withAnimation(
                .linear(duration: 8)
                    .repeatForever(autoreverses: false)
                    .delay(0.5)
            ) {
                ringRotation = 360
            }

            // Step 4: Title slides up
            withAnimation(.spring(response: 0.6, dampingFraction: 0.78).delay(0.7)) {
                titleOffset = 0
                titleOpacity = 1.0
            }

            // Step 5: Subtitle fades in
            withAnimation(.easeIn(duration: 0.4).delay(1.0)) {
                subtitleOpacity = 1.0
            }

            // Step 6: Loading dots
            withAnimation(.easeIn(duration: 0.3).delay(1.2)) {
                dotsOpacity = 1.0
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
