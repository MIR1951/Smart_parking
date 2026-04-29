import SwiftUI

struct ParkingGalleryViewer: View {
    @Environment(\.dismiss) private var dismiss
    let imageURLs: [String]
    let startIndex: Int

    @State private var selectedIndex = 0

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            if imageURLs.isEmpty {
                ContentUnavailableView("No Images", systemImage: "photo")
                    .foregroundStyle(.white)
            } else {
                TabView(selection: $selectedIndex) {
                    ForEach(Array(imageURLs.enumerated()), id: \.offset) { index, url in
                        ZoomableParkingImage(urlString: url)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .onAppear {
                    selectedIndex = min(max(startIndex, 0), max(imageURLs.count - 1, 0))
                }
            }

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.black.opacity(0.45))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .padding(.top, 14)
            .padding(.trailing, 16)
        }
    }
}

struct ZoomableParkingImage: View {
    let urlString: String

    @State private var scale: CGFloat = 1

    var body: some View {
        CachedAsyncImage(url: URL(string: urlString)) { image in
            image
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            scale = min(max(value, 1), 4)
                        }
                        .onEnded { _ in
                            if scale < 1.05 {
                                withAnimation(.spring) {
                                    scale = 1
                                }
                            }
                        }
                )
                .animation(.easeInOut(duration: 0.15), value: scale)
        } placeholder: {
            ProgressView()
                .tint(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}
