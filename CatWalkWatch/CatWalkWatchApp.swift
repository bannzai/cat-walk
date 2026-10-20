import SwiftUI

/// watchOS アプリの入口。猫が歩く `CatWalkView` を 1 つのウィンドウに出す。
@main
struct CatWalkWatchApp: App {
    var body: some Scene {
        WindowGroup {
            CatWalkView()
        }
    }
}
