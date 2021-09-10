//
//  TextFieldView.swift
//  HappyTime
//
//  Created by Finn Wu on 2021/8/19.
//

import SwiftUI

struct TextFieldView: View {
        
    @Binding var inputText: String
    
    let title: String
    let placeHolder: String
    let isSecure: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(title)
                .font(.headline)
                .padding(.leading, 10)
            
            GroupBox {
                if isSecure {
                    SecureField(placeHolder, text: $inputText)
                        .accentColor(.white)
                }
                else {
                    TextField(placeHolder, text: $inputText)
                        .accentColor(.white)
                }
            }
        }
    }
}

struct TextFieldView_Previews: PreviewProvider {
    @State static var text = ""
    
    static var previews: some View {
        TextFieldView(inputText: $text, title: "AAAAAAA", placeHolder: "testtt", isSecure: false)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
