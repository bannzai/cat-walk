import CatWalkCore
import ServiceManagement
import SwiftUI

/// 設定ウィンドウ。表示 / 非表示・大きさ・歩く速さはオーバーレイが保存し、ログイン時に起動は `SMAppService` の登録状態を正とする。
struct CatWalkSettingsView: View {
    /// 設定を反映して保存するオーバーレイ。
    let overlay: OverlayWindowController
    /// ログイン項目の登録状態。システム設定のログイン項目からも変えられるため、保存せず `SMAppService` から読み直す。
    @State private var loginItemStatus = SMAppService.mainApp.status
    /// 直前のログイン項目の登録・解除で起きたエラー。
    @State private var loginItemError: (any Error)?

    var body: some View {
        Form {
            Toggle("猫を表示する", isOn: Binding(get: { overlay.isCatVisible }, set: { overlay.setCatVisible(isVisible: $0) }))
                .accessibilityIdentifier("settings-cat-visible")
            Picker("大きさ", selection: Binding(get: { overlay.catSize }, set: { overlay.setCatSize(catSize: $0) })) {
                Text("小").tag(CatSize.small)
                Text("中").tag(CatSize.medium)
                Text("大").tag(CatSize.large)
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("settings-cat-size")
            Picker("歩く速さ", selection: Binding(get: { overlay.walkingSpeed }, set: { overlay.setWalkingSpeed(walkingSpeed: $0) })) {
                Text("のんびり").tag(CatWalkingSpeed.slow)
                Text("ふつう").tag(CatWalkingSpeed.normal)
                Text("はやい").tag(CatWalkingSpeed.fast)
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("settings-walking-speed")
            // 承認待ちも登録は済んでいるため、オフにすれば登録を取り消せるようオンとして見せる
            Toggle("ログイン時に起動する", isOn: Binding(get: { loginItemStatus == .enabled || loginItemStatus == .requiresApproval }, set: { setLaunchAtLogin(isEnabled: $0) }))
                .accessibilityIdentifier("settings-launch-at-login")
            if loginItemStatus == .requiresApproval {
                Text("システム設定のログイン項目で Cat Walk を許可してください")
                    .foregroundStyle(.secondary)
                Button("ログイン項目を開く") {
                    SMAppService.openSystemSettingsLoginItems()
                }
            }
            if let loginItemError {
                Text(loginItemError.localizedDescription)
                    .foregroundStyle(.red)
            }
            CatWalkAboutSection()
            #if DEBUG
            Section("開発用: 猫の姿勢") {
                // 設定ウィンドウの幅 420pt に 1 行 4 匹が収まる大きさ
                CatPoseGalleryView(size: 64)
            }
            #endif
        }
        .formStyle(.grouped)
        .frame(width: 420)
        // 既に前面のまま開き直した時は didBecomeActive が来ないため、開くたびにも読み直す
        .onAppear {
            loginItemStatus = SMAppService.mainApp.status
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            loginItemStatus = SMAppService.mainApp.status
        }
    }

    /// `isEnabled` に合わせてログイン項目を登録・解除し、結果の登録状態を読み直して表示に反映する。
    /// 既に同じ状態の時に呼んだ時の結果は `SMAppService` に依存するため冪等とは言い切れない。表示は呼んだ後の登録状態に合わせる。
    private func setLaunchAtLogin(isEnabled: Bool) {
        do {
            if isEnabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            loginItemError = nil
        } catch {
            loginItemError = error
        }
        loginItemStatus = SMAppService.mainApp.status
    }
}
