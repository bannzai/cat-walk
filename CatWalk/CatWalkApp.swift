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
        Settings {
            CatWalkSettingsView(overlay: appDelegate.overlay)
        }
    }
}

/// メニューバーのメニューの中身。猫の表示状態を読むため、変化を追跡できる View に分けている。
struct CatWalkMenu: View {
    /// 表示 / 非表示を切り替えるオーバーレイ。
    let overlay: OverlayWindowController
    /// 設定ウィンドウを開く操作。
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Text("Cat Walk")
        Divider()
        Button(overlay.isCatVisible ? "猫を隠す" : "猫を出す") {
            overlay.setCatVisible(isVisible: !overlay.isCatVisible)
        }
        Button("設定…") {
            // Dock に出ないアプリは前面のアプリにならないため、そのまま開くと設定ウィンドウが他のアプリの裏に開く
            NSApplication.shared.activate()
            openSettings()
        }
        .keyboardShortcut(",")
        Divider()
        Button("終了") {
            NSApplication.shared.terminate(nil)
        }
    }
}

/// オーバーレイの表示はウィンドウを持たない `MenuBarExtra` からは起動できないため、アプリの起動通知で出す。
final class AppDelegate: NSObject, NSApplicationDelegate {
    /// 全ディスプレイの猫のオーバーレイ。アプリの設定と猫の状態は標準の保存先に置く。
    let overlay = OverlayWindowController(defaults: .standard)

    func applicationDidFinishLaunching(_ notification: Notification) {
        overlay.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        overlay.saveStates()
    }
}
