//
//  AppInputField.swift
//  Smart parking
//
//  Shared form controls.
//

import SwiftUI

struct AppInputField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var isSecure = false
    @Binding var revealSecureText: Bool
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .never

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(AppTheme.Palette.textPrimary)

            HStack(spacing: AppTheme.Spacing.small) {
                Group {
                    if isSecure && !revealSecureText {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                            .textInputAutocapitalization(autocapitalization)
                            .keyboardType(keyboardType)
                    }
                }

                if isSecure {
                    Button {
                        revealSecureText.toggle()
                    } label: {
                        Image(systemName: revealSecureText ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(AppTheme.Palette.textSecondary)
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.vertical, 12)
            .background(AppTheme.Palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous)
                    .stroke(AppTheme.Palette.border, lineWidth: 1)
            )
        }
    }
}

extension AppInputField {
    init(
        title: String,
        placeholder: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType = .default,
        autocapitalization: TextInputAutocapitalization = .never
    ) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.isSecure = false
        self._revealSecureText = .constant(false)
        self.keyboardType = keyboardType
        self.autocapitalization = autocapitalization
    }
}
