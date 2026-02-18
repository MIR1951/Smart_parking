//
//  WalletManager.swift
//  Smart parking
//
//  Hamyon (wallet) boshqaruvi — Supabase asosida, UserDefaults fallback
//

internal import Combine
import Foundation
import Supabase
import SwiftUI

enum WalletError: LocalizedError {
    case readable(String)

    var errorDescription: String? {
        switch self {
        case .readable(let message): return message
        }
    }
}

// MARK: - Supabase DTO

struct WalletBalanceDTO: Codable {
    let user_id: UUID
    let balance: Int
    let updated_at: Date?
}

struct WalletTransactionDTO: Codable, Identifiable {
    let id: UUID
    let user_id: UUID
    let amount: Int
    let type: String
    let description: String?
    let created_at: Date
}

// MARK: - Local Model

struct WalletTransaction: Identifiable, Codable {
    let id: UUID
    let amount: Double
    let type: TransactionType
    let description: String
    let date: Date

    enum TransactionType: String, Codable {
        case topUp = "top_up"
        case payment = "payment"
    }
}

// RPC Parameters (MainActor default isolation bilan to'qnashmaslik uchun Encodable nonisolated qilinadi)
struct WalletRPCParams: Sendable {
    let p_amount: Int
    let p_description: String
}

nonisolated extension WalletRPCParams: Encodable {}

@MainActor
@Observable
final class WalletManager {
    static let shared = WalletManager()

    private let keyPrefix = "wallet_balance"
    private let txKeyPrefix = "wallet_transactions"
    private var currentUserID: String?
    private var balanceKey: String?
    private var txKey: String?

    private(set) var balance: Double = 0.0
    private(set) var transactions: [WalletTransaction] = []
    private(set) var isLoading = false

    private init() {}

    // MARK: - User Management

    func setCurrentUserID(_ userID: String?) {
        guard currentUserID != userID else { return }
        currentUserID = userID

        guard let userID else {
            balanceKey = nil
            txKey = nil
            balance = 0
            transactions = []
            return
        }

        balanceKey = "\(keyPrefix)_\(userID)"
        txKey = "\(txKeyPrefix)_\(userID)"

        // LocalDefaults → tez yuklash, keyin Supabase'dan yangilash
        loadLocalBalance()
        loadLocalTransactions()

        Task {
            await syncFromSupabase()
        }
    }

    // MARK: - Supabase Sync

