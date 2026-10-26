import CoreGraphics

/// 画面下端を歩く猫の矩形を、画面座標 (左下原点) で返す。`panelFrame` は猫を描くパネルの画面上の矩形、`walkX` は猫の左端のパネル内の x。
/// `CatOverlayView` は猫の中心をパネルの下端から `catSize` 上に置くため、縦は下端から `catSize / 2` 〜 `catSize * 3 / 2` になる。
func walkingCatScreenRect(panelFrame: CGRect, walkX: Double, catSize: Double) -> CGRect {
    CGRect(
        x: panelFrame.minX + walkX,
        y: panelFrame.minY + catSize / 2,
        width: catSize,
        height: catSize
    )
}

/// `previousWalkX` から `walkX` へ `durationSeconds` 秒かける linear のアニメーションで、始めてから `elapsedSeconds` 秒の時に描かれている x を返す。
/// アニメーションを終えた後と長さが 0 の時は `walkX` を返す。
func interpolatedWalkX(previousWalkX: Double, walkX: Double, elapsedSeconds: Double, durationSeconds: Double) -> Double {
    guard durationSeconds > 0 else {
        return walkX
    }
    return previousWalkX + (walkX - previousWalkX) * min(max(elapsedSeconds / durationSeconds, 0), 1)
}

/// 持ち上げた猫の中心を、パネルの左上を原点とする座標で返す。`locationInWindow` はカーソルのウィンドウ座標 (左下原点)、`panelSize` はパネルの大きさ。
/// 猫がパネルの外に出て見えなくならないよう、猫の全体がパネルに収まる範囲に留める。
func liftedCatCenter(locationInWindow: CGPoint, panelSize: CGSize, catSize: Double) -> CGPoint {
    CGPoint(
        x: min(max(locationInWindow.x, catSize / 2), max(panelSize.width - catSize / 2, catSize / 2)),
        y: min(max(panelSize.height - locationInWindow.y, catSize / 2), max(panelSize.height - catSize / 2, catSize / 2))
    )
}
