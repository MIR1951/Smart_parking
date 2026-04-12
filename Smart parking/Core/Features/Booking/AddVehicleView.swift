//
//  AddVehicleView.swift
//  Smart parking
//
//  Yangi mashina qo'shish sahifasi - brand va model tanlash bilan
//

import SwiftUI

// MARK: - Car Brands & Models Data
struct CarBrand: Identifiable {
    let id = UUID()
    let name: String
    let models: [String]
}

let carBrands: [CarBrand] = [
    CarBrand(
        name: "Toyota",
        models: ["Camry", "Corolla", "Fortuner", "Land Cruiser", "Prado", "RAV4", "Hilux"]),
    CarBrand(
        name: "Chevrolet",
        models: ["Malibu", "Captiva", "Cobalt", "Spark", "Tracker", "Tahoe", "Traverse"]),
    CarBrand(
        name: "Hyundai",
        models: ["Sonata", "Tucson", "Santa Fe", "Accent", "Elantra", "Palisade", "Kona"]),
    CarBrand(
        name: "Kia", models: ["Sportage", "K5", "Seltos", "Sorento", "Carnival", "Rio", "Cerato"]),
    CarBrand(name: "BMW", models: ["3 Series", "5 Series", "7 Series", "X3", "X5", "X7", "M3"]),
    CarBrand(
        name: "Mercedes",
        models: ["C-Class", "E-Class", "S-Class", "GLE", "GLC", "G-Class", "A-Class"]),
    CarBrand(name: "Audi", models: ["A4", "A6", "A8", "Q3", "Q5", "Q7", "Q8"]),
    CarBrand(
        name: "Volkswagen",
        models: ["Passat", "Tiguan", "Touareg", "Polo", "Golf", "Jetta", "Atlas"]),
    CarBrand(name: "Lexus", models: ["ES", "RX", "LX", "NX", "GX", "IS", "LS"]),
    CarBrand(
        name: "Honda", models: ["Accord", "Civic", "CR-V", "Pilot", "HR-V", "Odyssey", "City"]),
]

