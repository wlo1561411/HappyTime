//
//  MainViewModel.swift
//  HappyTime
//
//  Created by Finn Wu on 2021/8/19.
//

import Foundation
import SwiftUI
import Combine
import Firebase
import WidgetKit
import WatchConnectivity

class MainViewModel: NSObject, ObservableObject {
    
    typealias WebError = WebService.WebServiceError
    typealias ApiType = WebService.ApiType
    typealias PunchModel = PunchView.Model
    
    private let codeKey = "code_key"
    private let accountKey = "account_key"
    private let passwordKey = "password_key"
    
    private let minLatitude = 25.080149
    private let maxLatitude = 25.081812
    
    private let minlongitude = 121.564843
    private let maxlongitude = 121.565335
    
    private var cancellables = Set<AnyCancellable>()
    
    private var token: String? {
        didSet {
            DispatchQueue.main.async {
                self.isLogin = self.token != nil
            }
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
    
    var alertType: AlertType = .remind(type: .delete)
    
    private var clockType: ClockType = .In
    
    private let firestore = Firestore.firestore()
    
    var listener: ListenerRegistration?
    
    var session: WCSession
    
    @Published var userResult: (user: [User], error: String?) = ([], nil)
    
    init(_ session: WCSession = .default) {
        self.session = session
        super.init()
    }
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
    
    func login(onlyLogin: Bool = false) {
        
        let login = WebService
            .shared
            .login(code: "YIZHAO", account: account, password: password)
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveSubscription: { [weak self] _ in
                DispatchQueue.main.async {
                    let shouldShowLoading = UIApplication.shared.applicationState == .active
                    
                    if onlyLogin && shouldShowLoading { self?.isLoading = true }
                }
                
            }, receiveOutput: { [weak self] token in
                guard let self = self else { return }
                
                let shouldShowLoading = UIApplication.shared.applicationState == .active
                
                WidgetCenter.shared.reloadAllTimelines()
                
                self.token = token
                
                if shouldShowLoading {
                    if onlyLogin {
                        self.configAlert(alertType: .response(api: .login, error: nil, message: nil))
                    }
                    else {
                        self.configAlert(alertType: .response(api: .clock(type: self.clockType), error: nil, message: nil))
                    }
                }

                if !self.isSavedAccount { self.saveUserInfo() }
                
            }, receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                
                let shouldShowLoading = UIApplication.shared.applicationState == .active
                
                if onlyLogin && shouldShowLoading { self.isLoading = false }
                
                switch completion {
                case .finished: break
                case .failure(let error):
                    if shouldShowLoading {
                        if onlyLogin {
                            self.configAlert(alertType: .response(api: .login, error: error, message: nil))
                        }
                        else {
                            self.configAlert(alertType: .response(
                                api: .clock(type: self.clockType),
                                error: nil,
                                message: "但登入失敗，" + error.message)
                            )
                        }
                    }
                }
            })
            .eraseToAnyPublisher()
        
        getAttendance(upsteam: login)
    }
    
    func getAttendance<T>(upsteam: AnyPublisher<T, WebError>) {
        
        let getAttendance = WebService
            .shared
            .getAttendance()
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveOutput: { [weak self] attendance in
                guard let punches = attendance.punch?.allPunches, punches.count > 0 else { return }
                self?.punchModel = .init(title: "出勤紀錄", punches: punches)
                
                self?.sendMessage(.log, value: [punches.map { $0.workTime }])
                
                if let onPunch = attendance.punch?.onPunch?.first {
                    NotificationManager.shared.createNotification(with: onPunch.workTime)
                }
            }, receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished: break
                case .failure(_):
                    self?.punchModel = nil
                }
            })
            .eraseToAnyPublisher()
        
        upsteam
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
    
    func loginAction(onlyLogin: Bool = false) {
        WebService.shared.removeAllCookies()
        
        token = nil
        
        DispatchQueue.main.async { [weak self] in
            self?.punchModel = nil
        }
        
        login(onlyLogin: onlyLogin)
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
            
            setupWatchConnect()
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
    
    func generateCoordinate() -> (latitude: Double, longitude: Double)  {
        let latitude = Double.random(in: minLatitude...maxLatitude).decimal(6)
        let longitude = Double.random(in: minlongitude...maxlongitude).decimal(6)
        return (latitude, longitude)
    }
}

