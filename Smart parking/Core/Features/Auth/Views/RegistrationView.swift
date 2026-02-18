//
//  RegistrationView.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 02/12/25.
//

import SwiftUI

struct RegistrationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthManager.self) private var authManager
    @Environment(LocalizationManager.self) private var loc
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var agreedToTerms: Bool = false
    @State private var isPasswordVisible: Bool = false
    @State private var showAuthError = false
    @State private var showInfoAlert = false
    @State private var infoMessage = ""
    @State private var nameTouched = false
    @State private var emailTouched = false
    @State private var passwordTouched = false
    @FocusState private var focusedField: RegField?

    private enum RegField { case name, email, password }

    private var isValidForm: Bool {
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && password.count >= 6
            && agreedToTerms
    }

    private var nameError: String? {
        guard nameTouched else { return nil }
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return loc.str(.valNameRequired) }
        if trimmed.count < 2 { return loc.str(.valNameMin) }
        return nil
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
        ZStack {
            AppAnimatedBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.Spacing.xLarge) {
                    VStack(spacing: AppTheme.Spacing.small) {
                        Text(loc.str(.registerTitle))
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(AppTheme.Palette.textPrimary)
                        Text(loc.str(.registerSubtitle))
                            .foregroundColor(AppTheme.Palette.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 28)

                    VStack(spacing: AppTheme.Spacing.medium) {
                        AppInputField(
                            title: loc.str(.registerName),
                            placeholder: loc.str(.registerNamePlaceholder),
                            text: $username,
                            keyboardType: .default,
                            autocapitalization: .words,
                            errorMessage: nameError
                        )
                        .focused($focusedField, equals: .name)
                        .onChange(of: focusedField) { _, newValue in
                            if newValue != .name { nameTouched = true }
                        }

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

                        HStack(spacing: AppTheme.Spacing.small) {
                            Toggle("", isOn: $agreedToTerms)
                                .labelsHidden()
                                .toggleStyle(CheckboxToggleStyle())

                            Text(loc.str(.registerAgreeWith))
                                .foregroundColor(AppTheme.Palette.textSecondary)

                            Button(loc.str(.registerTerms)) {
                                showInfo(loc.str(.profileComingSoon))
                            }
                            .foregroundColor(AppTheme.Palette.brand)
                            .fontWeight(.semibold)

                            Spacer()
                        }
                    }

                    AppPrimaryButton(
                        title: authManager.isLoading
                            ? loc.str(.registerSigningUp) : loc.str(.registerSignUp),
                        isLoading: authManager.isLoading,
                        isEnabled: isValidForm && !authManager.isLoading
                    ) {
                        signUp()
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

                    HStack(spacing: 4) {
                        Text(loc.str(.registerHaveAccount))
                            .foregroundColor(AppTheme.Palette.textSecondary)
                        Button(loc.str(.registerSignIn)) {
                            dismiss()
                        }
                        .foregroundColor(AppTheme.Palette.brand)
                        .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 28)
                .appReveal(0.03)
            }
        }
        .onChange(of: authManager.authError) { _, newValue in
            showAuthError = newValue != nil
        }
        .alert(loc.str(.registerErrorTitle), isPresented: $showAuthError) {
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

// Checkbox uslubini yaratish uchun yordamchi struct
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .foregroundColor(configuration.isOn ? AppTheme.Palette.brand : .gray)
                .font(.title2)
        }
    }
}

extension RegistrationView {
    fileprivate func signUp() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard
            !trimmedUsername.isEmpty,
            !trimmedEmail.isEmpty,
            password.count >= 6,
            agreedToTerms,
            !authManager.isLoading
        else { return }

        Task {
            await authManager.signUp(
                email: trimmedEmail,
                password: password,
                username: trimmedUsername
            )
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
    RegistrationView()
        .environment(AuthManager())
}
