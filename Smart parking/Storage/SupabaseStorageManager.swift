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
}
