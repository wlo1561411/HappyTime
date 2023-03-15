//
//  AddUserView.swift
//  HappyTime
//
//  Created by Patty Chang on 15/03/2023.
//

import SwiftUI

struct AddUserView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @StateObject fileprivate var mainViewModel = MainViewModel()
    @State private var name: String = ""
    @State private var account: String = ""
    @State private var password: String = ""
    
    @State private var result: (user: [User], error: String?) = ([], nil)
    @State private var showAlert: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            TextFieldView(
                inputText: $name,
                title: "Name",
                placeHolder: "Enter name",
                isSecure: false
            )
            
            TextFieldView(
                inputText: $account,
                title: "Account",
                placeHolder: "Enter account",
                isSecure: true
            )
            
            TextFieldView(
                inputText: $password,
                title: "Password",
                placeHolder: "Enter password",
                isSecure: true
            )
            
            Button {
                add()
            } label: {
                Text("Add")
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                    .padding(10)
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white, lineWidth: 2)
                    }
            }
            .padding(.top)
            
            Spacer()
        }
        .padding(.top, 40)
        .padding(.horizontal, 10)
        .navigationTitle("新增使用者")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                }
            }
        }
        .onReceive(mainViewModel.$userResult.dropFirst()) { output in
            result = output
            showAlert.toggle()
        }
        .alert(
            result.user.isEmpty ? (result.error ?? "新增錯誤") : "新增成功",
            isPresented: $showAlert,
            actions: {
                Button {
                    if !alertContent.isEmpty {
                        reset()
                    }
                } label: {
                    Text("OK")
                }
            },
            message: {
                Text(alertContent)
            }
        )
    }
}

private extension AddUserView {
    
    var alertContent: String {
        result.user.map { $0.name }.joined(separator: "\n")
    }
    
    func add() {
        guard !account.isEmpty && !name.isEmpty && !password.isEmpty else {
            showAlert.toggle()
            return
        }
        mainViewModel.addUser(
            id: account,
            name: name,
            password: password
        )
    }
    
    func reset() {
        account = ""
        name = ""
        password = ""
    }
}

struct AddUserView_Previews: PreviewProvider {
    static var previews: some View {
        AddUserView()
    }
}
