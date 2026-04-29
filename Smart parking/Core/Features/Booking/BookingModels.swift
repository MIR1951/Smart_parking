import Foundation

// MARK: - BookingParking

struct BookingParking: Codable, Identifiable {
    let id: UUID
    let name: String
    let city: String?
    let address: String?
    let latitude: Double?
    let longitude: Double?
    let thumbnail_url: String?
    let price_per_hour: Double
    let rating: Double?
    let total_spots: Int?
    let description: String?
    let is_popular: Bool?
    let images: [String]?
    let features: [String]?

    init(
        id: UUID,
        name: String,
        city: String? = nil,
        address: String?,
        latitude: Double? = nil,
        longitude: Double? = nil,
        thumbnail_url: String?,
        price_per_hour: Double,
        rating: Double?,
        total_spots: Int? = nil,
        description: String? = nil,
        is_popular: Bool? = nil,
        images: [String]? = nil,
        features: [String]? = nil
    ) {
        self.id = id
        self.name = name
        self.city = city
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.thumbnail_url = thumbnail_url
        self.price_per_hour = price_per_hour
        self.rating = rating
        self.total_spots = total_spots
        self.description = description
        self.is_popular = is_popular
        self.images = images
        self.features = features
    }

    var asParking: Parking {
        Parking(
            id: id,
            name: name,
            city: city ?? "Tashkent",
            address: address,
            latitude: latitude ?? 41.3111,
            longitude: longitude ?? 69.2797,
            price_per_hour: price_per_hour,
            rating: rating,
            thumbnail_url: thumbnail_url,
            total_spots: total_spots ?? 0,
            live_occupancy: nil,
            description: description,
            is_popular: is_popular,
            images: images,
            features: features
        )
    }
}

// MARK: - BookingItem

struct BookingItem: Codable, Identifiable {
    let id: UUID
    let status: String

    let start_time: Date?
    let end_time: Date?
    let actual_start_time: Date?
    let actual_end_time: Date?

    let parking: BookingParking

    var isInParking: Bool {
        status == "in_use"
    }

    var isCompleted: Bool {
        status == "completed" || status == "expired" || status == "no_show"
            || (status == "active" && (end_time ?? Date()) <= Date())
    }

    var isCancelled: Bool {
        status == "canceled" || status == "cancelled"
    }

    var canCancel: Bool {
        status == "active" && actual_start_time == nil
    }

    var durationMinutes: Int {
        guard let start = start_time, let end = end_time else { return 0 }
        return Int(end.timeIntervalSince(start) / 60)
    }

    var totalAmount: Double {
        let hours = Double(durationMinutes) / 60.0
        return hours * parking.price_per_hour
    }

    var isOvertime: Bool {
        guard let end = end_time else { return false }
        return Date() > end && status == "in_use"
    }

    var overtimeAmount: Double {
        guard isOvertime, let end = end_time else { return 0 }
        let overtimeMinutes = Date().timeIntervalSince(end) / 60
        let extra30MinBlocks = ceil(overtimeMinutes / 30)
        let halfHourRate = parking.price_per_hour / 2
        return extra30MinBlocks * halfHourRate
    }
}

// MARK: - BookingTab

enum BookingTab: String, CaseIterable {
    case ongoing = "Ongoing"
    case completed = "Completed"
    case cancelled = "Cancelled"

    var displayName: String {
        switch self {
        case .ongoing: return LocalizationManager.shared.str(.bookingsOngoing)
        case .completed: return LocalizationManager.shared.str(.bookingsCompleted)
        case .cancelled: return LocalizationManager.shared.str(.bookingsCancelled)
        }
    }
}
