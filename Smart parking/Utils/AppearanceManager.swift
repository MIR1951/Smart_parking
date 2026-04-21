//
//  AppearanceManager.swift
//  Smart parking
//
//  Created by Smart Parking on 12/02/26.
//

import SwiftUI

// MARK: - AppAppearance

enum AppAppearance: String, CaseIterable, Identifiable {
    case system = "system"
    case light = "light"
    case dark = "dark"

    var id: String { rawValue }

    func displayName(_ lang: AppLanguage) -> String {
        switch self {
        case .system:
            switch lang {
            case .uz: return "Tizim"
            case .en: return "System"
            case .ru: return "Системная"
            }
        case .light:
            switch lang {
            case .uz: return "Yorug'"
            case .en: return "Light"
            case .ru: return "Светлая"
            }
        case .dark:
            switch lang {
            case .uz: return "Qorong'u"
            case .en: return "Dark"
            case .ru: return "Тёмная"
            }
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

@Observable
@MainActor
final class AppearanceManager {
    static let shared = AppearanceManager()

    private let appearanceKey = "app_appearance"
    private let themeKey = "app_color_theme"

    var currentAppearance: AppAppearance {
        didSet {
            UserDefaults.standard.set(currentAppearance.rawValue, forKey: appearanceKey)
        }
    }

    var currentColorTheme: AppColorTheme {
        didSet {
            UserDefaults.standard.set(currentColorTheme.rawValue, forKey: themeKey)
            themeVersion += 1
        }
    }

    private(set) var themeVersion: Int = 0

    private init() {
        let savedAppearance = UserDefaults.standard.string(forKey: "app_appearance") ?? "system"
        self.currentAppearance = AppAppearance(rawValue: savedAppearance) ?? .system

        let savedTheme = UserDefaults.standard.string(forKey: "app_color_theme") ?? "carbon"
        self.currentColorTheme = AppColorTheme(rawValue: savedTheme) ?? .carbon
    }
}
