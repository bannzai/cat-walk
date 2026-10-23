import SwiftUI
import WidgetKit

/// watchOS のコンプリケーション。タイムラインの区切りごとに猫の姿勢が変わる。
@main
struct CatWalkWatchWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "CatWalkWatchWidget", provider: CatWalkTimelineProvider()) { entry in
            CatWalkWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Cat Walk")
        .description("猫が時間ごとに姿勢を変えます")
        .supportedFamilies([.accessoryRectangular, .accessoryCircular])
    }
}
