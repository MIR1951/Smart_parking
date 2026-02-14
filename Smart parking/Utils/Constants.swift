//
//  Constants.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 02/12/25.
//

import Foundation

enum Constants {
    static let projectURLString = requiredString(for: "SUPABASE_URL")
    static let projectAPIKey = requiredString(for: "SUPABASE_ANON_KEY")

    private static func requiredString(for key: String) -> String {
        guard
            let value = Bundle.main.object(forInfoDictionaryKey: key) as? String,
            !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            fatalError("Missing Info.plist key: \(key)")
        }
        return value
    }
}
