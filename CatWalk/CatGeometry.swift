import CoreGraphics

/// 画面下端を歩く猫が描かれ得る矩形を、画面座標 (左下原点) で返す。`panelFrame` は猫を描くパネルの画面上の矩形。
/// `CatOverlayView` は猫の中心をパネルの下端から `catSize` 上に置くため、縦は下端から `catSize / 2` 〜 `catSize * 3 / 2` になる。
/// 歩く間は linear のアニメーションが `previousWalkX` から `walkX` へ猫を動かすため、横は両方の位置の猫を含める。
func walkingCatScreenRect(panelFrame: CGRect, walkX: Double, previousWalkX: Double, catSize: Double) -> CGRect {
    CGRect(
        x: panelFrame.minX + min(walkX, previousWalkX),
        y: panelFrame.minY + catSize / 2,
        width: abs(walkX - previousWalkX) + catSize,
        height: catSize
    )
}

/// 持ち上げた猫の中心を、パネルの左上を原点とする座標で返す。`locationInWindow` はカーソルのウィンドウ座標 (左下原点)、`panelSize` はパネルの大きさ。
/// 猫がパネルの外に出て見えなくならないよう、猫の全体がパネルに収まる範囲に留める。
func liftedCatCenter(locationInWindow: CGPoint, panelSize: CGSize, catSize: Double) -> CGPoint {
    CGPoint(
        x: min(max(locationInWindow.x, catSize / 2), max(panelSize.width - catSize / 2, catSize / 2)),
        y: min(max(panelSize.height - locationInWindow.y, catSize / 2), max(panelSize.height - catSize / 2, catSize / 2))
    )
}
