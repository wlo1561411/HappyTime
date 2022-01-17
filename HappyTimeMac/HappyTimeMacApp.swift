//
//  HappyTimeMacApp.swift
//  HappyTimeMac
//
//  Created by Wesley on 2022/1/17.
//

import SwiftUI
import Firebase

@main
struct HappyTimeMacApp: App {
    
    init() {
      FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}
