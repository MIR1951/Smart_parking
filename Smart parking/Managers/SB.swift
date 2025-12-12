//
//  SB.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 12/12/25.
//


import Supabase
import Foundation

final class SB {
    static let client = SupabaseClient(
        supabaseURL: URL(string: Constants.projectURLString)!,
        supabaseKey: Constants.projectAPIKey
    )
}
