//
//  UserProfileView.swift
//  Smart parking
//
//  To'liq profil sahifasi - sozlamalar, transport vositalari, to'lov usullari
//

import PhotosUI
import SwiftUI

struct UserProfileView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(UserManager.self) private var userManager

    @State private var selectedItem: PhotosPickerItem?
    @State private var profileImage: Image?
    @State private var showPhotoPicker = false
    @State private var showEditProfile = false
    @State private var showVehicles = false
    @State private var showPaymentMethods = false
    @State private var showNotificationSettings = false
    @State private var showPrivacyPolicy = false
    @State private var showHelpCenter = false
    @State private var showSignOutAlert = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Profile Header
                    profileHeader

                    // Account Section
                    settingsSection(title: "Account") {
                        SettingsRow(icon: "person", title: "Edit Profile", color: .purple) {
                            showEditProfile = true
                        }
                        SettingsRow(icon: "car.fill", title: "My Vehicles", color: .blue) {
                            showVehicles = true
                        }
                        SettingsRow(icon: "creditcard", title: "Payment Methods", color: .green) {
                            showPaymentMethods = true
                        }
                    }

                    // Preferences Section
                    settingsSection(title: "Preferences") {
                        SettingsRow(icon: "bell", title: "Notifications", color: .orange) {
                            showNotificationSettings = true
                        }
                        SettingsRow(
                            icon: "globe", title: "Language", subtitle: "English", color: .cyan
                        ) {}
                        SettingsRow(
                            icon: "moon", title: "Dark Mode", color: .indigo, hasToggle: true
                        ) {}
                    }

                    // Support Section
                    settingsSection(title: "Support") {
                        SettingsRow(icon: "questionmark.circle", title: "Help Center", color: .teal)
                        {
                            showHelpCenter = true
                        }
                        SettingsRow(icon: "shield", title: "Privacy Policy", color: .gray) {
                            showPrivacyPolicy = true
                        }
                        SettingsRow(icon: "doc.text", title: "Terms of Service", color: .gray) {}
                    }

                    // Sign Out Button
                    signOutButton

                    // App Version
                    Text("Version 1.0.0")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.bottom, 20)
                }
                .padding(.horizontal)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .photosPicker(isPresented: $showPhotoPicker, selection: $selectedItem)
            .sheet(isPresented: $showEditProfile) {
                EditProfileView()
            }
            .sheet(isPresented: $showVehicles) {
                MyVehiclesView()
            }
            .sheet(isPresented: $showPaymentMethods) {
                PaymentMethodsSettingsView()
            }
            .sheet(isPresented: $showNotificationSettings) {
                NotificationSettingsView()
            }
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    Task { await authManager.signOut() }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
        .task {
            await userManager.fetchCurrentUser()
        }
        .task(id: selectedItem) {
            await onImageSelection()
        }
    }

    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if let profileImage {
                        profileImage
                            .resizable()
                            .scaledToFill()
                    } else if let url = userManager.currentUser?.profileImageURL {
                        CachedAsyncImage(url: URL(string: url)) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            ProgressView()
                        }
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundStyle(.gray.opacity(0.5))
                    }
                }
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .onTapGesture { showPhotoPicker = true }

                // Camera button
                Circle()
                    .fill(Color.purple)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "camera.fill")
                            .font(.caption)
                            .foregroundColor(.white)
                    )
                    .offset(x: 4, y: 4)
                    .onTapGesture { showPhotoPicker = true }
            }

            // Name & Email
            VStack(spacing: 4) {
                Text(userManager.currentUser?.username ?? "User")
                    .font(.title2)
                    .fontWeight(.bold)

                Text(userManager.currentUser?.email ?? "email@example.com")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 20)
    }

    // MARK: - Settings Section
    private func settingsSection(title: String, @ViewBuilder content: () -> some View) -> some View
    {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.gray)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content()
            }
            .background(Color.white)
            .cornerRadius(16)
        }
    }

    // MARK: - Sign Out Button
    private var signOutButton: some View {
        Button {
            showSignOutAlert = true
        } label: {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .foregroundColor(.red)
                Text("Sign Out")
                    .fontWeight(.medium)
                    .foregroundColor(.red)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.red.opacity(0.1))
            .cornerRadius(16)
        }
    }

    // MARK: - Image Selection
    private func onImageSelection() async {
        guard let selectedItem, let user = userManager.currentUser else { return }

        do {
            guard let data = try await selectedItem.loadTransferable(type: Data.self) else {
                return
            }
            guard let uiImage = UIImage(data: data) else { return }

            profileImage = Image(uiImage: uiImage)

            let url = try await SupabaseStorageManager().uploadProfilePhoto(
                for: user, imageData: data)
            await userManager.updateProfileImageURL(url)
        } catch {
            print("Image upload error: \(error)")
        }
    }
}

