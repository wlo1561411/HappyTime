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
    
    private let db = Firestore.firestore()
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
   
        db.collection("clocks").addDocument(data: ["name": name, "clock": type.rawValue, "queue": false, "expired": false]) { error in
            
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
