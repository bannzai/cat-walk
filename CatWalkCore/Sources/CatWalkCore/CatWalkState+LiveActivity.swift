import Foundation

/// iOS の Live Activity (Dynamic Island・ロック画面の猫) の時刻を決めるための関数。
/// アプリが前面にいない間の更新はバックグラウンドの更新に頼り、姿勢は `timelineState` でウィジェットと同じ区切りに揃える。
extension CatWalkState {
    /// Live Activity を続ける最長の秒数。ActivityKit が Live Activity を終了させる上限 (8 時間) に合わせる。
    /// 出典: https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities
    public static let liveActivityMaximumSeconds: Double = 8 * 60 * 60

    /// `startDate` に始めた Live Activity を終了する時刻を返す。
    public static func liveActivityEndDate(startDate: Date) -> Date {
        startDate.addingTimeInterval(liveActivityMaximumSeconds)
    }

    /// `date` に Live Activity を更新した後、バックグラウンドで次に更新したい時刻を返す。
    /// ウィジェットのタイムラインと同じ時刻に姿勢を変えるため、`date` より後で最も近い区切り (`calendar` の暦でその日の 0 時から `timelineIntervalSeconds` ごと) にする。
    public static func liveActivityNextRefreshDate(date: Date, calendar: Calendar) -> Date {
        timelineDates(date: date, count: 2, calendar: calendar)[1]
    }
}
