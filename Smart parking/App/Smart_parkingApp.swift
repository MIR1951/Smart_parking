//
//  Smart_parkingApp.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 30/11/25.
//

import Supabase
import SwiftUI

@main
struct Smart_parkingApp: App {
    @State private var authManager = AuthManager()
    @State private var userManager = UserManager()
    @State private var loc = LocalizationManager.shared
    @State private var appearance = AppearanceManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authManager)
                .environment(userManager)
                .environment(loc)
                .environment(appearance)
                .preferredColorScheme(appearance.currentAppearance.colorScheme)
        }
    }
}
