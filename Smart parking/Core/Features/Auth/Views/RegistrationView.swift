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
    @Environment(\.colorScheme) private var colorScheme
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
    @State private var appeared = false
    @State private var shakeFields = false

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

    // MARK: - Adaptive Colors
    private var primaryText: Color { AppTheme.Palette.textPrimary }
    private var secondaryText: Color { AppTheme.Palette.textSecondary }
    private var accentColor: Color { AppTheme.Palette.brandLight }

    private var inputBg: Color {
        colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04)
    }

    private var inputBorder: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.08)
    }

    private var inputFocusBorder: Color {
        AppTheme.Palette.brand.opacity(0.6)
    }

    private var cardBg: Color {
        colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.7)
    }

    private var cardBorderColors: [Color] {
        colorScheme == .dark
            ? [.white.opacity(0.12), .white.opacity(0.03)]
            : [.white.opacity(0.8), .white.opacity(0.3)]
    }

    var body: some View {
        ZStack {
            AppAnimatedBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Title
                    VStack(spacing: 8) {
                        Text(loc.str(.registerTitle))
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(primaryText)

                        Text(loc.str(.registerSubtitle))
                            .font(.subheadline)
                            .foregroundColor(secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    .offset(y: appeared ? 0 : 20)
                    .opacity(appeared ? 1 : 0)

                    // Glass form card
                    VStack(spacing: 16) {
                        // Name field
                        authInputField(
                            title: loc.str(.registerName),
                            placeholder: loc.str(.registerNamePlaceholder),
                            text: $username,
                            icon: "person.fill",
                            isFocused: focusedField == .name,
                            error: nameError
                        )
                        .focused($focusedField, equals: .name)
                        .onChange(of: focusedField) { oldValue, newValue in
                            if oldValue == .name && newValue != .name { nameTouched = true }
                        }
                        .textInputAutocapitalization(.words)

                        // Email field
                        authInputField(
                            title: loc.str(.loginEmail),
                            placeholder: loc.str(.loginEmailPlaceholder),
                            text: $email,
                            icon: "envelope.fill",
                            isFocused: focusedField == .email,
                            error: emailError
                        )
                        .focused($focusedField, equals: .email)
                        .onChange(of: focusedField) { oldValue, newValue in
                            if oldValue == .email && newValue != .email { emailTouched = true }
                        }
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)

                        // Password field
                        VStack(alignment: .leading, spacing: 6) {
                            Text(loc.str(.loginPassword))
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(secondaryText)

                            HStack(spacing: 12) {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(accentColor)
                                    .font(.system(size: 15))

                                if isPasswordVisible {
                                    TextField(loc.str(.loginPasswordPlaceholder), text: $password)
                                        .foregroundColor(primaryText)
                                        .tint(accentColor)
                                        .focused($focusedField, equals: .password)
                                } else {
                                    SecureField(loc.str(.loginPasswordPlaceholder), text: $password)
                                        .foregroundColor(primaryText)
                                        .tint(accentColor)
                                        .focused($focusedField, equals: .password)
                                }

                                Button {
                                    isPasswordVisible.toggle()
                                } label: {
                                    Image(
                                        systemName: isPasswordVisible
                                            ? "eye.slash.fill" : "eye.fill"
                                    )
                                    .foregroundColor(secondaryText)
                                    .font(.system(size: 14))
                                }
                            }
                            .padding(14)
                            .background(inputBg)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(
                                        focusedField == .password
                                            ? inputFocusBorder
                                            : inputBorder,
                                        lineWidth: 1
                                    )
                            )

                            if let error = passwordError {
                                Text(error)
                                    .font(.caption2)
                                    .foregroundColor(AppTheme.Palette.danger)
                            }
                        }

                        // Terms checkbox
                        HStack(spacing: 10) {
                            Toggle("", isOn: $agreedToTerms)
                                .labelsHidden()
                                .toggleStyle(CheckboxToggleStyle())

                            Text(loc.str(.registerAgreeWith))
                                .foregroundColor(secondaryText)
                                .font(.footnote)

                            Button(loc.str(.registerTerms)) {
                                showInfo(loc.str(.profileComingSoon))
                            }
                            .foregroundColor(accentColor)
                            .fontWeight(.semibold)
                            .font(.footnote)

                            Spacer()
                        }
                    }
                    .padding(22)
                    .background(cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: cardBorderColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .offset(y: appeared ? 0 : 30)
                    .opacity(appeared ? 1 : 0)
                    .shakeEffect(trigger: shakeFields)

                    // Sign Up button
                    Button {
                        signUp()
                    } label: {
                        HStack(spacing: 10) {
                            if authManager.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text(loc.str(.registerSignUp))
                                    .fontWeight(.semibold)
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                        }
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: isValidForm && !authManager.isLoading
                                    ? [AppTheme.Palette.brand, AppTheme.Palette.brandLight]
                                    : [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(
                            color: isValidForm ? AppTheme.Palette.brand.opacity(0.4) : .clear,
                            radius: 16, y: 6
                        )
                    }
                    .disabled(!isValidForm || authManager.isLoading)
                    .pressStyle()

                    // Divider
                    HStack(spacing: 14) {
                        Rectangle().fill(secondaryText.opacity(0.2)).frame(height: 1)
                        Text(loc.str(.loginOrWith))
                            .font(.caption)
                            .foregroundColor(secondaryText)
                        Rectangle().fill(secondaryText.opacity(0.2)).frame(height: 1)
                    }

                    HStack(spacing: 20) {
                        socialButton("applelogo")
                        socialButton("google")
                        socialButton("facebook")
                    }

                    HStack(spacing: 4) {
                        Text(loc.str(.registerHaveAccount))
                            .foregroundColor(secondaryText)
                        Button(loc.str(.registerSignIn)) { dismiss() }
                            .foregroundColor(accentColor)
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 28)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.78).delay(0.1)) {
                appeared = true
            }
        }
        .onChange(of: authManager.authError) { _, newValue in
            showAuthError = newValue != nil
        }
        .alert(loc.str(.registerErrorTitle), isPresented: $showAuthError) {
            Button(loc.str(.ok)) { authManager.clearAuthError() }
        } message: {
            Text(authManager.authError ?? loc.str(.error))
        }
        .alert(loc.str(.info), isPresented: $showInfoAlert) {
            Button(loc.str(.ok)) {}
        } message: {
            Text(infoMessage)
        }
    }

    // Reusable auth input field
    @ViewBuilder
    private func authInputField(
        title: String,
        placeholder: String,
        text: Binding<String>,
        icon: String,
        isFocused: Bool,
        error: String?
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundColor(secondaryText)

            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(accentColor)
                    .font(.system(size: 15))

                TextField(placeholder, text: text)
                    .autocorrectionDisabled()
                    .foregroundColor(primaryText)
                    .tint(accentColor)
            }
            .padding(14)
            .background(inputBg)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        isFocused
                            ? inputFocusBorder
                            : inputBorder,
                        lineWidth: 1
                    )
            )

            if let error {
                Text(error)
                    .font(.caption2)
                    .foregroundColor(AppTheme.Palette.danger)
            }
        }
    }
}

// Checkbox style
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .foregroundColor(
                    configuration.isOn ? AppTheme.Palette.brand : AppTheme.Palette.textTertiary
                )
                .font(.title2)
        }
    }
}

extension RegistrationView {
    fileprivate func signUp() {
        nameTouched = true
        emailTouched = true
        passwordTouched = true
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard
            !trimmedUsername.isEmpty,
            !trimmedEmail.isEmpty,
            password.count >= 6,
            agreedToTerms,
            !authManager.isLoading
        else {
            AppTheme.Haptic.error()
            shakeFields.toggle()
            return
        }

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
            //SocialSignInButton(imageName: imageName)
        }
        .buttonStyle(.plain)
        .pressStyle()
    }
}

#Preview {
    RegistrationView()
        .environment(AuthManager())
}
