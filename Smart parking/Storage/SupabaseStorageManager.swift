//
//  SupabaseStorageManager.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 11/12/25.
//

import Foundation
import Supabase

struct SupabaseStorageManager {
    private let client : SupabaseClient
    
    init(){
        self.client = SupabaseClient.init(supabaseURL: URL(string: Constants.projectURLString)!, supabaseKey: Constants.projectAPIKey)
    }
    
    func uploadProfilePhoto(for user: User, imageData : Data) async throws -> String {
        let path = "\(user.id)/avatars.jpg"
        
        try await client.storage
            .from("avatars")
            .upload(path, data: imageData)
        
        let publicURL = try  client.storage.from("avatars").getPublicURL(path: path)
        print ("DEBUG: public url:\(publicURL.absoluteString)")
        return publicURL.absoluteString
    }
}
