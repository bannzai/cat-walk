import CatWalkCore
import SwiftUI

/// 猫のプレースホルダーが左右に歩いたり止まったりする view。
struct CatWalkView: View {
    /// 猫の大きさ。小さい画面でも往復の動きが確認できる、iOS の半分ほどの仮の値で、デザインの段階で決め直す。
    private static let catSize: Double = 28
    /// 歩く速さ (pt/秒)。猫の大きさに合わせて iOS の半分にした仮の値で、デザインの段階で決め直す。
    private static let walkingSpeed: Double = 12
    /// 状態を進める間隔 (秒)。動きの確認に十分な仮の間隔で、.animation の duration と揃えて途切れなく見せる。デザインの段階で決め直す。
    private static let tickSeconds: Double = 1

    @State private var walk = CatWalkState()

    var body: some View {
        GeometryReader { proxy in
            let travel = max(proxy.size.width - Self.catSize, 0)
            Image(systemName: "cat.fill")
                .font(.system(size: Self.catSize))
                .scaleEffect(x: walk.direction == .right ? 1 : -1, y: 1)
                .position(x: walk.x + Self.catSize / 2, y: proxy.size.height / 2)
                .animation(.linear(duration: Self.tickSeconds), value: walk.x)
                .task {
                    // 見た目の行動の並びに再現性は要らないため、OS の乱数を使う
                    var random = SystemRandomNumberGenerator()
                    while !Task.isCancelled {
                        try? await Task.sleep(for: .seconds(Self.tickSeconds))
                        walk = walk.advanced(elapsedSeconds: Self.tickSeconds, width: travel, walkingSpeed: Self.walkingSpeed, random: &random)
                    }
                }
        }
    }
}
