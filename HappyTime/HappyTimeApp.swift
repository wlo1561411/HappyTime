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
    
    var body: some Scene {
        WindowGroup {
//            MainView()
            TestView()
        }
        .onChange(of: scenePhase) { newScenePhase in
            switch newScenePhase {
            case .active:
                setupAppearance()
            case .inactive, .background: break
            @unknown default:
                print("Oh oops")
            }
        }
    }
    
    func setupAppearance() {
        updateNavigationBar(backgroundColor: UIColor(named: "AccentColor"), titleColor: .white)
        
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor.white
    }
    
    private func updateNavigationBar(backgroundColor: UIColor?, titleColor: UIColor?) {
        let coloredAppearance = UINavigationBarAppearance()
        coloredAppearance.configureWithTransparentBackground()
        coloredAppearance.backgroundColor = backgroundColor
        coloredAppearance.titleTextAttributes = [.foregroundColor: titleColor ?? .white]
        coloredAppearance.largeTitleTextAttributes = [.foregroundColor: titleColor ?? .white]

        UINavigationBar.appearance().standardAppearance = coloredAppearance
        UINavigationBar.appearance().compactAppearance = coloredAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = coloredAppearance
    }
}
