//
//  MainView.swift
//  HappyTimeMac
//
//  Created by Wesley on 2022/1/17.
//

import SwiftUI

struct MainView: View {
    
    enum ListType {
        case main
        case add
        case clock
    }
    
    @ObservedObject fileprivate var viewModel = MainViewModel()
    
    @State var listType: ListType = .main
    
    var body: some View {
        
        NavigationView {
            VStack(spacing: 10) {
                Button("Main") {
                    listType = .main
                }
                Button("Add") {
                    listType = .add
                }
                Button("Clock") {
                    listType = .clock
                }
            }
            
            
            switch listType {
            case .main:
                List (viewModel.list) { item in
                    Text(item.name)
                }
            case .add:
                VStack(spacing: 15) {
                    TextFieldView(
                        inputText: $viewModel.name,
                        title: "name",
                        placeHolder: "Enter name",
                        isSecure: false
                    )
                    
                    TextFieldView(
                        inputText: $viewModel.id,
                        title: "id",
                        placeHolder: "Enter id",
                        isSecure: false
                    )
                    
                    TextFieldView(
                        inputText: $viewModel.password,
                        title: "Password",
                        placeHolder: "Enter password",
                        isSecure: false
                    )
                    
                    Button("Add") {
                        viewModel.addData(id: viewModel.id, name: viewModel.name, password: viewModel.password)
                    }
                    
                }
            case .clock:
                VStack(spacing: 15) {
                    TextFieldView(
                        inputText: $viewModel.name,
                        title: "name",
                        placeHolder: "Enter name",
                        isSecure: false
                    )
                    
                    TextFieldView(
                        inputText: $viewModel.id,
                        title: "id",
                        placeHolder: "Enter id",
                        isSecure: false
                    )
                    
                    TextFieldView(
                        inputText: $viewModel.password,
                        title: "Password",
                        placeHolder: "Enter password",
                        isSecure: false
                    )
                    
                    Button("Login") {
                        viewModel.login()
                    }
                    
                    Button("Clock") {
                        viewModel.clock(.Out)
                    }
                    
                }
            }
            
        }.frame(minWidth: 80, minHeight: 40)
    }
    
    init() {
        viewModel.getData()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