// MARK: - Settings Row
struct SettingsRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    let color: Color
    var hasToggle: Bool = false
    let action: () -> Void

    @State private var isOn = false

    var body: some View {
        Button(action: hasToggle ? {} : action) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(0.15))
                        .frame(width: 36, height: 36)

                    Image(systemName: icon)
                        .font(.body)
                        .foregroundColor(color)
                }

                // Title
                Text(title)
                    .font(.body)
                    .foregroundColor(.black)

                Spacer()

                // Subtitle or Toggle or Chevron
                if hasToggle {
                    Toggle("", isOn: $isOn)
                        .labelsHidden()
                        .tint(.purple)
                } else if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.gray)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)

        Divider().padding(.leading, 66)
    }
}

// MARK: - Edit Profile View
struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(UserManager.self) private var userManager

    @State private var username = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Personal Information") {
                    TextField("Username", text: $username)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .disabled(true)
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                        .disabled(true)
                }

                Section {
                    Text("Hozircha faqat username yangilanadi.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await saveProfile() }
                    }
                    .disabled(isSaving)
                }
            }
            .onAppear {
                username = userManager.currentUser?.username ?? ""
                email = userManager.currentUser?.email ?? ""
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func saveProfile() async {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedUsername.isEmpty else {
            errorMessage = "Username bo'sh bo'lishi mumkin emas."
            showError = true
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            try await userManager.updateUsername(trimmedUsername)
            dismiss()
        } catch {
            errorMessage = "Profilni saqlab bo'lmadi: \(error.localizedDescription)"
            showError = true
        }
    }
}

// MARK: - My Vehicles View
struct MyVehiclesView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = VehiclesStore.shared
    @State private var showAddVehicle = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.vehicles) { vehicle in
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.systemGray6))
                                .frame(width: 50, height: 50)
                            Image(systemName: "car.fill")
                                .foregroundColor(.purple)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(vehicle.name)
                                .font(.headline)
                            Text("\(vehicle.type.rawValue) • \(vehicle.plateNumber)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .onDelete { indexSet in
                    indexSet.forEach { store.delete(store.vehicles[$0]) }
                }
            }
            .overlay {
                if store.vehicles.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "car")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("No vehicles added")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("My Vehicles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddVehicle = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddVehicle) {
                AddVehicleView(store: store)
            }
        }
    }
}

// MARK: - Payment Methods Settings View
struct PaymentMethodsSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showInfo = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    PaymentMethodRow(icon: "creditcard", name: "Visa •••• 4242", isDefault: true)
                    PaymentMethodRow(icon: "applelogo", name: "Apple Pay", isDefault: false)
                }

                Section {
                    Button {
                        showInfo = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.purple)
                            Text("Add Payment Method")
                                .foregroundColor(.purple)
                        }
                    }
                }
            }
            .navigationTitle("Payment Methods")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Info", isPresented: $showInfo) {
                Button("OK") {}
            } message: {
                Text("Yangi karta qo'shish backend qismi hali yoqilmagan.")
            }
        }
    }
}

struct PaymentMethodRow: View {
    let icon: String
    let name: String
    let isDefault: Bool

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.purple)
                .frame(width: 30)

            Text(name)

            Spacer()

            if isDefault {
                Text("Default")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.purple)
                    .cornerRadius(8)
            }
        }
    }
}

// MARK: - Notification Settings View
struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var bookingAlerts = true
    @State private var timeReminders = true
    @State private var promotions = false
    @State private var emailNotifications = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Push Notifications") {
                    Toggle("Booking Alerts", isOn: $bookingAlerts)
                    Toggle("Time Reminders", isOn: $timeReminders)
                    Toggle("Promotions & Offers", isOn: $promotions)
                }

                Section("Email") {
                    Toggle("Email Notifications", isOn: $emailNotifications)
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    UserProfileView()
}
