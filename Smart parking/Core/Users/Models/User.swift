//
//  User.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 02/12/25.
//

import Foundation

struct User: Identifiable, Codable {
    let id: String
    var email: String
    var username: String
    let createdAt: Date
    var profileImageURL: String? = nil

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case username
        case createdAt = "created_at"
        case profileImageURL = "profile_image_url"
    }
}
