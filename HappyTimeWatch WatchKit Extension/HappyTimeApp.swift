//
//  HappyTimeApp.swift
//  HappyTimeWatch WatchKit Extension
//
//  Created by Patty Chang on 18/07/2022.
//

import SwiftUI
import Firebase
import UserNotifications

@main
struct HappyTimeApp: App {
    
    init() {
      FirebaseApp.configure()
        
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.sound, .alert]) { success, error in
                if success {
                    print("authorization granted")
                } else if let error = error {
                    print(error.localizedDescription)
                }
            }
    }
    
    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
        }

        WKNotificationScene(controller: NotificationController.self, category: "notification")
    }
}
