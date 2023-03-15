//
//  NotificationEditor.swift
//  HappyTime
//
//  Created by Patty Chang on 23/12/2022.
//

import SwiftUI

struct NotificationEditor: View {
    @Binding var isShowed: Bool
    @Binding var time: Date
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
            VStack(alignment: .trailing) {
                Button {
                    isShowed.toggle()
                    NotificationManager.shared.addNotificationRequest(with: time)
                } label: {
                    Text("Save")
                        .foregroundColor(.white)
                        .fontWeight(.black)
                        .padding()
                }
                
                DatePicker(selection: $time, displayedComponents: .hourAndMinute) {
                    Text("設定下班時間提醒")
                        .font(.headline)
                        .bold()
                        .padding(.leading)
                }
                .preferredColorScheme(.dark)
                .foregroundColor(.white)
                .padding()
            }
        }
    }
}

struct NotificationEditor_Previews: PreviewProvider {
    static var previews: some View {
        NotificationEditor(isShowed: .constant(true), time: .constant(Date()))
            .previewLayout(.fixed(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.25))
    }
}
