//
//  ArcsView.swift
//  HappyTime
//
//  Created by Finn Wu on 2021/9/7.
//

import SwiftUI

struct ArcsView: View {
    @State var isAnimating: Bool = false
    let count: UInt
    let width: CGFloat
    let spacing: CGFloat

    var body: some View {
        GeometryReader { geometry in
            ForEach(0 ..< Int(count)) { index in
                item(forIndex: index, in: geometry.size)
                    .rotationEffect(isAnimating ? .degrees(360) : .degrees(0))
                    .animation(
                        Animation.default
                            .speed(Double.random(in: 0.2...0.5))
                            .repeatCount(isAnimating ? .max : 1, autoreverses: false)
                    )
            }
        }
        .aspectRatio(contentMode: .fit)
        .onAppear {
            isAnimating = true
        }
        .onDisappear {
            isAnimating = false
        }
    }

    private func item(forIndex index: Int, in geometrySize: CGSize) -> some View {
        Group { () -> Path in
            var p = Path()
            p.addArc(
                center: CGPoint(x: geometrySize.width / 2, y: geometrySize.height / 2),
                radius: geometrySize.width / 2 - width / 2 - CGFloat(index) * (width + spacing),
                startAngle: .degrees(0),
                endAngle: .degrees(Double(Int.random(in: 120...300))),
                clockwise: true
            )
            return p.strokedPath(.init(lineWidth: width))
        }
        .frame(width: geometrySize.width, height: geometrySize.height)
    }
}
