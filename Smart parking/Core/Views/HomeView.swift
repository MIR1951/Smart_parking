import SwiftUI
import SwiftUI

struct HomeView: View {
    
    @StateObject private var vm = ParkingViewModel()
    @State private var search = ""
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                
                VStack(alignment: .leading, spacing: 20) {
                    
                    // HEADER
                    headerSection
                    
                    // SEARCH
                    searchSection
                    
                    // POPULAR PARKING
                    popularSection
                    
                    // NEARBY PARKING
                    nearbySection
                }
                .padding(.vertical)
            }
            .task {
                await vm.loadParkings()
            }
        }
    }
    
    
    
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Location")
                    .foregroundColor(.gray)
                    .font(.caption)
                
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.primary)
                    
                    Text("New York, USA")
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            Circle()
                .fill(Color.primary.opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "bell")
                        .foregroundColor(.primary)
                )
        }
        .padding(.horizontal)
    }
    private var searchSection: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search Parking", text: $search)
                .autocorrectionDisabled()
        }
        .padding()
        .background(Color.bgLight)
        .cornerRadius(15)
        .padding(.horizontal)
    }
    private var popularSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            HStack {
                Text("Popular Parking")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("See All")
                    .foregroundColor(.primary)
                    .font(.subheadline)
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {

                    ForEach(vm.popularParkings) { parking in
                        NavigationLink {
                            ParkingDetailView(parking: parking)
                        } label: {
                            PopularParkingCard(parking: parking)
                        }
                    }
                }
                .padding()
            }

        }
    }
    private var nearbySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            HStack {
                Text("Nearby Parking")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("See All")
                    .foregroundColor(.primary)
                    .font(.subheadline)
            }
            .padding(.horizontal)
            
            VStack(spacing: 16) {
                ForEach(vm.nearbyParkings) { parking in
                    NavigationLink {
                        ParkingDetailView(parking: parking)
                    } label: {
                        NearbyParkingCard(parking: parking)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}
