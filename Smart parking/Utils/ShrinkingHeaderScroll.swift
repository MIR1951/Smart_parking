//
//  ShrinkingHeaderScroll.swift
//  Smart parking
//
//  Reusable container that collapses a sticky header as the user scrolls down.
//  Usage:
//    ShrinkingHeaderScroll(collapseRange: 200) { progress in
//        MyHeader(progress: progress)
//    } content: {
//        MyScrollContent()
//    }
//

import SwiftUI

struct ShrinkingHeaderScroll<Header: View, Content: View>: View {
    var collapseRange: CGFloat = 200

    @ViewBuilder let header: (_ progress: CGFloat) -> Header
    @ViewBuilder let content: () -> Content

    @State private var scrollOffset: CGFloat = 0

    private let spaceName = "ShrinkingHeaderScroll"

    var progress: CGFloat {
        min(max(scrollOffset / collapseRange, 0), 1)
    }

    var body: some View {
        VStack(spacing: 0) {
            header(progress)
                .animation(AppTheme.Anim.snappy, value: scrollOffset)

            ScrollView(showsIndicators: false) {
                GeometryReader { geo in
                    Color.clear
                        .preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: -geo.frame(in: .named(spaceName)).minY
                        )
                }
                .frame(height: 0)

                content()
            }
            .coordinateSpace(name: spaceName)
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                scrollOffset = value
            }
        }
    }
}
