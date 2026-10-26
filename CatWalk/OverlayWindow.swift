import AppKit
import CatWalkCore
import Observation
import SwiftUI

/// 1 枚のディスプレイの使える領域を覆う透明なパネル。猫の下にあるアプリの操作を妨げないことが要件のため、カーソルが猫の上にある間だけクリックを受ける。
final class OverlayPanel: NSPanel {
    /// このパネルで歩く猫の状態と駆動。ディスプレイ構成が変わってもパネルを使い回し、猫の位置と行動を保つ。
    let catWalkModel: CatWalkModel
    /// 猫を置いた時に呼ぶ処理。終了処理を通らずに終わっても置いた位置から再開できるよう、すぐ保存させるため。
    var didDrop: (() -> Void)?
    /// 猫の上でクリックを受けている間に判定し直す間隔 (秒)。猫は最速 48pt/秒で歩くため、0.1 秒なら猫が去った後に遮る幅を 5pt 程度に抑えられる。
    /// 動くのはカーソルが猫の上にある間だけで、常駐時の CPU には効かない
    static let hoverRecheckSeconds: Double = 0.1
    /// 猫の上でクリックを受けている間だけ判定し直し続ける Task。クリックを下のアプリに通している間は nil。
    private var hoverRecheckTask: Task<Void, Never>?

    init(screen: NSScreen, catWalkModel: CatWalkModel) {
        self.catWalkModel = catWalkModel
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
        // 猫の上でクリックを受け始めた後は、カーソルの移動が他のアプリに届かず global monitor で見えないため、パネル自身で受ける。
        // このパネルはキーウィンドウにならずアプリも前面にならないため、その状態でも移動を受けられる activeAlways にする
        contentView?.addTrackingArea(
            NSTrackingArea(rect: .zero, options: [.activeAlways, .mouseMoved, .mouseEnteredAndExited, .inVisibleRect], owner: self)
        )
        catWalkModel.didAdvance = { [weak self] in
            self?.updateIgnoresMouseEvents(mouseLocation: NSEvent.mouseLocation)
        }
        fit(screen: screen)
    }

    /// `screen` の使える領域と猫の大きさに合わせ、猫が歩ける幅を更新する。何度呼んでも結果は同じ (冪等)。
    func fit(screen: NSScreen) {
        // Dock やメニューバーに猫が隠れないよう、使える領域に合わせる
        setFrame(screen.visibleFrame, display: false)
        catWalkModel.travelWidth = max(screen.visibleFrame.width - catWalkModel.catSize, 0)
    }

    /// カーソルが猫の上にある間だけクリックを受け、それ以外は下のアプリに通す。持ち上げている間はカーソルが猫から外れても受け続け、離すまで猫を追わせる。
    /// `mouseLocation` はカーソルの画面座標 (左下原点)。判定は呼んだ時刻に描かれている猫の位置で行い、同じ時刻と位置なら何度呼んでも結果は同じ。
    /// 猫の外にある間に判定し直すのはカーソルが動いた時と状態を進めた時だけのため、止まったカーソルの下へ猫が歩いてきた間は、次に状態を進めるまで下のアプリにクリックを通す。
    /// 猫以外の場所のクリックを遮らないことを、動く猫を止まったカーソルで掴めることより優先した。
    /// 逆に猫の上でクリックを受けている間は、止まったカーソルから猫が歩き去った時に猫のいない場所のクリックを受けないよう、`hoverRecheckTask` で判定し直し続ける
    /// 隠している間・閉じた後は猫が見えないため、クリックを受けず判定し直しも止める。
    func updateIgnoresMouseEvents(mouseLocation: CGPoint) {
        // Mission Control や画面のロックで左ボタンを離したイベントがこのパネルに届かないと、持ち上げたまま画面全体のクリックを受け続けるため、ボタンの実際の状態で置く
        if catWalkModel.liftedCenter != nil, NSEvent.pressedMouseButtons & 1 == 0 {
            dropLiftedCat()
        }
        guard catWalkModel.liftedCenter == nil else {
            return
        }
        ignoresMouseEvents = !isVisible || !walkingCatScreenRect(
            panelFrame: frame,
            walkX: catWalkModel.displayedWalkX,
            catSize: catWalkModel.catSize
        ).contains(mouseLocation)
        if ignoresMouseEvents {
            hoverRecheckTask?.cancel()
            hoverRecheckTask = nil
        } else if hoverRecheckTask == nil {
            hoverRecheckTask = Task { [weak self] in
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(Self.hoverRecheckSeconds))
                    guard !Task.isCancelled, let self else {
                        return
                    }
                    updateIgnoresMouseEvents(mouseLocation: NSEvent.mouseLocation)
                }
            }
        }
    }

    /// 猫の上で受けた左ボタンの操作で、猫を持ち上げ・動かし・置く。ボタンを受けるのはカーソルが猫の上にある間と持ち上げている間だけのため、
    /// 受けた左ボタンの操作はすべて猫への操作として扱う。
    override func sendEvent(_ event: NSEvent) {
        switch event.type {
        case .leftMouseDown, .leftMouseDragged:
            catWalkModel.lift(center: liftedCatCenter(locationInWindow: event.locationInWindow, panelSize: frame.size, catSize: catWalkModel.catSize))
        case .leftMouseUp:
            dropLiftedCat()
            updateIgnoresMouseEvents(mouseLocation: NSEvent.mouseLocation)
        default:
            super.sendEvent(event)
        }
    }

    /// 持ち上げている猫を置いて保存させる。持ち上げていない時は何もしないため冪等。
    func dropLiftedCat() {
        guard catWalkModel.liftedCenter != nil else {
            return
        }
        catWalkModel.drop()
        didDrop?()
    }

    /// 猫の上でクリックを受けている間にカーソルが動いた時に、猫から外れていればクリックを下のアプリに通す状態へ戻す。
    override func mouseMoved(with event: NSEvent) {
        updateIgnoresMouseEvents(mouseLocation: NSEvent.mouseLocation)
    }

    /// 猫の上でクリックを受けている間にカーソルがパネルの外 (別のディスプレイ等) へ出た時に、クリックを下のアプリに通す状態へ戻す。
    override func mouseExited(with event: NSEvent) {
        updateIgnoresMouseEvents(mouseLocation: NSEvent.mouseLocation)
    }
}

