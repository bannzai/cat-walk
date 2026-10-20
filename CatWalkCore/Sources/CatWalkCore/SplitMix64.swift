/// 固定シードで決定的な列を返す SplitMix64。定数と手順は参照実装 https://prng.di.unimi.it/splitmix64.c に合わせる。
/// ウィジェットのタイムラインを日付由来のシードで再現するために使う。
struct SplitMix64: RandomNumberGenerator {
    /// 次の値を作るための内部状態。初期値がシードになる。
    var state: UInt64

    /// 内部状態を進めて次の値を返す。
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
