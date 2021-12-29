//
//  AttendanceWebView.swift
//  HappyTime
//
//  Created by Finn Wu on 2021/12/29.
//

import SwiftUI

struct AttendanceWebView: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        WebView(
            url: .init(string: "https://cloud.nueip.com/attendance_record")
        )
        .navigationBarTitle("出勤紀錄", displayMode: .inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                }
            }
        }
    }
}

struct AttendanceWebView_Previews: PreviewProvider {
    static var previews: some View {
        AttendanceWebView()
    }
}
