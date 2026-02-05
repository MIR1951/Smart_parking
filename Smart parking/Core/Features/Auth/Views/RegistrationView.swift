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
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var agreedToTerms: Bool = false
    @State private var isPasswordVisible: Bool = false
    @State private var showAuthError = false
    @State private var showInfoAlert = false
    @State private var infoMessage = ""

    private var isValidForm: Bool {
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && password.count >= 6
            && agreedToTerms
    }
    
    var body: some View {
        ZStack {
            AppTheme.Palette.pageBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.Spacing.xLarge) {
                    VStack(spacing: AppTheme.Spacing.small) {
                        Text("Create Account")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(AppTheme.Palette.textPrimary)
                        Text("Fill your information below or register with your social account.")
                            .foregroundColor(AppTheme.Palette.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 28)

                    VStack(spacing: AppTheme.Spacing.medium) {
                        AppInputField(
                            title: "Name",
                            placeholder: "Ex. John Doe",
                            text: $username,
                            keyboardType: .default,
                            autocapitalization: .words
                        )

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

                        HStack(spacing: AppTheme.Spacing.small) {
                            Toggle("", isOn: $agreedToTerms)
                                .labelsHidden()
                                .toggleStyle(CheckboxToggleStyle())

                            Text("Agree with")
                                .foregroundColor(AppTheme.Palette.textSecondary)

                            Button("Terms & Condition") {
                                showInfo("Terms sahifasi keyingi versiyada qo'shiladi.")
                            }
                            .foregroundColor(AppTheme.Palette.brand)
                            .fontWeight(.semibold)

                            Spacer()
                        }
                    }

                    AppPrimaryButton(
                        title: authManager.isLoading ? "Creating..." : "Sign Up",
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
                            Text("Or sign up with")
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
                        Text("Already have an account?")
                            .foregroundColor(AppTheme.Palette.textSecondary)
                        Button("Sign In") {
                            dismiss()
                        }
                        .foregroundColor(AppTheme.Palette.brand)
                        .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 28)
            }
        }
        .onChange(of: authManager.authError) { _, newValue in
            showAuthError = newValue != nil
        }
        .alert("Sign Up Error", isPresented: $showAuthError) {
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

private extension RegistrationView {
    func signUp(){
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

    func showInfo(_ message: String) {
        infoMessage = message
        showInfoAlert = true
    }

    @ViewBuilder
    func socialButton(_ imageName: String) -> some View {
        Button {
            showInfo("Social sign up hozircha yoqilmagan.")
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
