//
//  HappyTimeApp.swift
//  HappyTime
//
//  Created by Finn Wu on 2021/8/19.
//

import SwiftUI

@main
struct HappyTimeApp: App {
    
    @Environment(\.scenePhase) var scenePhase
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .accentColor(Color(UIColor(named: "AccentColor") ?? .darkGray))
        }
        .onChange(of: scenePhase) { newScenePhase in
            switch newScenePhase {
            case .active, .inactive, .background: break
            @unknown default:
                print("Oh oops")
            }
        }
    }
}
