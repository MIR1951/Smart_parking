//
//  PaymentMethodsView.swift
//  Smart parking
//
//  To'lov usulini tanlash sahifasi
//

import SwiftUI

struct PaymentMethodsView: View {
    @Binding var selectedMethod: PaymentMethod?
    let onBack: () -> Void
    let onConfirm: () -> Void
    private let loc = LocalizationManager.shared
    @State private var showComingSoonWarning = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {

                    // Wallet Section
                    Section {
                        paymentRow(method: .wallet)
                            .appReveal(0.03)
                    } header: {
                        Text(loc.str(.paymentWallet))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(AppTheme.Palette.textSecondary)
                    }

                    // Credit & Debit Card
                    Section {
                        addCardRow
                            .appReveal(0.06)
                    } header: {
                        Text(loc.str(.paymentCreditDebit))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(AppTheme.Palette.textSecondary)
                    }

                    // More Options
                    Section {
                        VStack(spacing: 12) {
                            paymentRow(method: .paypal)
                            paymentRow(method: .applePay)
                            paymentRow(method: .googlePay)
                        }
                    } header: {
                        Text(loc.str(.paymentMoreOptions))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(AppTheme.Palette.textSecondary)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
            }

            Spacer()

            // Confirm Button
            confirmButton
        }
        .background(AppAnimatedBackground())
        .navigationBarHidden(true)
        .onAppear {
            if selectedMethod != .wallet {
                selectedMethod = .wallet
            }
        }
        .alert(loc.str(.info), isPresented: $showComingSoonWarning) {
            Button(loc.str(.ok)) {}
        } message: {
            Text(loc.str(.paymentComingSoon))
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            Button {
                onBack()
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundColor(AppTheme.Palette.textPrimary)
                    .padding(12)
                    .background(AppTheme.Palette.surface)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.1), radius: 4)
            }
            .pressStyle()

            Spacer()

            Text(loc.str(.paymentTitle))
                .font(.headline)

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: - Payment Row
    private func paymentRow(method: PaymentMethod) -> some View {
        let isEnabled = method == .wallet

        return HStack(spacing: 16) {
            Image(systemName: method.icon)
                .font(.title3)
                .foregroundColor(isEnabled ? AppTheme.Palette.brand : AppTheme.Palette.textTertiary)
                .frame(width: 40, height: 40)
                .background(
                    isEnabled ? AppTheme.Palette.brandSoft : AppTheme.Palette.surfaceSecondary
                )
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 2) {
                Text(method.displayName)
                    .font(.body)
                    .foregroundColor(
                        isEnabled ? AppTheme.Palette.textPrimary : AppTheme.Palette.textSecondary
                    )

                if method == .wallet {
                    Text("\(loc.str(.walletBalance)): \(WalletManager.shared.formattedBalance)")
                        .font(.caption)
                        .foregroundColor(AppTheme.Palette.textSecondary)
                } else {
                    Text(loc.str(.paymentComingSoon))
                        .font(.caption)
                        .foregroundColor(AppTheme.Palette.textTertiary)
                }
            }

            Spacer()

            Circle()
                .stroke(
                    selectedMethod == method
                        ? AppTheme.Palette.brand
                        : (isEnabled ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2)),
                    lineWidth: 2
                )
                .frame(width: 24, height: 24)
                .overlay {
                    if selectedMethod == method {
                        Circle()
                            .fill(AppTheme.Palette.brand)
                            .frame(width: 14, height: 14)
                    }
                }
        }
        .padding()
        .background(AppTheme.Palette.surface)
        .cornerRadius(16)
        .opacity(isEnabled ? 1 : 0.65)
        .onTapGesture {
            if isEnabled {
                selectedMethod = method
            } else {
                showComingSoonWarning = true
            }
        }
    }

    // MARK: - Add Card Row
    private var addCardRow: some View {
        HStack(spacing: 16) {
            Image(systemName: "creditcard")
                .font(.title3)
                .foregroundColor(AppTheme.Palette.textTertiary)
                .frame(width: 40, height: 40)
                .background(AppTheme.Palette.surfaceSecondary)
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 2) {
                Text(loc.str(.paymentAddCard))
                    .font(.body)
                    .foregroundColor(AppTheme.Palette.textSecondary)
                Text(loc.str(.paymentComingSoon))
                    .font(.caption)
                    .foregroundColor(AppTheme.Palette.textTertiary)
            }

            Spacer()

            Image(systemName: "lock.fill")
                .font(.caption)
                .foregroundColor(AppTheme.Palette.textTertiary)
        }
        .padding()
        .background(AppTheme.Palette.surface)
        .cornerRadius(16)
        .opacity(0.7)
        .onTapGesture {
            showComingSoonWarning = true
        }
    }

    // MARK: - Confirm Button
    private var confirmButton: some View {
        AppPrimaryButton(
            title: loc.str(.paymentConfirm),
            isEnabled: selectedMethod == .wallet
        ) {
            onConfirm()
        }
        .padding(.horizontal)
        .padding(.bottom, 24)
    }
}
