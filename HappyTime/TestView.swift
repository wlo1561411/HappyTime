//
//  TestView.swift
//  HappyTime
//
//  Created by Finn Wu on 2021/9/8.
//

import SwiftUI
import Intents

struct TestView: View {
    
    @State var seconds: Double = 0
    
    var body: some View {
        VStack {
            Text("\(seconds)")
            
            SiriButton(shortcut: createUserActivity())
        }
        .onContinueUserActivity("com.Fun.HappyTime.Test", perform: { userActivity in
            calcTime()
        })
    }
    
    private func calcTime() {
        let f = DateFormatter()
        
        f.dateFormat = "YYYY-MM-dd HH:mm:ss"
        
        let start = f.date(from: "2021-01-01 00:00:00")
        let seconds = start!.timeIntervalSinceNow as Double
        
        self.seconds = seconds
    }
    
    func createUserActivity() -> INShortcut {
        let activity = NSUserActivity(activityType: "com.Fun.HappyTime.Test")
        
        activity.title = "test title"
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true
        activity.suggestedInvocationPhrase = "Test app"
        
        return .init(userActivity: activity)
    }
}

struct TestView_Previews: PreviewProvider {
    static var previews: some View {
        TestView()
    }
}
