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
            /// Use GemtryReader for keep postion when editing
            GeometryReader { _ in
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
                    
                    VStack(alignment: .center) {
                        Text("出勤紀錄")
                        Divider()
                            .background(Color.white)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("出勤紀錄")
                            Text("出勤紀錄")
                        }
                        .padding(.vertical, 5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                    .background(
                        Color.accentColor
                            .cornerRadius(10)
                    )
                    
                    ButtonView(title: "Delete") {
                        viewModel.prepareForDelete()
                    }
                }
            }
            .padding()
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .navigationBarTitle("Happy Time", displayMode: .large)
        }
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
        switch viewModel.alertType {
        case .remind:
            return Alert(
                title: Text(viewModel.alertType.title),
                message: viewModel.alertType.message == nil ? nil : Text(viewModel.alertType.message ?? ""),
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
                title: Text(viewModel.alertType.title),
                message: viewModel.alertType.message == nil ? nil : Text(viewModel.alertType.message ?? ""),
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
