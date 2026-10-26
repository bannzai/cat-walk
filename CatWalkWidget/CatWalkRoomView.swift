import CatWalkCore
import SwiftUI
import WidgetKit

/// iOS 27 のホーム画面 1 ページ分の特大ウィジェット (`systemExtraLargePortrait`) に出す猫の部屋の前景。部屋の床の上に猫を置き、今の行動の一言を添える。
/// 壁・窓・床は `CatWalkRoomBackground` を container background に置き、tinted / clear のモードでは OS が背景を外すため、前景には猫と一言と床の線だけを置く。
struct CatWalkRoomView: View {
    /// 猫の大きさ (pt)。ページ全体の部屋で小さく見えないよう他のサイズ (44pt) より大きくした仮の値で、デザインの段階で決め直す。
    private static let catSize: Double = 72

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.widgetContentMargins) private var widgetContentMargins
    @Environment(\.widgetRenderingMode) private var widgetRenderingMode

    /// 表示するエントリ。
    let entry: CatWalkWidgetEntry

    var body: some View {
        GeometryReader { proxy in
            // 背景は余白を含むウィジェット全体に、前景は余白の内側に描かれるため、背景の床の線の高さを前景の座標に直す
            let floorY = (proxy.size.height + widgetContentMargins.top + widgetContentMargins.bottom) * (1 - CatWalkRoomBackground.floorHeightRatio) - widgetContentMargins.top
            ZStack(alignment: .topLeading) {
                Text(entry.walk.activity.caption)
                    .font(.title2.bold())
                // 背景が外れるモードでも猫が床に立っていると分かるよう、猫の足元に線だけを前景に引く
                if widgetRenderingMode != .fullColor {
                    Rectangle()
                        .frame(height: 1)
                        .opacity(0.4)
                        .offset(y: floorY + Self.catSize)
                }
                CatPostureView(walk: entry.walk, coat: entry.coat, size: Self.catSize)
                    // 猫のラベルは上の一言と同じ文のため、VoiceOver で 2 回読まれないよう隠す
                    .accessibilityHidden(true)
                    .widgetAccentable()
                    .position(x: max(proxy.size.width - Self.catSize, 0) * entry.walk.x + Self.catSize / 2, y: floorY + Self.catSize / 2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            // 部屋の背景は配色に関わらず明るい色のため、通常カラーでは前景を light の配色で描き、ダークモードで猫と一言が白くなって読めなくなるのを防ぐ。tinted / clear では OS の配色に任せる
            .environment(\.colorScheme, widgetRenderingMode == .fullColor ? .light : colorScheme)
        }
    }
}

/// 猫の部屋の背景 (壁・窓・床・ラグ・棚)。絵の作り込みは見た目の段階 (#12) の後に回すため、SwiftUI の図形で描いた仮のもの。
struct CatWalkRoomBackground: View {
    /// ウィジェットの高さのうち床が占める割合。前景の猫を床の上に置くために `CatWalkRoomView` も使う。猫が歩く帯に十分な高さを残す仮の値で、デザインの段階で決め直す。
    static let floorHeightRatio: Double = 0.3

    var body: some View {
        GeometryReader { proxy in
            let floorTop = proxy.size.height * (1 - Self.floorHeightRatio)
            ZStack(alignment: .topLeading) {
                Color(red: 0.96, green: 0.91, blue: 0.84)
                // 窓
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.72, green: 0.86, blue: 0.96))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.white, lineWidth: 8)
                        Rectangle()
                            .fill(.white)
                            .frame(width: 6)
                        Rectangle()
                            .fill(.white)
                            .frame(height: 6)
                    }
                    .frame(width: proxy.size.width * 0.55, height: proxy.size.height * 0.28)
                    .position(x: proxy.size.width / 2, y: proxy.size.height * 0.3)
                // 棚
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color(red: 0.62, green: 0.45, blue: 0.3))
                        .frame(height: 8)
                    Rectangle()
                        .fill(Color(red: 0.7, green: 0.53, blue: 0.37))
                }
                .frame(width: proxy.size.width * 0.22, height: proxy.size.height * 0.16)
                .position(x: proxy.size.width * 0.16, y: floorTop - proxy.size.height * 0.08)
                // 床と幅木
                Rectangle()
                    .fill(Color(red: 0.78, green: 0.6, blue: 0.42))
                    .frame(height: proxy.size.height * Self.floorHeightRatio)
                    .offset(y: floorTop)
                Rectangle()
                    .fill(Color(red: 0.62, green: 0.45, blue: 0.3))
                    .frame(height: 6)
                    .offset(y: floorTop)
                // ラグ
                Ellipse()
                    .fill(Color(red: 0.86, green: 0.5, blue: 0.45))
                    .frame(width: proxy.size.width * 0.6, height: proxy.size.height * Self.floorHeightRatio * 0.4)
                    .position(x: proxy.size.width / 2, y: floorTop + proxy.size.height * Self.floorHeightRatio * 0.6)
            }
        }
    }
}