/// 全ディスプレイの上に置く `OverlayPanel` を保持し、ディスプレイ構成の変化・設定・マウスの位置に追従させる。設定と猫の状態の保存もここで行う。
@Observable
final class OverlayWindowController {
    /// 状態を保存する間隔 (秒)。強制終了や電源断で終了処理を通らずに終わっても、失う猫の移動をこの間隔の分までにする。
    /// 保存は数百バイトの書き込みで、30 秒ごとなら CPU にもディスクにも効かない
    static let autosaveIntervalSeconds: Double = 30

    /// 猫のオーバーレイを出しているか。メニューバーのメニューと設定ウィンドウから切り替える。
    private(set) var isCatVisible: Bool
    /// 猫の大きさ。
    private(set) var catSize: CatSize
    /// 猫の歩く速さ。
    private(set) var walkingSpeed: CatWalkingSpeed
    /// 設定と猫の状態の保存先。
    @ObservationIgnored private let defaults: UserDefaults
    /// ディスプレイ ID ごとのパネル。
    @ObservationIgnored private var panels: [CGDirectDisplayID: OverlayPanel] = [:]
    /// ディスプレイ構成の変更通知の購読。
    @ObservationIgnored private var screenObserver: NSObjectProtocol?
    /// 他のアプリに届くマウスの移動の監視。猫の上にある間はパネルの tracking area が受ける。
    @ObservationIgnored private var globalMouseMonitor: Any?
    /// このアプリの他のウィンドウ (設定ウィンドウ) に届くマウスの移動の監視。global monitor は自分のアプリに届くイベントを受けないため。
    /// 移動がそのウィンドウに届くかは中の view の tracking area 次第で、届かない間は状態を進めた時の判定し直しに頼る。
    @ObservationIgnored private var localMouseMonitor: Any?
    /// 一定間隔で状態を保存している Task。
    @ObservationIgnored private var autosaveTask: Task<Void, Never>?

    /// `defaults` から前回の設定を読む。テストでアプリの設定を読み書きしないよう保存先を受け取る。
    init(defaults: UserDefaults) {
        self.defaults = defaults
        isCatVisible = defaults.catWalkIsCatVisible
        catSize = defaults.catWalkSize
        walkingSpeed = defaults.catWalkWalkingSpeed
    }

