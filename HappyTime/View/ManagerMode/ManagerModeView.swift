//
//  ManagerModeView.swift
//  HappyTime
//
//  Created by Patty Chang on 15/03/2023.
//

import SwiftUI

struct ManagerModeView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var code: String = ""
    @State private var showAlert: Bool = false
    @State private var navLink: Bool = false
    @State private var status: Login = .fail
    
    var body: some View {
        VStack(alignment: .center, spacing: 30) {
            Image(systemName: "person.badge.key.fill")
                .resizable()
                .foregroundColor(.white)
                .aspectRatio(contentMode: .fit)
                .frame(width: 100)
            
            TextFieldView(
                inputText: $code,
                title: "Password",
                placeHolder: "Enter password",
                isSecure: true
            )
            .padding([.leading, .trailing], 50)
            
            Button {
                checkLogin()
            } label: {
                Text("Login")
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                    .padding(10)
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white, lineWidth: 2)
                    }
            }
            
            Spacer()
            
            NavigationLink(isActive: $navLink, destination: {
                AddUserView()
            }, label: {})
        }
        .padding(.top, 50)
        .navigationTitle("管理員模式")
        .navigationBarTitleDisplayMode(.inline)
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
        .alert(status.title, isPresented: $showAlert) {
            if status == .success {
                Button {
                    navLink.toggle()
                } label: {
                    Text("OK")
                }
            }
        }
    }
}

// MARK: - Login

private extension ManagerModeView {
    
    enum Login {
        case fail
        case success
        
        var title: String {
            switch self {
            case .fail:
                return "登入失敗"
            case .success:
                return "登入成功"
            }
        }
    }
    
    func checkLogin() {
        if code == "0414" {
            status = .success
        }
        showAlert.toggle()
    }
}

struct ManagerModeView_Previews: PreviewProvider {
    static var previews: some View {
        ManagerModeView()
    }
}
