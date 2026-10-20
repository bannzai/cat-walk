import AppKit
import SwiftUI

/// 画面全体を覆う透明・クリック透過のパネル。猫の下にあるアプリの操作を妨げないことが要件。
final class OverlayPanel: NSPanel {
    init(screen: NSScreen) {
        super.init(
            contentRect: screen.visibleFrame, // Dock やメニューバーに猫が隠れないよう、使える領域に合わせる
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        level = .floating
        ignoresMouseEvents = true
        // NSPanel は既定で非アクティブ化時に隠れるが、他のアプリの操作中も猫を表示し続ける必要があるため
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isReleasedWhenClosed = false
        contentView = NSHostingView(rootView: CatOverlayView())
    }
}

/// 全ディスプレイの上に置く `OverlayPanel` を保持し、ディスプレイ構成の変化に追従させる。
final class OverlayWindowController {
    private var panels: [OverlayPanel] = []
    private var screenObserver: NSObjectProtocol?

    /// 現在の全ディスプレイへ 1 枚ずつ `OverlayPanel` を作り直して前面に出す。
    /// ディスプレイ構成の変更通知の購読は初回だけ登録するため、何度呼んでも結果は同じ (冪等)。
    func show() {
        if screenObserver == nil {
            screenObserver = NotificationCenter.default.addObserver(
                forName: NSApplication.didChangeScreenParametersNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.show()
                }
            }
        }

        for panel in panels {
            panel.close()
        }
        panels = NSScreen.screens.map { screen in
            let panel = OverlayPanel(screen: screen)
            panel.orderFrontRegardless()
            return panel
        }
    }
}
