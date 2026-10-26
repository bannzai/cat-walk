import CatWalkCore
import SwiftUI

/// 設定画面の「猫の色・柄」の選択肢。3 OS の設定画面で同じ並びと名前にするため共有する。
/// 保存先は OS ごとに違う (macOS はアプリの保存先、iOS・watchOS はウィジェットと共有する App Group) ため、選んだ値の保存は呼ぶ側に任せる。
struct CatCoatPicker: View {
    /// 選んでいる柄。
    @Binding var coat: CatCoat

    var body: some View {
        Picker("猫の色・柄", selection: $coat) {
            ForEach(CatCoat.allCases, id: \.self) { option in
                Text(option.label)
                    .tag(option)
            }
        }
        .accessibilityIdentifier("settings-cat-coat")
    }
}
