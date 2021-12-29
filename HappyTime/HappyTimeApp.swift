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
    
    init() {
        setupAppearance()
    }
    
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
        coloredAppearance.shadowColor = .clear
        
        UINavigationBar.appearance().standardAppearance = coloredAppearance
        UINavigationBar.appearance().compactAppearance = coloredAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = coloredAppearance
        UINavigationBar.appearance().tintColor = titleColor
    }
}
