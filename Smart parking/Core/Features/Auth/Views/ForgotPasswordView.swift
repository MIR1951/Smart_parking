import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthManager.self) private var authManager
    @Environment(LocalizationManager.self) private var loc
    @Environment(\.colorScheme) private var colorScheme

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

    @State private var emailTouched = false
    @State private var otpTouched = false
    @State private var passwordTouched = false
    @State private var confirmTouched = false

    @State private var resendCountdown = 0
    @State private var resendTimer: Timer?

    // MARK: - Styling
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

    // MARK: - Validation
    private var emailError: String? {
        guard emailTouched else { return nil }
        let t = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty { return loc.str(.valEmailRequired) }
        if !t.contains("@") || !t.contains(".") { return loc.str(.valEmailInvalid) }
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
    private var isPasswordValid: Bool { newPassword.count >= 6 && newPassword == confirmPassword }

    private var passwordStrength: (label: String, color: Color, progress: CGFloat) {
        let len = newPassword.count
        let hasUpper = newPassword.rangeOfCharacter(from: .uppercaseLetters) != nil
        let hasDigit = newPassword.rangeOfCharacter(from: .decimalDigits) != nil
        let hasSpecial = newPassword.rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) != nil
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

    // MARK: - Body
    var body: some View {
        ZStack {
            LinearGradient(colors: bgGradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            Circle()
                .fill(RadialGradient(
                    colors: [AppTheme.Palette.brand.opacity(colorScheme == .dark ? 0.20 : 0.10), .clear],
                    center: .center, startRadius: 20, endRadius: 160
                ))
                .frame(width: 320, height: 320)
                .offset(x: -80, y: -200)

            Circle()
                .fill(RadialGradient(
                    colors: [Color(hex: "#00CEC9").opacity(colorScheme == .dark ? 0.12 : 0.08), .clear],
                    center: .center, startRadius: 20, endRadius: 140
                ))
                .frame(width: 280, height: 280)
                .offset(x: 100, y: 250)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    headerSection
                        .offset(y: appeared ? 0 : 20)
                        .opacity(appeared ? 1 : 0)

                    stepIndicator

                    Group {
                        switch currentStep {
                        case .email:
                            ForgotPasswordEmailStep(
                                email: $email,
                                emailTouched: $emailTouched,
                                emailError: emailError,
                                isEmailValid: isEmailValid,
                                isLoading: authManager.isLoading,
                                onSend: sendResetCode
                            )
                        case .otp:
                            ForgotPasswordOTPStep(
                                otpCode: $otpCode,
                                otpTouched: $otpTouched,
                                otpError: otpError,
                                isOTPValid: isOTPValid,
                                isLoading: authManager.isLoading,
                                resendCountdown: resendCountdown,
                                onVerify: verifyCode,
                                onResend: resendCode
                            )
                        case .newPassword:
                            ForgotPasswordNewPasswordStep(
                                newPassword: $newPassword,
                                confirmPassword: $confirmPassword,
                                isPasswordVisible: $isPasswordVisible,
                                isConfirmVisible: $isConfirmVisible,
                                passwordTouched: $passwordTouched,
                                confirmTouched: $confirmTouched,
                                passwordError: passwordError,
                                confirmError: confirmError,
                                isPasswordValid: isPasswordValid,
                                isLoading: authManager.isLoading,
                                passwordStrength: passwordStrength,
                                onUpdate: updatePassword
                            )
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
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
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [AppTheme.Palette.brand.opacity(0.3), AppTheme.Palette.brand.opacity(0.1)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle().stroke(
                            LinearGradient(
                                colors: [primaryText.opacity(0.3), primaryText.opacity(0.05)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                    )

                Image(systemName: currentStep == .newPassword
                    ? "lock.rotation"
                    : currentStep == .otp ? "envelope.badge.shield.half.filled" : "key.fill"
                )
                .font(.system(size: 32))
                .foregroundStyle(LinearGradient(
                    colors: [primaryText, accentColor],
                    startPoint: .top, endPoint: .bottom
                ))
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

    // MARK: - Actions
    private func sendResetCode() {
        emailTouched = true
        guard isEmailValid else { return }
        Task {
            let success = await authManager.resetPassword(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            if success {
                withAnimation(AppTheme.Anim.smooth) { currentStep = .otp }
                startResendTimer()
            }
        }
    }

    private func verifyCode() {
        otpTouched = true
        guard isOTPValid else { return }
        Task {
            let success = await authManager.verifyOTP(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                token: otpCode
            )
            if success {
                withAnimation(AppTheme.Anim.smooth) { currentStep = .newPassword }
            }
        }
    }

    private func updatePassword() {
        passwordTouched = true
        confirmTouched = true
        guard isPasswordValid else { return }
        Task {
            let success = await authManager.updatePassword(newPassword: newPassword)
            if success { showSuccessAlert = true }
        }
    }

    private func resendCode() {
        Task {
            let success = await authManager.resetPassword(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            if success { startResendTimer() }
        }
    }

    private func startResendTimer() {
        resendCountdown = 60
        resendTimer?.invalidate()
        resendTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                if resendCountdown > 0 { resendCountdown -= 1 }
                else { resendTimer?.invalidate() }
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
