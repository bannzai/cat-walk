import ActivityKit
import CatWalkCore
import Foundation

/// 散歩に出した猫の Live Activity の属性。アプリが開始・更新し、Widget Extension が Dynamic Island とロック画面に描くため、両方の target でコンパイルする。
/// ActivityKit がメインスレッド以外から扱うため nonisolated にする。
nonisolated struct CatWalkActivityAttributes: ActivityAttributes {
    /// 更新ごとに変わる猫の姿勢と位置。`x` は歩行範囲の幅に対する割合 (0...1) で、view が実際の幅に掛ける。
    typealias ContentState = CatWalkState

    /// アプリが前面にいない間に Live Activity を更新する BGAppRefreshTask の識別子。Info.plist の `BGTaskSchedulerPermittedIdentifiers` と揃える。
    static let refreshTaskIdentifier = "com.bannzai.CatWalkiOS.activity-refresh"

    /// 散歩に出した時刻。Live Activity を終了する時刻の起点にする。
    let startDate: Date
    /// 歩行範囲の幅を 1 とした歩く速さ (幅/秒)。開始時のアプリの歩行範囲から求め、バックグラウンドの更新でもアプリと同じ速さで歩かせる。
    let walkingSpeed: Double
}
