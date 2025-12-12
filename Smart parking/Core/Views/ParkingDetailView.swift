import SwiftUI

struct ParkingDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let parking: Parking
    
    @State private var selectedTab: DetailTab = .about
    
    var body: some View {
        
        VStack{
            ScrollView(showsIndicators: false) {
                
                VStack(alignment: .leading, spacing: 0) {
                    
                    // MARK: — Header Image
                    headerImage
                    
                    // MARK: — Summary (Name, Rating, Address)
                    headerInfo
                    
                    // MARK: — Tabs (About, Gallery, Review)
                    tabSelector
                    
                    // MARK: — Tab Content
                    Group {
                        switch selectedTab {
                        case .about:
                            aboutSection
                        case .gallery:
                            gallerySection
                        case .review:
                            reviewSection
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    
                    Spacer().frame(height: 120) // Book button markazga urilishmasligi uchun
                }
            }
            
        } .overlay(alignment: .bottomTrailing) {
            bottomBookingBar
    }
        .ignoresSafeArea(edges: .top)
        .navigationBarBackButtonHidden(true)
    }
    
}
    
// MARK: — UI COMPONENTS

extension ParkingDetailView {
   
    // MARK: Header Image
    private var headerImage: some View {
        ZStack(alignment: .topLeading) {
            AsyncImage(url: URL(string: parking.thumbnail_url ?? "")) { img in
                img.resizable().scaledToFill()
            } placeholder: {
                Rectangle().fill(Color.gray.opacity(0.2))
            }
            
            .frame(height: 260)
            .clipped()
           
            
            HStack {
                circularButton(system: "chevron.left") {
                    dismiss()
                }
                Spacer()
                circularButton(system: "square.and.arrow.up") { }
                circularButton(system: "heart") { }
            }
            .padding(.horizontal)
            .padding(.top,50)
        }
        
    }
    
    // MARK: Header Info
    private var headerInfo: some View {
        VStack(alignment: .leading, spacing: 6) {
            
            Text(parking.name)
                .font(.title2)
                .fontWeight(.semibold)
            
            HStack(spacing: 6) {
                Text("⭐️ 4.8 (365 reviews)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            HStack(spacing: 6) {
                Image(systemName: "mappin.and.ellipse")
                Text(parking.address ?? "Unknown")
            }
            .foregroundColor(.gray)
            .font(.subheadline)
            
        }
        .padding(.horizontal)
        .padding(.top, 12)
    }
    
    // MARK: Tabs
    private var tabSelector: some View {
        HStack {
            ForEach(DetailTab.allCases, id: \.rawValue) { tab in
                VStack {
                    Text(tab.rawValue)
                        .font(.headline)
                        .foregroundColor(selectedTab == tab ? Color.purple : .gray)
                    
                    if selectedTab == tab {
                        Rectangle()
                            .fill(Color.purple)
                            .frame(height: 3)
                           
                    } else {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 3)
                    }
                }
                .onTapGesture {
                    withAnimation(.easeInOut) { selectedTab = tab }
                }
            }
        }
        .padding(.top, 16)
    }
    
   
    
    
    // MARK: ABOUT TAB
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            HStack {
                HStack {
                    Image(systemName: "clock")
                    Text("05 mins away")
                }
                Spacer()
                HStack {
                    Image(systemName: "car.fill")
                    Text("\(parking.total_spots - (parking.live_occupancy ?? 0)) Spots Available")
                }
            }
            .foregroundColor(.purple)
            .font(.subheadline)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Description")
                    .font(.headline)
                Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit...")
                    .foregroundColor(.gray)
            }
            
            VStack(alignment: .leading) {
                Text("Operated by")
                    .font(.headline)
                
                HStack {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 42, height: 42)
                    VStack(alignment: .leading) {
                        Text("John Doe")
                        Text("Manager")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
            }
            
        }
    }
    
    
    // MARK: GALLERY TAB
    private var gallerySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Gallery (400)")
                    .font(.headline)
                Spacer()
                Text("add photo")
                    .foregroundColor(.purple)
                    .font(.subheadline)
            }
            
            LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
                ForEach(0..<6, id: \.self) { i in
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 120)
                        .cornerRadius(12)
                }
            }
        }
    }
    
    
    // MARK: REVIEW TAB
    private var reviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            HStack {
                Text("Reviews")
                    .font(.headline)
                Spacer()
                Text("add review")
                    .foregroundColor(.purple)
            }
            
            // Search
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .frame(height: 46)
                .overlay(
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundColor(.gray)
                        Text("Search in reviews").foregroundColor(.gray)
                        Spacer()
                    }
                    .padding(.horizontal)
                )
            
            // Example review
            HStack {
                Circle().fill(Color.gray.opacity(0.3)).frame(width: 42, height: 42)
                VStack(alignment: .leading) {
                    Text("Dale Thiel").bold()
                    Text("11 months ago").foregroundColor(.gray).font(.caption)
                }
                Spacer()
            }
            
            Text("Great parking space! Very clean and safe.")
                .foregroundColor(.gray)
        }
    }
    
    
    // MARK: Bottom Booking Bar
    private var bottomBookingBar: some View {
       
        HStack {
            VStack(alignment: .leading) {
                Text("Total Price")
                    .foregroundColor(.gray)
                    .font(.caption)
                Text("$\(parking.price_per_hour, specifier: "%.2f") /hr")
                    .font(.title3)
                    .fontWeight(.bold)
            }
            Spacer()
            
            Button(action: {}) {
                Text("Book Slot")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 160)
                    .background(Color.purple)
                    .cornerRadius(14)
            }
        }
        .padding(.top)
        .background(Color.bgLight)
        .padding(.horizontal)
//        .safeAreaInset(edge: .bottom) { EmptyView() }
    }
    
    
    // MARK: Button UI
    private func circularButton(system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.headline)
                .foregroundColor(.black)
                .padding(10)
                .background(Color.white)
                .clipShape(Circle())
                .shadow(radius: 3)
        }
    }
}


// MARK: — TABS ENUM

enum DetailTab: String, CaseIterable {
    case about = "About"
    case gallery = "Gallery"
    case review = "Review"
}

