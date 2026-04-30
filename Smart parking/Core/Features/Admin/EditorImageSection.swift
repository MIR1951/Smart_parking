import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

struct EditorImageSection: View {
    @Environment(LocalizationManager.self) private var loc

    @Binding var existingImageURLs: [String]
    @Binding var selectedImages: [UIImage]
    @Binding var selectedPhotoItems: [PhotosPickerItem]

    @State private var isDroppingImages = false

    var body: some View {
        VStack(spacing: 12) {
            if !existingImageURLs.isEmpty {
                existingImagesRow
            }

            if !selectedImages.isEmpty {
                newImagesRow
            }

            let total = existingImageURLs.count + selectedImages.count

            PhotosPicker(
                selection: $selectedPhotoItems,
                maxSelectionCount: max(1, 5 - total),
                matching: .images
            ) {
                HStack(spacing: 6) {
                    Image(systemName: "photo.badge.plus")
                    Text(loc.str(.adminAddImage))
                }
                .font(AppTheme.Typography.subheadline)
                .fontWeight(.medium)
                .foregroundColor(AppTheme.Palette.brand)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(AppTheme.Palette.brandSoft)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small, style: .continuous))
            }
            .disabled(total >= 5)
            .opacity(total >= 5 ? 0.5 : 1)
            .pressStyle()
            .onChange(of: selectedPhotoItems) { _, newItems in
                Task { await loadSelectedImages(from: newItems) }
            }

            Text(loc.str(.adminImageHint))
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Palette.textTertiary)

            if total < 5 {
                dropZone
            }
        }
    }

    private var existingImagesRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(existingImageURLs.enumerated()), id: \.element) { index, url in
                    ZStack(alignment: .topTrailing) {
                        CachedAsyncImage(url: URL(string: url)) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(AppTheme.Palette.surfaceSecondary)
                        }
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .clipped()

                        Button {
                            existingImageURLs.remove(at: index)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.white)
                                .shadow(radius: 2)
                        }
                        .offset(x: 4, y: -4)
                    }
                }
            }
        }
    }

    private var newImagesRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: image)
                            .resizable().scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .clipped()

                        Button {
                            selectedImages.remove(at: index)
                            if index < selectedPhotoItems.count {
                                selectedPhotoItems.remove(at: index)
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.white)
                                .shadow(radius: 2)
                        }
                        .offset(x: 4, y: -4)
                    }
                }
            }
        }
    }

    private var dropZone: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                .strokeBorder(
                    isDroppingImages ? AppTheme.Palette.brand : AppTheme.Palette.textTertiary.opacity(0.4),
                    style: StrokeStyle(lineWidth: 1.5, dash: [6])
                )
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                        .fill(isDroppingImages ? AppTheme.Palette.brandSoft : Color.clear)
                )
                .frame(height: 64)

            HStack(spacing: 8) {
                Image(systemName: "arrow.down.to.line")
                    .font(.title3)
                    .foregroundColor(isDroppingImages ? AppTheme.Palette.brand : AppTheme.Palette.textTertiary)
                Text(loc.str(.adminDropHint))
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(isDroppingImages ? AppTheme.Palette.brand : AppTheme.Palette.textTertiary)
            }
        }
        .onDrop(of: [UTType.image], isTargeted: $isDroppingImages) { providers in
            handleDroppedImages(providers)
        }
    }

    private func loadSelectedImages(from items: [PhotosPickerItem]) async {
        var images: [UIImage] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data)
            {
                images.append(image)
            }
        }
        await MainActor.run { selectedImages = images }
    }

    @discardableResult
    private func handleDroppedImages(_ providers: [NSItemProvider]) -> Bool {
        let total = existingImageURLs.count + selectedImages.count
        let canAdd = max(0, 5 - total)
        guard canAdd > 0 else { return false }

        for provider in providers.prefix(canAdd) {
            provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
                guard let data, let image = UIImage(data: data) else { return }
                DispatchQueue.main.async { self.selectedImages.append(image) }
            }
        }
        return true
    }
}
