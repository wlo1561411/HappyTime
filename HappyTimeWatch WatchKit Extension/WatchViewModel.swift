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

class WatchViewModel: ObservableObject {
    
    private let reference = Database.database().reference()
    private var handle: DatabaseHandle?
    private var cancellables = Set<AnyCancellable>()
    
    private let codeKey = "code_key"
    private let accountKey = "account_key"
    private let passwordKey = "password_key"
    
    var code = ""
    var account = ""
    var password = ""
    
    private var token: String?
    
    @Published var attendence: String = ""
    
    var isLoading = false
    
    init() {
        queryUserInfo()
    }
}

extension WatchViewModel {
    
    func clock(_ type: ClockType) {
        guard !isLoading,
              let key = reference.child("clocks").childByAutoId().key else { return }
        
        isLoading = true
        
        reference.child("clocks")
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
                      let data = try? JSONSerialization.data(withJSONObject: snapshot.value),
                      let clock = try? JSONDecoder().decode(Clock.self, from: data),
                      clock.documentID == id,
                      let status = ClockSttus.init(rawValue: clock.status) else { return }
                
                switch status {
                case .success:
                    self.deleteClock(id: id)
                    self.login()
                    
                case .fail, .userNotFind:
                    self.deleteClock(id: id)
                    
                default:
                    break
                }
            })
    }
    
    private func deleteClock(id: String) {
        reference
            .child("clocks")
            .child(id)
            .removeValue { [weak self] _, _ in
                if let handle = self?.handle {
                    self?.reference.removeObserver(withHandle: handle)
                }
            }
    }
}

private extension WatchViewModel {
    
    func login() {
        
        let login = WebService
            .shared
            .login(code: "YIZHAO", account: account, password: password)
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveOutput: { [weak self] token in
                guard let self = self else { return }
                
//                WidgetCenter.shared.reloadAllTimelines()
                
                self.token = token
            })
            .eraseToAnyPublisher()
        
        getAttendance(upsteam: login)
    }
    
    func getAttendance<T>(upsteam: AnyPublisher<T, WebService.WebServiceError>) {
        
        let getAttendance = WebService
            .shared
            .getAttendance()
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveOutput: { [weak self] attendance in
                if let onPunch = attendance.punch?.onPunch?.first {
                    self?.createNotification(with: onPunch.workTime)
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

private extension WatchViewModel {
    
    func queryUserInfo() {
        if let code = query(for: codeKey),
           let account = query(for: accountKey),
           let password = query(for: passwordKey) {
            self.code = code
            self.account = account
            self.password = password
        }
    }
    
    func query(for key: String) -> String? {
        let query: [String: Any] =
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: kCFBooleanTrue ?? false
        ]
        
        var retrivedData: AnyObject? = nil
        let _ = SecItemCopyMatching(query as CFDictionary, &retrivedData)
        
        guard let data = retrivedData as? Data else { return nil }
        return String(data: data, encoding: String.Encoding.utf8)
    }
}

// MARK: - Notification

private extension WatchViewModel {
    
    func createNotification(with dateString: String) {
        let group = DispatchGroup()
        
        var isExist = false
        
        group.enter()
        UNUserNotificationCenter
            .current()
            .getPendingNotificationRequests { requests in
                isExist = requests.first(where: { $0.content.body == dateString }) != nil
                group.leave()
            }
        
        group.notify(queue: .global()) { [weak self] in
            guard !isExist else {
                print("already Exist")
                return
            }
            self?.addNotificationRequest(with: dateString)
        }
    }
    
    private func addNotificationRequest(with dateString: String) {
        UNUserNotificationCenter
            .current()
            .getNotificationSettings { setting in
                
                guard setting.authorizationStatus == .authorized else { return }
                
                let format = DateFormatter()
                format.dateFormat = "yyyy-MM-dd HH:mm:ss"
                format.timeZone = TimeZone.current
                
                guard let date = format.date(from: dateString),
                      let added = Calendar.current.date(byAdding: .init(timeZone: .current, hour: 9, minute: 1), to: date)
                else { return }
                
                let content = UNMutableNotificationContent()
                content.title = "下班了！"
                content.subtitle = "請記得打卡～～～"
                content.body = dateString
                content.sound = .default
                
                guard let imageURL: URL = Bundle.main.url(forResource: "NotificationIcon", withExtension: "png"),
                      let attachment = try? UNNotificationAttachment(identifier: "image", url: imageURL, options: nil)
                else { return }
                
                content.attachments = [attachment]
                
                let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: added)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let request = UNNotificationRequest(identifier: "notification", content: content, trigger: trigger)
                
                UNUserNotificationCenter.current().add(request) { [weak self] _ in
                    print("add notification success")
                    self?.attendence = dateString
                }
            }
    }
}
