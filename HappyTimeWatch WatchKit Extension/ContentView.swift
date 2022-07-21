//
//  ContentView.swift
//  HappyTimeWatch WatchKit Extension
//
//  Created by Patty Chang on 18/07/2022.
//

import SwiftUI

struct ContentView: View {
    @State var height: CGFloat?
    @ObservedObject fileprivate var viewModel = WatchViewModel()
    
    var body: some View {
            ScrollView {
                VStack(spacing: 12) {
                    if viewModel.attendance.isEmpty {
                        Text("")
                    }
                    else {
                        Text("")
                            .frame(maxHeight: 10)
                    }

                    Button {
                        viewModel.sendMessage(.clockIn)
                    } label: {
                        Text("IN")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                    .frame(maxHeight: 50)

                    Button {
                        viewModel.sendMessage(.clockOut)
                    } label: {
                        Text("OUT")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                    .frame(maxHeight: 50)

                    if !viewModel.attendance.isEmpty {
                        Text(viewModel.attendance)
                            .font(.caption)
                            .fontWeight(.bold)
                            .lineLimit(nil)
                    }
                }
            }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
