import AppKit
import Observation
import SwiftUI

/// 1 枚のディスプレイの使える領域を覆う透明・クリック透過のパネル。猫の下にあるアプリの操作を妨げないことが要件。
final class OverlayPanel: NSPanel {
    /// このパネルで歩く猫の状態と駆動。ディスプレイ構成が変わってもパネルを使い回し、猫の位置と行動を保つ。
    let catWalkModel = CatWalkModel()

    init(screen: NSScreen) {
        super.init(
            contentRect: screen.visibleFrame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        level = .floating
        ignoresMouseEvents = true
        // NSPanel は既定で非アクティブ化時に隠れるが、他のアプリの操作中も猫を表示し続ける必要があるため
        hidesOnDeactivate = false
        // 全 Space に出し、他アプリのフルスクリーンの Space にも重ね、Mission Control で他のウィンドウと一緒に動かさないため
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isReleasedWhenClosed = false
        contentView = NSHostingView(rootView: CatOverlayView(model: catWalkModel))
        fit(screen: screen)
    }

    /// `screen` の使える領域に合わせ、猫が歩ける幅を更新する。何度呼んでも結果は同じ (冪等)。
    func fit(screen: NSScreen) {
        // Dock やメニューバーに猫が隠れないよう、使える領域に合わせる
        setFrame(screen.visibleFrame, display: false)
        catWalkModel.travelWidth = max(screen.visibleFrame.width - CatOverlayView.catSize, 0)
    }
}

/// 全ディスプレイの上に置く `OverlayPanel` を保持し、ディスプレイ構成の変化と猫の表示 / 非表示に追従させる。
@Observable
final class OverlayWindowController {
    /// 猫のオーバーレイを出しているか。メニューバーのメニューから切り替える。保存は別 issue のため、起動のたびに出した状態から始める。
    private(set) var isCatVisible = true
    /// ディスプレイ ID ごとのパネル。
    @ObservationIgnored private var panels: [CGDirectDisplayID: OverlayPanel] = [:]
    /// ディスプレイ構成の変更通知の購読。
    @ObservationIgnored private var screenObserver: NSObjectProtocol?

    /// 猫を出すか (`isVisible` が true) 隠すかを決め、全ディスプレイのパネルに反映する。隠している間はパネルを画面から外し、
    /// 猫の状態を進めるタイマーも止める。ディスプレイ構成の変更通知の購読は初回だけ登録するため、同じ値で何度呼んでも結果は同じ (冪等)。
    func setCatVisible(isVisible: Bool) {
        isCatVisible = isVisible
        if screenObserver == nil {
            // ディスプレイの抜き差し・解像度・Dock の大きさの変更で visibleFrame が変わるため
            screenObserver = NotificationCenter.default.addObserver(
                forName: NSApplication.didChangeScreenParametersNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.syncPanels()
                }
            }
        }
        syncPanels()
    }

    /// 今のディスプレイ構成と `isCatVisible` にパネルを合わせる。外れたディスプレイのパネルは閉じ、増えたディスプレイにだけ新しく作る。
    /// 何度呼んでも結果は同じ (冪等)。
    private func syncPanels() {
        let screens = Dictionary(
            NSScreen.screens.compactMap { screen in
                (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber).map { (CGDirectDisplayID($0.uint32Value), screen) }
            },
            uniquingKeysWith: { first, _ in first }
        )
        for (displayID, panel) in panels where screens[displayID] == nil {
            panel.catWalkModel.stop()
            panel.close()
            panels[displayID] = nil
        }
        for (displayID, screen) in screens {
            let panel = panels[displayID] ?? OverlayPanel(screen: screen)
            panels[displayID] = panel
            panel.fit(screen: screen)
            if isCatVisible {
                panel.orderFrontRegardless()
                panel.catWalkModel.start()
            } else {
                panel.catWalkModel.stop()
                panel.orderOut(nil)
            }
        }
    }
}
