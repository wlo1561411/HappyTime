//
//  SwiftUIView.swift
//  HappyTime
//
//  Created by Finn Wu on 2021/8/19.
//

import SwiftUI

struct MainView: View {
    
    @StateObject fileprivate var viewModel = MainViewModel()
        
    var body: some View {
        NavigationView {
            /// Use GemtryReader for keep view postion when editing
            GeometryReader { _ in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 30) {
                        VStack(spacing: 30) {
                            TextFieldView(inputText: $viewModel.code, placeHolder: "Code", isSecure: true)
                            
                            TextFieldView(inputText: $viewModel.account, placeHolder: "Account", isSecure: true)
                            
                            TextFieldView(inputText: $viewModel.password, placeHolder: "Password", isSecure: true)
                        }
                        
                        ButtonView(title: "Login") {
                            viewModel.loginAction()
                            endTextEditing()
                        }
                        
                        HStack {
                            ButtonView(title: ClockType.In.rawValue) {
                                viewModel.prepareForClock(.In)
                                endTextEditing()
                            }
                            
                            ButtonView(title: ClockType.Out.rawValue) {
                                viewModel.prepareForClock(.Out)
                                endTextEditing()
                            }
                        }
                        
                        if let model = viewModel.punchModel {
                            PunchView(model: model)
                        }
                        
                        ButtonView(title: "Delete") {
                            viewModel.prepareForDelete()
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .padding(.top, 30)
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .navigationBarTitle("Happy Time", displayMode: .large)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .overlay(viewModel.isLoading ? LoadingView() : nil)
        .onAppear {
            viewModel.queryUserInfo()
        }
        .onTapGesture {
            endTextEditing()
        }
        .alert(isPresented: $viewModel.isPopAlert) {
            buildAlert()
        }
    }
    
    func buildAlert() -> Alert {
        let elements = viewModel.alertType.elements
        
        switch viewModel.alertType {
        case .remind:
            return Alert(
                title: Text(elements.title),
                message: elements.message == nil ? nil : Text(elements.message ?? ""),
                primaryButton:
                    .default(
                        Text("OK"),
                        action: {
                            viewModel.remindAction()
                        }
                    ),
                secondaryButton:
                    .cancel(
                        Text("Cancel")
                    )
            )
        case .response:
            return Alert(
                title: Text(elements.title),
                message: elements.message == nil ? nil : Text(elements.message ?? ""),
                dismissButton:.default(
                    Text("OK")
                )
            )
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
