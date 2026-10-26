import CatWalkCore
import SwiftUI

/// 猫が画面下端を歩き、行動ごとに姿勢を変える view。持ち上げられている間はカーソルの位置に、持ち上げられた姿勢で出す。
struct CatOverlayView: View {
    /// 描画する猫の状態。
    let model: CatWalkModel

    var body: some View {
        GeometryReader { proxy in
            CatPostureView(walk: model.walk, size: model.catSize, isLifted: model.liftedCenter != nil)
                .position(model.liftedCenter ?? CGPoint(x: model.walk.x + model.catSize / 2, y: proxy.size.height - model.catSize))
                // simtunnel の画面操作で猫の位置を読み、ドラッグとクリックの座標を決めるため
                .accessibilityIdentifier("overlay-cat")
        }
    }
}
