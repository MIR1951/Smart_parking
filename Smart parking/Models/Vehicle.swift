//
//  Vehicle.swift
//  Smart parking
//
//  Foydalanuvchi mashinalari modeli
//

import Foundation

struct Vehicle: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String  // "Toyota Fortuner"
    var type: VehicleType  // .suv, .sedan, .mpv
    var plateNumber: String  // "GR 123-ABCD"
    var color: VehicleColor  // .red, .blue, .orange

    init(
        id: UUID = UUID(), name: String, type: VehicleType, plateNumber: String,
        color: VehicleColor = .gray
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.plateNumber = plateNumber
        self.color = color
    }
}

enum VehicleType: String, Codable, CaseIterable {
    case sedan = "Sedan"
    case suv = "SUV"
    case mpv = "MPV"
    case hatchback = "Hatchback"
    case pickup = "Pickup"
}

enum VehicleColor: String, Codable, CaseIterable {
    case red, blue, orange, green, gray, white, black

    var uiColor: String {
        switch self {
        case .red: return "car_red"
        case .blue: return "car_blue"
        case .orange: return "car_orange"
        case .green: return "car_green"
        case .gray: return "car_gray"
        case .white: return "car_white"
        case .black: return "car_black"
        }
    }
}
