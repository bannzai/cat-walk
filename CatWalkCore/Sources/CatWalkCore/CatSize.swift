/// 設定で選べる猫の大きさ。保存した設定を後の版でも読めるよう、raw value を保存形式として固定する。
public enum CatSize: String, CaseIterable, Codable, Sendable {
    /// 小。
    case small
    /// 中。
    case medium
    /// 大。
    case large

    /// 猫の一辺 (pt)。中は立ち上げ時の 44pt を引き継ぎ、小は作業の邪魔をしない控えめな大きさ、大は離れて見ても姿勢が分かる大きさとして選んだ。デザインの段階で決め直す
    public var points: Double {
        switch self {
        case .small:
            32
        case .medium:
            44
        case .large:
            64
        }
    }
}
