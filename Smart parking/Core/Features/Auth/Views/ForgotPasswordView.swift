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

    // Validation touched states
    @State private var emailTouched = false
    @State private var otpTouched = false
    @State private var passwordTouched = false
    @State private var confirmTouched = false

    // Timer for resend
    @State private var resendCountdown = 0
    @State private var resendTimer: Timer?

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
            AppAnimatedBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.Spacing.xLarge) {
                    // Header
                    headerSection

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
                        ))
                }
                .padding(.horizontal, 18)
                .padding(.vertical)
                .appReveal(0.03)
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
                        .foregroundColor(AppTheme.Palette.textPrimary)
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
        VStack(spacing: AppTheme.Spacing.small) {
            // Icon
            ZStack {
                Circle()
                    .fill(AppTheme.Palette.brand.opacity(0.12))
                    .frame(width: 80, height: 80)

                Image(
                    systemName: currentStep == .newPassword
                        ? "lock.rotation"
                        : currentStep == .otp ? "envelope.badge.shield.half.filled" : "key.fill"
                )
                .font(.system(size: 32))
                .foregroundColor(AppTheme.Palette.brand)
                .contentTransition(.symbolEffect(.replace))
            }
            .padding(.top, 20)

            Text(stepTitle)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppTheme.Palette.textPrimary)

            Text(stepSubtitle)
                .font(.subheadline)
                .foregroundColor(AppTheme.Palette.textSecondary)
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
                            ? AppTheme.Palette.brand
                            : AppTheme.Palette.border
                    )
                    .frame(height: 4)
                    .animation(AppTheme.Anim.smooth, value: currentStep)
            }
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Step 1: Email
    private var emailStep: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            AppInputField(
                title: loc.str(.loginEmail),
                placeholder: loc.str(.loginEmailPlaceholder),
                text: $email,
                keyboardType: .emailAddress,
                autocapitalization: .never,
                errorMessage: emailError
            )
            .onSubmit { emailTouched = true }

            AppPrimaryButton(
                title: authManager.isLoading ? loc.str(.forgotSending) : loc.str(.forgotSendCode),
                isLoading: authManager.isLoading,
                isEnabled: isEmailValid && !authManager.isLoading
            ) {
                sendResetCode()
            }
        }
    }

    // MARK: - Step 2: OTP
    private var otpStep: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            otpInputSection

            AppPrimaryButton(
                title: authManager.isLoading ? loc.str(.forgotVerifying) : loc.str(.forgotVerify),
                isLoading: authManager.isLoading,
                isEnabled: isOTPValid && !authManager.isLoading
            ) {
                verifyCode()
            }

            HStack {
                if resendCountdown > 0 {
                    Text("\(loc.str(.forgotResendIn)) (\(resendCountdown)s)")
                        .font(.footnote)
                        .foregroundColor(AppTheme.Palette.textSecondary)
                } else {
                    Button(loc.str(.forgotResendCode)) {
                        resendCode()
                    }
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(AppTheme.Palette.brand)
                }
            }
            .padding(.top, 4)
        }
    }

    // MARK: - OTP Input
    private var otpInputSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
            Text(loc.str(.forgotConfirmCode))
                .font(.subheadline.weight(.medium))
                .foregroundColor(AppTheme.Palette.textPrimary)

            HStack(spacing: 6) {
                ForEach(0..<8, id: \.self) { index in
                    let char =
                        index < otpCode.count
                        ? String(otpCode[otpCode.index(otpCode.startIndex, offsetBy: index)])
                        : ""

                    Text(char)
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(AppTheme.Palette.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(AppTheme.Palette.surface)
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: AppTheme.Radius.medium, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(
                                cornerRadius: AppTheme.Radius.medium, style: .continuous
                            )
                            .stroke(
                                index < otpCode.count
                                    ? AppTheme.Palette.brand
                                    : AppTheme.Palette.border,
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
                        // Only digits, max 6
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
        VStack(spacing: AppTheme.Spacing.medium) {
            AppInputField(
                title: loc.str(.forgotNewPassword),
                placeholder: loc.str(.forgotMinChars),
                text: $newPassword,
                isSecure: true,
                revealSecureText: $isPasswordVisible,
                errorMessage: passwordError
            )
            .onSubmit { passwordTouched = true }

            AppInputField(
                title: loc.str(.forgotConfirmPassword),
                placeholder: loc.str(.forgotConfirmPassword),
                text: $confirmPassword,
                isSecure: true,
                revealSecureText: $isConfirmVisible,
                errorMessage: confirmError
            )
            .onSubmit { confirmTouched = true }

            if !newPassword.isEmpty {
                passwordStrengthBar
            }

            AppPrimaryButton(
                title: authManager.isLoading
                    ? loc.str(.forgotSaving) : loc.str(.forgotUpdatePassword),
                isLoading: authManager.isLoading,
                isEnabled: isPasswordValid && !authManager.isLoading
            ) {
                updatePassword()
            }
        }
    }

    // MARK: - Password Strength
    private var passwordStrengthBar: some View {
        let strength = passwordStrength
        return VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppTheme.Palette.border.opacity(0.3))
                        .frame(height: 4)

                    Capsule()
                        .fill(strength.color)
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
        case 3: return (loc.str(.strengthGood), Color.yellow, 0.6)
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
