/// 設定で選べる猫の歩く速さ。保存した設定を後の版でも読めるよう、raw value を保存形式として固定する。
public enum CatWalkingSpeed: String, CaseIterable, Codable, Sendable {
    /// のんびり。
    case slow
    /// ふつう。
    case normal
    /// はやい。
    case fast

    /// 歩く速さ (pt/秒)。ふつうは `CatWalkState.defaultWalkingSpeed` を引き継ぎ、のんびりとはやいは見比べて違いが分かるよう半分と倍にした。デザインの段階で決め直す
    public var pointsPerSecond: Double {
        switch self {
        case .slow:
            CatWalkState.defaultWalkingSpeed / 2
        case .normal:
            CatWalkState.defaultWalkingSpeed
        case .fast:
            CatWalkState.defaultWalkingSpeed * 2
        }
    }
}
