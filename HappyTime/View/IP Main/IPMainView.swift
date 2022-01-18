//
//  IPMainView.swift
//  HappyTime
//
//  Created by Finn Wu on 2021/8/19.
//

import SwiftUI
import Firebase

struct IPMainView: View {
    
    @StateObject fileprivate var viewModel = IPMainViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 40) {
                    VStack(spacing: 15) {
                        TextFieldView(
                            inputText: $viewModel.name,
                            title: "Name",
                            placeHolder: "Enter Name",
                            isSecure: false
                        )
                    }
                    
                    HStack {
                        
                        Button(action: {
                            viewModel.prepareForClock(.In)
                            endTextEditing()
                        }, label: {
                            Text(ClockType.In.rawValue)
                                .font(.title2)
                                .frame(maxWidth: .infinity)
                                .foregroundColor(viewModel.isAvailable ? .white:.gray)
                                .padding()
                        })
                        .background(
                            Color.accentColor
                                .cornerRadius(10)
                        )
                        .disabled(!viewModel.isAvailable)
                        
                        Button(action: {
                            viewModel.prepareForClock(.Out)
                            endTextEditing()
                        }, label: {
                            Text(ClockType.Out.rawValue)
                                .font(.title2)
                                .frame(maxWidth: .infinity)
                                .foregroundColor(viewModel.isAvailable ? .white:.gray)
                                .padding()
                        })
                        .background(
                            Color.accentColor
                                .cornerRadius(10)
                        )
                        .disabled(!viewModel.isAvailable)
                    }
                    
                }
                .padding(.top, 30)
            }
            .padding(.horizontal, 10)
            .navigationBarTitle("Happy Time", displayMode: .large)
            .ignoresSafeArea(.container, edges: .bottom)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .overlay(viewModel.isLoading ? LoadingView() : nil)
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

struct IPMainView_Previews: PreviewProvider {
    static var previews: some View {
        IPMainView()
    }
}
