import SwiftUI

/// iOS アプリの入口。猫が歩く `CatWalkView` を 1 つのウィンドウに出し、アプリが前面にいない間は BGAppRefreshTask で Live Activity の猫を更新する。
@main
struct CatWalkiOSApp: App {
    var body: some Scene {
        WindowGroup {
            CatWalkView()
        }
        .backgroundTask(.appRefresh(CatWalkActivityAttributes.refreshTaskIdentifier)) {
            await refreshCatWalkActivities(date: .now)
        }
    }
}
