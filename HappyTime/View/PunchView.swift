//
//  PunchView.swift
//  HappyTime
//
//  Created by Finn Wu on 2021/9/7.
//

import SwiftUI

struct PunchView: View {
    
    struct Model {
        let title: String
        let punches: [PunchElement]
    }
    
    let model: Model
    
    var body: some View {
        VStack(alignment: .center) {
            Text(model.title)
            
            Divider()
                .background(Color.white)
            
            VStack(alignment: .leading, spacing: 10) {
                ForEach(model.punches, id: \.self) { element in
                    if let type = element.chinese {
                        HStack {
                            Text(type)
                            Spacer()
                            Text(element.workTime)
                        }
                    }
                }
            }
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(
            Color.accentColor
                .cornerRadius(10)
        )
    }
}

struct PunchView_Previews: PreviewProvider {
    static var previews: some View {
        PunchView(
            model: .init(
                title: "Test",
                punches: [
                    .init(workTime: "?????1", type: "onPunch"),
                    .init(workTime: "?????2", type: "onPunch")
                ]
            )
        )
    }
}
