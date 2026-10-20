import SwiftUI

/// iOS アプリの入口。猫が歩く `CatWalkView` を 1 つのウィンドウに出す。
@main
struct CatWalkiOSApp: App {
    var body: some Scene {
        WindowGroup {
            CatWalkView()
        }
    }
}
