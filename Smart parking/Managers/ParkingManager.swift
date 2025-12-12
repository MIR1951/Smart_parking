//
//  ParkingManager.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 12/12/25.
//


import Foundation
import Supabase
internal import Combine

@MainActor
class ParkingManager: ObservableObject {
    @Published var parkings: [ParkingStatus] = []
    private let client = SB.client

    func fetchParkings() async {
        do {
            let response = try await client
                .from("parking_status")
                .select()
                .execute()

            // 🚀 response.data = Supabase’dan kelgan to‘g‘ri JSON Data
            let decoded = try JSONDecoder().decode([ParkingStatus].self, from: response.data)

            self.parkings = decoded

        } catch {
            print("DEBUG: fetchParkings error:", error)
        }
    }
}

