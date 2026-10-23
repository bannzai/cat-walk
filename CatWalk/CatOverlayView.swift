import CatWalkCore
import SwiftUI

/// 猫のプレースホルダーが画面下端を歩き、行動ごとに姿勢を変える view。持ち上げられている間はカーソルの位置に出す。
struct CatOverlayView: View {
    /// 描画する猫の状態。
    let model: CatWalkModel

    var body: some View {
        GeometryReader { proxy in
            pose
                .scaleEffect(x: model.walk.direction == .right ? 1 : -1, y: 1)
                .position(model.liftedCenter ?? CGPoint(x: model.walk.x + model.catSize / 2, y: proxy.size.height - model.catSize))
                // simtunnel の画面操作で猫の位置を読み、ドラッグとクリックの座標を決めるため
                .accessibilityIdentifier("overlay-cat")
        }
    }

    /// 行動ごとの姿勢。見た目の作り込みはデザインの段階 (#12) で差し替えるため、`cat.fill` の変形と記号の重ね描きで見分けられる程度にする。
    @ViewBuilder private var pose: some View {
        if model.liftedCenter != nil {
            // 首の後ろをつままれて体が縦に伸びた姿
            catImage
                .scaleEffect(x: 0.85, y: 1.2)
        } else {
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
            // macOS には撫でる操作がまだ無く入らないが、iOS・watchOS と同じ姿勢にしておく
            case .delighted:
                catImage
                    .overlay(alignment: .topTrailing) {
                        symbol(name: "heart.fill")
                    }
            }
        }
    }

    /// 猫の本体。
    private var catImage: some View {
        Image(systemName: "cat.fill")
            .font(.system(size: model.catSize))
    }

    /// 猫の頭の上に重ねる小さな記号。`name` は SF Symbols の名前。
    private func symbol(name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: model.catSize / 3))
            .offset(y: -model.catSize / 3)
    }
}
