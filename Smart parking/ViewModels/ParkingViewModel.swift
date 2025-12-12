//
//  ParkingViewModel.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 12/12/25.
//

import Foundation
internal import Combine


@MainActor
final class ParkingViewModel: ObservableObject {
    @Published var popularParkings: [Parking] = []
    @Published var nearbyParkings: [Parking] = []

    private let service = ParkingService()

    func loadParkings() async {
        do {
            let all = try await service.fetchParkings()

            self.popularParkings = all.shuffled().prefix(5).map { $0 }
            self.nearbyParkings = all.shuffled().prefix(10).map { $0 }

        } catch {
            print("ERROR fetching parkings: \(error)")
        }
    }
}
