/// 猫がその時にしている行動。保存した状態を後の版でも読めるよう、raw value を保存形式として固定する。
public enum CatActivity: String, CaseIterable, Codable, Sendable {
    /// 歩く。この行動の間だけ横位置が変わる。
    case walking
    /// 立ち止まる。
    case standing
    /// 座る。
    case sitting
    /// 眠る。
    case sleeping
    /// 毛づくろいする。
    case grooming

    /// この行動を続ける秒数の範囲。下限は 0 より大きく、`CatWalkState.advanced` が経過時間を区切る処理を必ず前に進める。
    public var durationRange: Range<Double> {
        switch self {
        // 競合の低評価の最大の原因が「動かない・単調」なため、歩く時間は数歩で終わらず画面を横切り始める長さにする。デザインの段階で決め直す
        case .walking:
            5..<15
        // 歩きの合間の小休止として、止まったと気づける程度の短さにする。デザインの段階で決め直す
        case .standing:
            2..<6
        // 眠りの前後の落ち着いた姿勢として、立ち止まるより長く見せる。デザインの段階で決め直す
        case .sitting:
            5..<20
        // 眠りは猫らしさの中心なので最も長くする。一方で作業中に「動かない」と感じさせないよう 2 分以内に起こす。デザインの段階で決め直す
        case .sleeping:
            30..<120
        // 毛づくろいは短い仕草として、立ち止まると同程度にする。デザインの段階で決め直す
        case .grooming:
            3..<8
        }
    }

    /// この行動の次に選べる行動。自分自身を含まないため、切り替わると必ず別の行動になる。
    public var nextCandidates: [CatActivity] {
        switch self {
        case .walking:
            [.standing, .sitting, .grooming]
        case .standing:
            [.walking, .sitting, .grooming]
        // 歩いている猫がいきなり眠らないよう、眠りには座った後にだけ入る
        case .sitting:
            [.standing, .sleeping, .grooming, .walking]
        case .sleeping:
            [.sitting, .standing]
        case .grooming:
            [.sitting, .walking, .standing]
        }
    }

    /// `unitRandom` (`0..<1`) に対応する次の行動を返す。0 なら `nextCandidates` の先頭になる。
    public func nextActivity(unitRandom: Double) -> CatActivity {
        nextCandidates[min(Int(unitRandom * Double(nextCandidates.count)), nextCandidates.count - 1)]
    }

    /// `unitRandom` (`0..<1`) に対応する、この行動を続ける秒数を返す。0 なら `durationRange` の下限になる。
    public func duration(unitRandom: Double) -> Double {
        durationRange.lowerBound + unitRandom * (durationRange.upperBound - durationRange.lowerBound)
    }
}
