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
    @State private var appeared = false

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
                // Premium gradient background
                LinearGradient(
                    colors: [
                        Color(hex: "#0D0D1F"),
                        Color(hex: "#161630"),
                        Color(hex: "#1A1545"),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Animated orbs
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "#6C5CE7").opacity(0.25), .clear],
                            center: .center, startRadius: 20, endRadius: 180
                        )
                    )
                    .frame(width: 350, height: 350)
                    .offset(x: -100, y: -200)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "#00CEC9").opacity(0.12), .clear],
                            center: .center, startRadius: 20, endRadius: 150
                        )
                    )
                    .frame(width: 300, height: 300)
                    .offset(x: 120, y: 250)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        // App Icon
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: "#6C5CE7").opacity(0.3),
                                            Color(hex: "#6C5CE7").opacity(0.1),
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
                                                    .white.opacity(0.3), .white.opacity(0.05),
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
                                        colors: [.white, Color(hex: "#A29BFE")],
                                        startPoint: .top, endPoint: .bottom
                                    )
                                )
                        }
                        .shadow(color: Color(hex: "#6C5CE7").opacity(0.4), radius: 20, y: 8)
                        .padding(.top, 50)
                        .scaleEffect(appeared ? 1 : 0.5)
                        .opacity(appeared ? 1 : 0)

                        // Title
                        VStack(spacing: 8) {
                            Text(loc.str(.loginTitle))
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)

                            Text(loc.str(.loginSubtitle))
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .offset(y: appeared ? 0 : 20)
                        .opacity(appeared ? 1 : 0)

                        // Glass form card
                        VStack(spacing: 18) {
                            // Email field
                            VStack(alignment: .leading, spacing: 6) {
                                Text(loc.str(.loginEmail))
                                    .font(AppTheme.Typography.caption)
                                    .foregroundColor(.white.opacity(0.6))

                                HStack(spacing: 12) {
                                    Image(systemName: "envelope.fill")
                                        .foregroundColor(Color(hex: "#A29BFE"))
                                        .font(.system(size: 15))

                                    TextField(loc.str(.loginEmailPlaceholder), text: $email)
                                        .autocorrectionDisabled()
                                        .textInputAutocapitalization(.never)
                                        .keyboardType(.emailAddress)
                                        .foregroundColor(.white)
                                        .tint(Color(hex: "#A29BFE"))
                                        .focused($focusedField, equals: .email)
                                        .onChange(of: focusedField) { _, newValue in
                                            if newValue != .email { emailTouched = true }
                                        }
                                }
                                .padding(14)
                                .background(Color.white.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(
                                            focusedField == .email
                                                ? Color(hex: "#6C5CE7").opacity(0.6)
                                                : Color.white.opacity(0.08),
                                            lineWidth: 1
                                        )
                                )

                                if let error = emailError {
                                    Text(error)
                                        .font(.caption2)
                                        .foregroundColor(Color(hex: "#FF7675"))
                                }
                            }

                            // Password field
                            VStack(alignment: .leading, spacing: 6) {
                                Text(loc.str(.loginPassword))
                                    .font(AppTheme.Typography.caption)
                                    .foregroundColor(.white.opacity(0.6))

                                HStack(spacing: 12) {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(Color(hex: "#A29BFE"))
                                        .font(.system(size: 15))

                                    if isPasswordVisible {
                                        TextField(
                                            loc.str(.loginPasswordPlaceholder), text: $password
                                        )
                                        .foregroundColor(.white)
                                        .tint(Color(hex: "#A29BFE"))
                                        .focused($focusedField, equals: .password)
                                        .onChange(of: focusedField) { _, newValue in
                                            if newValue != .password { passwordTouched = true }
                                        }
                                    } else {
                                        SecureField(
                                            loc.str(.loginPasswordPlaceholder), text: $password
                                        )
                                        .foregroundColor(.white)
                                        .tint(Color(hex: "#A29BFE"))
                                        .focused($focusedField, equals: .password)
                                        .onChange(of: focusedField) { _, newValue in
                                            if newValue != .password { passwordTouched = true }
                                        }
                                    }

                                    Button {
                                        isPasswordVisible.toggle()
                                    } label: {
                                        Image(
                                            systemName: isPasswordVisible
                                                ? "eye.slash.fill" : "eye.fill"
                                        )
                                        .foregroundColor(.white.opacity(0.4))
                                        .font(.system(size: 14))
                                    }
                                }
                                .padding(14)
                                .background(Color.white.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(
                                            focusedField == .password
                                                ? Color(hex: "#6C5CE7").opacity(0.6)
                                                : Color.white.opacity(0.08),
                                            lineWidth: 1
                                        )
                                )

                                if let error = passwordError {
                                    Text(error)
                                        .font(.caption2)
                                        .foregroundColor(Color(hex: "#FF7675"))
                                }
                            }

                            HStack {
                                Spacer()
                                NavigationLink(loc.str(.loginForgotPassword)) {
                                    ForgotPasswordView()
                                }
                                .font(.footnote)
                                .foregroundColor(Color(hex: "#A29BFE"))
                            }
                        }
                        .padding(22)
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [.white.opacity(0.12), .white.opacity(0.03)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .offset(y: appeared ? 0 : 30)
                        .opacity(appeared ? 1 : 0)

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
                                        ? [Color(hex: "#6C5CE7"), Color(hex: "#A29BFE")]
                                        : [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(
                                color: isValidCredentials
                                    ? Color(hex: "#6C5CE7").opacity(0.4)
                                    : .clear,
                                radius: 16,
                                y: 6
                            )
                        }
                        .disabled(!isValidCredentials || authManager.isLoading)
                        .pressStyle()

                        // Divider
                        HStack(spacing: 14) {
                            Rectangle()
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 1)
                            Text(loc.str(.loginOrWith))
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.4))
                            Rectangle()
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 1)
                        }

                        // Social buttons
                        HStack(spacing: 20) {
                            socialButton("applelogo")
                            socialButton("google")
                            socialButton("facebook")
                        }

                        // Sign up link
                        NavigationLink {
                            RegistrationView()
                                .navigationBarBackButtonHidden()
                        } label: {
                            HStack(spacing: 4) {
                                Text(loc.str(.loginNoAccount))
                                    .foregroundColor(.white.opacity(0.5))
                                Text(loc.str(.loginSignUp))
                                    .foregroundColor(Color(hex: "#A29BFE"))
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
            .alert(loc.str(.info), isPresented: $showInfoAlert) {
                Button(loc.str(.ok)) {}
            } message: {
                Text(infoMessage)
            }
        }
    }
}

// Social sign-in button (glassmorphism style)
struct SocialSignInButton: View {
    let imageName: String

    var body: some View {
        Group {
            if imageName == "applelogo" {
                Image(systemName: imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(.white)
            } else if imageName == "google" {
                Text("G")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(hex: "#EA4335"), Color(hex: "#4285F4"), Color(hex: "#34A853"),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            } else if imageName == "facebook" {
                Text("f")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#4285F4"))
            } else {
                Text(imageName.prefix(1).uppercased())
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
        }
        .frame(width: 56, height: 56)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
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
        .pressStyle()
    }
}

#Preview {
    LoginView()
        .environment(AuthManager())
}
