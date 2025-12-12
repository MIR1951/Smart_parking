//
//  UserManager.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 11/12/25.
//

import Foundation

@Observable
@MainActor
class UserManager {
    var currentUser: User?
    private var service: UserService
    
    init(service: UserService = UserService()) {
        self.service = service
    }
    
    func fetchCorrentUser () async  {
        do{
            self.currentUser = try await self.service.fetchCorrentUser()
        }
        catch{
            print("DEBUG: Error fetching current user\(error)")
        }
    }
    func updateProfileImageURL(_ imageURL: String) async {
        do {
            try await service.updateProfileImageURL(imageURL)
            self.currentUser?.profileImageURL = imageURL
        }catch{
            print("DEBUG: failed to update profile image url \(error)")
        }
    }
}
