import SwiftUI

struct EditorFeaturesSection: View {
    @Binding var selectedFeatures: Set<String>

    private let features = [
        "CCTV", "24/7", "Covered", "EV Charging", "Disabled Access",
        "Security Guard", "WiFi", "Car Wash", "Valet",
    ]

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
            spacing: 10
        ) {
            ForEach(features, id: \.self) { feature in
                chip(feature)
            }
        }
    }

    private func chip(_ feature: String) -> some View {
        let isSelected = selectedFeatures.contains(feature)
        return Text(feature)
            .font(AppTheme.Typography.caption)
            .fontWeight(.medium)
            .foregroundColor(isSelected ? .white : AppTheme.Palette.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                isSelected
                    ? AnyShapeStyle(LinearGradient(
                        colors: [AppTheme.Palette.brand, AppTheme.Palette.brandLight],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    : AnyShapeStyle(AppTheme.Palette.surfaceSecondary)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .onTapGesture {
                withAnimation(AppTheme.Anim.quick) {
                    if isSelected { selectedFeatures.remove(feature) }
                    else { selectedFeatures.insert(feature) }
                }
            }
    }
}
