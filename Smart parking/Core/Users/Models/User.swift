//
//  User.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 02/12/25.
//

import Foundation

enum UserRole: String, Codable {
    case customer
    case owner
}

struct User: Identifiable, Codable {
    let id: String
    var email: String
    var username: String
    let createdAt: Date
    var profileImageURL: String? = nil
    var role: UserRole = .customer

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case username
        case createdAt = "created_at"
        case profileImageURL = "profile_image_url"
        case role
    }

    init(
        id: String,
        email: String,
        username: String,
        createdAt: Date,
        profileImageURL: String? = nil,
        role: UserRole = .customer
    ) {
        self.id = id
        self.email = email
        self.username = username
        self.createdAt = createdAt
        self.profileImageURL = profileImageURL
        self.role = role
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        username = try container.decode(String.self, forKey: .username)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        profileImageURL = try container.decodeIfPresent(String.self, forKey: .profileImageURL)
        role = (try? container.decode(UserRole.self, forKey: .role)) ?? .customer
    }
}
