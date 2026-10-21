import ActivityKit
import BackgroundTasks
import CatWalkCore
import Foundation

// Live Activity の開始・更新・終了と、アプリが前面にいない間の更新の予約。
// ActivityKit の `Activity` は Sendable ではないため、取得から更新までを nonisolated の関数の中で閉じ、MainActor の view とは Sendable な値だけをやり取りする。

/// 散歩中 (終了していない) の Live Activity があるかを返す。
nonisolated func isCatWalkActivityRunning() -> Bool {
    !runningCatWalkActivities().isEmpty
}

/// `walk` の姿勢で Live Activity を開始する。散歩中の Live Activity が既にあれば何もしない。
/// `walkingSpeed` は歩行範囲の幅を 1 とした歩く速さで、バックグラウンドの更新に使う。開始できない時 (ユーザーが Live Activity を許可していない等) は ActivityKit のエラーを投げる。
nonisolated func startCatWalkActivity(walk: CatWalkState, walkingSpeed: Double, date: Date) throws {
    guard !isCatWalkActivityRunning() else {
        return
    }
    _ = try Activity.request(
        attributes: CatWalkActivityAttributes(startDate: date, walkingSpeed: walkingSpeed),
        content: ActivityContent(state: walk, staleDate: CatWalkState.liveActivityEndDate(startDate: date))
    )
}

/// 散歩中の Live Activity をすべて `walk` の姿勢に更新する。アプリが前面にいる間に状態を進めるたびに呼ぶ。
nonisolated func updateCatWalkActivities(walk: CatWalkState, date: Date) async {
    for activity in runningCatWalkActivities() {
        await updateCatWalkActivity(activity: activity, walk: walk, date: date)
    }
}

/// 散歩中の Live Activity をすべて、`date` を含むウィジェットのタイムラインの区切りの姿勢に更新し、散歩が続くなら次の更新を予約する。
/// アプリが前面にいない間の BGAppRefreshTask から呼ぶ。区切りの姿勢はアプリの猫と続いていないが、ホーム画面のウィジェットと同じ時刻に同じ行動になる。
nonisolated func refreshCatWalkActivities(date: Date) async {
    for activity in runningCatWalkActivities() {
        await updateCatWalkActivity(
            activity: activity,
            walk: CatWalkState.timelineState(date: date, calendar: .current, width: 1, walkingSpeed: activity.attributes.walkingSpeed),
            date: date
        )
    }
    if isCatWalkActivityRunning() {
        scheduleCatWalkActivityRefresh(date: date)
    }
}

/// 散歩中の Live Activity をすべてすぐに終了する。ユーザーが自分で猫を帰したため、ロック画面にも残さない。
nonisolated func endCatWalkActivities() async {
    for activity in runningCatWalkActivities() {
        await activity.end(nil, dismissalPolicy: .immediate)
    }
}

/// `date` の後の次のタイムラインの区切り以降に、Live Activity を更新する BGAppRefreshTask を予約する。予約済みのものは置き換えるため、何度呼んでも予約は 1 つになる。
nonisolated func scheduleCatWalkActivityRefresh(date: Date) {
    let request = BGAppRefreshTaskRequest(identifier: CatWalkActivityAttributes.refreshTaskIdentifier)
    request.earliestBeginDate = CatWalkState.liveActivityNextRefreshDate(date: date, calendar: .current)
    do {
        try BGTaskScheduler.shared.submit(request)
    } catch {
        // Simulator やバックグラウンド更新をオフにした端末では予約できない。予約できなくても Live Activity は最後の姿勢のまま表示され、
        // アプリを前面に戻すと 1 秒ごとの更新が再開するため、散歩は止めずにエラーを記録するだけにする
        print("BGAppRefreshTask を予約できませんでした: \(error)")
    }
}

/// 終了していない (表示中または古くなった) Live Activity を返す。
nonisolated private func runningCatWalkActivities() -> [Activity<CatWalkActivityAttributes>] {
    Activity<CatWalkActivityAttributes>.activities.filter { $0.activityState == .active || $0.activityState == .stale }
}

/// `activity` を `walk` の姿勢に更新する。開始から上限の時間を過ぎていれば、代わりにその姿勢で終了し、ロック画面には ActivityKit の既定の時間だけ残す。
nonisolated private func updateCatWalkActivity(activity: Activity<CatWalkActivityAttributes>, walk: CatWalkState, date: Date) async {
    let endDate = CatWalkState.liveActivityEndDate(startDate: activity.attributes.startDate)
    let content = ActivityContent(state: walk, staleDate: endDate)
    if date >= endDate {
        await activity.end(content, dismissalPolicy: .default)
    } else {
        await activity.update(content)
    }
}
