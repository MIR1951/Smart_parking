//
//  UserServices.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 11/12/25.
//

import Foundation
import Supabase

struct UserService{
    private let client: SupabaseClient
    
    init() {
        self.client = SupabaseClient.init(supabaseURL: URL(string: Constants.projectURLString)!, supabaseKey: Constants.projectAPIKey)
          
    }
    
    
    func fetchCorrentUser()async throws -> User{
        let user = try await client.auth.session.user
        
        return try await client.from("users")
            .select()
            .eq("id", value: user.id.uuidString)
            .single()
            .execute()
            .value
    }
    func updateProfileImageURL(_ imageURL: String) async throws {
        guard let uid = client.auth.currentUser?.id.uuidString else {
            print("DEBUG: No valid session found. User is not authenticated.")
            throw URLError(.userAuthenticationRequired)
        }

        try await client
            .from("users")
            .update(["profileImageURL": imageURL])
            .eq("id", value: uid)
            .execute()

        print("DEBUG: Profile image URL updated successfully!")
    }
}
