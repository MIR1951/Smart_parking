//
//  ProfileSubViews.swift
//  Smart parking
//

import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(UserManager.self) private var userManager
    @Environment(LocalizationManager.self) private var loc

    @State private var username: String = ""
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppAnimatedBackground()

                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(loc.str(.registerName))
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Palette.textSecondary)

                        TextField(loc.str(.registerNamePlaceholder), text: $username)
                            .padding(14)
                            .background(AppTheme.Palette.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .padding(.horizontal)

                    AppPrimaryButton(title: loc.str(.profileSave)) {
                        Task {
                            isSaving = true
                            try? await userManager.updateUsername(username)
                            isSaving = false
                            dismiss()
                        }
                    }
                    .padding(.horizontal)
                    .disabled(username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)

                    Spacer()
                }
                .padding(.top, 24)
            }
            .navigationTitle(loc.str(.profileEditProfile))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(loc.str(.cancel)) { dismiss() }
                }
            }
        }
        .onAppear {
            username = userManager.currentUser?.username ?? ""
        }
    }
}

struct PaymentMethodsSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(LocalizationManager.self) private var loc

    var body: some View {
        NavigationStack {
            ZStack {
                AppAnimatedBackground()
                AppStateView(kind: .empty(
                    icon: "creditcard.fill",
                    title: loc.str(.profileComingSoon),
                    subtitle: ""
                ))
            }
            .navigationTitle(loc.str(.profilePaymentMethods))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(loc.str(.cancel)) { dismiss() }
                }
            }
        }
    }
}

struct MyVehiclesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(LocalizationManager.self) private var loc
    @ObservedObject private var vehiclesStore = VehiclesStore.shared

    @State private var showAddVehicle = false
    @State private var vehicleToDelete: Vehicle?
    @State private var showDeleteAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppAnimatedBackground()

                if vehiclesStore.isLoading && vehiclesStore.vehicles.isEmpty {
                    AppStateView(kind: .loading(title: loc.str(.launchLoading)))
                } else if vehiclesStore.vehicles.isEmpty {
                    AppStateView(kind: .empty(
                        icon: "car.fill",
                        title: loc.str(.vehicleNotFound),
                        subtitle: loc.str(.vehicleAddFirst)
                    ))
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
                            ForEach(vehiclesStore.vehicles) { vehicle in
                                VehicleRow(vehicle: vehicle) {
                                    vehicleToDelete = vehicle
                                    showDeleteAlert = true
                                }
                                .transition(.asymmetric(
                                    insertion: .move(edge: .top).combined(with: .opacity),
                                    removal: .move(edge: .trailing).combined(with: .opacity)
                                ))
                            }
                        }
                        .padding()
                        .animation(AppTheme.Anim.snappy, value: vehiclesStore.vehicles.count)
                    }
                }
            }
            .navigationTitle(loc.str(.profileMyVehicles))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(loc.str(.cancel)) { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        AppTheme.Haptic.light()
                        showAddVehicle = true
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                }
            }
            .task { await vehiclesStore.syncFromSupabase() }
            .sheet(isPresented: $showAddVehicle) {
                AddVehicleView(store: vehiclesStore)
            }
            .alert(loc.str(.vehicleDeleteTitle), isPresented: $showDeleteAlert, presenting: vehicleToDelete) { vehicle in
                Button(loc.str(.vehicleDelete), role: .destructive) {
                    withAnimation(AppTheme.Anim.snappy) {
                        vehiclesStore.delete(vehicle)
                    }
                    AppTheme.Haptic.error()
                }
                Button(loc.str(.cancel), role: .cancel) {}
            } message: { _ in
                Text(loc.str(.vehicleDeleteConfirm))
            }
        }
    }
}

private struct VehicleRow: View {
    let vehicle: Vehicle
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.Palette.brandSoft)
                    .frame(width: 44, height: 44)
                Image(systemName: vehicleIcon)
                    .font(.system(size: 18))
                    .foregroundColor(AppTheme.Palette.brand)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(vehicle.name)
                    .font(AppTheme.Typography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.Palette.textPrimary)
                HStack(spacing: 6) {
                    Text(vehicle.plateNumber)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Palette.textSecondary)
                    Text("·")
                        .foregroundColor(AppTheme.Palette.textTertiary)
                    Text(vehicle.type.rawValue)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Palette.textTertiary)
                }
            }

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.Palette.danger)
                    .padding(8)
                    .background(AppTheme.Palette.danger.opacity(0.1))
                    .clipShape(Circle())
            }
            .pressStyle()
        }
        .padding(14)
        .glassCard()
    }

    private var vehicleIcon: String {
        switch vehicle.type {
        case .suv, .pickup: return "car.side.fill"
        case .mpv: return "bus.fill"
        default: return "car.fill"
        }
    }
}
