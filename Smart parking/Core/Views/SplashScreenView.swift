//
//  SplashScreenView.swift
//  Smart parking
//
//  Ilova ochilishida ko'rsatiladigan animatsiyali splash screen
//

import SwiftUI
internal import Combine

struct SplashScreenView: View {
    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0
    @State private var titleOffset: CGFloat = 40
    @State private var titleOpacity: Double = 0
    @State private var ringScale: CGFloat = 0.6
    @State private var ringOpacity: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var dotsOpacity: Double = 0
    @State private var activeDot: Int = 0

    private let dotTimer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "#1E1B4B"),
                    Color(hex: "#312E81"),
                    Color(hex: "#4338CA"),
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Decorative circles
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.08),
                            Color.clear,
                        ]),
                        center: .center,
                        startRadius: 10,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .offset(x: -120, y: -250)

            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.purple.opacity(0.15),
                            Color.clear,
                        ]),
                        center: .center,
                        startRadius: 10,
                        endRadius: 180
                    )
                )
                .frame(width: 350, height: 350)
                .offset(x: 130, y: 300)

            VStack(spacing: 24) {
                Spacer()

                // Logo with animated ring
                ZStack {
                    // Pulse ring
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 2)
                        .frame(width: 140, height: 140)
                        .scaleEffect(pulseScale)
                        .opacity(ringOpacity)

                    // Outer ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.4),
                                    Color.white.opacity(0.1),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(ringScale)
                        .opacity(ringOpacity)

                    // Icon circle
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.2),
                                        Color.white.opacity(0.05),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)

                        Image(systemName: "car.fill")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, .white.opacity(0.8)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                }

                // App title
                VStack(spacing: 8) {
                    Text("Smart Parking")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Find • Book • Park")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .tracking(2)
                }
                .offset(y: titleOffset)
                .opacity(titleOpacity)

                Spacer()

                // Loading dots
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(Color.white)
                            .frame(width: 8, height: 8)
                            .scaleEffect(activeDot == index ? 1.3 : 0.7)
                            .opacity(activeDot == index ? 1.0 : 0.4)
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
            // Step 1: Logo appears
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }

            // Step 2: Ring appears
            withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
                ringScale = 1.0
                ringOpacity = 1.0
            }

            // Step 3: Pulse ring animation
            withAnimation(
                .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
                    .delay(0.7)
            ) {
                pulseScale = 1.3
            }

            // Step 4: Title slides up
            withAnimation(.easeOut(duration: 0.6).delay(0.8)) {
                titleOffset = 0
                titleOpacity = 1.0
            }

            // Step 5: Loading dots
            withAnimation(.easeIn(duration: 0.3).delay(1.2)) {
                dotsOpacity = 1.0
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
