//
//  ContentView.swift
//  HappyTimeWatch WatchKit Extension
//
//  Created by Patty Chang on 18/07/2022.
//

import SwiftUI

struct ContentView: View {
    
    @ObservedObject fileprivate var viewModel = WatchViewModel()
    
    var body: some View {
        VStack {
            Text("")
                .padding()
            
            Button {
                viewModel.clock(.In)
            } label: {
                Text("IN")
                    .font(.title3)
                    .fontWeight(.bold)
                    .padding()
            }

            Button {
                viewModel.clock(.Out)
            } label: {
                Text("OUT")
                    .font(.title3)
                    .fontWeight(.bold)
                    .padding()
            }
            
            Text(viewModel.attendance)
                .font(.caption)
                .fontWeight(.bold)
                .padding()
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
