//
//  User.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 02/12/25.
//

import Foundation

struct User :Identifiable, Codable{
    let id: String
    let email: String
    let username: String
    let createdAt: Date
    let profileImageURL: String? = nil
    
    
    
}
