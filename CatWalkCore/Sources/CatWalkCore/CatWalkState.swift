/// 猫の歩行状態を表す純粋な値型。描画やタイマーに依存させず、3 つのプラットフォームで同じ振る舞いを共有する。
/// 位置と行動の保存で使うため `Codable` にする。
public struct CatWalkState: Equatable, Codable, Sendable {
    /// 猫が向いている方向。保存した状態を後の版でも読めるよう、raw value を保存形式として固定する。
    public enum Direction: String, Equatable, Codable, Sendable {
        /// 左向き。x が減る方向に歩く。
        case left
        /// 右向き。x が増える方向に歩く。
        case right
    }

    /// プレースホルダーの見た目と動きの確認に十分な仮の歩く速さ (pt/秒)。立ち上げ時の 1 秒 24pt の歩幅を引き継ぐ。デザインの段階で決め直す
    public static let defaultWalkingSpeed: Double = 24

    /// 歩行範囲の左端を 0 とした猫の横位置。
    public var x: Double
    /// 歩く時に進む向き。
    public var direction: Direction
    /// 今している行動。
    public var activity: CatActivity
    /// 今の行動に入ってからの経過秒数。
    public var activityElapsed: Double
    /// 次の行動に切り替わるまでの残り秒数。
    public var activityRemaining: Double

    /// `activityRemaining` を省略した時は `activity` の滞在時間の下限から始める。
    /// 既定値は保存した状態が無い初回起動の姿を表す。
    /// - `x` と `direction`: 左端から右向きに出ると、最初の 1 歩から画面の内側へ歩き出すため
    /// - `activity`: 起動直後に動く姿を見せるため歩く行動にする
    /// - `activityElapsed`: 行動に入った瞬間から始めるため
    /// - `activityRemaining`: 滞在時間の抽選に乱数を使わずに済む下限にする
    public init(
        x: Double = 0,
        direction: Direction = .right,
        activity: CatActivity = .walking,
        activityElapsed: Double = 0,
        activityRemaining: Double? = nil
    ) {
        self.x = x
        self.direction = direction
        self.activity = activity
        self.activityElapsed = activityElapsed
        self.activityRemaining = activityRemaining ?? activity.durationRange.lowerBound
    }

    /// `elapsedSeconds` 秒進めた状態を返す。歩く間は `walkingSpeed` (pt/秒) で x を進めて端 (0 と `width`) で折り返し、
    /// 滞在時間が尽きるたびに次の行動と滞在時間を `random` から選ぶ。1 回の呼び出しで複数の行動をまたいでもよい。
    /// `random` を `inout` で受けて状態を進めるため冪等ではない。同じ状態の `random` を渡せば同じ結果になり、固定シードのテストで決定的にできる。
    public func advanced(
        elapsedSeconds: Double,
        width: Double,
        walkingSpeed: Double,
        random: inout some RandomNumberGenerator
    ) -> CatWalkState {
        var next = self
        // 画面の幅が縮んでも範囲外から歩き出さないようにする
        next.x = min(max(x, 0), max(width, 0))
        var remainingSeconds = max(elapsedSeconds, 0)
        while remainingSeconds > 0 {
            let segmentSeconds = min(remainingSeconds, max(next.activityRemaining, 0))
            if next.activity == .walking {
                next.walk(distance: walkingSpeed * segmentSeconds, width: width)
            }
            next.activityElapsed += segmentSeconds
            next.activityRemaining -= segmentSeconds
            remainingSeconds -= segmentSeconds
            if next.activityRemaining <= 0 {
                next.activity = next.activity.nextActivity(unitRandom: Self.unitRandom(random: &random))
                next.activityElapsed = 0
                next.activityRemaining = next.activity.duration(unitRandom: Self.unitRandom(random: &random))
            }
        }
        return next
    }

    /// 撫でられた直後の状態を返す。今の行動を中断して喜ぶ行動に入り、位置と向きは変えない。
    /// 滞在時間は `init` と同じく乱数を使わずに済む下限にする。
    public func petted() -> CatWalkState {
        CatWalkState(x: x, direction: direction, activity: .delighted)
    }

    /// `direction` に `distance` 進め、端に達したら端で向きを反転する。端ちょうどに着いた時も反転した向きにする。
    private mutating func walk(distance: Double, width: Double) {
        guard width > 0 else {
            x = 0
            return
        }
        // 1 往復 (2 * width) 進むと同じ位置・向きに戻るため、右向きの座標を 0..<2 * width の環として扱い、端を何度も越える距離も畳む
        let lap = 2 * width
        let position = ((direction == .right ? x : lap - x) + distance.truncatingRemainder(dividingBy: lap)).truncatingRemainder(dividingBy: lap)
        if position < width {
            x = position
            direction = .right
        } else {
            x = lap - position
            direction = .left
        }
    }

    /// `random` から `0..<1` の値を作る。整数の `random(in:using:)`・`randomElement(using:)`・閉区間の `Double.random(in:using:)` は棄却サンプリングで、
    /// 定数を返す generator を渡すと終わらないことがあるため、上位 53 bit を Double の仮数に詰める方法で 1 回の `next()` から必ず作る。
    private static func unitRandom(random: inout some RandomNumberGenerator) -> Double {
        Double(random.next() >> 11) * 0x1p-53
    }
}
