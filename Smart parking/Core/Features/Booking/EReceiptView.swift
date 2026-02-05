//
//  EReceiptView.swift
//  Smart parking
//
//  Elektron chek sahifasi - PDF download bilan
//

import PDFKit
import SwiftUI

struct EReceiptView: View {
    let parking: Parking
    let vehicle: Vehicle
    let selectedMinutes: Int
    let paymentMethod: PaymentMethod
    let reservationId: UUID

    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false
    @State private var pdfURL: URL?
    @State private var isGeneratingPDF = false

    // Calculated values
    private var startTime: Date { Date() }
    private var endTime: Date { startTime.addingTimeInterval(Double(selectedMinutes) * 60) }
    private var hours: Double { Double(selectedMinutes) / 60.0 }
    private var amount: Double { hours * parking.price_per_hour }
    private var fees: Double { 2.0 }
    private var total: Double { amount + fees }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
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
            .background(AppTheme.Palette.pageBackground.ignoresSafeArea())
            .navigationTitle("E-Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = pdfURL {
                    ShareSheet(activityItems: [url])
                }
            }
        }
    }

    // MARK: - Barcode Section
    private var barcodeSection: some View {
        VStack(spacing: 8) {
            // Barcode (deterministic based on reservation ID)
            HStack(spacing: 2) {
                ForEach(0..<40, id: \.self) { i in
                    let width = barcodeWidth(for: i)
                    Rectangle()
                        .fill(Color.black)
                        .frame(width: width, height: 60)
                }
            }
            .padding(.vertical, 8)

            Text(reservationId.uuidString.prefix(12).uppercased())
                .font(.caption)
                .foregroundColor(AppTheme.Palette.textSecondary)
        }
        .padding()
        .background(AppTheme.Palette.surface)
        .cornerRadius(16)
    }

    private func barcodeWidth(for index: Int) -> CGFloat {
        // Deterministic width based on reservation ID
        let hash = reservationId.hashValue
        let seed = abs(hash >> (index % 8)) % 4
        return CGFloat(seed + 1)
    }

    // MARK: - Vehicle Info Section
    private var vehicleInfoSection: some View {
        VStack(spacing: 12) {
            infoRow(title: "Car", value: "\(vehicle.name) (\(vehicle.type.rawValue))")
            infoRow(title: "Car Number Plate", value: vehicle.plateNumber)
            infoRow(title: "Parking", value: parking.name)
            infoRow(title: "Address", value: parking.address ?? "N/A")
        }
    }

    // MARK: - Time Info Section
    private var timeInfoSection: some View {
        VStack(spacing: 12) {
            infoRow(title: "Arriving Time", value: startTime.fullDateTime)
            infoRow(title: "Exit Time", value: endTime.fullDateTime)
            infoRow(title: "Duration", value: formatDuration(selectedMinutes))
        }
    }

    // MARK: - Price Info Section
    private var priceInfoSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Rate")
                Spacer()
                Text(String(format: "$%.2f", parking.price_per_hour))
                    .fontWeight(.medium)
                Text("/hr")
                    .foregroundColor(AppTheme.Palette.textSecondary)
            }

            HStack {
                Text("Duration")
                Spacer()
                Text(formatDuration(selectedMinutes))
                    .fontWeight(.medium)
            }

            HStack {
                Text("Subtotal")
                Spacer()
                Text(String(format: "$%.2f", amount))
                    .fontWeight(.medium)
            }

            HStack {
                Text("Service Fee")
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
                    .foregroundColor(AppTheme.Palette.brand)
            }
        }
    }

    // MARK: - Payment Info Section
    private var paymentInfoSection: some View {
        VStack(spacing: 12) {
            infoRow(title: "Payment Method", value: paymentMethod.displayName)
            infoRow(title: "Date", value: startTime.fullDateTime)
            infoRow(
                title: "Reservation ID",
                value: String(reservationId.uuidString.prefix(8)).uppercased())
            infoRow(title: "Status", value: "Confirmed ✓")
        }
    }

    // MARK: - Download Button
    private var downloadButton: some View {
        Button {
            generateAndSharePDF()
        } label: {
            HStack {
                if isGeneratingPDF {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "arrow.down.doc.fill")
                }
                Text("Download E-Receipt")
            }
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(AppTheme.Palette.brand)
            .cornerRadius(26)
        }
        .disabled(isGeneratingPDF)
        .padding(.horizontal)
        .padding(.bottom, 24)
    }

    // MARK: - PDF Generation
    private func generateAndSharePDF() {
        isGeneratingPDF = true

        Task {
            let pdfData = generatePDFData()

            // Save to temp file
            let fileName = "SmartParking_Receipt_\(reservationId.uuidString.prefix(8)).pdf"
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

            do {
                try pdfData.write(to: tempURL)
                await MainActor.run {
                    self.pdfURL = tempURL
                    self.isGeneratingPDF = false
                    self.showShareSheet = true
                }
            } catch {
                await MainActor.run {
                    self.isGeneratingPDF = false
                }
                print("PDF save error: \(error)")
            }
        }
    }

    private func generatePDFData() -> Data {
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 50

        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        return renderer.pdfData { context in
            context.beginPage()

            var yPosition: CGFloat = margin

            // Title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor.black,
            ]
            let title = "Smart Parking E-Receipt"
            title.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: titleAttributes)
            yPosition += 40

            // Divider
            let dividerPath = UIBezierPath()
            dividerPath.move(to: CGPoint(x: margin, y: yPosition))
            dividerPath.addLine(to: CGPoint(x: pageWidth - margin, y: yPosition))
            UIColor.gray.setStroke()
            dividerPath.stroke()
            yPosition += 20

            // Content
            let labelAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.gray,
            ]
            let valueAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14, weight: .medium),
                .foregroundColor: UIColor.black,
            ]

            func drawRow(_ label: String, _ value: String) {
                label.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: labelAttributes)
                value.draw(
                    at: CGPoint(x: pageWidth / 2, y: yPosition), withAttributes: valueAttributes)
                yPosition += 25
            }

            drawRow("Reservation ID:", reservationId.uuidString.prefix(8).uppercased())
            drawRow("Parking:", parking.name)
            drawRow("Address:", parking.address ?? "N/A")
            drawRow("Vehicle:", "\(vehicle.name) (\(vehicle.plateNumber))")
            drawRow("Start Time:", startTime.fullDateTime)
            drawRow("End Time:", endTime.fullDateTime)
            drawRow("Duration:", formatDuration(selectedMinutes))

            yPosition += 20

            drawRow("Rate:", String(format: "$%.2f/hr", parking.price_per_hour))
            drawRow("Subtotal:", String(format: "$%.2f", amount))
            drawRow("Service Fee:", String(format: "$%.2f", fees))

            yPosition += 10

            // Total
            let totalAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 18),
                .foregroundColor: UIColor.systemPurple,
            ]
            "Total:".draw(at: CGPoint(x: margin, y: yPosition), withAttributes: valueAttributes)
            String(format: "$%.2f", total).draw(
                at: CGPoint(x: pageWidth / 2, y: yPosition), withAttributes: totalAttributes)
            yPosition += 40

            // Footer
            let footerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.gray,
            ]
            "Thank you for using Smart Parking!".draw(
                at: CGPoint(x: margin, y: yPosition), withAttributes: footerAttributes)
        }
    }

    // MARK: - Helpers
    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(AppTheme.Palette.textSecondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }

    private func formatDuration(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h == 0 { return "\(m) min" }
        if m == 0 { return "\(h) hour\(h > 1 ? "s" : "")" }
        return "\(h)h \(m)m"
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
