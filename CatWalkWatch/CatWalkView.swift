import CatWalkCore
import SwiftUI

/// 猫が左右に歩いたり止まったりする view。Always On で画面が暗くなっている間は状態を進めず、今の姿勢のまま止める。
struct CatWalkView: View {
    /// 猫の大きさ。小さい画面でも往復の動きが確認できる、iOS の半分ほどの仮の値で、デザインの段階で決め直す。
    private static let catSize: Double = 28
    /// 歩く速さ (pt/秒)。猫の大きさに合わせて iOS の半分にした仮の値で、デザインの段階で決め直す。
    private static let walkingSpeed: Double = 12
    /// 状態を進める間隔 (秒)。動きの確認に十分な仮の間隔で、.animation の duration と揃えて途切れなく見せる。デザインの段階で決め直す。
    private static let tickSeconds: Double = 1

    @Environment(\.isLuminanceReduced) private var isLuminanceReduced
    @State private var walk = CatWalkState()

    var body: some View {
        GeometryReader { proxy in
            let travel = max(proxy.size.width - Self.catSize, 0)
            CatPostureView(walk: walk, size: Self.catSize)
                .position(x: walk.x + Self.catSize / 2, y: proxy.size.height / 2)
                .animation(.linear(duration: Self.tickSeconds), value: walk.x)
                .task(id: isLuminanceReduced) {
                    // Always On では画面の更新が 1 分に 1 回ほどに間引かれ、毎秒の動きが飛び飛びに見えるため止める
                    // 出典: https://developer.apple.com/documentation/watchos-apps/designing-your-app-for-the-always-on-state
                    guard !isLuminanceReduced else {
                        return
                    }
                    // 見た目の行動の並びに再現性は要らないため、OS の乱数を使う
                    var random = SystemRandomNumberGenerator()
                    while !Task.isCancelled {
                        // Always On に入って取り消された時に 1 歩進めてから止まらないよう、状態を進めずに抜ける
                        do {
                            try await Task.sleep(for: .seconds(Self.tickSeconds))
                        } catch {
                            return
                        }
                        walk = walk.advanced(elapsedSeconds: Self.tickSeconds, width: travel, walkingSpeed: Self.walkingSpeed, random: &random)
                    }
                }
        }
    }
}
