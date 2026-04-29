import SwiftUI

struct BookingCard: View {
    let item: BookingItem
    let tab: BookingTab
    let onCardTap: () -> Void
    let onLeftTap: () -> Void
    let onTicketTap: () -> Void

    private var leftButtonTitle: String {
        switch tab {
        case .ongoing:
            if item.isInParking {
                return LocalizationManager.shared.str(.bookingsTimer)
            } else if item.canCancel {
                return LocalizationManager.shared.str(.bookingsCancel)
            } else {
                return LocalizationManager.shared.str(.bookingsView)
            }
        case .completed:
            return LocalizationManager.shared.str(.bookingsView)
        case .cancelled:
            return LocalizationManager.shared.str(.bookingsView)
        }
    }

    private var rightButtonTitle: String {
        switch tab {
        case .ongoing:
            return LocalizationManager.shared.str(.bookingsETicket)
        case .completed:
            return LocalizationManager.shared.str(.bookingsViewReceipt)
        case .cancelled:
            return LocalizationManager.shared.str(.bookingsDetails)
        }
    }

    private var leftButtonStyle: (Color, Color) {
        switch tab {
        case .ongoing:
            if item.canCancel {
                return (AppTheme.Palette.danger.opacity(0.12), AppTheme.Palette.danger)
            } else {
                return (AppTheme.Palette.brand.opacity(0.12), AppTheme.Palette.brand)
            }
        case .completed:
            return (AppTheme.Palette.success.opacity(0.12), AppTheme.Palette.success)
        case .cancelled:
            return (AppTheme.Palette.warning.opacity(0.12), AppTheme.Palette.warning)
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    CachedAsyncImage(url: URL(string: item.parking.thumbnail_url ?? "")) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Rectangle().fill(Color.gray.opacity(0.2))
                    }
                    .frame(width: 110, height: 90)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(LocalizationManager.shared.str(.detailCarParking))
                                .font(.caption)
                                .foregroundColor(AppTheme.Palette.brand)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(AppTheme.Palette.brand.opacity(0.10))
                                .clipShape(Capsule())

                            Spacer()

                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.Palette.warning)
                                Text(String(format: "%.1f", item.parking.rating ?? 4.5))
                                    .font(.caption)
                                    .foregroundColor(AppTheme.Palette.textSecondary)
                            }
                        }

                        Text(item.parking.name)
                            .font(.headline)
                            .foregroundColor(AppTheme.Palette.textPrimary)
                            .lineLimit(1)

                        HStack(spacing: 6) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.caption)
                                .foregroundColor(AppTheme.Palette.textSecondary)
                            Text(item.parking.address ?? LocalizationManager.shared.str(.bookingsUnknown))
                                .font(.caption)
                                .foregroundColor(AppTheme.Palette.textSecondary)
                                .lineLimit(1)
                        }

                        HStack(spacing: 4) {
                            Text("\(Int(item.parking.price_per_hour)) \(LocalizationManager.shared.str(.walletCurrency))")
                                .font(.headline)
                                .foregroundColor(AppTheme.Palette.brand)
                            Text(LocalizationManager.shared.str(.bookingsPerHour))
                                .font(.caption)
                                .foregroundColor(AppTheme.Palette.textSecondary)
                        }
                    }
                }

                timeInfoSection

                if item.isOvertime {
                    overtimeWarning
                }
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onCardTap)

            if tab == .ongoing {
                HStack(spacing: 12) {
                    Button(action: onLeftTap) {
                        Text(leftButtonTitle)
                            .fontWeight(.semibold)
                            .foregroundColor(leftButtonStyle.1)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(leftButtonStyle.0)
                            .clipShape(Capsule())
                    }
                    .pressStyle()

                    Button(action: onTicketTap) {
                        Text(rightButtonTitle)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(AppTheme.Gradient.brand)
                            .clipShape(Capsule())
                    }
                    .pressStyle()
                }
            } else {
                Button(action: onTicketTap) {
                    Text(rightButtonTitle)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppTheme.Gradient.brand)
                        .clipShape(Capsule())
                }
                .pressStyle()
            }
        }
        .padding(14)
        .background(AppTheme.Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                .stroke(AppTheme.Palette.border, lineWidth: 1)
        )
        .appShadow(AppTheme.Shadow.small())
    }

    // MARK: - Time Info Section
    private var timeInfoSection: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizationManager.shared.str(.bookingsStart))
                    .font(.caption2)
                    .foregroundColor(AppTheme.Palette.textSecondary)
                Text(formatTime(item.start_time))
                    .font(.caption)
                    .fontWeight(.medium)
            }

            Image(systemName: "arrow.right")
                .font(.caption)
                .foregroundColor(AppTheme.Palette.textSecondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizationManager.shared.str(.bookingsEnd))
                    .font(.caption2)
                    .foregroundColor(AppTheme.Palette.textSecondary)
                Text(formatTime(item.end_time))
                    .font(.caption)
                    .fontWeight(.medium)
            }

            Spacer()

            Text("\(item.durationMinutes) \(LocalizationManager.shared.str(.bookingMin))")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.Palette.brand)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(AppTheme.Palette.brand.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(AppTheme.Palette.pageBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Overtime Warning
    private var overtimeWarning: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(AppTheme.Palette.warning)

            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizationManager.shared.str(.bookingsOvertime))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.Palette.warning)

                Text("\(LocalizationManager.shared.str(.bookingsExtraCharge)): $\(item.overtimeAmount, specifier: "%.2f")")
                    .font(.caption2)
                    .foregroundColor(AppTheme.Palette.textSecondary)
            }

            Spacer()
        }
        .padding(10)
        .background(AppTheme.Palette.warningSoft)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func formatTime(_ date: Date?) -> String {
        guard let date = date else { return "--:--" }
        return DateFormatter.shortDateTime.string(from: date)
    }
}
