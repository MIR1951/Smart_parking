//
//  SupabaseStorageManager.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 11/12/25.
//

import Foundation
import Supabase

struct SupabaseStorageManager {
    private let client: SupabaseClient
    
    init() {
        self.client = SB.shared.client
    }
    
    func uploadProfilePhoto(for user: User, imageData : Data) async throws -> String {
        let path = "\(user.id)/avatars/latest.jpg"
        
        try await client.storage
            .from("avatars")
            .upload(
                path,
                data: imageData,
                options: FileOptions(
                    cacheControl: "60",
                    contentType: "image/jpeg",
                    upsert: true
                )
            )
        
        let publicURL = try  client.storage.from("avatars").getPublicURL(path: path)
        let cacheBustedURL = "\(publicURL.absoluteString)?v=\(Int(Date().timeIntervalSince1970))"
        return cacheBustedURL
    }

    func publicURL(for bucket: String, path: String) throws -> String {
        try client.storage.from(bucket).getPublicURL(path: path).absoluteString
    }

    func uploadParkingImage(
        imageData: Data,
        city: String,
        parkingSlug: String,
        fileName: String = UUID().uuidString + ".jpg"
    ) async throws -> String {
        let normalizedCity = sanitizePathComponent(city.lowercased())
        let normalizedSlug = sanitizePathComponent(parkingSlug.lowercased())
        let path = "\(normalizedCity)/\(normalizedSlug)/\(fileName)"

        try await client.storage
            .from("parking-images")
            .upload(
                path,
                data: imageData,
                options: FileOptions(
                    cacheControl: "3600",
                    contentType: "image/jpeg",
                    upsert: true
                )
            )

        return try publicURL(for: "parking-images", path: path)
    }

    private func sanitizePathComponent(_ raw: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let joined = raw
            .replacingOccurrences(of: " ", with: "-")
            .unicodeScalars
            .map { allowed.contains($0) ? String($0) : "-" }
            .joined()

        return joined.replacingOccurrences(of: "--", with: "-")
    }
}
