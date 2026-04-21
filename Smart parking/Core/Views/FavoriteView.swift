//
//  FavoriteView.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 02/12/25.
//

import SwiftUI

struct FavoriteView: View {
    @Environment(LocalizationManager.self) private var loc

    @EnvironmentObject var parkingsStore: ParkingsStore
    @EnvironmentObject var favoritesStore: FavoritesStore
    @EnvironmentObject var availabilityStore: ParkingAvailabilityStore

    @State private var parkingToRemove: Parking?
    @State private var scrollOffset: CGFloat = 0

    private var headerProgress: CGFloat { min(max(scrollOffset / 150, 0), 1) }

    private var favoriteParkings: [Parking] {
        parkingsStore.all.filter { favoritesStore.isFavorite($0.id) }
    }

    var body: some View {
        ZStack {
            AppAnimatedBackground()

            VStack(spacing: 0) {
                // Sticky shrinking header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(loc.str(.favoriteTitle))
                            .font(.system(size: 28 - headerProgress * 8, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.Palette.textPrimary)

                        Text("\(favoriteParkings.count) \(loc.str(.tabFavorite))")
                            .font(AppTheme.Typography.subheadline)
                            .foregroundColor(AppTheme.Palette.textSecondary)
                            .opacity(max(0, Double(1 - headerProgress * 2)))
                    }

                    Spacer()

                    Image(systemName: "heart.fill")
                        .font(.system(size: max(14, 22 - headerProgress * 8)))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppTheme.Palette.favoriteAccent, AppTheme.Palette.danger],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .frame(width: max(32, 46 - headerProgress * 14), height: max(32, 46 - headerProgress * 14))
                        .background(AppTheme.Palette.surfaceGlass)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(AppTheme.Palette.borderGlass, lineWidth: 1)
                        )
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)
                .animation(AppTheme.Anim.snappy, value: headerProgress)

                if favoriteParkings.isEmpty && !parkingsStore.isLoading {
                    emptyState
                } else {
                    ScrollView(showsIndicators: false) {
                        GeometryReader { geo in
                            Color.clear.preference(
                                key: ScrollOffsetPreferenceKey.self,
                                value: -geo.frame(in: .named("favScroll")).minY
                            )
                        }.frame(height: 0)

                        VStack(spacing: 14) {
                            ForEach(Array(favoriteParkings.enumerated()), id: \.element.id) {
                                index, parking in
                                NavigationLink(value: AppRoute.parkingDetail(parking)) {
                                    NearbyParkingCard(
                                        parking: parking,
                                        availability: availabilityStore.availability(for: parking.id),
                                        isFavorite: true,
                                        onToggleFavorite: {
                                            parkingToRemove = parking
                                        }
                                    )
                                }
                                .buttonStyle(.plain)
                                .pressStyle()
                                .appReveal(Double(index) * 0.05)
                            }
                            .padding(.horizontal, 20)

                            Spacer(minLength: 100)
                        }
                    }
                    .coordinateSpace(name: "favScroll")
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        withAnimation(AppTheme.Anim.snappy) { scrollOffset = value }
                    }
                }
            }
        }
        .confirmationDialog(
            loc.str(.favoriteRemoveTitle),
            isPresented: .init(
                get: { parkingToRemove != nil },
                set: { if !$0 { parkingToRemove = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(loc.str(.favoriteYesRemove), role: .destructive) {
                if let parking = parkingToRemove {
                    AppTheme.Haptic.success()
                    Task {
                        favoritesStore.toggle(parking.id)
                    }
                }
                parkingToRemove = nil
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppTheme.Palette.brand.opacity(0.15),
                                AppTheme.Palette.brandLight.opacity(0.05),
                            ],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "heart.slash.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppTheme.Palette.brand, AppTheme.Palette.brandLight],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
            }

            Text(loc.str(.favoriteEmpty))
                .font(AppTheme.Typography.title3)
                .foregroundColor(AppTheme.Palette.textPrimary)

            Text(loc.str(.favoriteEmptySubtitle))
                .font(AppTheme.Typography.subheadline)
                .foregroundColor(AppTheme.Palette.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .appReveal(0.1)
    }
}
