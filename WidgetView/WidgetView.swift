//
//  WidgetView.swift
//  WidgetView
//
//  Created by Patty Chang on 18/05/2022.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        UNUserNotificationCenter
            .current()
            .getPendingNotificationRequests { notifications in
                let currentDate = Date()
                let target = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)
                
                let timeline = Timeline(
                    entries: [
                        SimpleEntry(
                            date: Date(),
                            startTime: notifications.first?.content.body
                        )
                    ],
                    policy: .after(target!)
                )
                completion(timeline)
            }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    var startTime: String?
}

struct WidgetViewEntryView : View {
    var entry: Provider.Entry
    
    @Environment(\.widgetFamily) var family

    var body: some View {
        
        switch family {
            
        case .systemSmall:
            ZStack {
                Color.black
                Color("brown")
                    .opacity(0.77)
                Image("icon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .opacity(0.6)
                    .blur(radius: 3)
                Text("LOG")
                    .font(.title)
                    .fontWeight(.heavy)
                    .shadow(color: .black, radius: 8, x: 2, y: -2)
                    .foregroundColor(.white)
                    .widgetURL(WidgetViewModel.Model.logURL)  // default deeplink
            }
            
        case .systemMedium:
            ZStack {
                Color.black
                Color("brown")
                    .opacity(0.79)
                HStack {
                    Spacer()
                    Image("icon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .opacity(0.6)
                        .blur(radius: 3)
                }
                
                VStack {
                    Text("")
                        .padding()
                    
                    HStack {
                        Spacer()
                        Link(destination: WidgetViewModel.Model.inURL) {
                            Text("IN")
                                .font(.title)
                                .fontWeight(.heavy)
                                .foregroundColor(.white)
                                .shadow(color: .black, radius: 8, x: 2, y: -2)
                        }
                        
                        Spacer()
                        Text("LOG")
                            .font(.title)
                            .fontWeight(.heavy)
                            .shadow(color: .black, radius: 8, x: 2, y: -2)
                            .foregroundColor(.white)
                            .widgetURL(WidgetViewModel.Model.logURL)
                        
                        Spacer()
                        Link(destination: WidgetViewModel.Model.outURL) {
                            Text("OUT")
                                .font(.title)
                                .fontWeight(.heavy)
                                .foregroundColor(.white)
                                .shadow(color: .black, radius: 8, x: 5, y: -5)
                        }
                        Spacer()
                    }
                    .padding()
                    
                    Text(entry.startTime ?? "")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 8, x: 2, y: -2)
                        .padding()
                }
            }
            
        default:
            ZStack {
                Color.black
                Color("brown")
                    .opacity(0.77)
                Image("icon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .opacity(0.6)
                    .blur(radius: 3)
                Text("LOG")
                    .font(.title)
                    .fontWeight(.heavy)
                    .shadow(color: .black, radius: 8, x: 2, y: -2)
                    .foregroundColor(.white)
                    .widgetURL(WidgetViewModel.Model.logURL)
            }
        }
    }
}

@main
struct WidgetView: Widget {
    let kind: String = "WidgetView"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WidgetViewEntryView(entry: entry)
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
    }
}

struct WidgetView_Previews: PreviewProvider {
    static var previews: some View {
        WidgetViewEntryView(entry: SimpleEntry(date: Date()))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
