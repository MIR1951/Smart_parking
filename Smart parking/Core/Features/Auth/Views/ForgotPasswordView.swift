//
//  ForgotPasswordView.swift
//  Smart parking
//
//  Created by Smart Parking on 11/02/26.
//

import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthManager.self) private var authManager
    @Environment(LocalizationManager.self) private var loc
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Steps
    enum Step: Int, CaseIterable {
        case email = 0
        case otp = 1
        case newPassword = 2
    }

    @State private var currentStep: Step = .email
    @State private var email = ""
    @State private var otpCode = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isPasswordVisible = false
    @State private var isConfirmVisible = false
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    @State private var appeared = false

    // Validation touched states
    @State private var emailTouched = false
    @State private var otpTouched = false
    @State private var passwordTouched = false
    @State private var confirmTouched = false

    // Timer for resend
    @State private var resendCountdown = 0
    @State private var resendTimer: Timer?

    // MARK: - Adaptive Colors
    private var bgGradientColors: [Color] {
        colorScheme == .dark
            ? [Color(hex: "#020617"), Color(hex: "#0C1929"), Color(hex: "#0F293E")]
            : [Color(hex: "#F0F9FF"), Color(hex: "#E0F2FE"), Color(hex: "#BAE6FD")]
    }

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

    // MARK: - Validation
    private var emailError: String? {
        guard emailTouched else { return nil }
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return loc.str(.valEmailRequired) }
        if !trimmed.contains("@") || !trimmed.contains(".") { return loc.str(.valEmailInvalid) }
        return nil
    }

    private var otpError: String? {
        guard otpTouched else { return nil }
        if otpCode.isEmpty { return loc.str(.valCodeRequired) }
        if otpCode.count < 8 { return loc.str(.valCodeLength) }
        return nil
    }

    private var passwordError: String? {
        guard passwordTouched else { return nil }
        if newPassword.isEmpty { return loc.str(.valPasswordRequired) }
        if newPassword.count < 6 { return loc.str(.valPasswordMin) }
        return nil
    }

    private var confirmError: String? {
        guard confirmTouched else { return nil }
        if confirmPassword.isEmpty { return loc.str(.valConfirmRequired) }
        if confirmPassword != newPassword { return loc.str(.valPasswordMismatch) }
        return nil
    }

    private var isEmailValid: Bool {
        let t = email.trimmingCharacters(in: .whitespacesAndNewlines)
        return !t.isEmpty && t.contains("@") && t.contains(".")
    }

    private var isOTPValid: Bool { otpCode.count == 8 }

    private var isPasswordValid: Bool {
        newPassword.count >= 6 && newPassword == confirmPassword
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            // Adaptive gradient background
            LinearGradient(
                colors: bgGradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Animated orbs
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            AppTheme.Palette.brand.opacity(colorScheme == .dark ? 0.20 : 0.10),
                            .clear,
                        ],
                        center: .center, startRadius: 20, endRadius: 160
                    )
                )
                .frame(width: 320, height: 320)
                .offset(x: -80, y: -200)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "#00CEC9").opacity(colorScheme == .dark ? 0.12 : 0.08),
                            .clear,
                        ],
                        center: .center, startRadius: 20, endRadius: 140
                    )
                )
                .frame(width: 280, height: 280)
                .offset(x: 100, y: 250)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                        .offset(y: appeared ? 0 : 20)
                        .opacity(appeared ? 1 : 0)

                    // Step indicator
                    stepIndicator

                    // Current step content
                    Group {
                        switch currentStep {
                        case .email:
                            emailStep
                        case .otp:
                            otpStep
                        case .newPassword:
                            newPasswordStep
                        }
                    }
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        )
                    )
                    .offset(y: appeared ? 0 : 30)
                    .opacity(appeared ? 1 : 0)
                }
                .padding(.horizontal, 22)
                .padding(.vertical)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.78).delay(0.1)) {
                appeared = true
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    if currentStep == .email {
                        dismiss()
                    } else {
                        withAnimation(AppTheme.Anim.smooth) {
                            currentStep = Step(rawValue: currentStep.rawValue - 1) ?? .email
                        }
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundColor(primaryText)
                        .frame(width: 36, height: 36)
                        .background(inputBg)
                        .clipShape(Circle())
                }
            }
        }
        .alert(loc.str(.forgotSuccessTitle), isPresented: $showSuccessAlert) {
            Button(loc.str(.forgotGoToLogin)) { dismiss() }
        } message: {
            Text(loc.str(.forgotSuccessMessage))
        }
        .alert(loc.str(.forgotErrorTitle), isPresented: $showErrorAlert) {
            Button(loc.str(.ok)) { authManager.clearAuthError() }
        } message: {
            Text(authManager.authError ?? loc.str(.error))
        }
        .onChange(of: authManager.authError) { _, newValue in
            if newValue != nil { showErrorAlert = true }
        }
        .onDisappear {
            resendTimer?.invalidate()
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 12) {
            // Glass icon circle
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
                                    colors: [primaryText.opacity(0.3), primaryText.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )

                Image(
                    systemName: currentStep == .newPassword
                        ? "lock.rotation"
                        : currentStep == .otp ? "envelope.badge.shield.half.filled" : "key.fill"
                )
                .font(.system(size: 32))
                .foregroundStyle(
                    LinearGradient(
                        colors: [primaryText, accentColor],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .contentTransition(.symbolEffect(.replace))
            }
            .shadow(color: AppTheme.Palette.brand.opacity(0.4), radius: 20, y: 8)
            .padding(.top, 20)

            Text(stepTitle)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(primaryText)

            Text(stepSubtitle)
                .font(.subheadline)
                .foregroundColor(secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    private var stepTitle: String {
        switch currentStep {
        case .email: return loc.str(.forgotTitle)
        case .otp: return loc.str(.forgotCodeTitle)
        case .newPassword: return loc.str(.forgotNewPassTitle)
        }
    }

    private var stepSubtitle: String {
        switch currentStep {
        case .email: return loc.str(.forgotSubtitle)
        case .otp: return "\(email) — \(loc.str(.forgotCodeSubtitle))"
        case .newPassword: return loc.str(.forgotNewPassSubtitle)
        }
    }

    // MARK: - Step Indicator
    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(Step.allCases, id: \.rawValue) { step in
                Capsule()
                    .fill(
                        step.rawValue <= currentStep.rawValue
                            ? LinearGradient(
                                colors: [AppTheme.Palette.brand, AppTheme.Palette.brandLight],
                                startPoint: .leading, endPoint: .trailing
                            )
                            : LinearGradient(
                                colors: [secondaryText.opacity(0.2), secondaryText.opacity(0.2)],
                                startPoint: .leading, endPoint: .trailing
                            )
                    )
                    .frame(height: 4)
                    .animation(AppTheme.Anim.smooth, value: currentStep)
            }
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Step 1: Email
    private var emailStep: some View {
        VStack(spacing: 18) {
            // Glass card
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
                        .onSubmit { emailTouched = true }
                }
                .padding(14)
                .background(inputBg)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(inputBorder, lineWidth: 1)
                )

                if let error = emailError {
                    Text(error)
                        .font(.caption2)
                        .foregroundColor(AppTheme.Palette.danger)
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
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )

            // Button
            Button {
                sendResetCode()
            } label: {
                HStack(spacing: 10) {
                    if authManager.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text(loc.str(.forgotSendCode))
                            .fontWeight(.semibold)
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 14))
                    }
                }
                .font(AppTheme.Typography.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: isEmailValid && !authManager.isLoading
                            ? [AppTheme.Palette.brand, AppTheme.Palette.brandLight]
                            : [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(
                    color: isEmailValid ? AppTheme.Palette.brand.opacity(0.4) : .clear,
                    radius: 16, y: 6
                )
            }
            .disabled(!isEmailValid || authManager.isLoading)
            .pressStyle()
        }
    }

    // MARK: - Step 2: OTP
    private var otpStep: some View {
        VStack(spacing: 18) {
            VStack(spacing: 16) {
                otpInputSection
            }
            .padding(22)
            .background(cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: cardBorderColors,
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )

            Button {
                verifyCode()
            } label: {
                HStack(spacing: 10) {
                    if authManager.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text(loc.str(.forgotVerify))
                            .fontWeight(.semibold)
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 14))
                    }
                }
                .font(AppTheme.Typography.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: isOTPValid && !authManager.isLoading
                            ? [AppTheme.Palette.brand, AppTheme.Palette.brandLight]
                            : [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(
                    color: isOTPValid ? AppTheme.Palette.brand.opacity(0.4) : .clear,
                    radius: 16, y: 6
                )
            }
            .disabled(!isOTPValid || authManager.isLoading)
            .pressStyle()

            HStack {
                if resendCountdown > 0 {
                    Text("\(loc.str(.forgotResendIn)) (\(resendCountdown)s)")
                        .font(.footnote)
                        .foregroundColor(secondaryText)
                } else {
                    Button(loc.str(.forgotResendCode)) { resendCode() }
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(accentColor)
                }
            }
            .padding(.top, 4)
        }
    }

    // MARK: - OTP Input
    private var otpInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(loc.str(.forgotConfirmCode))
                .font(.subheadline.weight(.medium))
                .foregroundColor(primaryText)

            HStack(spacing: 6) {
                ForEach(0..<8, id: \.self) { index in
                    let char =
                        index < otpCode.count
                        ? String(otpCode[otpCode.index(otpCode.startIndex, offsetBy: index)])
                        : ""

                    Text(char)
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(primaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(inputBg)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(
                                    index < otpCode.count
                                        ? inputFocusBorder
                                        : inputBorder,
                                    lineWidth: index < otpCode.count ? 1.5 : 1
                                )
                        )
                        .scaleEffect(index < otpCode.count ? 1.05 : 1.0)
                        .animation(AppTheme.Anim.smooth, value: otpCode)
                }
            }
            .overlay {
                TextField("", text: $otpCode)
                    .keyboardType(.numberPad)
                    .foregroundColor(.clear)
                    .tint(.clear)
                    .onChange(of: otpCode) { _, newValue in
                        let filtered = String(newValue.filter { $0.isNumber }.prefix(8))
                        if filtered != newValue { otpCode = filtered }
                    }
            }

            if let error = otpError {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption2)
                    Text(error)
                        .font(.caption)
                }
                .foregroundColor(AppTheme.Palette.danger)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(AppTheme.Anim.smooth, value: otpError)
    }

    // MARK: - Step 3: New Password
    private var newPasswordStep: some View {
        VStack(spacing: 18) {
            VStack(spacing: 16) {
                // New password
                VStack(alignment: .leading, spacing: 6) {
                    Text(loc.str(.forgotNewPassword))
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(secondaryText)

                    HStack(spacing: 12) {
                        Image(systemName: "lock.fill")
                            .foregroundColor(accentColor)
                            .font(.system(size: 15))

                        if isPasswordVisible {
                            TextField(loc.str(.forgotMinChars), text: $newPassword)
                                .foregroundColor(primaryText)
                                .tint(accentColor)
                                .onSubmit { passwordTouched = true }
                        } else {
                            SecureField(loc.str(.forgotMinChars), text: $newPassword)
                                .foregroundColor(primaryText)
                                .tint(accentColor)
                                .onSubmit { passwordTouched = true }
                        }

                        Button {
                            isPasswordVisible.toggle()
                        } label: {
                            Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(secondaryText)
                                .font(.system(size: 14))
                        }
                    }
                    .padding(14)
                    .background(inputBg)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(inputBorder, lineWidth: 1)
                    )

                    if let error = passwordError {
                        Text(error)
                            .font(.caption2)
                            .foregroundColor(AppTheme.Palette.danger)
                    }
                }

                // Confirm password
                VStack(alignment: .leading, spacing: 6) {
                    Text(loc.str(.forgotConfirmPassword))
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(secondaryText)

                    HStack(spacing: 12) {
                        Image(systemName: "lock.rotation")
                            .foregroundColor(accentColor)
                            .font(.system(size: 15))

                        if isConfirmVisible {
                            TextField(loc.str(.forgotConfirmPassword), text: $confirmPassword)
                                .foregroundColor(primaryText)
                                .tint(accentColor)
                                .onSubmit { confirmTouched = true }
                        } else {
                            SecureField(loc.str(.forgotConfirmPassword), text: $confirmPassword)
                                .foregroundColor(primaryText)
                                .tint(accentColor)
                                .onSubmit { confirmTouched = true }
                        }

                        Button {
                            isConfirmVisible.toggle()
                        } label: {
                            Image(systemName: isConfirmVisible ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(secondaryText)
                                .font(.system(size: 14))
                        }
                    }
                    .padding(14)
                    .background(inputBg)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(inputBorder, lineWidth: 1)
                    )

                    if let error = confirmError {
                        Text(error)
                            .font(.caption2)
                            .foregroundColor(AppTheme.Palette.danger)
                    }
                }

                if !newPassword.isEmpty {
                    passwordStrengthBar
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
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )

            Button {
                updatePassword()
            } label: {
                HStack(spacing: 10) {
                    if authManager.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text(loc.str(.forgotUpdatePassword))
                            .fontWeight(.semibold)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                    }
                }
                .font(AppTheme.Typography.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: isPasswordValid && !authManager.isLoading
                            ? [AppTheme.Palette.brand, AppTheme.Palette.brandLight]
                            : [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(
                    color: isPasswordValid ? AppTheme.Palette.brand.opacity(0.4) : .clear,
                    radius: 16, y: 6
                )
            }
            .disabled(!isPasswordValid || authManager.isLoading)
            .pressStyle()
        }
    }

    // MARK: - Password Strength
    private var passwordStrengthBar: some View {
        let strength = passwordStrength
        return VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(secondaryText.opacity(0.15))
                        .frame(height: 4)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [strength.color, strength.color.opacity(0.7)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * strength.progress, height: 4)
                        .animation(AppTheme.Anim.smooth, value: newPassword)
                }
            }
            .frame(height: 4)

            Text(strength.label)
                .font(.caption)
                .foregroundColor(strength.color)
        }
        .padding(.horizontal, 2)
    }

    private var passwordStrength: (label: String, color: Color, progress: CGFloat) {
        let len = newPassword.count
        let hasUpper = newPassword.rangeOfCharacter(from: .uppercaseLetters) != nil
        let hasDigit = newPassword.rangeOfCharacter(from: .decimalDigits) != nil
        let hasSpecial =
            newPassword.rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) != nil

        var score = 0
        if len >= 6 { score += 1 }
        if len >= 8 { score += 1 }
        if hasUpper { score += 1 }
        if hasDigit { score += 1 }
        if hasSpecial { score += 1 }

        switch score {
        case 0...1: return (loc.str(.strengthWeak), AppTheme.Palette.danger, 0.2)
        case 2: return (loc.str(.strengthFair), Color.orange, 0.4)
        case 3: return (loc.str(.strengthGood), Color(hex: "#FDCB6E"), 0.6)
        case 4: return (loc.str(.strengthStrong), AppTheme.Palette.success, 0.8)
        default: return (loc.str(.strengthVeryStrong), AppTheme.Palette.success, 1.0)
        }
    }

    // MARK: - Actions
    private func sendResetCode() {
        emailTouched = true
        guard isEmailValid else { return }

        Task {
            let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
            let success = await authManager.resetPassword(email: trimmedEmail)
            if success {
                withAnimation(AppTheme.Anim.smooth) {
                    currentStep = .otp
                }
                startResendTimer()
            }
        }
    }

    private func verifyCode() {
        otpTouched = true
        guard isOTPValid else { return }

        Task {
            let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
            let success = await authManager.verifyOTP(email: trimmedEmail, token: otpCode)
            if success {
                withAnimation(AppTheme.Anim.smooth) {
                    currentStep = .newPassword
                }
            }
        }
    }

    private func updatePassword() {
        passwordTouched = true
        confirmTouched = true
        guard isPasswordValid else { return }

        Task {
            let success = await authManager.updatePassword(newPassword: newPassword)
            if success {
                showSuccessAlert = true
            }
        }
    }

    private func resendCode() {
        Task {
            let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
            let success = await authManager.resetPassword(email: trimmedEmail)
            if success {
                startResendTimer()
            }
        }
    }

    private func startResendTimer() {
        resendCountdown = 60
        resendTimer?.invalidate()
        resendTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                if resendCountdown > 0 {
                    resendCountdown -= 1
                } else {
                    resendTimer?.invalidate()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ForgotPasswordView()
            .environment(AuthManager())
    }
}
