import SwiftUI
import WidgetKit

/// iOS のホーム画面・ロック画面のウィジェット。タイムラインの区切りごとに猫の姿勢と位置が変わり、タップでアプリを開いて撫でる。
struct CatWalkWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "CatWalkWidget", provider: CatWalkTimelineProvider()) { entry in
            CatWalkWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    CatWalkWidgetBackground()
                }
                // アプリはどの URL で開かれても撫でる反応をするため、URL は行き先を表す名前にとどめる
                .widgetURL(URL(string: "catwalk://pet"))
        }
        .configurationDisplayName("Cat Walk")
        .description("猫が時間ごとに姿勢と場所を変えます")
        .supportedFamilies(supportedFamilies)
    }

    /// 提供するサイズ。iOS 27 ではホーム画面 1 ページ分の特大サイズに猫の部屋を出す。
    /// 特大サイズは iOS 27 の SDK (Xcode 27・Swift 6.4) にしか無いため、Xcode 26 の CI でもビルドできるよう compiler で分ける。
    private var supportedFamilies: [WidgetFamily] {
        #if compiler(>=6.4)
        if #available(iOS 27.0, *) {
            return [.systemSmall, .accessoryRectangular, .systemExtraLargePortrait]
        }
        #endif
        return [.systemSmall, .accessoryRectangular]
    }
}

/// ウィジェットの背景。特大サイズは猫の部屋、それ以外は従来の塗り。
/// tinted / clear のモードで OS が外せるよう、部屋の壁・窓・床は前景ではなく container background に置く。
private struct CatWalkWidgetBackground: View {
    @Environment(\.widgetFamily) private var widgetFamily

    var body: some View {
        switch widgetFamily {
        #if compiler(>=6.4)
        case .systemExtraLargePortrait:
            CatWalkRoomBackground()
        #endif
        default:
            Rectangle()
                .fill(.fill.tertiary)
        }
    }
}
