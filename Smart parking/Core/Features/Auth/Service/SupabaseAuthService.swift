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
    
    func signUp(email:String,password:String,username:String) async throws -> String {
        let response = try await client.auth.signUp(email: email, password: password)
        print(response.user)
        let uid = response.user.id.uuidString
        try await uploadUserData(with: uid, email: email, username: username)
        return uid
    }
    
    func signIn(email: String, password: String) async throws -> String {
        let response = try await client.auth.signIn(email: email, password: password)
       
        print(response.user)
        
        return response.user.id.uuidString
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
    }
    
    func getCurrentUserSession() async throws ->String? {
        let session = try await client.auth.session
        let supabaseUser = session.user
        return supabaseUser.id.uuidString
    }
    func uploadUserData(with uid: String, email: String, username: String) async throws{
        let user = User(id: uid, email: email, username: username, createdAt: Date())
        try await client.from("users").insert(user).execute()
    }
    
}
