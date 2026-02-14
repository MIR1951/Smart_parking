//
//  ShimmerModifier.swift
//  Smart parking
//
//  Shimmer (skeleton) loading effect
//

import SwiftUI

// MARK: - Shimmer ViewModifier

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    let w = geo.size.width
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .white.opacity(0.5), location: 0.3),
                            .init(color: .white.opacity(0.7), location: 0.5),
                            .init(color: .white.opacity(0.5), location: 0.7),
                            .init(color: .clear, location: 1),
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: w * 1.5)
                    .offset(x: -w + phase * (w * 2.5))
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .onAppear {
                withAnimation(
                    .linear(duration: 1.4)
                        .repeatForever(autoreverses: false)
                ) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Skeleton Shapes

struct SkeletonBox: View {
    var width: CGFloat? = nil
    var height: CGFloat = 16
    var radius: CGFloat = 8

    var body: some View {
        RoundedRectangle(cornerRadius: radius)
            .fill(Color.gray.opacity(0.15))
            .frame(width: width, height: height)
            .shimmer()
    }
}

// MARK: - Home Shimmer Skeletons

struct PopularCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SkeletonBox(height: 140, radius: 15)
                .frame(width: 220)

            SkeletonBox(width: 70, height: 12)
            SkeletonBox(width: 150, height: 16)
            SkeletonBox(width: 100, height: 14)

            HStack {
                SkeletonBox(width: 70, height: 12)
                Spacer()
                SkeletonBox(width: 70, height: 12)
            }
        }
        .frame(width: 220)
        .padding(12)
        .appCard()
    }
}

struct NearbyCardSkeleton: View {
    var body: some View {
        HStack(spacing: 15) {
            SkeletonBox(height: 90, radius: 15)
                .frame(width: 90)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    SkeletonBox(width: 80, height: 12)
                    Spacer()
                    SkeletonBox(width: 40, height: 12)
                }
                SkeletonBox(width: 160, height: 16)
                SkeletonBox(width: 120, height: 12)
                SkeletonBox(width: 90, height: 14)
                HStack {
                    SkeletonBox(width: 70, height: 12)
                    Spacer()
                    SkeletonBox(width: 70, height: 12)
                }
            }
        }
        .padding(14)
        .appCard()
    }
}

struct HomeShimmerView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header skeleton
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    SkeletonBox(width: 60, height: 10)
                    SkeletonBox(width: 150, height: 16)
                }
                Spacer()
                SkeletonBox(height: 40, radius: 20)
                    .frame(width: 40)
            }
            .padding(.horizontal)

            // Search skeleton
            SkeletonBox(height: 46, radius: 14)
                .padding(.horizontal)

            // Popular section
            VStack(alignment: .leading, spacing: 12) {
                SkeletonBox(width: 130, height: 18)
                    .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(0..<3, id: \.self) { _ in
                            PopularCardSkeleton()
                        }
                    }
                    .padding(.horizontal)
                }
            }

            // Nearby section
            VStack(alignment: .leading, spacing: 12) {
                SkeletonBox(width: 130, height: 18)
                    .padding(.horizontal)

                VStack(spacing: 16) {
                    ForEach(0..<3, id: \.self) { _ in
                        NearbyCardSkeleton()
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
}

// MARK: - Bookings Shimmer Skeleton

struct BookingCardSkeleton: View {
    var body: some View {
        HStack(spacing: 14) {
            SkeletonBox(height: 90, radius: 14)
                .frame(width: 90)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    SkeletonBox(width: 70, height: 12)
                    Spacer()
                    SkeletonBox(width: 50, height: 12)
                }
                SkeletonBox(width: 140, height: 16)
                SkeletonBox(width: 110, height: 12)

                HStack {
                    SkeletonBox(width: 80, height: 14)
                    Spacer()
                    SkeletonBox(width: 60, height: 14)
                }
            }
        }
        .padding(14)
        .background(AppTheme.Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
    }
}

struct BookingsShimmerView: View {
    var body: some View {
        VStack(spacing: 16) {
            ForEach(0..<4, id: \.self) { _ in
                BookingCardSkeleton()
            }
        }
    }
}