// MARK: - Firebase API

extension MainViewModel {
    
    func addUser(id: String, name: String, password: String) {
        firestore
            .collection("users")
            .addDocument(data: ["id": id, "name": name, "password": password]) { error in
                if let error = error {
                    self.userResult = ([], error.localizedDescription)
                    return
                }
                self.getUser()
            }
    }
    
    private func getUser() {
        firestore
            .collection("users")
            .getDocuments { allSnapshot, error in
                guard let allSnapshot = allSnapshot else { return }
                let dataArray = allSnapshot.documents.map {
                    $0.data()
                }
                
                guard let json = try? JSONSerialization.data(withJSONObject: dataArray),
                      let userArray = try? JSONDecoder().decode([User].self, from: json) else { return }
                self.userResult = (userArray, nil)
            }
    }
    
    private func clock(_ type: ClockType) {
        
        clockType = type
   
        isLoading = true
         
        firestore
            .collection("clocks")
            .addDocument(data: ["name": code,
                                "clock": type.rawValue,
                                "status": ClockSttus.none.rawValue]) { [weak self] error in
            guard error == nil else {
                self?.isLoading = false
                self?.configAlert(alertType: .response(api: .login, error: .requestFail(error: error!), message: "阿伯 出事了"))
                return
            }
        }
        .getDocument { [weak self] snapshot, error in
            guard let snapshot = snapshot, error == nil else {
                self?.isLoading = false
                self?.configAlert(alertType: .response(api: .login, error: .requestFail(error: error!), message: "阿伯 出事了"))
                return
            }
            self?.bindClock(type, id: snapshot.documentID)
        }
    }
    
    private func bindClock(_ type: ClockType, id: String) {
        
        listener = firestore.collection("clocks").document(id).addSnapshotListener { [weak self] snapshot, error in

            guard let snapshot = snapshot,
                  snapshot.documentID == id,
                  let json = snapshot.data(),
                  let data = try? JSONSerialization.data(withJSONObject: json),
                  let clock = try? JSONDecoder().decode(Clock.self, from: data),
                  let status = ClockSttus.init(rawValue: clock.status) else {
                return
            }
            
            self?.isLoading = false
            
            switch status {
            case .success:
                self?.deleteClock(id: id)
                self?.loginAction(onlyLogin: false)
                
            case .fail:
                self?.configAlert(alertType: .response(api: .clock(type: type), error: .httpResponseError, message: nil))
                self?.deleteClock(id: id)
                
            case .userNotFind:
                self?.configAlert(alertType: .response(api: .clock(type: type), error: .httpResponseError, message: "找不到使用者"))
                self?.deleteClock(id: id)
                
            default:
                break
            }
        }
    }
    
    private func deleteClock(id: String) {
        firestore
            .collection("clocks")
            .document(id)
            .delete { error in
                self.listener?.remove()
            }
    }
}

// MARK: - Watch Connect

extension MainViewModel: WCSessionDelegate {
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {}
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        sendMessage(.log)
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        let actions = message.keys.map { Action(rawValue: $0) }
        
        actions.forEach { action in
            switch action {
            case .log:
                loginAction(onlyLogin: true)
                
            case .clockIn:
                clockAction(.In)
                
            case .clockOut:
                clockAction(.Out)
                
            default : break
            }
        }
    }
}

private extension MainViewModel {
    
    enum Action: String {
        case log
        case clockIn
        case clockOut
    }
    
    func setupWatchConnect() {
        if WCSession.isSupported() {
            self.session.delegate = self
            self.session.activate()
        }
    }
    
    func sendMessage(_ action: Action, value: Any? = nil) {
        if session.isReachable {
            switch action {
            case .log:
                if let value = value {
                    session.sendMessage(
                        [action.rawValue: value],
                        replyHandler: nil
                    )
                }
                else {
                    NotificationManager
                        .shared
                        .getNotification { [weak self] time in
                            self?.session.sendMessage(
                                [action.rawValue: [time]],
                                replyHandler: nil
                            )
                        }
                }
            default: break
            }
        }
    }
}
