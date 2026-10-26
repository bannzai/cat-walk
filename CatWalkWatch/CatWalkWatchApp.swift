import SwiftUI

/// watchOS アプリの入口。猫が歩く `CatWalkView` を 1 つのウィンドウに出し、右上のボタンから設定画面 (利用規約・プライバシーポリシー・お問い合わせの案内) を開く。
@main
struct CatWalkWatchApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                CatWalkView()
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            NavigationLink {
                                Form {
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
        }
    }
}
