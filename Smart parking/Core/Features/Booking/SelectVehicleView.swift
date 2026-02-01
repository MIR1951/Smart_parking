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
    let onContinue: () -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = VehiclesStore.shared
    @State private var showAddVehicle = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            // Vehicle List
            ScrollView(showsIndicators: false) {
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
                .padding(.horizontal)
                .padding(.top, 16)
            }

            Spacer()

            // Continue Button
            continueButton
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationBarHidden(true)
        .sheet(isPresented: $showAddVehicle) {
            AddVehicleView(store: store)
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundColor(.black)
                    .padding(12)
                    .background(Color.white)
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
                    .foregroundColor(.black)
                    .padding(12)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.1), radius: 4)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: - Continue Button
    private var continueButton: some View {
        Button(action: onContinue) {
            Text("Continue")
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(selectedVehicle != nil ? Color.purple : Color.gray)
                .cornerRadius(26)
        }
        .disabled(selectedVehicle == nil)
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
                    .foregroundColor(.gray)
            }

            Spacer()

            // Selection Circle
            Circle()
                .stroke(isSelected ? Color.purple : Color.gray.opacity(0.3), lineWidth: 2)
                .frame(width: 24, height: 24)
                .overlay {
                    if isSelected {
                        Circle()
                            .fill(Color.purple)
                            .frame(width: 14, height: 14)
                    }
                }
        }
        .padding()
        .background(Color.white)
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
