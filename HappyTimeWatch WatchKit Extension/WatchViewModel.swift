//
//  WatchViewModel.swift
//  HappyTimeWatch WatchKit Extension
//
//  Created by Patty Chang on 18/07/2022.
//

import Foundation
import UIKit
import FirebaseDatabase
import SwiftUI
import Combine
import UserNotifications
import WatchConnectivity


class WatchViewModel: NSObject, ObservableObject {
    
    private let reference = Database.database().reference()
    private var handle: DatabaseHandle?
    private var cancellables = Set<AnyCancellable>()
    
    private let codeKey = "code_key"
    private let accountKey = "account_key"
    private let passwordKey = "password_key"
    
    var code = UserDefaults.standard.code {
        didSet {
            UserDefaults.standard.code = code
        }
    }
    var account = UserDefaults.standard.account {
        didSet {
            UserDefaults.standard.account = account
        }
    }
    var password = UserDefaults.standard.password {
        didSet {
            UserDefaults.standard.password = password
        }
    }
    
    @Published var attendance: String = UserDefaults.standard.attendance {
        didSet {
            UserDefaults.standard.attendance = attendance
        }
    }
    
    private var token: String?
    
    var isLoading = false
    
    var session: WCSession
    
    init(_ session: WCSession = .default) {
        self.session = session
        super.init()
        
        setupWatchConnect()
    }
}

// MARK: - API

extension WatchViewModel {
    
    func clock(_ type: ClockType) {
        guard !isLoading,
              let key = reference.child("clocks").childByAutoId().key else { return }
        
        isLoading = true
        
        reference
            .child("clocks")
            .child(key)
            .setValue([
                "documentID": key,
                "name": code,
                "clock": type.rawValue,
                "status": ClockSttus.none.rawValue
            ], withCompletionBlock: { [weak self] _, _ in
                self?.isLoading = false
                self?.bindClock(type, id: key)
            })
    }
    
    private func bindClock(_ type: ClockType, id: String) {
        handle = reference
            .child("clocks")
            .child(id)
            .observe(.value, with: { [weak self] snapshot in
                guard let self = self,
                      let data = try? JSONSerialization.data(withJSONObject: snapshot.value as Any),
                      let clock = try? JSONDecoder().decode(Clock.self, from: data),
                      clock.documentID == id,
                      let status = ClockSttus.init(rawValue: clock.status) else { return }
                
                switch status {
                case .success:
                    self.deleteClock(id: id)
                    self.sendMessage()
                    
                case .fail, .userNotFind:
                    self.deleteClock(id: id)
                    
                default:
                    break
                }
            })
    }
    
    private func deleteClock(id: String) {
        if let handle = handle {
            reference.removeObserver(withHandle: handle)
        }
        
        // FIXME: delete value ???
//        reference
//            .child("clocks")
//            .child(id)
//            .removeValue { [weak self] _, _ in
//                if let handle = self?.handle {
//                    self?.reference.removeObserver(withHandle: handle)
//                }
//            }
    }
}

// MARK: - Watch Connect

private extension WatchViewModel {
    
    func setupWatchConnect() {
        if WCSession.isSupported() {
            self.session.delegate = self
            self.session.activate()
        }
    }
    
    func sendMessage() {
        if session.isReachable {
            session.sendMessage(
                ["notification": "notification"],
                replyHandler: nil
            )
        }
    }
}

extension WatchViewModel: WCSessionDelegate {
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        
        if let time = message["attendance"] as? String, !time.isEmpty {
            DispatchQueue.main.async { [weak self] in
                self?.attendance = time
            }
        }
        
        if let name = message["code"] as? String,
           let account = message["account"] as? String,
           let password = message["password"] as? String {
            self.code = name
            self.account = account
            self.password = password
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        sendMessage()
    }
}
