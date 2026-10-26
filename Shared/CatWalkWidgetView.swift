import CatWalkCore
import SwiftUI
import WidgetKit

/// iOS・watchOS のウィジェットに共通の view。円形のコンプリケーションは姿勢だけ、iOS 27 の特大サイズは猫の部屋、それ以外は猫を横位置に置いて一言を添える。
struct CatWalkWidgetView: View {
    @Environment(\.widgetFamily) private var widgetFamily

    /// 表示するエントリ。
    let entry: CatWalkWidgetEntry

    var body: some View {
        switch widgetFamily {
        case .accessoryCircular:
            // 円形は小さく横位置を出す余地が無いため、姿勢だけを中央に出す。大きさは円の内側に収まる仮の値で、デザインの段階で決め直す
            CatPostureView(activity: entry.walk.activity, direction: entry.walk.direction, size: 24)
        // 特大サイズは iOS 27 の SDK (Xcode 27・Swift 6.4) の iOS にしか無いため、watchOS と Xcode 26 の CI でもビルドできるよう分ける
        #if os(iOS) && compiler(>=6.4)
        case .systemExtraLargePortrait:
            CatWalkRoomView(entry: entry)
        #endif
        default:
            // ホーム画面は猫の大きさをアプリと揃え、ロック画面・コンプリケーションは一言と並ぶ高さに収める。どちらも仮の値で、デザインの段階で決め直す
            // watchOS では systemSmall が使えず比較もできないため、両 OS にある accessoryRectangular で見分ける
            let catSize: Double = widgetFamily == .accessoryRectangular ? 22 : 44
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.walk.activity.caption)
                    .font(.headline)
                GeometryReader { proxy in
                    CatPostureView(activity: entry.walk.activity, direction: entry.walk.direction, size: catSize)
                        .position(x: max(proxy.size.width - catSize, 0) * entry.walk.x + catSize / 2, y: proxy.size.height - catSize / 2)
                }
            }
        }
    }
}
