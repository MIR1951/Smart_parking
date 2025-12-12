//
//  Reservation.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 12/12/25.
//


import Foundation

struct Reservation: Identifiable, Codable {
    let id: UUID
    let parking_id: UUID
    let user_id: UUID
    
    let start_time: Date
    let end_time: Date

    var actual_start_time: Date?
    var actual_end_time: Date?
    var status: String
}
