import ActivityKit
import CatWalkCore
import SwiftUI
import WidgetKit

/// 散歩に出した猫の Live Activity。アプリが送った姿勢と位置で、ロック画面と Dynamic Island に猫を出す。タップでアプリを開いて撫でる。
/// 猫の大きさはどれもプレースホルダーの見た目の確認に十分な仮の値で、デザインの段階で決め直す。
struct CatWalkLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CatWalkActivityAttributes.self) { context in
            // ロック画面はホーム画面のウィジェットと同じく、一言と歩く範囲の中の猫を出す。猫の大きさはホーム画面と揃える
            VStack(alignment: .leading, spacing: 4) {
                Text(context.state.activity.caption)
                    .font(.headline)
                CatWalkActivityTrackView(walk: context.state, catSize: 44)
                    .frame(height: 52)
            }
            .padding()
            // アプリはどの URL で開かれても撫でる反応をするため、URL はウィジェットと同じ行き先を表す名前にとどめる
            .widgetURL(URL(string: "catwalk://pet"))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.state.activity.caption)
                        .font(.headline)
                }
                // 展開時は横幅いっぱいの下段を歩く範囲にし、ロック画面と同じく横位置を出す
                DynamicIslandExpandedRegion(.bottom) {
                    CatWalkActivityTrackView(walk: context.state, catSize: 32)
                        .frame(height: 40)
                }
            } compactLeading: {
                // compact と minimal は横位置を出す余地が無いため、姿勢だけを出す
                CatPostureView(walk: context.state, size: 16)
                    // 猫のラベルは compactTrailing の一言と同じ文のため、VoiceOver で 2 回読まれないよう隠す
                    .accessibilityHidden(true)
            } compactTrailing: {
                Text(context.state.activity.caption)
                    .font(.caption2)
                    .lineLimit(1)
            } minimal: {
                CatPostureView(walk: context.state, size: 16)
            }
            .widgetURL(URL(string: "catwalk://pet"))
        }
    }
}

/// Live Activity の歩く範囲。`walk.x` (歩行範囲の幅に対する割合) を実際の幅に掛けて、猫を下端に置く。
private struct CatWalkActivityTrackView: View {
    /// 表示する猫の状態。
    let walk: CatWalkState
    /// 猫の大きさ (pt)。
    let catSize: Double

    var body: some View {
        GeometryReader { proxy in
            CatPostureView(walk: walk, size: catSize)
                // ロック画面・展開時はどちらも一言と並べて出すため、猫のラベルを VoiceOver で 2 回読ませないよう隠す
                .accessibilityHidden(true)
                .position(x: max(proxy.size.width - catSize, 0) * walk.x + catSize / 2, y: proxy.size.height - catSize / 2)
        }
    }
}
