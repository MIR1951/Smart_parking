//
//  PaymentMethod.swift
//  Smart parking
//
//  To'lov usullari
//

import Foundation

enum PaymentMethod: String, Codable, CaseIterable, Identifiable {
    case wallet = "Wallet"
    case applePay = "Apple Pay"
    case googlePay = "Google Pay"
    case paypal = "Paypal"
    case card = "Card"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .wallet: return "wallet.pass"
        case .applePay: return "applelogo"
        case .googlePay: return "g.circle.fill"
        case .paypal: return "p.circle.fill"
        case .card: return "creditcard"
        }
    }

    var displayName: String { rawValue }
}
