//
//  IPMainViewModel.swift
//  HappyTime
//
//  Created by Finn Wu on 2021/8/19.
//

import Foundation
import SwiftUI
import Combine
import Firebase

class IPMainViewModel: ObservableObject {
    
    typealias WebError = WebService.WebServiceError
    typealias ApiType = WebService.ApiType
    
    private var cancellables = Set<AnyCancellable>()

    @Published var name = "" {
        didSet {
            isAvailable = !name.isEmpty
        }
    }
    
    @Published var isAvailable = false
    @Published var isPopAlert = false
    @Published var isLoading = false
    
    var alertType: AlertType = .remind(type: .In)
    
    private let firestore = Firestore.firestore()
    
    var listener: ListenerRegistration?
}

// MARK: - Alert Type

extension IPMainViewModel {
    
    enum AlertType {
        case remind(type: ClockType)
        case response(api: ApiType, error: WebError?, message: String?)
        
        var elements: (title: String, message: String?) {
            switch self {
            case .remind(let type):
                return ("提醒您！", "你確定要\(type.chinese)嗎？")
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

// MARK: - Firebase API

private extension IPMainViewModel {
    
    func clock(_ type: ClockType) {
   
        isLoading = true
         
        firestore
            .collection("clocks")
            .addDocument(data: ["name": name,
                                "clock": type.rawValue,
                                "status": ClockSttus.none.rawValue]) { error in
            guard error == nil else {
                self.alertType = .response(api: .login, error: .requestFail(error: error!), message: "阿伯 出事了")
                self.isLoading = false
                self.isPopAlert = true
                return
            }
        }
        .getDocument { snapshot, error in
            
            guard let snapshot = snapshot, error == nil else {
                self.alertType = .response(api: .login, error: .requestFail(error: error!), message: "阿伯 出事了")
                self.isLoading = false
                self.isPopAlert = true
                return
            }
            
            self.bindClock(type, id: snapshot.documentID)
        }
    }
    
    func bindClock(_ type: ClockType, id: String) {
        
        listener = firestore.collection("clocks").document(id).addSnapshotListener { snapshot, error in

            guard let snapshot = snapshot,
                  snapshot.documentID == id,
                  let json = snapshot.data(),
                  let data = try? JSONSerialization.data(withJSONObject: json),
                  let clock = try? JSONDecoder().decode(Clock.self, from: data),
                  let status = ClockSttus.init(rawValue: clock.status) else {
                return
            }
            
            switch status {
            case .success:
                self.alertType = .response(api: .clock(type: type), error: nil, message: nil)
                self.isLoading = false
                self.isPopAlert = true
                self.deleteClock(id: id)
            case .fail:
                self.alertType = .response(api: .clock(type: type), error: .httpResponseError, message: nil)
                self.isLoading = false
                self.isPopAlert = true
                self.deleteClock(id: id)
            case .userNotFind:
                self.alertType = .response(api: .clock(type: type), error: .httpResponseError, message: "找不到使用者")
                self.isLoading = false
                self.isPopAlert = true
                self.deleteClock(id: id)
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

// MARK: - Action

extension IPMainViewModel {
    
    func clockAction(_ type: ClockType) {
        clock(type)
    }
    
    func remindAction() {
        switch alertType {
        case .remind(let type):
            clockAction(type)
        case .response(_, _, _):
            break
        }
    }
}

// MARK: - Other

extension IPMainViewModel {

    func configAlert(alertType: AlertType) {
        self.alertType = alertType
        self.isPopAlert = true
    }
    
    func prepareForClock(_ type: ClockType) {
        configAlert(alertType: .remind(type: type))
    }
    
    func isCompleteInput() -> Bool {
        return !name.isEmpty
    }
}
