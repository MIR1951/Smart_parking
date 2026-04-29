//
//  AdminParkingListView.swift
//  Smart parking
//
//  Owner parkinglar ro'yxati — qo'shish, tahrirlash, o'chirish
//

import SwiftUI

struct AdminParkingListView: View {
    @Bindable var store: AdminStore
    @Environment(LocalizationManager.self) private var loc

    @State private var showAddSheet = false
    @State private var parkingToEdit: Parking?
    @State private var parkingToDelete: Parking?
    @State private var showDeleteConfirm = false
    @State private var searchText = ""
    @State private var scrollOffset: CGFloat = 0

    private var headerProgress: CGFloat { min(max(scrollOffset / 120, 0), 1) }
    private var titleFontSize: CGFloat { 22 - headerProgress * 4 }

    private var filteredParkings: [Parking] {
        if searchText.isEmpty { return store.ownedParkings }
        return store.ownedParkings.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            ($0.address ?? "").localizedCaseInsensitiveContains(searchText) ||
            $0.city.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ZStack {
            AppAnimatedBackground()

            VStack(spacing: 0) {
                // Sticky header
                HStack {
                    Text(loc.str(.adminMyParkings))
                        .font(.system(size: titleFontSize, weight: .bold, design: .rounded))

                    Spacer()

                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [AppTheme.Palette.brand, AppTheme.Palette.brandLight],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .pressStyle()
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 8)
                .animation(AppTheme.Anim.snappy, value: headerProgress)

                ScrollView(showsIndicators: false) {
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: -geo.frame(in: .named("parkingListScroll")).minY
                        )
                    }.frame(height: 0)

                    VStack(spacing: 16) {
                        // Search bar
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(AppTheme.Palette.textTertiary)
                            TextField(loc.str(.adminSearchParkings), text: $searchText)
                                .font(AppTheme.Typography.body)
                        }
                        .padding(12)
                        .glassCard(cornerRadius: AppTheme.Radius.medium)
                        .padding(.horizontal)
                        .appReveal(0.05)

                if store.isLoading && store.ownedParkings.isEmpty {
                    AppStateView(kind: .loading(title: loc.str(.launchLoading)))
                        .padding(.top, 60)
                } else if filteredParkings.isEmpty && !searchText.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(AppTheme.Palette.textTertiary)
                        Text(loc.str(.exploreNoResults))
                            .font(AppTheme.Typography.subheadline)
                            .foregroundColor(AppTheme.Palette.textSecondary)
                    }
                    .padding(.top, 60)
                } else if store.ownedParkings.isEmpty {
                    emptyState
                } else {
                    ForEach(Array(filteredParkings.enumerated()), id: \.element.id) { index, parking in
                        AdminParkingCard(
                            parking: parking,
                            onEdit: { parkingToEdit = parking },
                            onDelete: {
                                parkingToDelete = parking
                                showDeleteConfirm = true
                            }
                        )
                        .padding(.horizontal)
                        .appReveal(0.05 + Double(index) * 0.04)
                    }
                    }
                }
                .padding(.bottom, 24)
                }
                .coordinateSpace(name: "parkingListScroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    withAnimation(AppTheme.Anim.snappy) { scrollOffset = value }
                }
                .refreshable { await store.refreshParkings() }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showAddSheet) {
            AdminParkingEditorView(store: store, parking: nil)
        }
        .sheet(item: $parkingToEdit) { parking in
            AdminParkingEditorView(store: store, parking: parking)
        }
        .alert(loc.str(.adminDeleteConfirm), isPresented: $showDeleteConfirm) {
            Button(loc.str(.adminDeleteNo), role: .cancel) {}
            Button(loc.str(.adminDeleteYes), role: .destructive) {
                if let parking = parkingToDelete {
                    Task {
                        try? await store.deleteParking(id: parking.id)
                    }
                }
            }
        } message: {
            if let parking = parkingToDelete {
                Text(parking.name)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "parkingsign.circle")
                .font(.system(size: 56))
                .foregroundColor(AppTheme.Palette.textTertiary)

            Text(loc.str(.adminNoParkings))
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Palette.textSecondary)

            Text(loc.str(.adminNoParkingsSub))
                .font(AppTheme.Typography.subheadline)
                .foregroundColor(AppTheme.Palette.textTertiary)
                .multilineTextAlignment(.center)

            Button {
                showAddSheet = true
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text(loc.str(.adminAddParking))
                }
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [AppTheme.Palette.brand, AppTheme.Palette.brandLight],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
            }
            .pressStyle()
        }
        .padding(.top, 60)
    }
}

