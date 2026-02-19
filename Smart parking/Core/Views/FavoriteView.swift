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

    private var favoriteParkings: [Parking] {
        parkingsStore.all.filter { favoritesStore.isFavorite($0.id) }
    }

    var body: some View {
        ZStack {
            AppAnimatedBackground()

            if favoriteParkings.isEmpty && !parkingsStore.isLoading {
                emptyState
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(loc.str(.favoriteTitle))
                                    .font(AppTheme.Typography.title)
                                    .foregroundColor(AppTheme.Palette.textPrimary)

                                Text("\(favoriteParkings.count) \(loc.str(.tabFavorite))")
                                    .font(AppTheme.Typography.subheadline)
                                    .foregroundColor(AppTheme.Palette.textSecondary)
                            }

                            Spacer()

                            Image(systemName: "heart.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            AppTheme.Palette.brand, AppTheme.Palette.brandLight,
                                        ],
                                        startPoint: .top, endPoint: .bottom
                                    )
                                )
                                .frame(width: 46, height: 46)
                                .background(AppTheme.Palette.surfaceGlass)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(AppTheme.Palette.borderGlass, lineWidth: 1)
                                )
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .appReveal(0.0)

                        // Parking list
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
