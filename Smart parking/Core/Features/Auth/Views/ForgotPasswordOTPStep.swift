import SwiftUI

struct ForgotPasswordOTPStep: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(LocalizationManager.self) private var loc

    @Binding var otpCode: String
    @Binding var otpTouched: Bool

    var otpError: String?
    var isOTPValid: Bool
    var isLoading: Bool
    var resendCountdown: Int
    var onVerify: () -> Void
    var onResend: () -> Void

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
    private var primaryText: Color { AppTheme.Palette.textPrimary }
    private var secondaryText: Color { AppTheme.Palette.textSecondary }
    private var accentColor: Color { AppTheme.Palette.brandLight }

    var body: some View {
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

            Button(action: onVerify) {
                HStack(spacing: 10) {
                    if isLoading {
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
                        colors: isOTPValid && !isLoading
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
            .disabled(!isOTPValid || isLoading)
            .pressStyle()

            HStack {
                if resendCountdown > 0 {
                    Text("\(loc.str(.forgotResendIn)) (\(resendCountdown)s)")
                        .font(.footnote)
                        .foregroundColor(secondaryText)
                } else {
                    Button(loc.str(.forgotResendCode), action: onResend)
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(accentColor)
                }
            }
            .padding(.top, 4)
        }
    }

    private var otpInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(loc.str(.forgotConfirmCode))
                .font(.subheadline.weight(.medium))
                .foregroundColor(primaryText)

            HStack(spacing: 6) {
                ForEach(0..<8, id: \.self) { index in
                    let char = index < otpCode.count
                        ? String(otpCode[otpCode.index(otpCode.startIndex, offsetBy: index)])
                        : ""

                    Text(char)
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(primaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(inputBg)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(
                                    index < otpCode.count ? inputFocusBorder : inputBorder,
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
}
