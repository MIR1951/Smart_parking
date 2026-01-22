//
//  ProfileView.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 23/01/26.
//


import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(spacing: 10) {
                    Circle().fill(Color.gray.opacity(0.2)).frame(width: 90, height: 90)
                    Text("Esther Howard").font(.title3).fontWeight(.semibold)
                }
                .padding(.top, 20)

                VStack(spacing: 0) {
                    ProfileRow(icon: "person", title: "Your profile")
                    ProfileRow(icon: "creditcard", title: "Payment Methods")
                    ProfileRow(icon: "wallet.pass", title: "My Wallet")
                    ProfileRow(icon: "gearshape", title: "Settings")
                    ProfileRow(icon: "questionmark.circle", title: "Help Center")
                    ProfileRow(icon: "lock", title: "Privacy Policy")
                    ProfileRow(icon: "person.2", title: "Invites Friends")
                    ProfileRow(icon: "arrow.right.square", title: "Log out")
                }
                .background(Color.white)
                .cornerRadius(16)
                .padding(.horizontal)

                Spacer()
            }
            .background(Color.bgLight.ignoresSafeArea())
            .navigationTitle("Profile")
        }
    }
}

struct ProfileRow: View {
    let icon: String
    let title: String

    var body: some View {
        HStack {
            Image(systemName: icon).foregroundColor(.primary)
            Text(title)
            Spacer()
            Image(systemName: "chevron.right").foregroundColor(.gray)
        }
        .padding()
        Divider()
    }
}