    func syncFromSupabase() async {
        guard let userID = currentUserID, let userId = UUID(uuidString: userID) else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            // 1) Balans
            let wallets: [WalletBalanceDTO] = try await SB.shared.client
                .from("user_wallets")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value

            if let wallet = wallets.first {
                balance = Double(wallet.balance)
                saveLocalBalance()
            }

            // 2) Tranzaksiyalar
            let txDTOs: [WalletTransactionDTO] = try await SB.shared.client
                .from("wallet_transactions")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .limit(50)
                .execute()
                .value

            if !txDTOs.isEmpty {
                transactions = txDTOs.map { dto in
                    WalletTransaction(
                        id: dto.id,
                        amount: Double(dto.amount),
                        type: dto.type == "top_up" ? .topUp : .payment,
                        description: dto.description ?? "",
                        date: dto.created_at
                    )
                }
                saveLocalTransactions()
            }

        } catch {
            print("WalletManager sync error: \(error)")
        }
    }

    // MARK: - Operations (Supabase RPC)

    func topUp(amount: Double) async throws {
        let loc = LocalizationManager.shared
        guard amount > 0 else {
            throw WalletError.readable(loc.str(.walletInvalidAmount))
        }
        let intAmount = Int(amount)

        do {
            // Supabase RPC — atomik top-up
            let params = WalletRPCParams(
                p_amount: intAmount,
                p_description: loc.str(.walletTopUpDone)
            )

            let newBalance: Int = try await SB.shared.client
                .rpc("wallet_top_up", params: params)
                .execute()
                .value

            balance = Double(newBalance)
            saveLocalBalance()

            // Local tranzaksiya update
            let tx = WalletTransaction(
                id: UUID(),
                amount: amount,
                type: .topUp,
                description: loc.str(.walletTopUpDone),
                date: Date()
            )
            transactions.insert(tx, at: 0)
            saveLocalTransactions()

        } catch {
            // Fallback: local
            print("TopUp remote failed: \(error). Falling back to local.")
            try localTopUp(amount: amount)
        }
    }

    func deduct(amount: Double, description: String? = nil) async throws {
        let loc = LocalizationManager.shared
        guard amount > 0 else {
            throw WalletError.readable(loc.str(.walletInvalidAmount))
        }
        guard balance >= amount else {
            throw WalletError.readable(loc.str(.walletInsufficientBalance))
        }

        let intAmount = Int(amount)
        let desc = description ?? loc.str(.walletPaymentFor)

        do {
            // Supabase RPC — atomik deduction
            let params = WalletRPCParams(
                p_amount: intAmount,
                p_description: desc
            )

            let newBalance: Int = try await SB.shared.client
                .rpc("wallet_deduct", params: params)
                .execute()
                .value

            balance = Double(newBalance)
            saveLocalBalance()

            // Local tranzaksiya update
            let tx = WalletTransaction(
                id: UUID(),
                amount: -amount,
                type: .payment,
                description: desc,
                date: Date()
            )
            transactions.insert(tx, at: 0)
            saveLocalTransactions()

        } catch {
            // Fallback: local
            print("Deduct remote failed: \(error). Falling back to local.")
            try localDeduct(amount: amount, description: desc)
        }
    }

    // MARK: - Local Fallback Operations

    private func localTopUp(amount: Double) throws {
        let loc = LocalizationManager.shared
        guard amount > 0 else { throw WalletError.readable(loc.str(.walletInvalidAmount)) }
        balance += amount

        let tx = WalletTransaction(
            id: UUID(),
            amount: amount,
            type: .topUp,
            description: loc.str(.walletTopUpDone),
            date: Date()
        )
        transactions.insert(tx, at: 0)
        saveLocalBalance()
        saveLocalTransactions()
    }

    private func localDeduct(amount: Double, description: String) throws {
        let loc = LocalizationManager.shared
        guard amount > 0 else { throw WalletError.readable(loc.str(.walletInvalidAmount)) }
        guard balance >= amount else {
            throw WalletError.readable(loc.str(.walletInsufficientBalance))
        }
        balance -= amount

        let tx = WalletTransaction(
            id: UUID(),
            amount: -amount,
            type: .payment,
            description: description,
            date: Date()
        )
        transactions.insert(tx, at: 0)
        saveLocalBalance()
        saveLocalTransactions()
    }

    // MARK: - Formatting

    var formattedBalance: String {
        formatCurrency(balance)
    }

    /// So'm formatida summa chiqarish: "12 500 so'm"
    func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.maximumFractionDigits = 0
        let formatted = formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
        return "\(formatted) so'm"
    }

    // MARK: - Transaction Date Formatting

    /// Tranzaksiya sanasini formatlash: "18-fev, 23:45"
    func formatTransactionDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MMM, HH:mm"
        formatter.locale = Locale(identifier: "uz_UZ")
        return formatter.string(from: date)
    }

    // MARK: - Local Persistence (offline fallback)

    private func loadLocalBalance() {
        guard let key = balanceKey else { return }
        balance = UserDefaults.standard.double(forKey: key)
    }

    private func saveLocalBalance() {
        guard let key = balanceKey else { return }
        UserDefaults.standard.set(balance, forKey: key)
    }

    private func loadLocalTransactions() {
        guard let key = txKey,
            let data = UserDefaults.standard.data(forKey: key),
            let decoded = try? JSONDecoder().decode([WalletTransaction].self, from: data)
        else {
            transactions = []
            return
        }
        transactions = decoded
    }

    private func saveLocalTransactions() {
        guard let key = txKey else { return }
        if let encoded = try? JSONEncoder().encode(transactions) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
}
