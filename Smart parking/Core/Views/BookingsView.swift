//
//  BookingsView.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 23/01/26.
//


import SwiftUI

struct BookingsView: View {
    enum Tab: String, CaseIterable { case ongoing = "Ongoing", completed = "Completed", cancelled = "Cancelled" }
    @State private var tab: Tab = .ongoing

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $tab) {
                    ForEach(Tab.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding()

                ScrollView {
                    VStack(spacing: 16) {
                        // BookingCard’lar
                        BookingCard()
                        BookingCard()
                    }
                    .padding()
                }
            }
            .navigationTitle("My Booking")
        }
    }
}

struct BookingCard: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(Color.white)
            .shadow(radius: 2)
            .frame(height: 140)
            .overlay(Text("Booking Card UI (rasmga mos qilib keyin to‘ldiramiz)"))
    }
}
