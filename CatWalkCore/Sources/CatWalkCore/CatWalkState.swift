/// 猫の歩行状態を表す純粋な値型。描画やタイマーに依存させず、3 つのプラットフォームで同じ歩き方を共有する。
public struct CatWalkState: Equatable, Sendable {
    /// 猫が向いている方向。
    public enum Direction: Equatable, Sendable {
        /// 左向き。x が減る方向に歩く。
        case left
        /// 右向き。x が増える方向に歩く。
        case right
    }

    /// 歩行範囲の左端を 0 とした猫の横位置。
    public var x: Double
    /// 次の 1 歩で進む向き。
    public var direction: Direction
    /// 1 歩で進む距離。
    public var stride: Double

    // プレースホルダーの見た目と動きの確認に十分な仮の歩幅。デザインの段階で決め直す
    public init(x: Double = 0, direction: Direction = .right, stride: Double = 24) {
        self.x = x
        self.direction = direction
        self.stride = stride
    }

    /// 1 歩進めた状態を返す。端 (0 と `width`) に達したら端に揃えて向きを反転する。
    public func step(width: Double) -> CatWalkState {
        var next = self
        switch direction {
        case .right:
            next.x = x + stride
            if next.x >= width {
                next.x = width
                next.direction = .left
            }
        case .left:
            next.x = x - stride
            if next.x <= 0 {
                next.x = 0
                next.direction = .right
            }
        }
        return next
    }
}
