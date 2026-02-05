//
//  LoginView.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 02/12/25.
//

 import SwiftUI

struct LoginView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isPasswordVisible: Bool = false
    @State private var showAuthError = false
    @State private var showInfoAlert = false
    @State private var infoMessage = ""

    private var isValidCredentials: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && password.count >= 6
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Palette.pageBackground
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppTheme.Spacing.xLarge) {
                        VStack(spacing: AppTheme.Spacing.small) {
                            Text("Sign In")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(AppTheme.Palette.textPrimary)
                            Text("Hi! Welcome back, you've been missed")
                                .foregroundColor(AppTheme.Palette.textSecondary)
                        }
                        .padding(.top, 28)

                        VStack(spacing: AppTheme.Spacing.medium) {
                            AppInputField(
                                title: "Email",
                                placeholder: "example@gmail.com",
                                text: $email,
                                keyboardType: .emailAddress,
                                autocapitalization: .never
                            )

                            AppInputField(
                                title: "Password",
                                placeholder: "**********",
                                text: $password,
                                isSecure: true,
                                revealSecureText: $isPasswordVisible
                            )

                            HStack {
                                Spacer()
                                Button("Forgot Password?") {
                                    forgotPassword()
                                }
                                .font(.footnote)
                                .foregroundColor(AppTheme.Palette.brand)
                            }
                        }

                        AppPrimaryButton(
                            title: authManager.isLoading ? "Signing In..." : "Sign In",
                            isLoading: authManager.isLoading,
                            isEnabled: isValidCredentials && !authManager.isLoading
                        ) {
                            signIn()
                        }

                        VStack(spacing: AppTheme.Spacing.large) {
                            HStack(spacing: AppTheme.Spacing.small) {
                                Rectangle()
                                    .fill(AppTheme.Palette.border)
                                    .frame(height: 1)
                                Text("Or sign in with")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.Palette.textSecondary)
                                Rectangle()
                                    .fill(AppTheme.Palette.border)
                                    .frame(height: 1)
                            }

                            HStack(spacing: 28) {
                                socialButton("applelogo")
                                socialButton("google")
                                socialButton("facebook")
                            }
                        }

                        NavigationLink {
                            RegistrationView()
                                .navigationBarBackButtonHidden()
                        } label: {
                            HStack(spacing: 4) {
                                Text("Don't have an account?")
                                    .foregroundColor(AppTheme.Palette.textSecondary)
                                Text("Sign Up")
                                    .foregroundColor(AppTheme.Palette.brand)
                                    .fontWeight(.semibold)
                            }
                            .font(.subheadline)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 28)
                }
            }
            .onChange(of: authManager.authError) { _, newValue in
                showAuthError = newValue != nil
            }
            .alert("Sign In Error", isPresented: $showAuthError) {
                Button("OK") {
                    authManager.clearAuthError()
                }
            } message: {
                Text(authManager.authError ?? "Unknown error")
            }
            .alert("Info", isPresented: $showInfoAlert) {
                Button("OK") {}
            } message: {
                Text(infoMessage)
            }
        }
    }
}

// Ijtimoiy tarmoq tugmalari uchun yordamchi struct (rasmlar SF Symbols orqali shartli ravishda berilgan)
struct SocialSignInButton: View {
    var imageName: String
    
    var body: some View {
        // Haqiqiy ilovada Apple, Google, Facebook logotiplari alohida rasm resurslari sifatida yuklanadi.
        // Bu erda namuna sifatida SF Symbols ishlatilgan.
        if imageName == "applelogo" {
            Image(systemName: imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .frame(width: 52, height: 52)
                .background(AppTheme.Palette.surface)
                .clipShape(Circle())
                .overlay(Circle().stroke(AppTheme.Palette.border, lineWidth: 1))
        } else {
            // Google va Facebook logolari uchun joy egasi
            Text(imageName.prefix(1).uppercased())
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.Palette.textPrimary)
                .frame(width: 52, height: 52)
                .background(AppTheme.Palette.surface)
                .clipShape(Circle())
                .overlay(Circle().stroke(AppTheme.Palette.border, lineWidth: 1))
        }
    }
}
private extension LoginView {
    func signIn(){
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty, password.count >= 6, !authManager.isLoading else { return }

        Task{
            await authManager.signIn(email: trimmedEmail, password: password)
        }
    }

    func forgotPassword() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else {
            showInfo("Avval email kiriting.")
            return
        }

        Task {
            let didSend = await authManager.resetPassword(email: trimmedEmail)
            if didSend {
                showInfo("Parolni tiklash havolasi emailingizga yuborildi.")
            }
        }
    }

    func showInfo(_ message: String) {
        infoMessage = message
        showInfoAlert = true
    }

    @ViewBuilder
    func socialButton(_ imageName: String) -> some View {
        Button {
            showInfo("Social sign in hozircha yoqilmagan.")
        } label: {
            SocialSignInButton(imageName: imageName)
        }
        .buttonStyle(.plain)
    }
}


#Preview {
    LoginView()
        .environment(AuthManager())
}
