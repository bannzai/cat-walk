/// 猫の歩行状態を表す純粋な値型。描画やタイマーに依存させず、3 つのプラットフォームで同じ歩き方を共有する。
public struct CatWalkState: Equatable, Sendable {
    public enum Direction: Equatable, Sendable {
        case left
        case right
    }

    public var x: Double
    public var direction: Direction
    public var stride: Double

    public init(x: Double = 0, direction: Direction = .right, stride: Double = 24) {
        self.x = x
        self.direction = direction
        self.stride = stride
    }

    /// 1 歩進めた状態を返す。端 (0 と `width`) に達したら端に揃えて向きを反転する。
    public func step(in width: Double) -> CatWalkState {
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
