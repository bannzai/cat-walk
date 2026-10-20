import CatWalkCore
import SwiftUI

/// 猫のプレースホルダーが左右に往復する view。
struct CatWalkView: View {
    /// 猫の大きさ。小さい画面でも往復の動きが確認できる、iOS の半分ほどの仮の値で、デザインの段階で決め直す。
    private static let catSize: Double = 28

    // 歩幅も猫の大きさに合わせた仮の値で、デザインの段階で決め直す
    @State private var walk = CatWalkState(stride: 12)

    var body: some View {
        GeometryReader { proxy in
            let travel = max(proxy.size.width - Self.catSize, 0)
            Image(systemName: "cat.fill")
                .font(.system(size: Self.catSize))
                .scaleEffect(x: walk.direction == .right ? 1 : -1, y: 1)
                .position(x: walk.x + Self.catSize / 2, y: proxy.size.height / 2)
                .animation(.linear(duration: 1), value: walk.x)
                .task {
                    while !Task.isCancelled {
                        // 動きの確認に十分な仮の間隔。.animation の duration と揃えて途切れなく見せる。デザインの段階で決め直す
                        try? await Task.sleep(for: .seconds(1))
                        walk = walk.step(width: travel)
                    }
                }
        }
    }
}
