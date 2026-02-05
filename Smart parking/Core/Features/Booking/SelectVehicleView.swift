//
//  SelectVehicleView.swift
//  Smart parking
//
//  Mashina tanlash sahifasi
//

import SwiftUI

struct SelectVehicleView: View {
    let parking: Parking
    let selectedMinutes: Int
    @Binding var selectedVehicle: Vehicle?
    let onBack: () -> Void
    let onContinue: () -> Void

    @StateObject private var store = VehiclesStore.shared
    @State private var showAddVehicle = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            // Vehicle List
            ScrollView(showsIndicators: false) {
                Group {
                    if store.vehicles.isEmpty {
                        AppStateView(
                            kind: .empty(
                                icon: "car",
                                title: "Vehicle topilmadi",
                                subtitle: "Davom etish uchun avval mashina qo'shing."
                            )
                        )
                        .padding(.top, 40)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(store.vehicles) { vehicle in
                                VehicleRow(
                                    vehicle: vehicle,
                                    isSelected: selectedVehicle?.id == vehicle.id
                                )
                                .onTapGesture {
                                    selectedVehicle = vehicle
                                }
                            }
                        }
                        .padding(.top, 16)
                    }
                }
                .padding(.horizontal)
            }

            Spacer()

            // Continue Button
            continueButton
        }
        .background(AppTheme.Palette.pageBackground.ignoresSafeArea())
        .navigationBarHidden(true)
        .sheet(isPresented: $showAddVehicle) {
            AddVehicleView(store: store)
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            Button {
                onBack()
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundColor(AppTheme.Palette.textPrimary)
                    .padding(12)
                    .background(AppTheme.Palette.surface)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.1), radius: 4)
            }

            Spacer()

            Text("Select Vehicle")
                .font(.headline)

            Spacer()

            Button {
                showAddVehicle = true
            } label: {
                Image(systemName: "plus")
                    .foregroundColor(AppTheme.Palette.textPrimary)
                    .padding(12)
                    .background(AppTheme.Palette.surface)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.1), radius: 4)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: - Continue Button
    private var continueButton: some View {
        AppPrimaryButton(
            title: "Continue",
            isEnabled: selectedVehicle != nil
        ) {
            onContinue()
        }
        .padding(.horizontal)
        .padding(.bottom, 24)
    }
}

// MARK: - Vehicle Row
private struct VehicleRow: View {
    let vehicle: Vehicle
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 16) {
            // Car Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .frame(width: 56, height: 56)

                Image(systemName: "car.fill")
                    .font(.title2)
                    .foregroundColor(colorForVehicle)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(vehicle.name)
                    .font(.headline)

                Text("\(vehicle.type.rawValue) • \(vehicle.plateNumber)")
                    .font(.caption)
                    .foregroundColor(AppTheme.Palette.textSecondary)
            }

            Spacer()

            // Selection Circle
            Circle()
                .stroke(isSelected ? AppTheme.Palette.brand : Color.gray.opacity(0.3), lineWidth: 2)
                .frame(width: 24, height: 24)
                .overlay {
                    if isSelected {
                        Circle()
                            .fill(AppTheme.Palette.brand)
                            .frame(width: 14, height: 14)
                    }
                }
        }
        .padding()
        .background(AppTheme.Palette.surface)
        .cornerRadius(16)
    }

    private var colorForVehicle: Color {
        switch vehicle.color {
        case .red: return .red
        case .blue: return .blue
        case .orange: return .orange
        case .green: return .green
        case .gray: return .gray
        case .white: return .gray
        case .black: return .black
        }
    }
}