// MARK: - Admin Parking Card

private struct AdminParkingCard: View {
    let parking: Parking
    let onEdit: () -> Void
    let onDelete: () -> Void

    private let loc = LocalizationManager.shared

    private var occupancyRatio: Double {
        let occupancy = parking.live_occupancy ?? 0
        let total = parking.total_spots
        return total > 0 ? Double(occupancy) / Double(total) : 0
    }

    private var occupancyColor: Color {
        if occupancyRatio > 0.8 { return AppTheme.Palette.danger }
        if occupancyRatio > 0.5 { return AppTheme.Palette.warning }
        return AppTheme.Palette.success
    }

    var body: some View {
        VStack(spacing: 0) {
            // Image
            ZStack(alignment: .topTrailing) {
                CachedAsyncImage(url: URL(string: parking.thumbnail_url ?? "")) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Rectangle().fill(AppTheme.Palette.surfaceSecondary)
                        .overlay(
                            Image(systemName: "car.fill")
                                .font(.largeTitle)
                                .foregroundColor(AppTheme.Palette.textTertiary)
                        )
                }
                .frame(height: 160)
                .clipped()
                .imageGradient()

                // Rating badge
                if let rating = parking.rating, rating > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", rating))
                            .font(AppTheme.Typography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xSmall, style: .continuous))
                    .padding(10)
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(parking.name)
                        .font(AppTheme.Typography.headline)

                    Spacer()

                    HStack(spacing: 4) {
                        Circle()
                            .fill(occupancyColor)
                            .frame(width: 8, height: 8)
                        Text("\(parking.live_occupancy ?? 0)/\(parking.total_spots)")
                            .font(AppTheme.Typography.caption)
                            .fontWeight(.medium)
                            .foregroundColor(AppTheme.Palette.textSecondary)
                    }
                }

                // Occupancy bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(AppTheme.Palette.surfaceSecondary)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(occupancyColor)
                            .frame(width: geo.size.width * min(occupancyRatio, 1.0))
                    }
                }
                .frame(height: 5)

                HStack(spacing: 16) {
                    Label("\(Int(parking.price_per_hour)) \(loc.str(.walletCurrency))\(loc.str(.bookingsPerHour))", systemImage: "banknote")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Palette.brand)
                        .fontWeight(.medium)

                    if let address = parking.address {
                        Label(address, systemImage: "mappin")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Palette.textSecondary)
                            .lineLimit(1)
                    }
                }

                // Features
                if let features = parking.features, !features.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(features.prefix(4), id: \.self) { feature in
                                Text(feature)
                                    .font(.system(size: 10, weight: .medium, design: .rounded))
                                    .foregroundColor(AppTheme.Palette.textSecondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(AppTheme.Palette.surfaceSecondary)
                                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            }
                        }
                    }
                }

                // Actions
                HStack(spacing: 12) {
                    Button(action: onEdit) {
                        HStack(spacing: 4) {
                            Image(systemName: "pencil")
                            Text(LocalizationManager.shared.str(.adminEditParking))
                        }
                        .font(AppTheme.Typography.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.Palette.brand)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(AppTheme.Palette.brandSoft)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small, style: .continuous))
                    }
                    .pressStyle()

                    Spacer()

                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.Palette.danger)
                            .padding(8)
                            .background(AppTheme.Palette.dangerSoft)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xSmall, style: .continuous))
                    }
                    .pressStyle()
                }
                .padding(.top, 2)
            }
            .padding()
        }
        .glassCard()
    }
}
