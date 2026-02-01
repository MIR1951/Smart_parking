//
//  EReceiptView.swift
//  Smart parking
//
//  Elektron chek sahifasi
//

import SwiftUI

struct EReceiptView: View {
    let parking: Parking
    let vehicle: Vehicle
    let selectedMinutes: Int
    let paymentMethod: PaymentMethod
    let reservationId: UUID

    @Environment(\.dismiss) private var dismiss

    // Calculated values
    private var startTime: Date { Date() }
    private var endTime: Date { startTime.addingTimeInterval(Double(selectedMinutes) * 60) }
    private var hours: Double { Double(selectedMinutes) / 60.0 }
    private var amount: Double { hours * parking.price_per_hour }
    private var fees: Double { 2.0 }
    private var total: Double { amount + fees }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Barcode
                    barcodeSection

                    // Vehicle Info
                    vehicleInfoSection

                    Divider()

                    // Time Info
                    timeInfoSection

                    Divider()

                    // Price Info
                    priceInfoSection

                    Divider()

                    // Payment Info
                    paymentInfoSection
                }
                .padding(.horizontal)
                .padding(.top, 16)
            }

            Spacer()

            // Download Button
            downloadButton
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationBarHidden(true)
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

            Text("E-Receipt")
                .font(.headline)

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: - Barcode Section
    private var barcodeSection: some View {
        VStack {
            // Fake barcode using rectangles
            HStack(spacing: 2) {
                ForEach(0..<40, id: \.self) { i in
                    Rectangle()
                        .fill(Color.black)
                        .frame(width: CGFloat.random(in: 1...4), height: 60)
                }
            }
            .padding(.vertical, 8)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }

    // MARK: - Vehicle Info Section
    private var vehicleInfoSection: some View {
        VStack(spacing: 12) {
            infoRow(title: "Car", value: "\(vehicle.name) (\(vehicle.type.rawValue))")
            infoRow(title: "Car Number Plate", value: vehicle.plateNumber)
            infoRow(title: "Parking", value: parking.name)
        }
    }

    // MARK: - Time Info Section
    private var timeInfoSection: some View {
        VStack(spacing: 12) {
            infoRow(title: "Arriving Time", value: formatDateTime(startTime))
            infoRow(title: "Exit Time", value: formatDateTime(endTime))
            infoRow(title: "Duration", value: formatDuration(selectedMinutes))
        }
    }

    // MARK: - Price Info Section
    private var priceInfoSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Amount")
                Spacer()
                Text(String(format: "$%.2f", parking.price_per_hour))
                    .fontWeight(.medium)
                Text("/hr")
                    .foregroundColor(.gray)
            }

            HStack {
                Text("Total Hours")
                Spacer()
                Text(formatDuration(selectedMinutes))
                    .fontWeight(.medium)
            }

            HStack {
                Text("Fees")
                Spacer()
                Text(String(format: "$%.2f", fees))
                    .fontWeight(.medium)
            }

            Divider()

            HStack {
                Text("Total")
                    .fontWeight(.semibold)
                Spacer()
                Text(String(format: "$%.2f", total))
                    .font(.title3)
                    .fontWeight(.bold)
            }
        }
    }

    // MARK: - Payment Info Section
    private var paymentInfoSection: some View {
        VStack(spacing: 12) {
            infoRow(title: "Payment Methods", value: paymentMethod.displayName)
            infoRow(title: "Date", value: formatDate(Date()))
            infoRow(
                title: "Reservation ID",
                value: String(reservationId.uuidString.prefix(8)).uppercased())
        }
    }

    // MARK: - Download Button
    private var downloadButton: some View {
        Button {
            // Download action - could generate PDF
        } label: {
            Text("Download E-Receipt")
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(Color.purple)
                .cornerRadius(26)
        }
        .padding(.horizontal)
        .padding(.bottom, 24)
    }

    // MARK: - Helpers
    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }

    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM dd | hh:mm a"
        return formatter.string(from: date)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy | hh:mm a"
        return formatter.string(from: date)
    }

    private func formatDuration(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h == 0 { return "\(m) min" }
        if m == 0 { return "\(h) hour\(h > 1 ? "s" : "")" }
        return "\(h)h \(m)m"
    }
}
