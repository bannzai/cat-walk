import CatWalkCore
import SwiftUI

/// watchOS アプリの入口。猫が歩く `CatWalkView` を 1 つのウィンドウに出し、右上のボタンから設定画面 (猫の色・柄、利用規約・プライバシーポリシー・お問い合わせの案内) を開く。
@main
struct CatWalkWatchApp: App {
    /// 設定で選んだ猫の色・柄。コンプリケーションも読むため、App Group の保存先から読み、変えたらそこへ書く。
    @State private var coat = UserDefaults.catWalkShared.catWalkCoat

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                CatWalkView(coat: coat)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            NavigationLink {
                                Form {
                                    CatCoatPicker(coat: $coat)
                                    CatWalkAboutSection()
                                }
                                .navigationTitle("設定")
                            } label: {
                                Label("設定", systemImage: "gearshape")
                            }
                            .accessibilityIdentifier("settings-button")
                        }
                    }
            }
            .onChange(of: coat) { _, newCoat in
                saveSharedCatCoat(coat: newCoat)
            }
        }
    }
}
