import CatWalkCore
import SwiftUI
import WidgetKit

/// 猫を行動に合わせた姿勢の絵で描く view。3 OS のアプリとウィジェットで同じ猫に見せるため共有する。
/// 絵は `Shared/Assets.xcassets` の `cat-<姿勢>` で、`tools/cat-art/build.mjs` が書き出す。
struct CatPostureView: View {
    /// 歩く 2 コマを切り替える間隔 (秒)。どの OS も歩く間は 1 秒ごとに状態を進めるため、状態が進むたびに足が入れ替わって見える長さにする。
    static let walkingStepSeconds: Double = 1

    /// ロック画面・コンプリケーション・色合いを変えたホーム画面では、色の絵が OS に塗り潰されて目鼻が消えるため、単色の絵に切り替える。
    @Environment(\.widgetRenderingMode) private var widgetRenderingMode

    /// 描く猫の状態。行動・向き・歩く 2 コマのどちらかを決める。
    let walk: CatWalkState
    /// 猫の大きさ (pt)。絵の正方形の一辺。
    let size: Double
    /// 持ち上げられているか。持ち上げは macOS のドラッグ中だけで、ほかの OS は常に false。
    var isLifted = false

    var body: some View {
        Image(walk.artworkName(isLifted: isLifted, isMonochrome: widgetRenderingMode != .fullColor))
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .scaleEffect(x: walk.direction == .right ? 1 : -1, y: 1)
    }
}

extension CatWalkState {
    /// 今の姿勢の絵の Asset Catalog の名前。`isMonochrome` なら白 1 色の絵 (`-mono`) にする。
    /// 持ち上げは時間で進む行動ではなく `CatWalkState` に入らないため、引数で受けて行動より優先する。
    func artworkName(isLifted: Bool, isMonochrome: Bool) -> String {
        let pose = if isLifted {
            "lifted"
        } else {
            switch activity {
            case .walking:
                walkingStep(stepSeconds: CatPostureView.walkingStepSeconds) == 0 ? "walk1" : "walk2"
            case .standing:
                "stand"
            case .sitting:
                "sit"
            case .sleeping:
                "sleep"
            case .grooming:
                "groom"
            case .delighted:
                "delighted"
            }
        }
        return "cat-\(pose)\(isMonochrome ? "-mono" : "")"
    }
}

extension CatActivity {
    /// 今の行動を表す一言。ウィジェットで姿勢に添える。
    var caption: LocalizedStringKey {
        switch self {
        case .walking:
            "おさんぽ中"
        case .standing:
            "ひとやすみ"
        case .sitting:
            "おすわり"
        case .sleeping:
            "おやすみ中"
        case .grooming:
            "毛づくろい"
        case .delighted:
            "うれしい"
        }
    }
}
