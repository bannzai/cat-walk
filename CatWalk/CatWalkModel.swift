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
    private(set) var walk: CatWalkState
    /// 猫の一辺 (pt)。設定の大きさから決まる。
    var catSize: Double
    /// 猫の色・柄。設定から決まる。
    var coat: CatCoat
    /// 歩く速さ (pt/秒)。設定の歩く速さから決まり、次に状態を進める時から効く。
    @ObservationIgnored var walkingSpeed: Double
    /// 持ち上げられている間の猫の中心 (パネルの左上を原点とする座標)。持ち上げていない間は nil。
    /// 持ち上げは時間で進む行動ではなく離すまで続く操作のため、`CatWalkState` の行動に入れない。保存する状態にも入らないため、持ち上げたまま終了しても次の起動では画面下端の猫に戻る。
    private(set) var liftedCenter: CGPoint?
    /// 直前に状態を進める前の `walk.x`。歩く間は linear のアニメーションがここから `walk.x` へ猫を動かすため、今描かれている位置を求めるのに使う。
    @ObservationIgnored private(set) var previousWalkX: Double
    /// `previousWalkX` から `walk.x` への linear のアニメーションを始めた時刻。補間していない間は nil。
    @ObservationIgnored private var walkAnimationStart: ContinuousClock.Instant?
    /// `previousWalkX` から `walk.x` への linear のアニメーションの長さ (秒)。
    @ObservationIgnored private var walkAnimationSeconds: Double = 0
    /// 猫が歩ける横幅 (pt)。パネルの幅から猫の大きさを引いた値で、ディスプレイ構成や猫の大きさが変わるたびにパネルが更新する。
    /// 眠っている間は次に状態を進めるまで長く待つため、縮んだ時はその場で猫を範囲内へ戻し、画面外に取り残さない。
    var travelWidth: Double = 0 {
        didSet {
            walk = walk.clamped(width: travelWidth)
            previousWalkX = min(previousWalkX, travelWidth)
        }
    }
    /// 状態を進めた後に呼ぶ処理。猫がカーソルの下から歩き去った時に、パネルがクリックを受け続けないよう判定し直させるため。
    @ObservationIgnored var didAdvance: (() -> Void)?
    /// 状態を進めている Task。止まっている間は nil。
    @ObservationIgnored private var driveTask: Task<Void, Never>?
    /// 経過時間を測る時計。Task.sleep と同じくスリープ中の時間も数える。
    @ObservationIgnored private let clock = ContinuousClock()
    /// 最後に `walk` へ経過時間を反映した時刻。止める時と保存する時に、そこから経った分を行動の残り時間から引くために持つ。
    @ObservationIgnored private var lastInstant: ContinuousClock.Instant?

    /// 保存した状態と、設定の大きさ・色・柄・歩く速さから始めるため、どれも既定値を持たせず受け取る。
    init(walk: CatWalkState, catSize: Double, coat: CatCoat, walkingSpeed: Double) {
        self.walk = walk
        self.catSize = catSize
        self.coat = coat
        self.walkingSpeed = walkingSpeed
        previousWalkX = walk.x
    }

    /// 今の時刻までに経った時間を、行動の経過と残り時間に反映した状態。歩く以外の行動は切り替わるまで 1 回だけ待つため、
    /// 保存して次の起動で戻した時や出し直した時に、同じ行動を最初から待ち直さないようにする。止まっている間は `walk` と同じ。
    var currentWalk: CatWalkState {
        guard let lastInstant else {
            return walk
        }
        var next = walk
        let elapsedSeconds = (clock.now - lastInstant) / .seconds(1)
        next.activityElapsed += elapsedSeconds
        next.activityRemaining -= elapsedSeconds
        return next
    }

    /// 状態を時間で進め始める。歩く間は `walkingTickSeconds` ごと、ほかの行動では行動が切り替わる時だけ起きる。
    /// 持ち上げている間は置かれるまで進めない。既に動いていれば何もしないため冪等。
    func start() {
        guard driveTask == nil, liftedCenter == nil else {
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
                didAdvance?()
            }
        }
    }

    /// 状態を進めるのを止める。止まっている間はタイマーが動かず、猫はその場に留まる。
    /// 止めるまでに経った時間は `currentWalk` と同じく行動の残り時間から引く。止まっている時に呼んでも何もしないため冪等。
    func stop() {
        guard let driveTask, lastInstant != nil else {
            return
        }
        driveTask.cancel()
        walk = currentWalk
        self.driveTask = nil
        lastInstant = nil
    }

    /// 猫を `center` (パネルの左上を原点とする座標) に持ち上げる。持ち上げている間は状態を進めない。同じ `center` で何度呼んでも結果は同じ (冪等)。
    func lift(center: CGPoint) {
        stop()
        liftedCenter = center
    }

    /// 持ち上げていた猫を真下の画面下端へ落とし、そこから歩き出させる。持ち上げていない時は何もしないため冪等。
    func drop() {
        guard let liftedCenter else {
            return
        }
        walk = CatWalkState(x: liftedCenter.x - catSize / 2, direction: walk.direction).clamped(width: travelWidth)
        previousWalkX = walk.x
        // 離した位置から画面下端へ落ちて見せるため。0.25 秒は、離した手応えが残り、待たされたと感じない短さとして選んだ
        withAnimation(.easeIn(duration: 0.25)) {
            self.liftedCenter = nil
        }
        start()
    }

    /// `elapsedSeconds` 秒ぶん状態を進める。歩いていた間の移動だけを linear に補間して見せる。
    /// `random` を進めるため冪等ではない。
    private func advance(elapsedSeconds: Double, random: inout SystemRandomNumberGenerator) {
        let next = walk.advanced(elapsedSeconds: elapsedSeconds, width: travelWidth, walkingSpeed: walkingSpeed, random: &random)
        // Mac のスリープからの復帰などで大きく遅れた時に、遅れた時間をかけて動かさないよう、1 刻みの遅れの範囲だけ補間する。
        // 2 刻みは Task.sleep の揺らぎを吸収できる余裕として選んだ
        guard walk.activity == .walking, elapsedSeconds <= Self.walkingTickSeconds * 2 else {
            walk = next
            previousWalkX = next.x
            return
        }
        previousWalkX = walk.x
        walkAnimationStart = clock.now
        walkAnimationSeconds = elapsedSeconds
        withAnimation(.linear(duration: elapsedSeconds)) {
            walk = next
        }
    }

    /// 今画面に描かれている猫の左端の x。歩く間は linear のアニメーションの途中の位置になるため、マウスの判定を見えている猫に合わせるのに使う。
    var displayedWalkX: Double {
        guard let walkAnimationStart else {
            return walk.x
        }
        return interpolatedWalkX(
            previousWalkX: previousWalkX,
            walkX: walk.x,
            elapsedSeconds: (clock.now - walkAnimationStart) / .seconds(1),
            durationSeconds: walkAnimationSeconds
        )
    }
}
