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
            ScrollView(showsIndicators: false) {
                VStack(spacing: 40) {
                    VStack(spacing: 15) {
                        TextFieldView(
                            inputText: $viewModel.code,
                            title: "Name",
                            placeHolder: "Enter Name",
                            isSecure: false
                        )
                        
                        TextFieldView(
                            inputText: $viewModel.account,
                            title: "Account",
                            placeHolder: "Enter account",
                            isSecure: true
                        )
                        
                        TextFieldView(
                            inputText: $viewModel.password,
                            title: "Password",
                            placeHolder: "Enter password",
                            isSecure: true
                        )
                    }
                    
                    ButtonView(title: "Login") {
                        viewModel.loginAction(onlyLogin: true)
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
                    .padding(.bottom, 100)
                }
                .padding(.top, 30)
            }
            .padding(.horizontal, 10)
            .onTapGesture {
                endTextEditing()
            }
            .navigationBarTitle("Happy Time", displayMode: .large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        AttendanceWebView()
                    } label: {
                        Text("Web")
                            .foregroundColor(.white)
                    }
                    .opacity(viewModel.isLogin ? 1 : 0)
                }
            }
            .ignoresSafeArea(.container, edges: .bottom)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .overlay(viewModel.isLoading ? LoadingView() : nil)
        .onAppear {
            viewModel.queryUserInfo()
        }
        .onReceive(AppManager.shared.$isReceivedNotification) { isReceived in
            if isReceived {
                viewModel.prepareForClock(.Out)
            }
        }
        .alert(isPresented: $viewModel.isPopAlert) {
            buildAlert {
                viewModel.remindAction()
            }
        }
    }
    
    
    func buildAlert(action: (() -> Void)?) -> Alert {
        
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
                                action?()
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
