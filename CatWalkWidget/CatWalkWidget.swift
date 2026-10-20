import SwiftUI
import WidgetKit

/// iOS のホーム画面・ロック画面のウィジェット。タイムラインの区切りごとに猫の姿勢と位置が変わり、タップでアプリを開いて撫でる。
@main
struct CatWalkWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "CatWalkWidget", provider: CatWalkTimelineProvider()) { entry in
            CatWalkWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
                // アプリはどの URL で開かれても撫でる反応をするため、URL は行き先を表す名前にとどめる
                .widgetURL(URL(string: "catwalk://pet"))
        }
        .configurationDisplayName("Cat Walk")
        .description("猫が時間ごとに姿勢と場所を変えます")
        .supportedFamilies([.systemSmall, .accessoryRectangular])
    }
}
