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
            if let currentUser = authManager.currentUser {
                VStack{
                    Text(currentUser.email)
                    
                    Button { Task { await authManager.signOut() }} label: {
                        Text("Sign Out")
                            .font(Font.largeTitle)
                            .padding()
                    }
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
