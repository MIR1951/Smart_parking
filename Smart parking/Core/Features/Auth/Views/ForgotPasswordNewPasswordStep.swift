import SwiftUI

struct ForgotPasswordNewPasswordStep: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(LocalizationManager.self) private var loc

    @Binding var newPassword: String
    @Binding var confirmPassword: String
    @Binding var isPasswordVisible: Bool
    @Binding var isConfirmVisible: Bool
    @Binding var passwordTouched: Bool
    @Binding var confirmTouched: Bool

    var passwordError: String?
    var confirmError: String?
    var isPasswordValid: Bool
    var isLoading: Bool
    var passwordStrength: (label: String, color: Color, progress: CGFloat)
    var onUpdate: () -> Void

    private var inputBg: Color {
        colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04)
    }
    private var inputBorder: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.08)
    }
    private var cardBg: Color {
        colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.7)
    }
    private var cardBorderColors: [Color] {
        colorScheme == .dark
            ? [.white.opacity(0.12), .white.opacity(0.03)]
            : [.white.opacity(0.8), .white.opacity(0.3)]
    }
    private var primaryText: Color { AppTheme.Palette.textPrimary }
    private var secondaryText: Color { AppTheme.Palette.textSecondary }
    private var accentColor: Color { AppTheme.Palette.brandLight }

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 16) {
                newPasswordField
                confirmPasswordField

                if !newPassword.isEmpty {
                    strengthBar
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

            Button(action: onUpdate) {
                HStack(spacing: 10) {
                    if isLoading {
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
                        colors: isPasswordValid && !isLoading
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
            .disabled(!isPasswordValid || isLoading)
            .pressStyle()
        }
    }

    private var newPasswordField: some View {
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

                Button { isPasswordVisible.toggle() } label: {
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
    }

    private var confirmPasswordField: some View {
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

                Button { isConfirmVisible.toggle() } label: {
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
    }

    private var strengthBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(secondaryText.opacity(0.15))
                        .frame(height: 4)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [passwordStrength.color, passwordStrength.color.opacity(0.7)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * passwordStrength.progress, height: 4)
                        .animation(AppTheme.Anim.smooth, value: newPassword)
                }
            }
            .frame(height: 4)

            Text(passwordStrength.label)
                .font(.caption)
                .foregroundColor(passwordStrength.color)
        }
        .padding(.horizontal, 2)
    }
}
