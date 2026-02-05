//
//  CachedAsyncImage.swift
//  Smart parking
//
//  Rasm caching uchun optimizatsiya qilingan komponent
//

import SwiftUI

// MARK: - Image Cache Manager

final class ImageCacheManager {
    static let shared = ImageCacheManager()
    
    private let memoryCache = NSCache<NSURL, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    private init() {
        // Cache papkasini yaratish
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDirectory = caches.appendingPathComponent("ImageCache", isDirectory: true)
        
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // Memory cache konfiguratsiyasi
        memoryCache.countLimit = 100
        memoryCache.totalCostLimit = 50 * 1024 * 1024 // 50 MB
    }
    
    // MARK: - Memory Cache
    
    func getFromMemory(for url: URL) -> UIImage? {
        memoryCache.object(forKey: url as NSURL)
    }
    
    func saveToMemory(_ image: UIImage, for url: URL) {
        memoryCache.setObject(image, forKey: url as NSURL)
    }
    
    // MARK: - Disk Cache
    
    private func diskPath(for url: URL) -> URL {
        let filename = url.absoluteString.data(using: .utf8)?.base64EncodedString() ?? UUID().uuidString
        return cacheDirectory.appendingPathComponent(filename)
    }
    
    func getFromDisk(for url: URL) -> UIImage? {
        let path = diskPath(for: url)
        guard let data = try? Data(contentsOf: path),
              let image = UIImage(data: data) else { return nil }
        
        // Diskdan o'qilsa memory ga ham saqlaymiz
        saveToMemory(image, for: url)
        return image
    }
    
    func saveToDisk(_ image: UIImage, for url: URL) {
        let path = diskPath(for: url)
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        try? data.write(to: path)
    }
    
    // MARK: - Combined Get/Save
    
    func getImage(for url: URL) -> UIImage? {
        // Avval memory dan
        if let cached = getFromMemory(for: url) {
            return cached
        }
        // Keyin disk dan
        return getFromDisk(for: url)
    }
    
    func saveImage(_ image: UIImage, for url: URL) {
        saveToMemory(image, for: url)

        // Disk ga background da save qilamiz
        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.saveToDisk(image, for: url)
        }
    }
    
    // MARK: - Clear Cache
    
    func clearCache() {
        memoryCache.removeAllObjects()
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
}

// MARK: - Cached Async Image View

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    
    @State private var image: UIImage?
    @State private var isLoading = false
    
    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let image {
                content(Image(uiImage: image))
            } else {
                placeholder()
                    .onAppear {
                        loadImage()
                    }
            }
        }
    }
    
    private func loadImage() {
        guard let url, !isLoading else { return }
        
        // Avval cache dan tekshiramiz
        if let cached = ImageCacheManager.shared.getImage(for: url) {
            self.image = cached
            return
        }
        
        // Cache da yo'q - network dan yuklaymiz
        isLoading = true
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                
                if let downloadedImage = UIImage(data: data) {
                    // Cache ga saqlaymiz
                    ImageCacheManager.shared.saveImage(downloadedImage, for: url)
                    
                    await MainActor.run {
                        self.image = downloadedImage
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - Convenience Initializer

extension CachedAsyncImage where Placeholder == ProgressView<EmptyView, EmptyView> {
    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content
    ) {
        self.init(url: url, content: content, placeholder: { ProgressView() })
    }
}

extension CachedAsyncImage where Content == Image, Placeholder == ProgressView<EmptyView, EmptyView> {
    init(url: URL?) {
        self.init(url: url, content: { $0 }, placeholder: { ProgressView() })
    }
}
