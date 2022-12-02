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
    
//    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    
    private struct MenuView: View {
          var body: some View {
            HStack {
              Text("Hello from SwiftUI View")
              Spacer()
            }
            .background(Color.blue)
            .padding()
          }
        }
    
    init() {
      FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}

//class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
//
//    private var statusItem: NSStatusItem!
//
//    @MainActor func applicationDidFinishLaunching(_ notification: Notification) {
//
//        let contentView = MainView()
//
//        let view = NSHostingView(rootView: contentView)
//
//        // Don't forget to set the frame, otherwise it won't be shown.
//        view.frame = NSRect(x: 0, y: 0, width: 200, height: 200)
//
//        let menuItem = NSMenuItem()
//        menuItem.view = view
//
//        let menu = NSMenu()
//        menu.addItem(menuItem)
//
//        // StatusItem is stored as a class property.
//        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
//        self.statusItem?.menu = menu
////        self.statusItem?.button?.title = "HAPPY"
//
//        self.statusItem?.button?.image = NSImage(named: "32")
//    }
//}
