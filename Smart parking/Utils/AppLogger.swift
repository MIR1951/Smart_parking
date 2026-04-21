//
//  AppLogger.swift
//  Smart parking
//
//  Structured logging via os.Logger
//

import os
import Foundation

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.smartparking"

    static let auth = Logger(subsystem: subsystem, category: "auth")
    static let wallet = Logger(subsystem: subsystem, category: "wallet")
    static let vehicles = Logger(subsystem: subsystem, category: "vehicles")
    static let storage = Logger(subsystem: subsystem, category: "storage")
    static let booking = Logger(subsystem: subsystem, category: "booking")
    static let parking = Logger(subsystem: subsystem, category: "parking")
    static let admin = Logger(subsystem: subsystem, category: "admin")
}
