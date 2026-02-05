import SwiftUI
import MapKit
import CoreLocation

struct ExploreView: View {

    @EnvironmentObject var parkings: ParkingsStore
    @EnvironmentObject var availabilityStore: ParkingAvailabilityStore

    @State private var search = ""
    @StateObject private var locationManager = LocationManager()

    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 41.3117, longitude: 69.2797),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
    )

    @State private var didRequestLocation = false
    @State private var showFilterInfo = false

    private var filtered: [Parking] {
        let base = parkings.nearby
        let q = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return base }

        return base.filter {
            $0.name.lowercased().contains(q) ||
            ($0.address ?? "").lowercased().contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            Map(position: $cameraPosition) {
                ForEach(filtered) { p in
                    Annotation("", coordinate: .init(latitude: p.latitude, longitude: p.longitude)) {
                    Circle()
                        .fill(Color.primary)
                        .frame(width: 12, height: 12)
                    }
                }
            }
            .ignoresSafeArea()

            // TOP SEARCH BAR (rasmdagidek yuqorida)
            .safeAreaInset(edge: .top) {
                HStack(spacing: 12) {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)

                        TextField("Search Parking", text: $search)
                            .autocorrectionDisabled()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(.white)
                    .cornerRadius(14)

                    Button {
                        showFilterInfo = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.primary)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 8)
                .alert("Info", isPresented: $showFilterInfo) {
                    Button("OK") {}
                } message: {
                    Text("Filter bo'limi keyingi versiyada qo'shiladi.")
                }
            }

            // BOTTOM CARDS (TabBar ustida, balandroq)
            .safeAreaInset(edge: .bottom) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(filtered.prefix(10)) { parking in
                            NavigationLink {
                                ParkingDetailView(parking: parking)
                            } label: {
                                PopularParkingCard(parking: parking)
                            }
                            .buttonStyle(.plain)   // ✅ navigation ishlaydi
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                }
                .background(Color.clear)
            }

            .task {
                // availability realtime (agar root’da start qilmagan bo‘lsangiz)
                availabilityStore.initialLoad()
                availabilityStore.startRealtime()

                if !didRequestLocation {
                    didRequestLocation = true
                    locationManager.requestPermission()
                }

                // parkings yo'q bo'lsa yuklash
                if parkings.all.isEmpty && !parkings.isLoading {
                    parkings.load(userLocation: locationManager.location)
                }
            }
            .onChange(of: locationManager.location) { _, loc in
                if let loc {
                    withAnimation {
                        cameraPosition = .region(
                            MKCoordinateRegion(
                                center: loc.coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                            )
                        )
                    }
                }
                if parkings.all.isEmpty {
                    parkings.load(userLocation: loc, force: true)
                } else {
                    parkings.recomputeNearby(userLocation: loc)
                }
            }
        }
    }
}
