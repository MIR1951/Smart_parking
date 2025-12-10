//
//  UserProfileView.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 10/12/25.
//

import SwiftUI

struct UserProfileView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(UserManager.self) private var userManager
    var body: some View {
        NavigationStack{
            List{
                Section{
                    VStack(alignment: .leading, spacing:6){
                        Text(userManager.currentUser?.username ?? "Loading")
                        Text(userManager.currentUser?.email ?? "Loading")
                    }
                }
                Section{
                    Button("Sign out"){
                        Task{
                            await authManager.signOut()
                        }
                    }
                    .foregroundStyle(Color.red)
                  
                    
                }
            }
        }
        .task {
            await userManager.fetchCorrentUser()
        }
    }
}

#Preview {
    UserProfileView()
}
