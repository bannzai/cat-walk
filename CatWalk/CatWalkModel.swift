import CatWalkCore
import Observation
import SwiftUI

/// 1 枚のオーバーレイで歩く猫の状態と、その状態を時間で進める駆動。
/// 猫を隠している間にタイマーを止められるよう、駆動を view の寿命から切り離してパネルが持つ。
@Observable
final class CatWalkModel {
    /// 歩く間に状態を進める間隔 (秒)。歩く間の描画は linear のアニメーションが毎フレーム補間するため、この間隔は CPU にほぼ効かない。
    /// 長くするほど端での折り返しが直線の補間で端に届かずに見えるため、立ち上げ時の 1 秒を引き継ぐ
    static let walkingTickSeconds: Double = 1

    /// 今の猫の状態。
    private(set) var walk = CatWalkState()
    /// 猫が歩ける横幅 (pt)。パネルの幅から猫の大きさを引いた値で、ディスプレイ構成が変わるたびにパネルが更新する。
    /// 眠っている間は次に状態を進めるまで長く待つため、縮んだ時はその場で猫を範囲内へ戻し、画面外に取り残さない。
    var travelWidth: Double = 0 {
        didSet {
            walk = walk.clamped(width: travelWidth)
        }
    }
    /// 状態を進めている Task。止まっている間は nil。
    @ObservationIgnored private var driveTask: Task<Void, Never>?
    /// 経過時間を測る時計。Task.sleep と同じくスリープ中の時間も数える。
    @ObservationIgnored private let clock = ContinuousClock()
    /// 最後に `walk` へ経過時間を反映した時刻。止める時に、そこから経った分を行動の残り時間から引くために持つ。
    @ObservationIgnored private var lastInstant: ContinuousClock.Instant?

    /// 状態を時間で進め始める。歩く間は `walkingTickSeconds` ごと、ほかの行動では行動が切り替わる時だけ起きる。
    /// 既に動いていれば何もしないため冪等。
    func start() {
        guard driveTask == nil else {
            return
        }
        lastInstant = clock.now
        driveTask = Task { [weak self] in
            // 見た目の行動の並びに再現性は要らないため、OS の乱数を使う
            var random = SystemRandomNumberGenerator()
            while !Task.isCancelled {
                guard let waitSeconds = self?.walk.secondsUntilNextUpdate(walkingTickSeconds: Self.walkingTickSeconds) else {
                    return
                }
                try? await Task.sleep(for: .seconds(waitSeconds))
                guard !Task.isCancelled, let self, let lastInstant else {
                    return
                }
                // Task.sleep の遅れや Mac のスリープからの復帰で状態がずれないよう、待った秒数ではなく実際に経った秒数で進める
                let now = clock.now
                advance(elapsedSeconds: (now - lastInstant) / .seconds(1), random: &random)
                self.lastInstant = now
            }
        }
    }

    /// 状態を進めるのを止める。止まっている間はタイマーが動かず、猫はその場に留まる。
    /// 歩く以外の行動は切り替わるまで 1 回だけ待つため、止めるまでに経った時間を行動の残り時間から引き、出し直した時に同じ行動を最初から待ち直さないようにする。
    /// 止まっている時に呼んでも何もしないため冪等。
    func stop() {
        guard let driveTask, let lastInstant else {
            return
        }
        driveTask.cancel()
        self.driveTask = nil
        self.lastInstant = nil
        let elapsedSeconds = (clock.now - lastInstant) / .seconds(1)
        walk.activityElapsed += elapsedSeconds
        walk.activityRemaining -= elapsedSeconds
    }

    /// `elapsedSeconds` 秒ぶん状態を進める。歩いていた間の移動だけを linear に補間して見せる。
    /// `random` を進めるため冪等ではない。
    private func advance(elapsedSeconds: Double, random: inout SystemRandomNumberGenerator) {
        let next = walk.advanced(elapsedSeconds: elapsedSeconds, width: travelWidth, walkingSpeed: CatWalkState.defaultWalkingSpeed, random: &random)
        // Mac のスリープからの復帰などで大きく遅れた時に、遅れた時間をかけて動かさないよう、1 刻みの遅れの範囲だけ補間する。
        // 2 刻みは Task.sleep の揺らぎを吸収できる余裕として選んだ
        guard walk.activity == .walking, elapsedSeconds <= Self.walkingTickSeconds * 2 else {
            walk = next
            return
        }
        withAnimation(.linear(duration: elapsedSeconds)) {
            walk = next
        }
    }
}
