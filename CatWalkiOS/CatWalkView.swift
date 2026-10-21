import CatWalkCore
import SwiftUI

/// 猫のプレースホルダーが画面下端を歩いたり止まったりする view。タップするかウィジェットから開くと撫でて喜ばせる。
/// 「散歩に出す」で同じ猫を Live Activity (Dynamic Island・ロック画面) にも出し、前面にいる間は状態を進めるたびに更新する。
struct CatWalkView: View {
    /// 猫の大きさ。プレースホルダーの見た目の確認に十分な仮の値で、デザインの段階で決め直す。
    private static let catSize: Double = 44
    /// 状態を進める間隔 (秒)。動きの確認に十分な仮の間隔で、.animation の duration と揃えて途切れなく見せる。デザインの段階で決め直す。
    private static let tickSeconds: Double = 1

    @Environment(\.scenePhase) private var scenePhase
    @State private var walk = CatWalkState()
    /// 散歩中 (Live Activity が終了していない) か。ロック画面から消された時や上限の時間で終了した時にボタンを戻すため、状態を進めるたびに読み直す。
    @State private var isWalkingOut = isCatWalkActivityRunning()
    /// Live Activity を開始できなかったことを伝えるアラートを出しているか。
    @State private var isShowingActivityError = false
    /// Live Activity を開始できなかった時のエラーメッセージ。アラートの本文に加工せずに出す。
    @State private var activityErrorMessage = ""

    var body: some View {
        GeometryReader { proxy in
            let travel = max(proxy.size.width - Self.catSize, 0)
            CatPostureView(activity: walk.activity, direction: walk.direction, size: Self.catSize)
                .position(x: walk.x + Self.catSize / 2, y: proxy.size.height - Self.catSize * 2)
                .animation(.linear(duration: Self.tickSeconds), value: walk.x)
                .task {
                    // 見た目の行動の並びに再現性は要らないため、OS の乱数を使う
                    var random = SystemRandomNumberGenerator()
                    while !Task.isCancelled {
                        try? await Task.sleep(for: .seconds(Self.tickSeconds))
                        walk = walk.advanced(elapsedSeconds: Self.tickSeconds, width: travel, walkingSpeed: CatWalkState.defaultWalkingSpeed, random: &random)
                        isWalkingOut = isCatWalkActivityRunning()
                        if isWalkingOut {
                            await updateCatWalkActivities(walk: activityWalk(travel: travel), date: .now)
                        }
                    }
                }
            Button(isWalkingOut ? "おうちに帰す" : "散歩に出す") {
                if isWalkingOut {
                    Task {
                        await endCatWalkActivities()
                        isWalkingOut = isCatWalkActivityRunning()
                    }
                } else {
                    do {
                        // placeholder と同じく、幅が 0 の画面での 0 除算を避ける最小の幅を 1pt とする
                        try startCatWalkActivity(walk: activityWalk(travel: travel), walkingSpeed: CatWalkState.defaultWalkingSpeed / max(travel, 1), date: .now)
                        isWalkingOut = true
                        scheduleCatWalkActivityRefresh(date: .now)
                    } catch {
                        activityErrorMessage = String(describing: error)
                        isShowingActivityError = true
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top)
        }
        // 猫は小さく毎秒動くため、猫の上に限らず画面のどこをタップしても撫でられるようにする
        .contentShape(Rectangle())
        .onTapGesture {
            walk = walk.petted()
        }
        .onOpenURL { _ in
            walk = walk.petted()
        }
        .onChange(of: scenePhase) { _, newScenePhase in
            if newScenePhase == .background && isWalkingOut {
                scheduleCatWalkActivityRefresh(date: .now)
            }
        }
        .alert("散歩に出せませんでした", isPresented: $isShowingActivityError) {
            Button("OK") {}
        } message: {
            Text(activityErrorMessage)
        }
    }

    /// 今の猫の状態を、Live Activity に送る形 (`x` を歩行範囲 `travel` に対する割合にしたもの) にして返す。
    private func activityWalk(travel: Double) -> CatWalkState {
        var activityWalk = walk
        // 幅が 0 の画面では猫は左端から動かないため、0 除算を避けて左端に置く
        activityWalk.x = travel > 0 ? walk.x / travel : 0
        return activityWalk
    }
}
