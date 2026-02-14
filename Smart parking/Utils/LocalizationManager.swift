//
//  LocalizationManager.swift
//  Smart parking
//
//  Created by Smart Parking on 12/02/26.
//

import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case uz = "uz"
    case en = "en"
    case ru = "ru"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .uz: return "O'zbekcha"
        case .en: return "English"
        case .ru: return "Русский"
        }
    }

    var flag: String {
        switch self {
        case .uz: return "🇺🇿"
        case .en: return "🇺🇸"
        case .ru: return "🇷🇺"
        }
    }
}

@Observable
@MainActor
final class LocalizationManager {
    static let shared = LocalizationManager()

    private let key = "app_language"

    var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: key)
        }
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: key) ?? "uz"
        self.currentLanguage = AppLanguage(rawValue: saved) ?? .uz
    }

    func str(_ key: StringKey) -> String {
        return key.localized(currentLanguage)
    }
}
