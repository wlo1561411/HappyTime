//
//  HappyTimeApp.swift
//  HappyTimeWatch WatchKit Extension
//
//  Created by Patty Chang on 18/07/2022.
//

import SwiftUI
import Firebase

@main
struct HappyTimeApp: App {
    
    init() {
      FirebaseApp.configure()
    }
    
    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
        }

        WKNotificationScene(controller: NotificationController.self, category: "myCategory")
    }
}