    /// 前回の設定と猫の状態でパネルを出し、ディスプレイ構成の変化の追従・マウスの監視・一定間隔の保存を始める。
    /// 購読と監視は初回だけ登録するため、何度呼んでも結果は同じ (冪等)。
    func start() {
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
        // マウスの監視に Accessibility の許可は要らない (許可が要るのはキー入力の監視だけ)
        if globalMouseMonitor == nil {
            globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.updateIgnoresMouseEvents()
                }
            }
        }
        if localMouseMonitor == nil {
            localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
                MainActor.assumeIsolated {
                    self?.updateIgnoresMouseEvents()
                }
                return event
            }
        }
        if autosaveTask == nil {
            autosaveTask = Task { [weak self] in
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(Self.autosaveIntervalSeconds))
                    guard let self else {
                        return
                    }
                    saveStates()
                }
            }
        }
        syncPanels()
    }

    /// 猫を出すか (`isVisible` が true) 隠すかを決めて保存し、全ディスプレイのパネルに反映する。隠している間はパネルを画面から外し、
    /// 猫の状態を進めるタイマーも止める。同じ値で何度呼んでも結果は同じ (冪等)。
    func setCatVisible(isVisible: Bool) {
        isCatVisible = isVisible
        defaults.catWalkIsCatVisible = isVisible
        syncPanels()
        saveStates()
    }

    /// 猫の大きさを `catSize` にして保存し、全ディスプレイの猫に反映する。同じ値で何度呼んでも結果は同じ (冪等)。
    func setCatSize(catSize: CatSize) {
        self.catSize = catSize
        defaults.catWalkSize = catSize
        syncPanels()
        saveStates()
    }

    /// 猫の歩く速さを `walkingSpeed` にして保存し、全ディスプレイの猫に反映する。同じ値で何度呼んでも結果は同じ (冪等)。
    func setWalkingSpeed(walkingSpeed: CatWalkingSpeed) {
        self.walkingSpeed = walkingSpeed
        defaults.catWalkWalkingSpeed = walkingSpeed
        syncPanels()
    }

    /// 今出しているパネルの猫の状態を保存する。今は外しているディスプレイの保存済みの状態は残す。同じ状態で何度呼んでも結果は同じ (冪等)。
    func saveStates() {
        defaults.catWalkStates.merge(panels.map { (displayStorageKey(displayID: $0.key), $0.value.catWalkModel.currentWalk) }) { _, current in
            current
        }
    }

    /// 今のディスプレイ構成と設定にパネルを合わせる。外れたディスプレイのパネルは状態を保存して閉じ、増えたディスプレイにだけ前回の状態で新しく作る。
    /// 何度呼んでも結果は同じ (冪等)。
    private func syncPanels() {
        let screens = Dictionary(
            NSScreen.screens.compactMap { screen in
                (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber).map { (CGDirectDisplayID($0.uint32Value), screen) }
            },
            uniquingKeysWith: { first, _ in first }
        )
        for (displayID, panel) in panels where screens[displayID] == nil {
            // 持ち上げたまま閉じると、次にパネルを作った時まで持ち上げた状態が残るため置いてから閉じる
            panel.dropLiftedCat()
            panel.catWalkModel.stop()
            defaults.catWalkStates[displayStorageKey(displayID: displayID)] = panel.catWalkModel.currentWalk
            panel.close()
            panel.updateIgnoresMouseEvents(mouseLocation: NSEvent.mouseLocation)
            panels[displayID] = nil
        }
        let savedStates = defaults.catWalkStates
        for (displayID, screen) in screens {
            let panel = panels[displayID] ?? OverlayPanel(
                screen: screen,
                catWalkModel: CatWalkModel(
                    // 保存が無いディスプレイは、初回起動と同じ姿から歩き始める
                    walk: savedStates[displayStorageKey(displayID: displayID)] ?? CatWalkState(),
                    catSize: catSize.points,
                    walkingSpeed: walkingSpeed.pointsPerSecond
                )
            )
            panels[displayID] = panel
            panel.didDrop = { [weak self] in
                self?.saveStates()
            }
            panel.catWalkModel.catSize = catSize.points
            panel.catWalkModel.walkingSpeed = walkingSpeed.pointsPerSecond
            panel.fit(screen: screen)
            if isCatVisible {
                panel.orderFrontRegardless()
                panel.catWalkModel.start()
            } else {
                panel.dropLiftedCat()
                panel.catWalkModel.stop()
                panel.orderOut(nil)
            }
            panel.updateIgnoresMouseEvents(mouseLocation: NSEvent.mouseLocation)
        }
    }

    /// 全パネルのクリックを受けるかを、今のカーソルの位置で判定し直す。何度呼んでも結果は同じ (冪等)。
    private func updateIgnoresMouseEvents() {
        for panel in panels.values {
            panel.updateIgnoresMouseEvents(mouseLocation: NSEvent.mouseLocation)
        }
    }
}

/// `displayID` のディスプレイの状態を保存するキー。`CGDirectDisplayID` は Mac の再起動などで割り当て直されるため、ディスプレイごとに変わらない UUID の文字列にする。
/// UUID を取れないディスプレイは、保存した状態を戻せない時がある代わりに猫を出せるよう、ディスプレイ ID の文字列にする。
func displayStorageKey(displayID: CGDirectDisplayID) -> String {
    CGDisplayCreateUUIDFromDisplayID(displayID).map { CFUUIDCreateString(nil, $0.takeRetainedValue()) as String } ?? String(displayID)
}
