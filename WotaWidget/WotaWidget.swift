//
//  WotaWidget.swift
//  WotaWidget
//
//  Created by Camille Khubbetdinov on 16.01.2021.
//

import WidgetKit
import SwiftUI

extension UserDefaults {
    static var shared = UserDefaults(suiteName: "group.Wota.camille.com")
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct Score: View {
    var amount: Int
    var name: String
    var body: some View {
        
        VStack {
            ZStack {
                Rectangle()
                    .foregroundColor(.blue)
                VStack {
                    Spacer()
                    Text("\(self.amount)")
                        .foregroundColor(.white)
                        .bold()
                    Spacer()
                }
            }
            Text(name).font(.caption)
        }
    }
    
}

struct Person: Hashable {
    var name: String
    var amount: Int
}

struct WotaWidgetEntryView : View {
    var entry: Provider.Entry
    let ud = UserDefaults.shared
    @State var data: [Person] = []

    func setArray(_ dic: [String:Any]) -> [Person] {
        var array: [Person] = []
        for i in dic {
            array.append(Person(name: i.key, amount: i.value as! Int))
        }
        array.sort {$0.amount>$1.amount}
        return array
    }
//    func fetchData(_ data: [Person]) {
//
//    }
    
    var body: some View {
        HStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/, spacing: /*@START_MENU_TOKEN@*/nil/*@END_MENU_TOKEN@*/, content: {
            Spacer().frame(width: 8)
            ForEach(self.data, id: \.self) { person in
                Score(amount: person.amount, name: person.name)
            }
            Spacer().frame(width: 8)
        })
        .onAppear() {
            if ud!.value(forKey: "CurrentData") == nil {
                self.data = []
            } else {
                self.data = setArray(ud!.value(forKey: "CurrentData") as! [String : Any])
            }
            
        }
    }
}

@main
struct WotaWidget: Widget {
    let kind: String = "WotaWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WotaWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
    }
}

struct WotaWidget_Previews: PreviewProvider {
    static var previews: some View {
        WotaWidgetEntryView(entry: SimpleEntry(date: Date()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
        WotaWidgetEntryView(entry: SimpleEntry(date: Date()))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
        WotaWidgetEntryView(entry: SimpleEntry(date: Date()))
            .previewContext(WidgetPreviewContext(family: .systemLarge))
    }
}
