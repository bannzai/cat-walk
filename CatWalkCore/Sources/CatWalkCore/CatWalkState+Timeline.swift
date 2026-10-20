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

    /// `date` を含む区切りの時刻の猫の状態を返す。`calendar` の暦でその日の 0 時に初期状態から始め、その日の 0 時から作ったシードで区切りを 1 つずつ進める。
    /// 区切りごとに姿勢と位置が変わって見えるよう、各区切りは `timelineIntervalSeconds` 進めた後も、前の区切り (その日の最後の区切りは翌日の最初の区切りも) と行動が違い、
    /// かつ間に歩く行動を挟むまで行動の切り替わりごとに進める。
    /// そのため区切りの状態は時刻ちょうどの状態ではない。
    /// 同じ区切りには何度呼んでも同じ状態を返すため、タイムラインを作り直しても猫が飛ばない。行動の並びは `width` と `walkingSpeed` に依らないため、
    /// 同じ暦の iPhone と Apple Watch のウィジェットは同じ時刻に同じ行動になる。向きと位置は端で折り返す回数で決まり、画面の幅によって変わる。
    public static func timelineState(date: Date, calendar: Calendar, width: Double, walkingSpeed: Double) -> CatWalkState {
        let dayStart = calendar.startOfDay(for: date)
        var random = SplitMix64(state: UInt64(bitPattern: Int64(dayStart.timeIntervalSince1970)))
        var state = CatWalkState()
        for slot in stride(from: 1, through: Int((date.timeIntervalSince(dayStart) / timelineIntervalSeconds).rounded(.down)), by: 1) {
            let previousActivity = state.activity
            // 翌日の最初の区切りは初期状態に戻るため、その日の最後の区切りは初期状態の行動とも違う行動にして、日付をまたぐ時も姿勢を変える
            let nextDayActivity: CatActivity? = calendar.startOfDay(for: dayStart.addingTimeInterval(Double(slot + 1) * timelineIntervalSeconds)) == dayStart ? nil : CatWalkState().activity
            var elapsedSeconds: Double = 0
            var hasWalked = false
            while elapsedSeconds < timelineIntervalSeconds || state.activity == previousActivity || state.activity == nextDayActivity || !hasWalked {
                // 区切りまでは区切りの時刻で止め、区切りを過ぎた後は行動の切り替わりまで進める
                let stepSeconds = elapsedSeconds < timelineIntervalSeconds ? min(state.activityRemaining, timelineIntervalSeconds - elapsedSeconds) : state.activityRemaining
                hasWalked = hasWalked || state.activity == .walking
                state = state.advanced(elapsedSeconds: stepSeconds, width: width, walkingSpeed: walkingSpeed, random: &random)
                elapsedSeconds += stepSeconds
            }
        }
        return state
    }
}
