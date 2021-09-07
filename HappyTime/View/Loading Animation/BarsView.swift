//
//  BarsView.swift
//  HappyTime
//
//  Created by Finn Wu on 2021/9/7.
//

import SwiftUI

struct BarsView: View {
    @State var isAnimating: Bool = false
    
    let count: Int
    let spacing: CGFloat
    let cornerRadius: CGFloat
    let scaleRange: ClosedRange<Double>
    let opacityRange: ClosedRange<Double>

    init(count: Int = 8,
         spacing: CGFloat = 8,
         cornerRadius: CGFloat = 8,
         scaleRange: ClosedRange<Double> = (0.5...1),
         opacityRange: ClosedRange<Double> = (0.25...1)) {
        
        self.count = count
        self.spacing = spacing
        self.cornerRadius = cornerRadius
        self.scaleRange = scaleRange
        self.opacityRange = opacityRange
    }
    
    var body: some View {
        GeometryReader { geometry in
            ForEach(0 ..< count) { index in
                item(forIndex: index, in: geometry.size)
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

    private var scale: CGFloat { CGFloat(isAnimating ? scaleRange.lowerBound : scaleRange.upperBound) }
    private var opacity: Double { isAnimating ? opacityRange.lowerBound : opacityRange.upperBound }

    private func size(count: UInt, geometry: CGSize) -> CGFloat {
        (geometry.width / CGFloat(count)) - (spacing - 2)
    }

    private func item(forIndex index: Int, in geometrySize: CGSize) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius,  style: .continuous)
            .frame(width: size(count: UInt(count), geometry: geometrySize), height: geometrySize.height)
            .scaleEffect(x: 1, y: scale, anchor: .center)
            .opacity(opacity)
            .animation(
                Animation
                    .default
                    .repeatCount(isAnimating ? .max : 1, autoreverses: true)
                    .delay(Double(index) / Double(count) / 2)
            )
            .offset(x: CGFloat(index) * (size(count: UInt(count), geometry: geometrySize) + spacing))
    }
}
