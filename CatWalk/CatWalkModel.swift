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
    var travelWidth: Double = 0
    /// 状態を進めている Task。止まっている間は nil。
    @ObservationIgnored private var driveTask: Task<Void, Never>?

    /// 状態を時間で進め始める。歩く間は `walkingTickSeconds` ごと、ほかの行動では行動が切り替わる時だけ起きる。
    /// 既に動いていれば何もしないため冪等。
    func start() {
        guard driveTask == nil else {
            return
        }
        driveTask = Task { [weak self] in
            // 見た目の行動の並びに再現性は要らないため、OS の乱数を使う
            var random = SystemRandomNumberGenerator()
            let clock = ContinuousClock()
            var lastInstant = clock.now
            while !Task.isCancelled {
                guard let waitSeconds = self?.walk.secondsUntilNextUpdate(walkingTickSeconds: Self.walkingTickSeconds) else {
                    return
                }
                try? await Task.sleep(for: .seconds(waitSeconds))
                guard !Task.isCancelled, let self else {
                    return
                }
                // Task.sleep の遅れや Mac のスリープからの復帰で状態がずれないよう、待った秒数ではなく実際に経った秒数で進める
                let now = clock.now
                advance(elapsedSeconds: (now - lastInstant) / .seconds(1), random: &random)
                lastInstant = now
            }
        }
    }

    /// 状態を進めるのを止める。止まっている間はタイマーが動かず、猫はその場に留まる。何度呼んでも結果は同じ (冪等)。
    func stop() {
        driveTask?.cancel()
        driveTask = nil
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
