//
//  MainViewModel.swift
//  HappyTime
//
//  Created by Finn Wu on 2021/8/19.
//

import Foundation
import SwiftUI
import Combine

class MainViewModel: ObservableObject {
    
    enum AlertType {
        enum RemindType {
            case delete
            case clock(type: ClockType)
            
            var title: String {
                return "提醒您！"
            }
            
            var message: String {
                switch self {
                case .delete:
                    return "你確定要刪除已儲存的帳號密碼嗎？"
                case .clock(let type):
                    return "你確定要\(type.chinese)嗎？"
                }
            }
        }
        
        enum ApiType {
            case login(success: Bool?)
            case clock(type: ClockType, success: Bool?, message: String?)
            
            var title: String {
                switch self {
                case .login(let success):
                    if let success = success {
                        return "登入\(success ? "成功" : "失敗")"
                    }
                    else {
                        return "咦！"
                    }


                case .clock(let type, let success, _):
                    if let success = success {
                        return "\(type.chinese)\(success ? "成功" : "失敗")"
                    }
                    else {
                        return "咦！"
                    }
                }
            }
            
            var message: String? {
                switch self {
                case .login(let success):
                    if let success = success {
                        return success ? nil : "請稍後再次嘗試或重新登入。"
                    }
                    else {
                        return "請檢查輸入欄位。"
                    }

                case .clock(_, let success, let message):
                    if success != nil {
                        return message
                    }
                    else {
                        return "請稍後再次嘗試或重新登入。"
                    }
                }
            }
        }
        
        case remind(remindType: RemindType)
        case response(apiType: ApiType)
        
        var title: String {
            switch self {
            case .remind(let remindType):
                return remindType.title
            case .response(let apiType):
                return apiType.title
            }
        }
        
        var message: String? {
            switch self {
            case .remind(let remindType):
                return remindType.message
            case .response(let apiType):
                return apiType.message
            }
        }
    }
    
    private let codeKey = "code_key"
    private let accountKey = "account_key"
    private let passwordKey = "password_key"
    
    private let minLatitude = 25.080149
    private let maxLatitude = 25.081812
    
    private let minlongitude = 121.564843
    private let maxlongitude = 121.565335
        
    private var cancellables = Set<AnyCancellable>()
    
    private var token: String?
    
    private var isSavedAccount = false
        
    @Published var code = ""
    @Published var account = ""
    @Published var password = ""
    
    @Published var isPopAlert = false
    
    var alertType: AlertType = .remind(remindType: .delete)
}

// MARK: - API

private extension MainViewModel {

    func login() {
        if !isCompleteInput() {
            configAlert(
                alertType: .response(apiType: .login(success: nil))
            )
            return
        }
        
        WebService
            .shareInstance
            .login(code: code,
                   account: account,
                   password: password) { [weak self] success, token in

                if success {
                    self?.token = token
                    if !(self?.isSavedAccount ?? false) {
                        self?.saveUserInfo()
                    }
                }

                DispatchQueue.main.async {
                    self?.configAlert(
                        alertType: .response(apiType: .login(success: success))
                    )
                }
            }
    }
    
    func clock(_ type: ClockType) {
        let coordinate = generateCoordinate()

        WebService
            .shareInstance
            .clock(type,
                   token: token,
                   latitude: coordinate.latitude,
                   longitude: coordinate.longitude) { [weak self] success, message in
                
                DispatchQueue.main.async {
                    self?.configAlert(
                        alertType: .response(apiType: .clock(type: type, success: success, message: message))
                    )
                }
            }
    }
}

// MARK: - Combine API

private extension MainViewModel {
    
    func loginByCombine() {
        guard isCompleteInput() else {
            configAlert(alertType: .response(apiType: .login(success: nil)))
            return
        }
        
        WebService
            .shareInstance
            .login(code: code, account: account, password: password)?
//            .replaceError(with: nil)
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished: break
                case .failure(_) :
                    self?.configAlert(
                        alertType: .response(apiType: .login(success: false))
                    )
                }
            },
            receiveValue: { [weak self] token in
                guard let self = self else { return }
                
                if let token = token {
                    self.token = token

                    WebService
                        .shareInstance
                        .getAttendance()?
                        .sink(receiveCompletion: { _ in}, receiveValue: { string in
                            print(string)
                        })
                        .store(in: &self.cancellables)
                    
                    if !self.isSavedAccount {
                        self.saveUserInfo()
                    }
                }
                
                self.configAlert(
                    alertType: .response(apiType: .login(success: self.token != nil))
                )
            })
            .store(in: &cancellables)
    }
    
    func clockByCombine(_ type: ClockType) {
        let coordinate = generateCoordinate()

        WebService
            .shareInstance
            .clock(type, token: token ?? "", latitude: coordinate.latitude, longitude: coordinate.longitude)?
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                switch completion {
                case .finished: break
                case .failure(_) :
                    self.configAlert(
                        alertType: .response(apiType: .clock(type: type, success: nil, message: nil))
                    )
                }
            },
            receiveValue: { [weak self] response in
                self?.configAlert(
                    alertType: .response(apiType: .clock(type: type, success: response.isSuccess, message: response.message))
                )
            })
            .store(in: &cancellables)
    }
}

// MARK: - Keychain

private extension MainViewModel {
    
    func saveUserInfo() {
        if !isCompleteInput() { return }
        
        KeychainUtility.shareInstance.save(code, for: codeKey)
        KeychainUtility.shareInstance.save(account, for: accountKey)
        KeychainUtility.shareInstance.save(password, for: passwordKey)
    }
    
    func deleteUserInfo() {
        KeychainUtility.shareInstance.delete(for: codeKey)
        KeychainUtility.shareInstance.delete(for: accountKey)
        KeychainUtility.shareInstance.delete(for: passwordKey)
        
        code = ""
        account = ""
        password = ""
    }
}

// MARK: - Action

extension MainViewModel {
    
    func loginAction() {
        token = nil
        
//        login()
        loginByCombine()
    }
    
    func clockAction(_ type: ClockType) {
        
//        clock()
        clockByCombine(type)
    }
    
    func remindAction() {
        switch alertType {
        case .remind(let remindType):
            switch remindType {
            case .delete:
                deleteUserInfo()
            case .clock(let type):
                clockAction(type)
            }
            
        ///  Should not happen
        case .response(_):
            break
        }
    }
}

// MARK: - Other

extension MainViewModel {
    
    func queryUserInfo() {
        if let code = KeychainUtility.shareInstance.query(for: codeKey),
           let account = KeychainUtility.shareInstance.query(for: accountKey),
           let password = KeychainUtility.shareInstance.query(for: passwordKey) {
            isSavedAccount = true
            self.code = code
            self.account = account
            self.password = password
        }
        else {
            isSavedAccount = false
        }
    }
    
    func configAlert(alertType: AlertType) {
        self.alertType = alertType
        self.isPopAlert = true
    }
    
    func prepareForClock(_ type: ClockType) {
        configAlert(alertType: .remind(remindType: .clock(type: type)))
    }
    
    func prepareForDelete() {
        configAlert(alertType: .remind(remindType: .delete))
    }
    
    func isCompleteInput() -> Bool {
        return !code.isEmpty && !account.isEmpty && !password.isEmpty
    }

    func generateCoordinate() -> (latitude: Double, longitude: Double)  {
        let latitude = Double.random(in: minLatitude...maxLatitude).decimal(6)
        let longitude = Double.random(in: minlongitude...maxlongitude).decimal(6)
        return (latitude, longitude)
    }
}
