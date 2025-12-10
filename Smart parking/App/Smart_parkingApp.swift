//
//  Smart_parkingApp.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 30/11/25.
//

import SwiftUI
import Supabase

@main
struct Smart_parkingApp: App {
    @State private var authManager = AuthManager()
    @State private var userManager = UserManager()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authManager)
                .environment(userManager)
        }
    }
}
