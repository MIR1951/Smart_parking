//
//  AuthManager.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 02/12/25.
//

import Foundation
import Observation
import os

@Observable
@MainActor
class AuthManager {
    private let authService: SupabaseAuthService

    var currentUserID: String?
    var authError: String?
    var isLoading = false

    init(authService: SupabaseAuthService? = nil) {
        self.authService = authService ?? SupabaseAuthService(client: SB.shared.client)
    }

    func signUp(email: String, password: String, username: String) async {
        isLoading = true
        authError = nil
        defer { isLoading = false }

        do {
            self.currentUserID = try await authService.signUp(
                email: email, password: password, username: username)
        } catch {
            authError = error.localizedDescription

        }
    }

    func signIn(email: String, password: String) async {
        isLoading = true
        authError = nil
        defer { isLoading = false }

        do {
            self.currentUserID = try await authService.signIn(email: email, password: password)
        } catch {
            authError = error.localizedDescription

        }
    }
    func signOut() async {
        authError = nil
        currentUserID = nil  // Navigate away immediately
        do {
            try await authService.signOut()
        } catch {
            Logger.auth.error("SignOut error: \(error.localizedDescription)")
        }
    }

    func refreshUser() async {
        do {
            self.currentUserID = try await authService.getCurrentUserSession()
        } catch {
            Logger.auth.info("No active session: \(error.localizedDescription)")
            currentUserID = nil
        }
    }

    func clearAuthError() {
        authError = nil
    }

    func resetPassword(email: String) async -> Bool {
        isLoading = true
        authError = nil
        defer { isLoading = false }

        do {
            try await authService.resetPassword(email: email)
            return true
        } catch {
            authError = error.localizedDescription
            return false
        }
    }

    func verifyOTP(email: String, token: String) async -> Bool {
        isLoading = true
        authError = nil
        defer { isLoading = false }

        do {
            try await authService.verifyOTP(email: email, token: token)
            return true
        } catch {
            authError = error.localizedDescription
            return false
        }
    }

    func updatePassword(newPassword: String) async -> Bool {
        isLoading = true
        authError = nil
        defer { isLoading = false }

        do {
            try await authService.updatePassword(newPassword: newPassword)
            return true
        } catch {
            authError = error.localizedDescription
            return false
        }
    }
}
