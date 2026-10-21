import AppKit
import SwiftUI

/// メニューバーに常駐し、全ディスプレイの上に猫のオーバーレイを出すアプリ。
@main
struct CatWalkApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        MenuBarExtra("Cat Walk", systemImage: "cat.fill") {
            CatWalkMenu(overlay: appDelegate.overlay)
        }
    }
}

/// メニューバーのメニューの中身。猫の表示状態を読むため、変化を追跡できる View に分けている。
struct CatWalkMenu: View {
    /// 表示 / 非表示を切り替えるオーバーレイ。
    let overlay: OverlayWindowController

    var body: some View {
        Text("Cat Walk")
        Divider()
        Button(overlay.isCatVisible ? "猫を隠す" : "猫を出す") {
            overlay.setCatVisible(isVisible: !overlay.isCatVisible)
        }
        Divider()
        Button("終了") {
            NSApplication.shared.terminate(nil)
        }
    }
}

/// オーバーレイの表示はウィンドウを持たない `MenuBarExtra` からは起動できないため、アプリの起動通知で出す。
final class AppDelegate: NSObject, NSApplicationDelegate {
    /// 全ディスプレイの猫のオーバーレイ。
    let overlay = OverlayWindowController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        overlay.setCatVisible(isVisible: true)
    }
}
