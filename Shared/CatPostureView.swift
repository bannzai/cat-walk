import CatWalkCore
import SwiftUI

/// 猫のプレースホルダーを行動に合わせた姿勢で描く view。iOS・watchOS のアプリとウィジェットで同じ猫に見せるため共有する。
/// 姿勢の見た目は SF Symbols を組み合わせた仮のもので、デザインの段階で決め直す。
struct CatPostureView: View {
    /// 姿勢を決める行動。
    let activity: CatActivity
    /// 猫が向いている方向。
    let direction: CatWalkState.Direction
    /// 猫の大きさ (pt)。
    let size: Double

    var body: some View {
        Image(systemName: "cat.fill")
            .font(.system(size: size))
            .scaleEffect(x: direction == .right ? 1 : -1, y: activity == .sitting ? 0.8 : 1, anchor: .bottom)
            .overlay(alignment: .topTrailing) {
                if let badgeSymbolName = activity.badgeSymbolName {
                    Image(systemName: badgeSymbolName)
                        .font(.system(size: size / 2))
                        .offset(x: size / 4, y: -size / 4)
                }
            }
    }
}

extension CatActivity {
    /// 姿勢だけでは見分けにくい行動に添える SF Symbols の名前。添えない行動は nil。
    var badgeSymbolName: String? {
        switch self {
        case .walking:
            "pawprint.fill"
        case .standing, .sitting:
            nil
        case .sleeping:
            "zzz"
        case .grooming:
            "sparkles"
        case .delighted:
            "heart.fill"
        }
    }

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
