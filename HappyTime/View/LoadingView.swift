//
//  LoadingView.swift
//  HappyTime
//
//  Created by Finn Wu on 2021/9/7.
//

import SwiftUI

struct LoadingView: View {
    
    var body: some View {
        ZStack {
            Color
                .black
                .opacity(0.6)
                .ignoresSafeArea()
            
            VStack {
                BarsView(count: 5, spacing: 7, cornerRadius: 5)
                    .frame(width: 50, height: 48, alignment: .center)
                    .padding(.top, 3)
                
                Text("載入中")
                    .padding(.top, 8)
            }
            .background(
                Color
                    .accentColor
                    .frame(width: 120, height: 125, alignment: .center)
                    .cornerRadius(10)
            )
        }
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView()
    }
}
