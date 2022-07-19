//
//  MainView.swift
//  HappyTimeMac
//
//  Created by Wesley on 2022/1/17.
//

import SwiftUI

struct MainView: View {
    
    enum ListType {
        case member
        case log
    }
    
    @ObservedObject fileprivate var viewModel = MainViewModel()
    
    @ObservedObject fileprivate var viewModel_Realtime = MainViewModel_Realtime()
    
    @State var listType: ListType = .member
    
    var body: some View {
        
//        NavigationView {
//            VStack(spacing: 10) {
//                Button("Member") {
//                    listType = .member
//                }
//                Button("Log") {
//                    listType = .log
//                }
//            }
//
//            switch listType {
//            case .member:
//
//                    List (viewModel.userList) {
//                        Text($0.name)
//                    }
//            case .log:

                List (viewModel.log, id: \.self) { item in
                    Text(item)
                }
//            }

//        }.frame(minWidth: 360, minHeight: 360)
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