// MARK: - Add Vehicle View
struct AddVehicleView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: VehiclesStore
    private let loc = LocalizationManager.shared

    @State private var selectedBrand: CarBrand?
    @State private var selectedModel: String?
    @State private var plateNumber: String = ""

    @State private var showBrandPicker = false
    @State private var showModelPicker = false

    private var isValid: Bool {
        selectedBrand != nil && selectedModel != nil && !plateNumber.isEmpty
    }

    private var vehicleName: String {
        guard let brand = selectedBrand, let model = selectedModel else { return "" }
        return "\(brand.name) \(model)"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            // Form Content
            VStack(alignment: .leading, spacing: 24) {

                // Select Brand
                VStack(alignment: .leading, spacing: 10) {
                    Text(loc.str(.vehicleSelectBrand))
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Button {
                        showBrandPicker = true
                    } label: {
                        HStack {
                            Text(selectedBrand?.name ?? loc.str(.vehicleSelectBrand))
                                .foregroundColor(selectedBrand == nil ? .gray : .primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(AppTheme.Palette.brand)
                        }
                        .padding()
                        .background(AppTheme.Palette.surface)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    }
                }

                // Select Car (Model)
                VStack(alignment: .leading, spacing: 10) {
                    Text(loc.str(.vehicleSelectCar))
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Button {
                        if selectedBrand != nil {
                            showModelPicker = true
                        }
                    } label: {
                        HStack {
                            Text(selectedModel ?? loc.str(.vehicleSelectModel))
                                .foregroundColor(selectedModel == nil ? .gray : .primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(AppTheme.Palette.brand)
                        }
                        .padding()
                        .background(AppTheme.Palette.surface)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .disabled(selectedBrand == nil)
                    .opacity(selectedBrand == nil ? 0.6 : 1)
                }

                // Car Number Plate
                VStack(alignment: .leading, spacing: 10) {
                    Text(loc.str(.vehiclePlateNumber))
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    TextField(loc.str(.vehiclePlatePlaceholder), text: $plateNumber)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(AppTheme.Palette.surface)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .textInputAutocapitalization(.characters)
                }
            }
            .padding(.horizontal)
            .padding(.top, 24)
            .appReveal(0.04)

            Spacer()

            // Add Vehicle Button
            addButton
        }
        .background(AppAnimatedBackground())
        .navigationBarHidden(true)
        .sheet(isPresented: $showBrandPicker) {
            BrandPickerSheet(selectedBrand: $selectedBrand, selectedModel: $selectedModel)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showModelPicker) {
            if let brand = selectedBrand {
                ModelPickerSheet(brand: brand, selectedModel: $selectedModel)
                    .presentationDetents([.medium])
            }
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundColor(AppTheme.Palette.textPrimary)
                    .padding(12)
                    .background(AppTheme.Palette.surface)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.1), radius: 4)
            }
            .pressStyle()

            Spacer()

            Text(loc.str(.vehicleAddTitle))
                .font(.headline)

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: - Add Button
    private var addButton: some View {
        Button {
            let vehicle = Vehicle(
                name: vehicleName,
                type: guessVehicleType(selectedBrand?.name ?? "", selectedModel ?? ""),
                plateNumber: plateNumber
            )
            store.add(vehicle)
            dismiss()
        } label: {
            Text(loc.str(.vehicleAdd))
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background {
                    if isValid {
                        AppTheme.Gradient.brand
                    } else {
                        Color.gray
                    }
                }
                .cornerRadius(26)
        }
        .disabled(!isValid)
        .pressStyle()
        .padding(.horizontal)
        .padding(.bottom, 24)
    }

    // MARK: - Helper
    private func guessVehicleType(_ brand: String, _ model: String) -> VehicleType {
        let suvKeywords = [
            "Fortuner", "Land Cruiser", "Prado", "RAV4", "Tucson", "Santa Fe", "Sportage",
            "Sorento", "X3", "X5", "X7", "GLE", "GLC", "Q5", "Q7", "Q8", "Tiguan", "Touareg", "RX",
            "LX", "GX", "CR-V", "Pilot",
        ]
        let mpvKeywords = ["Carnival", "Odyssey", "Innova", "Traverse"]
        let pickupKeywords = ["Hilux", "Tahoe"]

        if suvKeywords.contains(where: { model.contains($0) }) { return .suv }
        if mpvKeywords.contains(where: { model.contains($0) }) { return .mpv }
        if pickupKeywords.contains(where: { model.contains($0) }) { return .pickup }
        return .sedan
    }
}

// MARK: - Brand Picker Sheet
private struct BrandPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedBrand: CarBrand?
    @Binding var selectedModel: String?
    private let loc = LocalizationManager.shared

    var body: some View {
        NavigationStack {
            List(carBrands) { brand in
                HStack {
                    Text(brand.name)
                        .font(.body)

                    Spacer()

                    if selectedBrand?.name == brand.name {
                        Image(systemName: "checkmark")
                            .foregroundColor(AppTheme.Palette.brand)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedBrand = brand
                    selectedModel = nil  // Reset model when brand changes
                    dismiss()
                }
            }
            .navigationTitle(loc.str(.vehicleSelectBrand))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(loc.str(.cancel)) { dismiss() }
                }
            }
        }
    }
}

// MARK: - Model Picker Sheet
private struct ModelPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let brand: CarBrand
    @Binding var selectedModel: String?
    private let loc = LocalizationManager.shared

    var body: some View {
        NavigationStack {
            List(brand.models, id: \.self) { model in
                HStack {
                    Text(model)
                        .font(.body)

                    Spacer()

                    if selectedModel == model {
                        Image(systemName: "checkmark")
                            .foregroundColor(AppTheme.Palette.brand)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedModel = model
                    dismiss()
                }
            }
            .navigationTitle("\(loc.str(.vehicleSelectModel)): \(brand.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(loc.str(.cancel)) { dismiss() }
                }
            }
        }
    }
}
