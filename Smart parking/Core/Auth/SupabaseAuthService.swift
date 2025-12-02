//
//  SupabaseAuthService.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 02/12/25.
//

import Foundation
import Supabase

struct SupabaseAuthService {
    private var client : SupabaseClient
    init() {
        self.client = SupabaseClient.init(
            supabaseURL: URL(string: Constants.projectURLString)!,
            supabaseKey: Constants.projectAPIKey
        )
    }
    
    func signUp(email:String,password:String) async throws -> User {
        let response = try await client.auth.signUp(email: email, password: password)
        guard let email = response.user.email else {
            print("DEBUG: No email")
            throw NSError()
        }
        
        print(response.user)
        
        return User(id:response.user.aud, email: email)
    }
    
    func signIn(email: String, password: String) async throws -> User {
        let response = try await client.auth.signIn(email: email, password: password)
        guard let email = response.user.email else {
            print("DEBUG: No email")
            throw NSError()
        }
        print(response.user)
        
        return User(id:response.user.aud, email: email)
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
    }
    
    func getCurrentUser() async throws ->User? {
        let session = try await client.auth.session
        let supabaseUser = session.user
        guard let email = supabaseUser.email else {
            print("DEBUG: No email")
            throw NSError()
        }
        return User(id:supabaseUser.aud, email: email)
    }
    
}
