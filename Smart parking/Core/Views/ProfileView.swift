//
//  ProfileView.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 23/01/26.
//


import SwiftUI

struct ProfileView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(UserManager.self) private var userManager
    @State private var showLogoutAlert = false
    @State private var showEditProfile = false
    @State private var showPaymentMethods = false
    @State private var showNotificationSettings = false
    @State private var showInfoAlert = false
    @State private var infoMessage = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(spacing: 10) {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 90, height: 90)
                        .overlay {
                            Text(userInitial)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                        }

                    Text(userManager.currentUser?.username ?? "User")
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text(userManager.currentUser?.email ?? "")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.top, 20)

                VStack(spacing: 0) {
                    ProfileRow(icon: "person", title: "Your profile")
                        .onTapGesture {
                            showEditProfile = true
                        }
                    ProfileRow(icon: "creditcard", title: "Payment Methods")
                        .onTapGesture {
                            showPaymentMethods = true
                        }
                    ProfileRow(icon: "wallet.pass", title: "My Wallet")
                        .onTapGesture {
                            showComingSoon("My Wallet bo'limi keyingi versiyada ochiladi.")
                        }
                    ProfileRow(icon: "gearshape", title: "Settings")
                        .onTapGesture {
                            showNotificationSettings = true
                        }
                    ProfileRow(icon: "questionmark.circle", title: "Help Center")
                        .onTapGesture {
                            showComingSoon("Help Center bo'limi keyingi versiyada ochiladi.")
                        }
                    ProfileRow(icon: "lock", title: "Privacy Policy")
                        .onTapGesture {
                            showComingSoon("Privacy Policy bo'limi keyingi versiyada ochiladi.")
                        }
                    ProfileRow(icon: "person.2", title: "Invites Friends")
                        .onTapGesture {
                            showComingSoon("Invite funksiyasi keyingi versiyada ochiladi.")
                        }

                    // 🔴 LOG OUT
                    ProfileRow(icon: "arrow.right.square", title: "Log out", isDestructive: true)
                        .onTapGesture {
                            showLogoutAlert = true
                        }
                }
                .background(Color.white)
                .cornerRadius(16)
                .padding(.horizontal)

                Spacer()
            }
            .background(Color.bgLight.ignoresSafeArea())
            .navigationTitle("Profile")
            .task {
                await userManager.fetchCurrentUser()
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileView()
            }
            .sheet(isPresented: $showPaymentMethods) {
                PaymentMethodsSettingsView()
            }
            .sheet(isPresented: $showNotificationSettings) {
                NotificationSettingsView()
            }
            .alert("Info", isPresented: $showInfoAlert) {
                Button("OK") {}
            } message: {
                Text(infoMessage)
            }
            .alert("Log out", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) {}

                Button("Log out", role: .destructive) {
                    Task {
                        await authManager.signOut()
                    }
                }
            } message: {
                Text("Are you sure you want to log out?")
            }
        }
    }

    private var userInitial: String {
        let source = userManager.currentUser?.username ?? userManager.currentUser?.email ?? "U"
        return String(source.prefix(1)).uppercased()
    }

    private func showComingSoon(_ message: String) {
        infoMessage = message
        showInfoAlert = true
    }
}


struct ProfileRow: View {
    let icon: String
    let title: String
    var isDestructive: Bool = false

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(isDestructive ? .red : .primary)

            Text(title)
                .foregroundColor(isDestructive ? .red : .primary)

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        Divider()
    }
}
