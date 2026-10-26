import CatWalkCore
import SwiftUI

/// 猫が画面下端を歩いたり止まったりする view。タップするかウィジェットから開くと撫でて喜ばせる。
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
    /// 設定画面 (猫の色・柄、利用規約・プライバシーポリシー・お問い合わせ) を出しているか。
    @State private var isShowingSettings = false
    /// 設定で選んだ猫の色・柄。ウィジェットも読むため、App Group の保存先から読み、変えたらそこへ書く。
    @State private var coat = UserDefaults.catWalkShared.catWalkCoat

    var body: some View {
        GeometryReader { proxy in
            let travel = max(proxy.size.width - Self.catSize, 0)
            CatPostureView(walk: walk, coat: coat, size: Self.catSize)
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
                        try startCatWalkActivity(walk: activityWalk(travel: travel), coat: coat, walkingSpeed: CatWalkState.defaultWalkingSpeed / max(travel, 1), date: .now)
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
            Button("設定", systemImage: "gearshape") {
                isShowingSettings = true
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
            .accessibilityIdentifier("settings-button")
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding([.top, .trailing])
        }
        // 猫は小さく毎秒動くため、猫の上に限らず画面のどこをタップしても撫でられるようにする
        .contentShape(Rectangle())
        .onTapGesture {
            walk = walk.petted()
        }
        .onOpenURL { _ in
            walk = walk.petted()
        }
        .onChange(of: coat) { _, newCoat in
            saveSharedCatCoat(coat: newCoat)
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
        .sheet(isPresented: $isShowingSettings) {
            NavigationStack {
                Form {
                    CatCoatPicker(coat: $coat)
                    CatWalkAboutSection()
                    #if DEBUG
                    Section("開発用: 猫の姿勢") {
                        // iPhone の幅に 1 行 4 匹が収まる大きさ
                        CatPoseGalleryView(coat: coat, size: 64)
                    }
                    #endif
                }
                .navigationTitle("設定")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("閉じる") {
                            isShowingSettings = false
                        }
                        .accessibilityIdentifier("settings-close")
                    }
                }
            }
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
