import CatWalkCore
import ClockHandRotationKit
import SwiftUI
import WidgetKit

/// ウィジェットの中で猫をコマ送りで動かす試作のうち、時計の針の回転を使う方法。Apple 純正の時計ウィジェットが針を回すのに使う非公開の修飾子 `_clockHandRotationEffect` は、
/// Xcode 27.1 の SDK の swiftinterface に宣言が無く直接は呼べないため、宣言が見えていた頃の SDK でビルド済みの ClockHandRotationKit (https://github.com/octree/ClockHandRotationKit) 経由で呼ぶ。
/// 全コマを重ね、各コマを細い帯の切り抜きで覆い、その切り抜きをシステムに回させて、帯が枠を横切る間だけ 1 コマずつ見せる。切り抜きの組み方は https://github.com/b5nt/Widgetnimation に倣う。
/// 非公開 API のため App Store の審査で落ちる可能性があり、採用するかは試作の結果を見て決める (issue #39)。
struct CatWalkClockHandWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "CatWalkClockHandWidget", provider: CatWalkClockHandProvider()) { entry in
            CatWalkClockHandView(coat: entry.coat)
                .containerBackground(for: .widget) {
                    Rectangle()
                        .fill(.fill.tertiary)
                }
        }
        .configurationDisplayName("Cat Walk (時計の針)")
        .description("時計の針の回転で猫がコマ送りで動きます")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

/// 時計の針の回転が効いているかだけを、コマの切り替えと切り離して確かめるウィジェット。猫の絵 1 枚をそのまま回す。
/// 「Cat Walk (時計の針)」が動かない時に、回転そのものが効いていないのか、コマの切り替え方の問題かを見分けるために置く。
struct CatWalkClockHandRotationCheckWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "CatWalkClockHandRotationCheckWidget", provider: CatWalkClockHandProvider()) { entry in
            Image("cat-\(entry.coat.rawValue)-stand")
                .resizable()
                .scaledToFit()
                .padding()
                // 1 周を目で追える長さにする。秒針と同じ 60 秒では、連続スクリーンショットで回ったかを見分けにくい
                .clockHandRotationEffect(period: .custom(4))
                .containerBackground(for: .widget) {
                    Rectangle()
                        .fill(.fill.tertiary)
                }
        }
        .configurationDisplayName("Cat Walk (回転の確認)")
        .description("猫の絵 1 枚を回して時計の針の回転が効くかを確かめます")
        .supportedFamilies([.systemSmall])
    }
}

/// 描く猫の柄だけを持つエントリ。WidgetKit がメインスレッド以外から扱うため nonisolated にする。
nonisolated private struct CatWalkClockHandEntry: TimelineEntry {
    /// エントリの時刻。回転はシステムが進めるため、描き直しの時刻としてだけ使う。
    let date: Date
    /// 設定で選んだ猫の色・柄。
    let coat: CatCoat
}

/// 回転はシステムのアニメーションで描き直しが要らないため、エントリは 1 つだけ返し、タイムラインを読み直させない。
/// 柄を変えた時はアプリが `WidgetCenter` で描き直させる。WidgetKit がメインスレッド以外から呼ぶため nonisolated にする。
nonisolated private struct CatWalkClockHandProvider: TimelineProvider {
    func placeholder(in context: Context) -> CatWalkClockHandEntry {
        CatWalkClockHandEntry(date: .now, coat: UserDefaults.catWalkShared.catWalkCoat)
    }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (CatWalkClockHandEntry) -> Void) {
        completion(CatWalkClockHandEntry(date: .now, coat: UserDefaults.catWalkShared.catWalkCoat))
    }

    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<CatWalkClockHandEntry>) -> Void) {
        completion(Timeline(entries: [CatWalkClockHandEntry(date: .now, coat: UserDefaults.catWalkShared.catWalkCoat)], policy: .never))
    }
}

/// 猫のコマを順に 1 枚ずつ見せる view。
private struct CatWalkClockHandView: View {
    /// コマに使う猫の絵の姿勢。歩く 2 コマを 2 往復した後、立ち止まって座り、毛づくろいする。
    private static let poses = ["walk1", "walk2", "walk1", "walk2", "stand", "sit", "sit", "groom"]
    /// 1 コマを見せる長さ (秒)。フォント版の 1 秒 1 コマはタイマーの更新間隔の制約で、この方法には無いため、歩く足の入れ替わりが自然に見える半分の長さにする。
    private static let frameSeconds = 0.5

    /// 設定で選んだ猫の色・柄。
    let coat: CatCoat

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            // 半径を枠の 50 倍にして、枠の中を通る円弧をほぼ直線の帯として扱う (Widgetnimation と同じ値)
            let arcRadius = size * 50
            let angle = 360 / Double(Self.poses.count)
            ZStack {
                ForEach(Self.poses.indices, id: \.self) { index in
                    Image("cat-\(coat.rawValue)-\(Self.poses[index])")
                        .resizable()
                        .scaledToFit()
                        .frame(width: size, height: size)
                        .mask(
                            CatWalkClockHandArc(startAngle: -angle * Double(index + 1), endAngle: -angle * Double(index), radius: arcRadius)
                                // 帯の太さを枠より太くし、帯が枠の上にある間はコマ全体が見えるようにする (Widgetnimation と同じ値)
                                .stroke(style: StrokeStyle(lineWidth: size * 1.5, lineCap: .butt))
                                .frame(width: size, height: size)
                                .clockHandRotationEffect(period: .custom(Self.frameSeconds * Double(Self.poses.count)))
                                .offset(y: arcRadius)
                        )
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .accessibilityLabel("歩く猫")
    }
}

/// 枠の中心を中心にした、`startAngle` から `endAngle` (度) までの半径 `radius` の円弧。回転させた時に枠の上へ来た 1 区間のコマだけを見せる切り抜きに使う。
/// `Shape` の `path(in:)` は SwiftUI がメインスレッド以外から呼ぶため nonisolated にする。
nonisolated private struct CatWalkClockHandArc: Shape {
    /// 円弧の始まりの角度 (度)。
    let startAngle: Double
    /// 円弧の終わりの角度 (度)。
    let endAngle: Double
    /// 円弧の半径 (pt)。
    let radius: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(center: CGPoint(x: rect.midX, y: rect.midY), radius: radius, startAngle: .degrees(startAngle), endAngle: .degrees(endAngle), clockwise: false)
        return path
    }
}
