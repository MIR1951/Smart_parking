//
//  FavoriteView.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 23/01/26.
//


import SwiftUI

struct FavoriteView: View {
    @StateObject private var vm = ParkingViewModel()

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ForEach(vm.popularParkings) { p in
                        NavigationLink { ParkingDetailView(parking: p) } label: {
                            NearbyParkingCard(parking: p)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Favorite")
        }
        .task { vm.loadParkings(userLocation: nil) }
    }
}
