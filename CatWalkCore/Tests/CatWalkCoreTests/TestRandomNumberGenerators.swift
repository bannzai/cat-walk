/// 常に 0 を返す generator。`unitRandom` が 0 になり、次の行動は候補の先頭、滞在時間は下限と手で導ける。
struct ZeroRandomNumberGenerator: RandomNumberGenerator {
    /// 常に 0 を返す。
    mutating func next() -> UInt64 {
        0
    }
}
