import SwiftUI

struct ForgotPasswordEmailStep: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(LocalizationManager.self) private var loc

    @Binding var email: String
    @Binding var emailTouched: Bool

    var emailError: String?
    var isEmailValid: Bool
    var isLoading: Bool
    var onSend: () -> Void

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

            Button(action: onSend) {
                HStack(spacing: 10) {
                    if isLoading {
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
                        colors: isEmailValid && !isLoading
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
            .disabled(!isEmailValid || isLoading)
            .pressStyle()
        }
    }
}
