//
//  NotificationManager.swift
//  HappyTime
//
//  Created by Patty Chang on 23/12/2022.
//

import UIKit
import Combine

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isReceivedNotification: Bool = false
    @Published var isNeededChange: Bool = false
    @Published var notificationTime = Date()
    
    private init() {}
    
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
        
        group.notify(queue: .main) { [unowned self] in
            guard !isExist, let date = date(dateString) else {
                print("already Exist")
                return
            }
            self.addNotificationRequest(with: self.checkTime(date))
        }
    }
    
    func checkTime(_ date: Date) -> Date? {
        guard let final = Calendar.current.date(bySettingHour: 19, minute: 10, second: 59, of: Date()),
              let added = Calendar.current.date(byAdding: .init(timeZone: .current, hour: 9, minute: 1), to: date)
        else { return nil }
        if added > final {
            notificationTime = final
            return final
        }
        notificationTime = added
        return added
    }
    
    func addNotificationRequest(with date: Date?) {
        removeNotification()
        
        UNUserNotificationCenter
            .current()
            .getNotificationSettings { setting in
                
                guard setting.authorizationStatus == .authorized else { return }
                
                guard let date = date else { return }
                
                let content = UNMutableNotificationContent()
                content.title = "下班了！"
                content.subtitle = "請記得打卡～～～🧡"
                if #available(iOS 15.0, *) {
                    content.body = date.formatted()
                } else {
                    content.body = date.description
                }
                content.sound = .default
                content.categoryIdentifier = "notification"
                
                guard let imageURL: URL = Bundle.main.url(forResource: "NotificationIcon", withExtension: "png"),
                      let attachment = try? UNNotificationAttachment(identifier: "image", url: imageURL, options: nil)
                else { return }
                
                content.attachments = [attachment]
                
                let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let request = UNNotificationRequest(identifier: "notification", content: content, trigger: trigger)
                
                UNUserNotificationCenter.current().add(request) { _ in
                    if #available(iOS 15.0, *) {
                        print("add notification success: ", date.formatted())
                    } else {
                        print("add notification success: ", date.description)
                    }
                }
            }
    }

    
    func getNotification(completion: @escaping (String) -> Void) {
        UNUserNotificationCenter
            .current()
            .getPendingNotificationRequests { notifications in
                completion(notifications.first?.content.body ?? "")
            }
    }
    
    func removeNotification() {
        UNUserNotificationCenter
            .current()
            .removeAllPendingNotificationRequests()
    }
}

fileprivate func date(_ date: String) -> Date? {
    let format = DateFormatter()
    format.dateFormat = "yyyy-MM-dd HH:mm:ss"
    format.timeZone = TimeZone.current
    return format.date(from: date)
}
