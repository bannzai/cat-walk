import CatWalkCore
import SwiftUI

/// 猫のプレースホルダーが画面下端を歩き、行動ごとに姿勢を変える view。
struct CatOverlayView: View {
    /// 猫の大きさ。プレースホルダーの見た目の確認に十分な仮の値で、デザインの段階で決め直す。
    static let catSize: Double = 44

    /// 描画する猫の状態。
    let model: CatWalkModel

    var body: some View {
        GeometryReader { proxy in
            pose
                .scaleEffect(x: model.walk.direction == .right ? 1 : -1, y: 1)
                .position(x: model.walk.x + Self.catSize / 2, y: proxy.size.height - Self.catSize)
        }
    }

    /// 行動ごとの姿勢。見た目の作り込みはデザインの段階 (#12) で差し替えるため、`cat.fill` の変形と記号の重ね描きで見分けられる程度にする。
    @ViewBuilder private var pose: some View {
        switch model.walk.activity {
        case .walking, .standing:
            catImage
        case .sitting:
            catImage
                .scaleEffect(x: 0.8, y: 1, anchor: .bottom)
        case .sleeping:
            catImage
                .scaleEffect(x: 1, y: 0.6, anchor: .bottom)
                .overlay(alignment: .topTrailing) {
                    symbol(name: "zzz")
                }
        case .grooming:
            catImage
                .overlay(alignment: .topLeading) {
                    symbol(name: "sparkles")
                }
        }
    }

    /// 猫の本体。
    private var catImage: some View {
        Image(systemName: "cat.fill")
            .font(.system(size: Self.catSize))
    }

    /// 猫の頭の上に重ねる小さな記号。`name` は SF Symbols の名前。
    private func symbol(name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: Self.catSize / 3))
            .offset(y: -Self.catSize / 3)
    }
}
