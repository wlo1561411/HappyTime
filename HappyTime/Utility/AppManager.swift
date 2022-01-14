//
//  AppManager.swift
//  HappyTime
//
//  Created by Finn Wu on 2022/1/3.
//

import UIKit
import Combine
import SwiftUI

class AppManager {
    
    static let shared = AppManager()
    
    @Published var isReceivedNotification: Bool = false
    
    private let minLatitude = 25.080149
    private let maxLatitude = 25.081812
    
    private let minlongitude = 121.564843
    private let maxlongitude = 121.565335
}

// MARK: - Notification

extension AppManager {
    
    func requestNotificationAuthrorization() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.sound, .alert]) { success, error in
                if success {
                    print("authorization granted")
                } else if let error = error {
                    print(error.localizedDescription)
                }
            }
    }
    
    /// When use other than default notification action (not in use now)
    func registerNotificationCategories() {
        
        let center = UNUserNotificationCenter.current()
        
        let action = UNNotificationAction(identifier: "clockout",
                                          title: "Clockout",
                                          options:.foreground)
        
        let category = UNNotificationCategory(identifier: "notification",
                                              actions: [action],
                                              intentIdentifiers: [],
                                              options: .customDismissAction)
        
        center.setNotificationCategories([category])
    }
    
    func createNotification(with dateString: String) {
        print(dateString)
        let group = DispatchGroup()
        
        var isExist = false
        
        group.enter()
        UNUserNotificationCenter
            .current()
            .getPendingNotificationRequests { requests in
                isExist = requests.first(where: { $0.content.body == dateString }) != nil
                group.leave()
            }
        
        group.notify(queue: .global()) { [unowned self] in
            guard !isExist else {
                print("already Exist")
                return
            }
            self.addNotificationRequest(with: dateString)
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
                content.categoryIdentifier = "notification"
                
                guard let imageURL: URL = Bundle.main.url(forResource: "NotificationIcon", withExtension: "png"),
                      let attachment = try? UNNotificationAttachment(identifier: "image", url: imageURL, options: nil)
                else { return }
                
                content.attachments = [attachment]
                
                let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: added)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let request = UNNotificationRequest(identifier: "notification", content: content, trigger: trigger)
                
                UNUserNotificationCenter.current().add(request) { _ in
                    print("add notification success")
                }
            }
    }
}

// MARK: - Keychain

extension AppManager {
    
    func save(_ value: String, for key: String) {
        let value = value.data(using: String.Encoding.utf8)!
        let query: [String: Any] =
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: value
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { return print("Save error!!") }
    }
    
    func update(_ value: String, for key: String) {
        let value = value.data(using: String.Encoding.utf8)!
        let query: [String: Any] =
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: value
        ]
        
        let status = SecItemUpdate(query as CFDictionary, [String: AnyObject]() as CFDictionary)
        guard status == errSecSuccess else { return print("Update error!!") }
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
    
    func delete(for key: String) {
        let query: [String: Any] =
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess else { return print("Remove error!!") }
    }
}

// MARK: - API
extension AppManager {
    
    func clock(_ type: ClockType, token: String?) -> AnyPublisher<ClockResponse, WebService.WebServiceError> {
        let coordinate = generateCoordinate()
        
        let clock = WebService
            .shared
            .clock(type, token: token ?? "", latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        return clock
    }
    
    private func generateCoordinate() -> (latitude: Double, longitude: Double)  {
        let latitude = Double.random(in: minLatitude...maxLatitude).decimal(6)
        let longitude = Double.random(in: minlongitude...maxlongitude).decimal(6)
        return (latitude, longitude)
    }
}
