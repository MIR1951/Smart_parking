import SwiftUI

/// Custom map marker bubble showing price and availability.
struct ParkingMarkerView: View {
    let price: Double
    let spots: Int?
    var isSelected: Bool = false

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
            Text("\(Int(price)) so'm")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    Capsule().fill(markerColor)
                        .shadow(color: markerColor.opacity(0.4), radius: 4, y: 2)
                )
                .overlay(
                    Capsule()
                        .stroke(Color.white, lineWidth: isSelected ? 2.5 : 0)
                )

            // Pointer triangle
            Triangle()
                .fill(markerColor)
                .frame(width: 10, height: 6)
                .offset(y: -1)
        }
        .scaleEffect(isSelected ? 1.3 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
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
