#if DEBUG
import CatWalkCore
import SwiftUI

/// 開発用に、猫のすべての姿勢の絵 (色と単色) を並べる view。行動は乱数で切り替わり、眠る姿勢は座った後にしか来ないため、
/// simtunnel のスクリーンショットで絵を確かめる時に待たずに全部を撮れるよう、macOS の設定と iOS のアプリに DEBUG ビルドだけ出す。
struct CatPoseGalleryView: View {
    /// 1 匹の大きさ (pt)。
    let size: Double

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: size + 24))], spacing: 12) {
            // 色と単色の 2 周を 1 つの ForEach にする。ForEach を入れ子にすると両方の id が 0〜7 で重なり、LazyVGrid が単色の周を描かないため
            ForEach(0..<catPoseGallerySamples.count * 2, id: \.self) { index in
                let sample = catPoseGallerySamples[index % catPoseGallerySamples.count]
                let isMonochrome = index >= catPoseGallerySamples.count
                VStack(spacing: 4) {
                    // 単色の絵はロック画面と同じく暗い背景に白で出す
                    Image(sample.walk.artworkName(isLifted: sample.isLifted, isMonochrome: isMonochrome))
                        .resizable()
                        .scaledToFit()
                        .frame(width: size, height: size)
                        // 単色の絵は template のため前景色で塗られ、既定の前景色 (ライトモードの黒) だと黒い背景に消える。色の絵は template ではないので前景色の影響を受けない
                        .foregroundStyle(.white)
                        .background(isMonochrome ? Color.black : Color.clear)
                    Text(sample.label)
                        .font(.caption2)
                }
            }
        }
        .accessibilityIdentifier("cat-pose-gallery")
    }
}

/// 一覧に並べる姿勢。歩く 2 コマは `activityElapsed` を 1 歩ずらして出し分ける。
private let catPoseGallerySamples: [(label: String, walk: CatWalkState, isLifted: Bool)] = [
    ("歩く 1", CatWalkState(activity: .walking, activityElapsed: 0), false),
    ("歩く 2", CatWalkState(activity: .walking, activityElapsed: CatPostureView.walkingStepSeconds), false),
    ("立ち止まる", CatWalkState(activity: .standing), false),
    ("座る", CatWalkState(activity: .sitting), false),
    ("眠る", CatWalkState(activity: .sleeping), false),
    ("毛づくろい", CatWalkState(activity: .grooming), false),
    ("喜ぶ", CatWalkState(activity: .delighted), false),
    ("持ち上げ", CatWalkState(), true),
]
#endif
