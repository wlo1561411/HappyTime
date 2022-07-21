//
//  WatchViewModel.swift
//  HappyTimeWatch WatchKit Extension
//
//  Created by Patty Chang on 18/07/2022.
//

import Foundation
import SwiftUI
import WatchConnectivity


class WatchViewModel: NSObject, ObservableObject {
    
    @Published var attendance = ""
    
    var session: WCSession
    
    init(_ session: WCSession = .default) {
        self.session = session
        super.init()
        
        setupWatchConnect()
    }
}

// MARK: - Action

extension WatchViewModel {
    
    enum Action: String {
        case log
        case clockIn
        case clockOut
    }
    
    func sendMessage(_ action: Action) {
        if session.isReachable {
            session.sendMessage(
                [
                    action.rawValue: action.rawValue
                ],
                replyHandler: nil
            )
        }
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
}

extension WatchViewModel: WCSessionDelegate {
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        
        if let times = message[Action.log.rawValue] as? [String] {
            DispatchQueue.main.async { [weak self] in
                let time = times.reduce("", { $0.isEmpty ? $1 : $0 + "\n" + $1 })
                self?.attendance = time
            }
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        sendMessage(.log)
    }
}
