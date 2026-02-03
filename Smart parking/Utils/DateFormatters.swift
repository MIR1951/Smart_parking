//
//  DateFormatters.swift
//  Smart parking
//
//  Optimizatsiya uchun static DateFormatter'lar
//

import Foundation

extension DateFormatter {
    /// "MMM dd, HH:mm" format (Jan 15, 14:30)
    static let shortDateTime: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM dd, HH:mm"
        return f
    }()

    /// "MMM dd, yyyy HH:mm" format (Jan 15, 2026 14:30)
    static let fullDateTime: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM dd, yyyy HH:mm"
        return f
    }()

    /// "HH:mm" format (14:30)
    static let timeOnly: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    /// "MMM dd" format (Jan 15)
    static let shortDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM dd"
        return f
    }()
}

extension Date {
    var shortDateTime: String {
        DateFormatter.shortDateTime.string(from: self)
    }

    var fullDateTime: String {
        DateFormatter.fullDateTime.string(from: self)
    }

    var timeOnly: String {
        DateFormatter.timeOnly.string(from: self)
    }

    var shortDate: String {
        DateFormatter.shortDate.string(from: self)
    }
}
