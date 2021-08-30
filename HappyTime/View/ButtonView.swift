//
//  ButtonView.swift
//  HappyTime
//
//  Created by Finn Wu on 2021/8/19.
//

import SwiftUI

struct ButtonView: View {
    
    let title: String
    
    var action: (() -> Void)?
    
    var body: some View {
        Button(action: {
            action?()
        }, label: {
            Text(title)
                .font(.title2)
                .frame(maxWidth: .infinity)
                .foregroundColor(.white)
                .padding()
        })
        .background(
            Color.accentColor
                .cornerRadius(10)
        )
    }
}

struct ButtonView_Previews: PreviewProvider {
    static var previews: some View {
        ButtonView(title: "TEST") {
            print("????")
        }
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
