//
//  Extension.swift
//  HappyTime
//
//  Created by Finn Wu on 2021/8/24.
//

import Foundation
import SwiftUI

extension Data{
    mutating func appendString(_ string: String) {
        guard let data = string.data(using: String.Encoding.utf8, allowLossyConversion: true) else { return }
        append(data)
    }
}

extension Double {
    func decimal(_ number: Int) -> Double {
        let muitple = pow(10.0, Double(number))
        return (self * muitple).rounded(.down) / muitple
    }
}

extension View {
    
    func frameFromGeometryReader(_ closure: @escaping (CGRect) -> Void) -> some View {
        overlay(
            GeometryReader { reader in
                Color
                    .clear
                    .onAppear {
                        DispatchQueue.main.async {
                            closure(reader.frame(in: .global))
                        }
                    }
            }
        )
    }
    
    func endTextEditing() {
        UIApplication
            .shared
            .sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil, from: nil, for: nil
            )
    }
}
