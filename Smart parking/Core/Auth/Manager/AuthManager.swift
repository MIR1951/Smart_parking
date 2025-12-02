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
    
    var currentUser : User?
    init(authService: SupabaseAuthService = SupabaseAuthService()) {
        self.authService = authService
    }
    
    func signUp(email: String, password: String) async  {
        do {
            self.currentUser = try await authService.signUp(email: email, password: password)
        } catch{
            print("DEBUG: signUp error: \(error.localizedDescription)")
        }
    }
    
    func signIn(email: String, password: String) async {
        do {
            self.currentUser = try await authService.signIn(email: email, password: password)
        } catch{
            print("DEBUG: signIn error: \(error.localizedDescription)")
        }
    }
    func signOut() async {
        do {
            try await authService.signOut()
            currentUser = nil
        } catch{
            print("DEBUG: signOut error: \(error.localizedDescription)")
        }
    }
    
    func refreshUser() async {
        do {
            self.currentUser = try await authService.getCurrentUser()
        } catch {
            print("Refresh user failed: \(error.localizedDescription)")
            currentUser = nil
        }
    }
}

