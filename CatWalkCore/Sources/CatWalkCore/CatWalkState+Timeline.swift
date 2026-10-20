import Foundation

/// iOS・watchOS のウィジェットのタイムラインを作るための関数。
/// ウィジェットは連続して動かせないため、区切りの時刻ごとの状態をその日の 0 時から状態機械で進めて求める。
extension CatWalkState {
    /// タイムラインのエントリの間隔 (秒)。WidgetKit の更新の目安 (15〜60 分に 1 回) の下限に合わせ、姿勢と位置が変わる機会を最も多くする。
    /// 出典: https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date
    public static let timelineIntervalSeconds: Double = 15 * 60

    /// `date` 以前で最も近い区切り (`calendar` の暦でその日の 0 時から `timelineIntervalSeconds` ごと) から始まる、`count` 個の区切りの時刻を返す。
    public static func timelineDates(date: Date, count: Int, calendar: Calendar) -> [Date] {
        let dayStart = calendar.startOfDay(for: date)
        let firstSlot = (date.timeIntervalSince(dayStart) / timelineIntervalSeconds).rounded(.down)
        return (0..<max(count, 0)).map { dayStart.addingTimeInterval((firstSlot + Double($0)) * timelineIntervalSeconds) }
    }

    /// `date` を含む区切りの時刻の猫の状態を返す。`calendar` の暦でその日の 0 時に初期状態から始め、その日の 0 時から作ったシードで区切りまで進める。
    /// 同じ区切りには何度呼んでも同じ状態を返すため、タイムラインを作り直しても猫が飛ばない。行動の並びは `width` と `walkingSpeed` に依らないため、
    /// 同じ暦の iPhone と Apple Watch のウィジェットは同じ時刻に同じ姿勢になる。
    public static func timelineState(date: Date, calendar: Calendar, width: Double, walkingSpeed: Double) -> CatWalkState {
        let dayStart = calendar.startOfDay(for: date)
        var random = SplitMix64(state: UInt64(bitPattern: Int64(dayStart.timeIntervalSince1970)))
        return CatWalkState().advanced(
            elapsedSeconds: (date.timeIntervalSince(dayStart) / timelineIntervalSeconds).rounded(.down) * timelineIntervalSeconds,
            width: width,
            walkingSpeed: walkingSpeed,
            random: &random
        )
    }
}
