import SwiftUI
import WidgetKit

/// ウィジェットの中で猫を 1 秒 1 コマで歩かせる試作。WidgetKit の公開 API には常に動くアニメーションが無いため、
/// 毎秒書き換わるタイマー表示の最後の 1 文字 (秒の 1 の位) を、数字の代わりに猫のコマを描くフォント (`CatWalkFrames-Regular.ttf`) で出す。
/// Apple はこの手法をサポートしておらず、電池の消耗を招きうると開発者フォーラムで回答している: https://developer.apple.com/forums/thread/757696
struct CatWalkFrameAnimationWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "CatWalkFrameAnimationWidget", provider: CatWalkFrameAnimationProvider()) { entry in
            CatWalkFrameAnimationView(startDate: entry.date)
                .containerBackground(for: .widget) {
                    Rectangle()
                        .fill(.fill.tertiary)
                }
        }
        .configurationDisplayName("Cat Walk (試作)")
        .description("1 秒 1 コマで猫が歩きます")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

/// タイマーを数え始める時刻だけを持つエントリ。WidgetKit がメインスレッド以外から扱うため nonisolated にする。
nonisolated private struct CatWalkFrameAnimationEntry: TimelineEntry {
    /// タイマーを数え始める時刻。
    let date: Date
}

/// タイマー表示が自分で毎秒描き直すため、エントリは 1 つだけ返し、タイムラインを読み直させない。
/// WidgetKit がメインスレッド以外から呼ぶため nonisolated にする。
nonisolated private struct CatWalkFrameAnimationProvider: TimelineProvider {
    func placeholder(in context: Context) -> CatWalkFrameAnimationEntry {
        CatWalkFrameAnimationEntry(date: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (CatWalkFrameAnimationEntry) -> Void) {
        completion(CatWalkFrameAnimationEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<CatWalkFrameAnimationEntry>) -> Void) {
        completion(Timeline(entries: [CatWalkFrameAnimationEntry(date: .now)], policy: .never))
    }
}

/// タイマー表示の最後の 1 文字だけを、ウィジェットの横幅いっぱいに見せる view。
private struct CatWalkFrameAnimationView: View {
    /// タイマーを数え始める時刻。ここからの経過秒の 1 の位がコマ番号になる。
    let startDate: Date

    /// フォントの 1 文字の幅 (em)。`scripts/generate_walk_frame_font.py` の `GLYPH_ADVANCE` / `UNITS_PER_EM` と揃える。
    private static let glyphWidthEm = 4.0
    /// タイマー表示の最大の文字数。時・分・秒と区切りの `:` で 8 文字 (`23:59:59`) に収まり、1 文字の余裕を持たせる。
    private static let maxCharacterCount = 9.0

    var body: some View {
        GeometryReader { proxy in
            Text(startDate, style: .timer)
                .font(.custom("CatWalkFrames-Regular", size: proxy.size.width / Self.glyphWidthEm))
                .multilineTextAlignment(.trailing)
                // 文字数が時間の経過で変わっても最後の 1 文字が同じ場所に来るよう、右寄せした幅の広い枠の右端の 1 文字分だけを見せる
                .frame(width: proxy.size.width * Self.maxCharacterCount, height: proxy.size.height, alignment: .trailing)
                .offset(x: -proxy.size.width * (Self.maxCharacterCount - 1))
        }
        .clipped()
        .accessibilityLabel("歩く猫")
    }
}
