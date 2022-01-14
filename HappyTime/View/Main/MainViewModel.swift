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
    
    typealias WebError = WebService.WebServiceError
    typealias ApiType = WebService.ApiType
    typealias PunchModel = PunchView.Model
    
    private let codeKey = "code_key"
    private let accountKey = "account_key"
    private let passwordKey = "password_key"
    
    private var cancellables = Set<AnyCancellable>()
    
    private var token: String? {
        didSet {
            isLogin = token != nil
        }
    }
    
    private var isSavedAccount = false
    
    @Published var code = ""
    @Published var account = ""
    @Published var password = ""
    
    @Published var punchModel: PunchModel?
    
    @Published var isPopAlert = false
    @Published var isLoading = false
    @Published var isLogin = false
    
    @Published var isReceivedNotification = false
    
    var alertType: AlertType = .remind(type: .delete)
}

// MARK: - Alert Type

extension MainViewModel {
    
    enum AlertType {
        enum RemindType {
            case delete
            case clock(type: ClockType)
            
            var elements: (title: String, message: String) {
                switch self {
                case .delete:
                    return ("提醒您！", "你確定要刪除已儲存的帳號密碼嗎？")
                case .clock(let type):
                    return ("提醒您！", "你確定要\(type.chinese)嗎？")
                }
            }
        }
        
        case remind(type: RemindType)
        case response(api: ApiType, error: WebError?, message: String?)
        
        var elements: (title: String, message: String?) {
            switch self {
            case .remind(let type):
                return type.elements
            case .response(let api, let error, let message):
                if let error = error {
                    return (api.title + "失敗", message ?? error.message)
                }
                else {
                    return (api.title + "成功", message)
                }
            }
        }
    }
}

// MARK: - Combine API

private extension MainViewModel {
    
    func login() {
        
        let login = WebService.shared
            .login(code: code, account: account, password: password)
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveSubscription: { [weak self] _ in
                self?.isLoading = true
            }, receiveOutput: { [weak self] token in
                guard let self = self else { return }
                
                self.token = token

                if !self.isSavedAccount { self.saveUserInfo() }
                
                self.configAlert(alertType: .response(api: .login, error: nil, message: nil))
            }, receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                
                switch completion {
                case .finished: break
                case .failure(let error):
                    self?.configAlert(alertType: .response(api: .login, error: error, message: nil))
                }
            })
            .eraseToAnyPublisher()
        
        getAttendance(upstream: login)
    }
    
    func clock(_ type: ClockType) {
        
        let clock = AppManager.shared
            .clock(type, token: token ?? "")
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveSubscription: { [weak self] _ in
                self?.isLoading = true
            }, receiveOutput: { [weak self] response in
                let error = response.isSuccess ? nil : WebError.invalidValue
                self?.configAlert(alertType: .response(api: .clock(type: type), error: error, message: response.message))

                if response.isSuccess, type == .In {
                    AppManager.shared.createNotification(with: response.datetime ?? "")
                }

            }, receiveCompletion: { [weak self] completion in
                self?.isLoading = false

                switch completion {
                case .finished: break
                case .failure(let error) :
                    self?.configAlert(alertType: .response(api: .clock(type: type), error: error, message: nil))
                }
            })
            .eraseToAnyPublisher()
        
        getAttendance(upstream: clock)
    }
    
    func getAttendance<T>(upstream: AnyPublisher<T, WebError>) {
        
        let getAttendance = WebService
            .shared
            .getAttendance()
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveOutput: { [weak self] attendance in
                guard let punches = attendance.punch?.allPunches, punches.count > 0 else { return }
                self?.punchModel = .init(title: "出勤紀錄", punches: punches)
                
                if let onPunch = attendance.punch?.onPunch?.first {
                    AppManager.shared.createNotification(with: onPunch.workTime)
                }
            }, receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished: break
                case .failure(_):
                    self?.punchModel = nil
                }
            })
            .eraseToAnyPublisher()
        
        upstream
            .flatMap { _ in getAttendance }
            .sink(receiveCompletion: { _ in }
                  ,receiveValue: { _ in })
            .store(in: &cancellables)
    }
}

// MARK: - Keychain

private extension MainViewModel {
    
    func saveUserInfo() {
        if !isCompleteInput() { return }
        
        AppManager.shared.save(code, for: codeKey)
        AppManager.shared.save(account, for: accountKey)
        AppManager.shared.save(password, for: passwordKey)
    }
    
    func deleteUserInfo() {
        AppManager.shared.delete(for: codeKey)
        AppManager.shared.delete(for: accountKey)
        AppManager.shared.delete(for: passwordKey)
        
        code = ""
        account = ""
        password = ""
        token = nil
    }
}

// MARK: - Action

extension MainViewModel {
    
    func loginAction() {
        WebService.shared.removeAllCookies()
        
        token = nil
        punchModel = nil
        
        login()
    }
    
    func clockAction(_ type: ClockType) {
        
        clock(type)
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
        case .response(_, _, _):
            break
        }
    }
    
    func performNotificationAction() {
        
        let pipeline = WebService.shared
            .login(code: code, account: account, password: password)
            .handleEvents(receiveSubscription:  { [weak self] _ in
                self?.isLoading = true
            })
            .flatMap { token -> AnyPublisher<ClockResponse, WebService.WebServiceError> in

                let publisher = AppManager.shared
                    .clock(.Out, token: token)

                return publisher
            }
            .handleEvents(receiveOutput: { [weak self] response in
                let error = response.isSuccess ? nil : WebError.invalidValue
                self?.configAlert(alertType: .response(api: .clock(type: .Out), error: error, message: response.message))

            }, receiveCompletion:  { [weak self] _ in
                self?.isLoading = false
            })
            .eraseToAnyPublisher()
        
        getAttendance(upstream: pipeline)
    }
}

// MARK: - Other

extension MainViewModel {
    
    func queryUserInfo() {
        if let code = AppManager.shared.query(for: codeKey),
           let account = AppManager.shared.query(for: accountKey),
           let password = AppManager.shared.query(for: passwordKey) {
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
        configAlert(alertType: .remind(type: .clock(type: type)))
    }
    
    func prepareForDelete() {
        configAlert(alertType: .remind(type: .delete))
    }
    
    func isCompleteInput() -> Bool {
        return !code.isEmpty && !account.isEmpty && !password.isEmpty
    }
}
