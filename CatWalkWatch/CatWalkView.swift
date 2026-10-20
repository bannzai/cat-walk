import CatWalkCore
import SwiftUI

/// 猫のプレースホルダーが左右に往復する view。
struct CatWalkView: View {
    private static let catSize: Double = 28

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
                        try? await Task.sleep(for: .seconds(1))
                        walk = walk.step(in: travel)
                    }
                }
        }
    }
}
