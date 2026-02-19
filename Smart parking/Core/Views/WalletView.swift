//
//  WalletView.swift
//  Smart parking
//
//  Hamyon sahifasi — balans ko'rish va to'ldirish
//

import SwiftUI

struct WalletView: View {
    @Environment(\.dismiss) private var dismiss
    private let loc = LocalizationManager.shared
    private let wallet = WalletManager.shared

    @State private var showTopUpSheet = false
    @State private var topUpAmount: String = ""
    @State private var showError = false
    @State private var errorMessage = ""

    private let quickAmounts: [Double] = [10_000, 20_000, 50_000, 100_000]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Balance Card
                balanceCard
                    .appReveal(0.03)

                // Quick Top Up
                quickTopUpSection
                    .appReveal(0.06)

                // Transactions
                transactionsSection
                    .appReveal(0.09)
            }
            .padding(.horizontal)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(AppAnimatedBackground())
        .navigationTitle(loc.str(.walletTitle))
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showTopUpSheet) {
            topUpSheet
                .presentationDetents([.height(300)])
                .presentationDragIndicator(.visible)
        }
        .alert(loc.str(.error), isPresented: $showError) {
            Button(loc.str(.ok)) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Balance Card

    private var balanceCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(loc.str(.walletBalance))
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))

                    Text(wallet.formattedBalance)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                Spacer()

                Image(systemName: "wallet.pass.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white.opacity(0.6), .white.opacity(0.2)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
            }

            Button {
                showTopUpSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text(loc.str(.walletTopUp))
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(.white.opacity(0.18))
                        .overlay(
                            Capsule()
                                .stroke(.white.opacity(0.25), lineWidth: 1)
                        )
                )
            }
            .pressStyle()
        }
        .padding(24)
        .background(
            LinearGradient(
                colors: [
                    AppTheme.Palette.brand, AppTheme.Palette.brandDark,
                    AppTheme.Palette.brandLight.opacity(0.6),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xLarge, style: .continuous))
        .shadow(color: AppTheme.Palette.brand.opacity(0.35), radius: 20, y: 10)
    }

    // MARK: - Quick Top Up

    private var quickTopUpSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(loc.str(.walletQuickTopUp))
                .font(.headline)

            LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
                ForEach(quickAmounts, id: \.self) { amount in
                    Button {
                        performTopUp(amount: amount)
                    } label: {
                        HStack {
                            Image(systemName: "plus")
                                .font(.caption)
                            Text(wallet.formatCurrency(amount))
                                .fontWeight(.semibold)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .foregroundColor(AppTheme.Palette.brand)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppTheme.Palette.brandSoft)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .pressStyle()
                }
            }
        }
        .padding()
        .background(AppTheme.Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                .stroke(AppTheme.Palette.border, lineWidth: 1)
        )
    }

    // MARK: - Transactions

    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(loc.str(.walletTransactions))
                .font(.headline)

            if wallet.transactions.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.largeTitle)
                        .foregroundColor(AppTheme.Palette.textTertiary)
                    Text(loc.str(.walletNoTransactions))
                        .font(.subheadline)
                        .foregroundColor(AppTheme.Palette.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                ForEach(wallet.transactions.prefix(20)) { tx in
                    transactionRow(tx)
                }
            }
        }
        .padding()
        .background(AppTheme.Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                .stroke(AppTheme.Palette.border, lineWidth: 1)
        )
    }

    private func transactionRow(_ tx: WalletTransaction) -> some View {
        HStack(spacing: 12) {
            Image(systemName: tx.type == .topUp ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .font(.title2)
                .foregroundStyle(
                    tx.type == .topUp
                        ? LinearGradient(
                            colors: [
                                AppTheme.Palette.success, AppTheme.Palette.success.opacity(0.7),
                            ], startPoint: .top, endPoint: .bottom)
                        : LinearGradient(
                            colors: [AppTheme.Palette.brand, AppTheme.Palette.brandLight],
                            startPoint: .top, endPoint: .bottom)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(tx.description)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(wallet.formatTransactionDate(tx.date))
                    .font(.caption)
                    .foregroundColor(AppTheme.Palette.textSecondary)
            }

            Spacer()

            Text("\(tx.amount >= 0 ? "+" : "")\(wallet.formatCurrency(abs(tx.amount)))")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(
                    tx.type == .topUp ? AppTheme.Palette.success : AppTheme.Palette.danger)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Top Up Sheet

    private var topUpSheet: some View {
        VStack(spacing: 20) {
            Text(loc.str(.walletEnterAmount))
                .font(.headline)
                .padding(.top, 8)

            HStack {
                TextField("0", text: $topUpAmount)
                    .keyboardType(.numberPad)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.Palette.textPrimary)

                Text(loc.str(.walletCurrency))
                    .font(.title2)
                    .foregroundColor(AppTheme.Palette.brand)
            }
            .padding()
            .background(AppTheme.Palette.pageBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            AppPrimaryButton(
                title: loc.str(.walletTopUp),
                isEnabled: Double(topUpAmount) ?? 0 > 0
            ) {
                if let amount = Double(topUpAmount), amount > 0 {
                    performTopUp(amount: amount)
                    showTopUpSheet = false
                    topUpAmount = ""
                }
            }

            Spacer()
        }
        .padding(.horizontal)
        .background(AppTheme.Palette.surface)
    }

    // MARK: - Actions

    private func performTopUp(amount: Double) {
        Task {
            do {
                try await wallet.topUp(amount: amount)
                AppTheme.Haptic.success()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}
