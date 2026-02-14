//
//  LoginView.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 02/12/25.
//

import SwiftUI

struct LoginView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(LocalizationManager.self) private var loc
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isPasswordVisible: Bool = false
    @State private var showAuthError = false
    @State private var showInfoAlert = false
    @State private var infoMessage = ""
    @State private var emailTouched = false
    @State private var passwordTouched = false
    @FocusState private var focusedField: AuthField?

    private enum AuthField { case email, password }

    private var isValidCredentials: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && password.count >= 6
    }

    private var emailError: String? {
        guard emailTouched else { return nil }
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return loc.str(.valEmailRequired) }
        if !trimmed.contains("@") || !trimmed.contains(".") { return loc.str(.valEmailInvalid) }
        return nil
    }

    private var passwordError: String? {
        guard passwordTouched else { return nil }
        if password.isEmpty { return loc.str(.valPasswordRequired) }
        if password.count < 6 { return loc.str(.valPasswordMin) }
        return nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Palette.pageBackground
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppTheme.Spacing.xLarge) {
                        VStack(spacing: AppTheme.Spacing.small) {
                            Text(loc.str(.loginTitle))
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(AppTheme.Palette.textPrimary)
                            Text(loc.str(.loginSubtitle))
                                .foregroundColor(AppTheme.Palette.textSecondary)
                        }
                        .padding(.top, 28)

                        VStack(spacing: AppTheme.Spacing.medium) {
                            AppInputField(
                                title: loc.str(.loginEmail),
                                placeholder: loc.str(.loginEmailPlaceholder),
                                text: $email,
                                keyboardType: .emailAddress,
                                autocapitalization: .never,
                                errorMessage: emailError
                            )
                            .focused($focusedField, equals: .email)
                            .onChange(of: focusedField) { _, newValue in
                                if newValue != .email { emailTouched = true }
                            }

                            AppInputField(
                                title: loc.str(.loginPassword),
                                placeholder: loc.str(.loginPasswordPlaceholder),
                                text: $password,
                                isSecure: true,
                                revealSecureText: $isPasswordVisible,
                                errorMessage: passwordError
                            )
                            .focused($focusedField, equals: .password)
                            .onChange(of: focusedField) { _, newValue in
                                if newValue != .password { passwordTouched = true }
                            }

                            HStack {
                                Spacer()
                                NavigationLink(loc.str(.loginForgotPassword)) {
                                    ForgotPasswordView()
                                }
                                .font(.footnote)
                                .foregroundColor(AppTheme.Palette.brand)
                            }
                        }

                        AppPrimaryButton(
                            title: authManager.isLoading
                                ? loc.str(.loginSigningIn) : loc.str(.loginSignIn),
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
                                Text(loc.str(.loginOrWith))
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
                                Text(loc.str(.loginNoAccount))
                                    .foregroundColor(AppTheme.Palette.textSecondary)
                                Text(loc.str(.loginSignUp))
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
            .alert(loc.str(.loginErrorTitle), isPresented: $showAuthError) {
                Button(loc.str(.ok)) {
                    authManager.clearAuthError()
                }
            } message: {
                Text(authManager.authError ?? loc.str(.error))
            }
            .alert(loc.str(.info), isPresented: $showInfoAlert) {
                Button(loc.str(.ok)) {}
            } message: {
                Text(infoMessage)
            }
        }
    }
}

// Ijtimoiy tarmoq tugmalari uchun yordamchi struct (rasmlar SF Symbols orqali shartli ravishda berilgan)
struct SocialSignInButton: View {
    let imageName: String

    var body: some View {
        if imageName == "applelogo" {
            Image(systemName: imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .frame(width: 52, height: 52)
                .background(AppTheme.Palette.surface)
                .clipShape(Circle())
                .overlay(Circle().stroke(AppTheme.Palette.border, lineWidth: 1))
        } else if imageName == "google" {
            // Google logo — styled "G"
            Text("G")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(hex: "#EA4335"), Color(hex: "#4285F4"), Color(hex: "#34A853"),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 52, height: 52)
                .background(AppTheme.Palette.surface)
                .clipShape(Circle())
                .overlay(Circle().stroke(AppTheme.Palette.border, lineWidth: 1))
        } else if imageName == "facebook" {
            // Facebook logo — styled "f"
            Text("f")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: "#1877F2"))
                .frame(width: 52, height: 52)
                .background(AppTheme.Palette.surface)
                .clipShape(Circle())
                .overlay(Circle().stroke(AppTheme.Palette.border, lineWidth: 1))
        } else {
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
extension LoginView {
    fileprivate func signIn() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty, password.count >= 6, !authManager.isLoading else { return }

        Task {
            await authManager.signIn(email: trimmedEmail, password: password)
        }
    }

    fileprivate func showInfo(_ message: String) {
        infoMessage = message
        showInfoAlert = true
    }

    @ViewBuilder
    fileprivate func socialButton(_ imageName: String) -> some View {
        Button {
            showInfo(loc.str(.loginSocialDisabled))
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
