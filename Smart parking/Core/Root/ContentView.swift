//
//  ContentView.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 30/11/25.
//

import SwiftUI
import Supabase
internal import Combine

struct ContentView: View {
    
    @Environment(AuthManager.self) private var authManager
    @StateObject private var availabilityStore = ParkingAvailabilityStore(client: SB.shared.client)
    @StateObject private var parkingsStore = ParkingsStore()
    @StateObject private var favoritesStore = FavoritesStore()
    
    @State private var didStart = false
    var body: some View {
        Group{
            if let currentUserID = authManager.currentUserID {
               

                // MainTabView chaqiriladigan joyda:
                MainTabView()
                    .environmentObject(parkingsStore)
                    .environmentObject(favoritesStore)
                    .environmentObject(availabilityStore)

                    .onAppear {
                                            guard !didStart else { return }
                                            didStart = true
                                            availabilityStore.initialLoad() // ✅ 1 marta
                                                  // ✅ 1 marta
                                        }
            }
            else {
                LoginView()
            }
        }
        .task {
            await authManager.refreshUser()
        }
    }
}

#Preview {
    ContentView()
        .environment(AuthManager())
}
