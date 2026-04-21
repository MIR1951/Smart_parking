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
    @Environment(\.colorScheme) private var colorScheme
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isPasswordVisible: Bool = false
    @State private var showAuthError = false
    @State private var emailTouched = false
    @State private var passwordTouched = false
    @FocusState private var focusedField: AuthField?
    @State private var appeared = false
    @State private var shakeFields = false

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

    private var inputFocusBorder: Color { AppTheme.Palette.brand.opacity(0.6) }

    private var cardBg: Color {
        colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.7)
    }

    private var cardBorderColors: [Color] {
        colorScheme == .dark
            ? [.white.opacity(0.12), .white.opacity(0.03)]
            : [.white.opacity(0.8), .white.opacity(0.3)]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppAnimatedBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        // App Icon
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            AppTheme.Palette.brand.opacity(0.3),
                                            AppTheme.Palette.brand.opacity(0.1),
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    primaryText.opacity(0.3),
                                                    primaryText.opacity(0.05),
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                )

                            Image(systemName: "car.fill")
                                .font(.system(size: 32, weight: .medium))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [primaryText, accentColor],
                                        startPoint: .top, endPoint: .bottom
                                    )
                                )
                        }
                        .shadow(color: AppTheme.Palette.brand.opacity(0.4), radius: 20, y: 8)
                        .padding(.top, 50)
                        .scaleEffect(appeared ? 1 : 0.5)
                        .opacity(appeared ? 1 : 0)

                        // Title
                        VStack(spacing: 8) {
                            Text(loc.str(.loginTitle))
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(primaryText)

                            Text(loc.str(.loginSubtitle))
                                .font(.subheadline)
                                .foregroundColor(secondaryText)
                        }
                        .offset(y: appeared ? 0 : 20)
                        .opacity(appeared ? 1 : 0)

                        // Glass form card
                        VStack(spacing: 18) {
                            // Email field
                            VStack(alignment: .leading, spacing: 6) {
                                Text(loc.str(.loginEmail))
                                    .font(AppTheme.Typography.caption)
                                    .foregroundColor(secondaryText)

                                HStack(spacing: 12) {
                                    Image(systemName: "envelope.fill")
                                        .foregroundColor(accentColor)
                                        .font(.system(size: 15))

                                    TextField(loc.str(.loginEmailPlaceholder), text: $email)
                                        .autocorrectionDisabled()
                                        .textInputAutocapitalization(.never)
                                        .keyboardType(.emailAddress)
                                        .foregroundColor(primaryText)
                                        .tint(accentColor)
                                        .focused($focusedField, equals: .email)
                                        .onChange(of: focusedField) { oldValue, newValue in
                                            if oldValue == .email && newValue != .email {
                                                emailTouched = true
                                            }
                                        }
                                }
                                .padding(14)
                                .background(inputBg)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(
                                            focusedField == .email
                                                ? inputFocusBorder
                                                : inputBorder,
                                            lineWidth: 1
                                        )
                                )

                                if let error = emailError {
                                    Text(error)
                                        .font(.caption2)
                                        .foregroundColor(AppTheme.Palette.danger)
                                }
                            }

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
                                        TextField(
                                            loc.str(.loginPasswordPlaceholder), text: $password
                                        )
                                        .foregroundColor(primaryText)
                                        .tint(accentColor)
                                        .focused($focusedField, equals: .password)
                                    } else {
                                        SecureField(
                                            loc.str(.loginPasswordPlaceholder), text: $password
                                        )
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

                            HStack {
                                Spacer()
                                NavigationLink(loc.str(.loginForgotPassword)) {
                                    ForgotPasswordView()
                                }
                                .font(.footnote)
                                .foregroundColor(accentColor)
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

                        // Sign In button
                        Button {
                            signIn()
                        } label: {
                            HStack(spacing: 10) {
                                if authManager.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text(loc.str(.loginSignIn))
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
                                    colors: isValidCredentials && !authManager.isLoading
                                        ? [AppTheme.Palette.brand, AppTheme.Palette.brandLight]
                                        : [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(
                                color: isValidCredentials
                                    ? AppTheme.Palette.brand.opacity(0.4)
                                    : .clear,
                                radius: 16,
                                y: 6
                            )
                        }
                        .disabled(!isValidCredentials || authManager.isLoading)
                        .pressStyle()

                        // Sign up link
                        NavigationLink {
                            RegistrationView()
                                .navigationBarBackButtonHidden()
                        } label: {
                            HStack(spacing: 4) {
                                Text(loc.str(.loginNoAccount))
                                    .foregroundColor(secondaryText)
                                Text(loc.str(.loginSignUp))
                                    .foregroundColor(accentColor)
                                    .fontWeight(.semibold)
                            }
                            .font(.subheadline)
                        }

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
            .alert(loc.str(.loginErrorTitle), isPresented: $showAuthError) {
                Button(loc.str(.ok)) {
                    authManager.clearAuthError()
                }
            } message: {
                Text(authManager.authError ?? loc.str(.error))
            }
        }
    }
}

extension LoginView {
    fileprivate func signIn() {
        emailTouched = true
        passwordTouched = true
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty, password.count >= 6, !authManager.isLoading else {
            AppTheme.Haptic.error()
            shakeFields.toggle()
            return
        }

        Task {
            await authManager.signIn(email: trimmedEmail, password: password)
        }
    }
}

#Preview {
    LoginView()
        .environment(AuthManager())
}
