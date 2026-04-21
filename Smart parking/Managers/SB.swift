//
//  SB.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 12/12/25.
//


import Supabase
import Foundation

final class SB {
    static let shared = SB()
    
    let client: SupabaseClient
    
    private init() {
        guard let url = URL(string: Constants.projectURLString) else {
            fatalError("[SB] SUPABASE_URL in Info.plist is not a valid URL. Got: '\(Constants.projectURLString)'")
        }
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: Constants.projectAPIKey
        )
    }
}
