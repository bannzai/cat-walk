import CatWalkCore
import WidgetKit

/// ウィジェットのタイムラインのエントリ。表示を始める時刻と、その時刻の猫の状態を持つ。
/// WidgetKit がメインスレッド以外から扱うため nonisolated にする。
nonisolated struct CatWalkWidgetEntry: TimelineEntry {
    /// エントリを表示し始める時刻。
    let date: Date
    /// その時刻の猫の状態。`x` は歩行範囲の幅に対する割合 (0...1) で、ウィジェットの余白を除いた実際の幅に view が掛ける。
    let walk: CatWalkState
}

/// iOS・watchOS のウィジェットに共通のタイムライン。`CatWalkState.timelineState` で区切りごとの猫の状態を並べる。
/// WidgetKit がメインスレッド以外から呼ぶため nonisolated にする。
nonisolated struct CatWalkTimelineProvider: TimelineProvider {
    /// 1 回のタイムラインに並べるエントリの数。15 分刻みで 4 時間分にし、再読み込みを 1 日 6 回に抑えて WidgetKit の更新予算 (1 日 40〜70 回) に余裕を残す。
    private static let entryCount = 16

    func placeholder(in context: Context) -> CatWalkWidgetEntry {
        Self.entry(date: .now, context: context)
    }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (CatWalkWidgetEntry) -> Void) {
        completion(Self.entry(date: .now, context: context))
    }

    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<CatWalkWidgetEntry>) -> Void) {
        let dates = CatWalkState.timelineDates(date: .now, count: Self.entryCount, calendar: .current)
        completion(
            Timeline(
                entries: dates.map { Self.entry(date: $0, context: context) },
                policy: .after(dates[0].addingTimeInterval(Double(Self.entryCount) * CatWalkState.timelineIntervalSeconds))
            )
        )
    }

    /// `date` の区切りの猫の状態を持つエントリを返す。歩行範囲の幅を 1 とし、歩く速さもウィジェットの幅に対する割合に直して渡す。
    private static func entry(date: Date, context: Context) -> CatWalkWidgetEntry {
        CatWalkWidgetEntry(
            date: date,
            walk: CatWalkState.timelineState(
                date: date,
                calendar: .current,
                width: 1,
                // placeholder では displaySize が 0 になり得るため、0 除算を避ける最小の幅を 1pt とする
                walkingSpeed: CatWalkState.defaultWalkingSpeed / max(context.displaySize.width, 1)
            )
        )
    }
}
