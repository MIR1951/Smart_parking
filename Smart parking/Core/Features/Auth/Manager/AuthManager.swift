//
//  AuthManager.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 02/12/25.
//

import Foundation
import Observation

@Observable
@MainActor
class AuthManager {
    private let authService : SupabaseAuthService
    
    var currentUserID : String?
    init(authService: SupabaseAuthService = SupabaseAuthService()) {
        self.authService = authService
    }
    
    func signUp(email: String, password: String, username: String) async  {
        do {
            self.currentUserID = try await authService.signUp(email: email, password: password, username: username)
        } catch{
            print("DEBUG: signUp error: \(error.localizedDescription)")
        }
    }
    
    func signIn(email: String, password: String) async {
        do {
            self.currentUserID = try await authService.signIn(email: email, password: password)
        } catch{
            print("DEBUG: signIn error: \(error.localizedDescription)")
        }
    }
    func signOut() async {
        do {
            try await authService.signOut()
            currentUserID = nil
        } catch{
            print("DEBUG: signOut error: \(error.localizedDescription)")
        }
    }
    
    func refreshUser() async {
        do {
            self.currentUserID = try await authService.getCurrentUserSession()
        } catch {
            print("Refresh user failed: \(error.localizedDescription)")
            currentUserID = nil
        }
    }
}

