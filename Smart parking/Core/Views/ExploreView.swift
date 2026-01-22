//
//  ExploreView.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 23/01/26.
//


import SwiftUI
import MapKit

struct ExploreView: View {
    @State private var search = ""
    @StateObject private var vm = ParkingViewModel()

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 41.3117, longitude: 69.2797),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )

    var body: some View {
        ZStack(alignment: .top) {
            Map(coordinateRegion: $region, annotationItems: vm.nearbyParkings) { p in
                MapAnnotation(coordinate: .init(latitude: p.latitude, longitude: p.longitude)) {
                    Circle().fill(Color.primary).frame(width: 12, height: 12)
                }
            }
            .ignoresSafeArea()

            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundColor(.gray)
                        TextField("Search Parking", text: $search)
                    }
                    .padding()
                    .background(.white)
                    .cornerRadius(14)

                    Button {
                        // filter sheet
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.primary)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)

                Spacer()

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(vm.nearbyParkings.prefix(10)) { parking in
                            NavigationLink {
                                ParkingDetailView(parking: parking)
                            } label: {
                                PopularParkingCard(parking: parking)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
        }
        .task {
            vm.loadParkings(userLocation: nil, force: true)
        }
    }
}
