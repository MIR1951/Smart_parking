//
//  ParkingCache.swift
//  Smart parking
//
//  Parking ma'lumotlarini cache qilish uchun
//

import Foundation

final class ParkingCache {
    static let shared = ParkingCache()

    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let cacheFileName = "parkings_cache.json"

    // Cache TTL (Time To Live) - 5 daqiqa
    private let cacheTTL: TimeInterval = 5 * 60

    private init() {
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDirectory = caches.appendingPathComponent("ParkingData", isDirectory: true)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    private var cacheFilePath: URL {
        cacheDirectory.appendingPathComponent(cacheFileName)
    }

    // MARK: - Cache Model

    private struct CacheEntry: Codable {
        let parkings: [Parking]
        let timestamp: Date
    }

    // MARK: - Save to Cache

    func save(_ parkings: [Parking]) {
        let entry = CacheEntry(parkings: parkings, timestamp: Date())
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(entry)
            try data.write(to: cacheFilePath, options: .atomic)
        } catch {

        }
    }

    // MARK: - Load from Cache

    func load() -> [Parking]? {
        guard fileManager.fileExists(atPath: cacheFilePath.path) else { return nil }

        do {
            let data = try Data(contentsOf: cacheFilePath)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let entry = try decoder.decode(CacheEntry.self, from: data)

            // TTL tekshirish
            if Date().timeIntervalSince(entry.timestamp) > cacheTTL {
                // Cache eskirgan, lekin stale data qaytaramiz (background da yangilanadi)
                return entry.parkings
            }

            return entry.parkings
        } catch {

            return nil
        }
    }

    // MARK: - Check if Cache is Fresh

    func isFresh() -> Bool {
        guard fileManager.fileExists(atPath: cacheFilePath.path) else { return false }

        do {
            let data = try Data(contentsOf: cacheFilePath)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let entry = try decoder.decode(CacheEntry.self, from: data)

            return Date().timeIntervalSince(entry.timestamp) <= cacheTTL
        } catch {
            return false
        }
    }

    // MARK: - Clear Cache

    func clear() {
        try? fileManager.removeItem(at: cacheFilePath)
    }
}
