import AppKit
import SwiftUI

/// メニューバーに常駐し、全ディスプレイの上に猫のオーバーレイを出すアプリ。
@main
struct CatWalkApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        MenuBarExtra("Cat Walk", systemImage: "cat.fill") {
            Text("Cat Walk")
            Divider()
            Button("終了") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}

/// オーバーレイの表示はウィンドウを持たない `MenuBarExtra` からは起動できないため、アプリの起動通知で出す。
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let overlay = OverlayWindowController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        overlay.show()
    }
}
