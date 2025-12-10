//
//  ContentView.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 30/11/25.
//

import SwiftUI

struct ContentView: View {
    
    @Environment(AuthManager.self) private var authManager

    var body: some View {
        Group{
            if let currentUserID = authManager.currentUserID {
               UserProfileView()
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
