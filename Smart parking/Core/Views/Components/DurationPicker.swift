//
//  DurationPicker.swift
//  Smart parking
//
//  Created by Kenjaboy Xajiyev on 12/12/25.
//


import SwiftUI

struct DurationPicker: View {
    @Binding var duration: Int
    let presets = [30, 60, 90, 120]

    var body: some View {
        VStack {
            HStack {
                ForEach(presets, id: \.self) { m in
                    Button("\(m)m") {
                        duration = m
                    }
                    .padding()
                    .background(duration == m ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundColor(duration == m ? .white : .black)
                    .cornerRadius(10)
                }
            }

            Slider(value: Binding(
                get: { Double(duration) },
                set: { duration = Int($0) }
            ), in: 30...240, step: 15)

            Text("Tanlangan: \(duration) daqiqa")
        }
        .padding()
    }
}
