import SwiftUI

/// Custom map marker bubble showing price and availability.
struct ParkingMarkerView: View {
    let price: Double
    let spots: Int?

    @State private var isPulsing = false

    private var markerColor: Color {
        guard let spots else { return AppTheme.Palette.brand }
        if spots == 0 { return AppTheme.Palette.danger }
        if spots <= 3 { return AppTheme.Palette.warning }
        return AppTheme.Palette.success
    }

    var body: some View {
        VStack(spacing: 0) {
            // Bubble
            Text("$\(price, specifier: "%.0f")")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    Capsule().fill(markerColor)
                        .shadow(color: markerColor.opacity(0.4), radius: 4, y: 2)
                )

            // Pointer triangle
            Triangle()
                .fill(markerColor)
                .frame(width: 10, height: 6)
                .offset(y: -1)
        }
        .background(
            Circle()
                .fill(markerColor.opacity(0.15))
                .frame(width: 36, height: 36)
                .scaleEffect(isPulsing ? 1.8 : 1.0)
                .opacity(isPulsing ? 0.0 : 0.6)
                .animation(
                    .easeOut(duration: 1.5).repeatForever(autoreverses: false),
                    value: isPulsing
                )
        )
        .onAppear { isPulsing = true }
    }
}

/// Simple triangle shape for the marker pointer.
private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.closeSubpath()
        return p
    }
}
