import CatWalkCore
import SwiftUI

@testable import CatWalk

/// App Store のスクリーンショットとヘッダークリエイティブの 1 枚。背景・キャッチコピー・端末の画面を 1 つの view で描き、`AppStoreScreenshotTests` が ImageRenderer で PNG に書き出す。
/// 書き出す大きさ (pt と倍率) は `AppStoreScreenshotTests` が決める。
enum AppStoreScreenshotPage: CaseIterable {
    /// iPhone 1 枚目。散歩に出した猫がロック画面の Live Activity を歩く。
    case iPhoneLockScreen
    /// iPhone 2 枚目。ホーム画面のウィジェットの猫。
    case iPhoneHomeScreen
    /// iPhone 3 枚目。アプリの画面で撫でて喜ぶ猫。
    case iPhonePetting
    /// Mac 1 枚目。作業中のデスクトップの下端を歩く猫。
    case macDesktop
    /// Mac 2 枚目。つまんで持ち上げた猫。
    case macLifting
    /// Mac 3 枚目。メニューバーと設定ウィンドウ。
    case macSettings
    /// 製品ページのヘッダー (21:9)。
    case productPageHeader
}

/// スクリーンショットの配色。紹介サイト (docs/index.html の `--bg`・`--text`・`--text-sub`・`--accent`・`--line`) と同じ色にし、ストアと紹介サイトの見た目を揃える。
enum AppStoreScreenshotPalette {
    /// 背景。
    static let background = Color(red: 0x1d / 255, green: 0x1f / 255, blue: 0x23 / 255)
    /// 見出しの文字。
    static let text = Color(red: 0xec / 255, green: 0xee / 255, blue: 0xf1 / 255)
    /// 補足の文字。
    static let subText = Color(red: 0xa8 / 255, green: 0xae / 255, blue: 0xb8 / 255)
    /// 強調 (茶トラの猫の色)。
    static let accent = Color(red: 0xf0 / 255, green: 0xa0 / 255, blue: 0x5a / 255)
    /// 床の線・枠。
    static let line = Color(red: 0x3a / 255, green: 0x3e / 255, blue: 0x46 / 255)
}

/// 1 枚のスクリーンショットを描く view。
struct AppStoreScreenshotPageView: View {
    /// 描くページ。
    let page: AppStoreScreenshotPage
    /// 文言を引く言語。
    let language: AppStoreScreenshotLanguage

    var body: some View {
        switch page {
        case .iPhoneLockScreen:
            IPhoneScreenshotLayout(title: language.copy(key: "iphone.lock.title"), subtitle: language.copy(key: "iphone.lock.subtitle"), calloutWalk: CatWalkState(activity: .walking)) {
                IPhoneLockScreen(language: language)
            }
        case .iPhoneHomeScreen:
            IPhoneScreenshotLayout(title: language.copy(key: "iphone.home.title"), subtitle: language.copy(key: "iphone.home.subtitle"), calloutWalk: CatWalkState(direction: .left, activity: .standing)) {
                IPhoneHomeScreen(language: language)
            }
        case .iPhonePetting:
            IPhoneScreenshotLayout(title: language.copy(key: "iphone.pet.title"), subtitle: language.copy(key: "iphone.pet.subtitle"), calloutWalk: CatWalkState(activity: .delighted)) {
                IPhoneAppScreen(language: language)
            }
        case .macDesktop:
            MacScreenshotLayout(title: language.copy(key: "mac.desktop.title"), subtitle: language.copy(key: "mac.desktop.subtitle"), calloutWalk: CatWalkState(activity: .walking), calloutIsLifted: false) {
                MacDesktop(cat: .walking, language: language)
            }
        case .macLifting:
            MacScreenshotLayout(title: language.copy(key: "mac.lift.title"), subtitle: language.copy(key: "mac.lift.subtitle"), calloutWalk: CatWalkState(), calloutIsLifted: true) {
                MacDesktop(cat: .lifted, language: language)
            }
        case .macSettings:
            MacScreenshotLayout(title: language.copy(key: "mac.settings.title"), subtitle: language.copy(key: "mac.settings.subtitle"), calloutWalk: CatWalkState(direction: .left, activity: .sitting), calloutIsLifted: false) {
                MacDesktop(cat: .settings, language: language)
            }
        case .productPageHeader:
            ProductPageHeader(language: language)
        }
    }
}

// MARK: - レイアウト

/// キャッチコピーの見出しと補足。短い文言のため句読点を使わず、見出しは改行で区切る (キャッチコピー定義の `\n`)。
private struct AppStoreScreenshotCaption: View {
    /// 見出し。
    let title: String
    /// 見出しの下の補足。
    let subtitle: String
    /// 見出しの文字の大きさ (pt)。補足はその半分にする。
    let titleSize: Double

    var body: some View {
        VStack(spacing: titleSize * 0.35) {
            Text(title)
                .font(.system(size: titleSize, weight: .heavy))
                .foregroundStyle(AppStoreScreenshotPalette.text)
                .lineSpacing(titleSize * 0.1)
            Text(subtitle)
                .font(.system(size: titleSize * 0.5, weight: .semibold))
                .foregroundStyle(AppStoreScreenshotPalette.accent)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
    }
}

/// iPhone 6.9 インチ (440 x 956 pt、3 倍で 1320 x 2868 px) の 1 枚。上にキャッチコピー、下に iPhone の枠に入れた画面を置き、端末に重ねて猫の拡大図を出す。
private struct IPhoneScreenshotLayout<Screen: View>: View {
    /// 見出し。
    let title: String
    /// 補足。
    let subtitle: String
    /// 拡大図に描く猫の状態。画面の中の猫と同じ姿勢にする。
    let calloutWalk: CatWalkState
    /// iPhone の画面 (393 x 852 pt で描く)。
    @ViewBuilder let screen: Screen

    var body: some View {
        ZStack(alignment: .top) {
            AppStoreScreenshotPalette.background
            AppStoreScreenshotCaption(title: title, subtitle: subtitle, titleSize: 34)
                .padding(.horizontal, 20)
                .padding(.top, 70)
            IPhoneFrame {
                screen
            }
            // 端末を 0.78 倍にすると、見出しの下 (250pt から) に端末の下端までが収まり、画面の下端近くの猫が見切れない
            .scaleEffect(0.78, anchor: .top)
            .padding(.top, 250)
            // 画面の中の猫は実寸 (44pt) で小さいため、端末の空いている中ほどに拡大図を重ねる
            AppStoreScreenshotCatCallout(walk: calloutWalk, isLifted: false, diameter: 190)
                .position(x: 322, y: 590)
        }
        .frame(width: 440, height: 956, alignment: .top)
        .clipped()
    }
}

/// 猫の拡大図。画面の中の実寸の猫が小さく見えるため、同じ姿勢の猫を円の中に大きく描く。
private struct AppStoreScreenshotCatCallout: View {
    /// 描く猫の状態。
    let walk: CatWalkState
    /// 持ち上げた姿で描くか。
    let isLifted: Bool
    /// 円の直径 (pt)。猫は直径の 0.62 倍にし、円の縁との間に余白を残す。
    let diameter: Double

    var body: some View {
        CatPostureView(walk: walk, size: diameter * 0.62, isLifted: isLifted)
            .frame(width: diameter, height: diameter)
            .background(Circle().fill(Color(red: 0xfa / 255, green: 0xf4 / 255, blue: 0xec / 255)))
            .overlay(Circle().stroke(AppStoreScreenshotPalette.accent, lineWidth: diameter * 0.03))
            .shadow(color: .black.opacity(0.45), radius: diameter * 0.08, y: diameter * 0.03)
    }
}

/// iPhone の枠。画面は iPhone 17 Pro と同じ 393 x 852 pt で描き、角を丸めて黒い縁を付ける。
private struct IPhoneFrame<Screen: View>: View {
    /// 枠の中の画面。
    @ViewBuilder let screen: Screen

    var body: some View {
        screen
            .frame(width: 393, height: 852)
            .clipShape(RoundedRectangle(cornerRadius: 55, style: .continuous))
            .overlay(alignment: .top) {
                // Dynamic Island
                Capsule()
                    .fill(.black)
                    .frame(width: 124, height: 36)
                    .padding(.top, 11)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 67, style: .continuous)
                    .fill(Color(white: 0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 67, style: .continuous)
                    .stroke(Color(white: 0.32), lineWidth: 2)
            )
    }
}

/// Mac (1440 x 900 pt、2 倍で 2880 x 1800 px) の 1 枚。上にキャッチコピー、下に Mac の画面を置く。
private struct MacScreenshotLayout<Screen: View>: View {
    /// 見出し。
    let title: String
    /// 補足。
    let subtitle: String
    /// 拡大図に描く猫の状態。画面の中の猫と同じ姿勢にする。
    let calloutWalk: CatWalkState
    /// 拡大図の猫を持ち上げた姿で描くか。
    let calloutIsLifted: Bool
    /// Mac の画面 (1440 x 900 pt で描く)。
    @ViewBuilder let screen: Screen

    var body: some View {
        ZStack(alignment: .top) {
            AppStoreScreenshotPalette.background
            AppStoreScreenshotCaption(title: title, subtitle: subtitle, titleSize: 50)
                .padding(.top, 56)
            screen
                .frame(width: 1440, height: 900)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(Color(white: 0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(Color(white: 0.3), lineWidth: 2)
                )
                // 画面を 0.72 倍にすると、見出しの下に 16:10 の画面全体が収まる
                .scaleEffect(0.72, anchor: .top)
                .padding(.top, 220)
            // 画面の中の猫は 64pt を 0.72 倍した大きさで小さいため、画面の右下に拡大図を重ねる
            AppStoreScreenshotCatCallout(walk: calloutWalk, isLifted: calloutIsLifted, diameter: 260)
                .position(x: 1250, y: 690)
        }
        .frame(width: 1440, height: 900, alignment: .top)
        .clipped()
    }
}

// MARK: - iPhone の画面

/// iPhone の画面の時刻。App Store のスクリーンショットで慣例の 9:41 にする。
private let iPhoneScreenClockText = "9:41"

/// ロック画面に散歩中の猫の Live Activity が出ている画面。Live Activity の中身は `CatWalkLiveActivity` のロック画面の表示 (一言と歩く範囲の中の 44pt の猫) に合わせる。
private struct IPhoneLockScreen: View {
    /// 文言を引く言語。
    let language: AppStoreScreenshotLanguage

    var body: some View {
        ZStack(alignment: .top) {
            IPhoneWallpaper()
            VStack(spacing: 0) {
                Text(language.copy(key: "iphone.lock.date"))
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.top, 72)
                Text(iPhoneScreenClockText)
                    .font(.system(size: 104, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                Spacer()
                VStack(alignment: .leading, spacing: 5) {
                    Text(language.app(key: "おさんぽ中"))
                        .font(.headline)
                        .foregroundStyle(.white)
                    AppStoreScreenshotCatTrack(walk: CatWalkState(x: 0.55, activity: .walking), catSize: 44)
                        .frame(height: 52)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color(white: 0.12).opacity(0.78))
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 120)
            }
        }
    }
}

/// ホーム画面にウィジェットの猫が出ている画面。ウィジェットは `CatWalkWidgetView` の systemSmall の表示 (一言と横位置の中の 44pt の猫) に合わせる。
private struct IPhoneHomeScreen: View {
    /// 文言を引く言語。
    let language: AppStoreScreenshotLanguage

    var body: some View {
        ZStack(alignment: .top) {
            IPhoneWallpaper()
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top, spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(language.app(key: "ひとやすみ"))
                            .font(.headline)
                            .foregroundStyle(Color(white: 0.1))
                        AppStoreScreenshotCatTrack(walk: CatWalkState(x: 0.6, direction: .left, activity: .standing), catSize: 44)
                    }
                    .padding(16)
                    .frame(width: 158, height: 158, alignment: .topLeading)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(.white.opacity(0.9))
                    )
                    IPhoneAppIconGrid(columns: 2, rows: 2)
                }
                IPhoneAppIconGrid(columns: 4, rows: 3)
            }
            .padding(.top, 76)
            .padding(.horizontal, 28)
            // Dock
            VStack {
                Spacer()
                IPhoneAppIconGrid(columns: 4, rows: 1)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 34, style: .continuous)
                            .fill(.white.opacity(0.18))
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }
        }
    }
}

/// アプリの画面。`CatWalkView` と同じく、上に「散歩に出す」と設定のボタン、画面下端の近くに猫を置き、撫でて喜んだ姿勢にする。
private struct IPhoneAppScreen: View {
    /// 文言を引く言語。
    let language: AppStoreScreenshotLanguage

    var body: some View {
        ZStack(alignment: .top) {
            Color.white
            Text(language.app(key: "散歩に出す"))
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.accentColor)
                )
                .padding(.top, 70)
            HStack {
                Spacer()
                Image(systemName: "gearshape")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color(white: 0.93)))
            }
            .padding(.top, 66)
            .padding(.trailing, 16)
            // `CatWalkView` は猫の中心を下端から猫 2 匹分の高さに置く
            ZStack {
                Circle()
                    .stroke(AppStoreScreenshotPalette.accent.opacity(0.5), lineWidth: 3)
                    .frame(width: 96, height: 96)
                Circle()
                    .fill(AppStoreScreenshotPalette.accent.opacity(0.18))
                    .frame(width: 64, height: 64)
                CatPostureView(walk: CatWalkState(activity: .delighted), size: 44)
            }
            .position(x: 210, y: 852 - 88)
        }
    }
}

/// ウィジェットと Live Activity の歩く範囲。`CatWalkWidgetView`・`CatWalkActivityTrackView` と同じく、`walk.x` (歩く範囲の幅に対する割合) の位置で猫を下端に置く。
private struct AppStoreScreenshotCatTrack: View {
    /// 描く猫の状態。
    let walk: CatWalkState
    /// 猫の大きさ (pt)。
    let catSize: Double

    var body: some View {
        GeometryReader { proxy in
            CatPostureView(walk: walk, size: catSize)
                .position(x: max(proxy.size.width - catSize, 0) * walk.x + catSize / 2, y: proxy.size.height - catSize / 2)
        }
    }
}

/// iPhone の壁紙。猫の茶色が映える落ち着いた紺の 1 色にする。
private struct IPhoneWallpaper: View {
    var body: some View {
        Color(red: 0.16, green: 0.2, blue: 0.3)
    }
}

/// ホーム画面のアプリのアイコンの並び。ほかのアプリの名前とアイコンを出さないよう、色の付いた角丸の四角で表す。
private struct IPhoneAppIconGrid: View {
    /// 列の数。
    let columns: Int
    /// 行の数。
    let rows: Int

    /// アイコンの色。ほかのアプリを特定させない、くすんだ色にする。
    private static let iconColors: [Color] = [
        Color(red: 0.42, green: 0.5, blue: 0.62),
        Color(red: 0.36, green: 0.55, blue: 0.5),
        Color(red: 0.6, green: 0.5, blue: 0.42),
        Color(red: 0.5, green: 0.44, blue: 0.6),
    ]

    var body: some View {
        Grid(horizontalSpacing: 24, verticalSpacing: 26) {
            ForEach(0..<rows, id: \.self) { row in
                GridRow {
                    ForEach(0..<columns, id: \.self) { column in
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Self.iconColors[(row * columns + column) % Self.iconColors.count])
                            .frame(width: 62, height: 62)
                    }
                }
            }
        }
    }
}

// MARK: - Mac の画面

/// Mac の画面に出す猫の場面。
private enum MacDesktopCat {
    /// Dock の上を歩く。
    case walking
    /// カーソルでつまんで持ち上げている。
    case lifted
    /// 座っている猫と、メニューバーのメニューと設定ウィンドウ。
    case settings
}

/// Mac のデスクトップ。作業中のウィンドウの手前で、`OverlayWindow` と同じく Dock の上端 (visibleFrame の下端) を猫が歩く。
private struct MacDesktop: View {
    /// 猫の場面。
    let cat: MacDesktopCat
    /// 文言を引く言語。
    let language: AppStoreScreenshotLanguage

    /// 猫の大きさ。設定の「大」(64pt) にし、縮小した画面でも姿勢が分かるようにする。
    private static let catSize = CatSize.large.points
    /// Dock の上端の y 座標 (pt)。
    private static let dockTop: Double = 900 - 86

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color(red: 0.2, green: 0.24, blue: 0.32)
            MacWindow(width: 760, height: 500, content: MacEditorContent())
                .offset(x: 120, y: 90)
            MacWindow(width: 600, height: 420, content: MacDocumentContent())
                .offset(x: 720, y: 220)
            MacMenuBar(showsMenu: cat == .settings, language: language)
            if cat == .settings {
                MacSettingsWindow(language: language)
                    // メニューバーのメニュー (右上) と重ならないよう、左下にずらす
                    .offset(x: 600, y: 190)
            }
            MacDock()
                .frame(width: 1440, height: 900, alignment: .bottom)
            catView
        }
        .frame(width: 1440, height: 900)
    }

    /// 場面ごとの猫。x 座標は Dock (中央 600〜840pt 付近) とウィンドウに重ならない、空いている所に置く。
    @ViewBuilder private var catView: some View {
        switch cat {
        case .walking:
            // Dock の左端の手前を歩いている所。足を Dock の上端に揃える
            CatPostureView(walk: CatWalkState(x: 0.4, activity: .walking), size: Self.catSize)
                .position(x: 520, y: Self.dockTop - Self.catSize / 2)
        case .lifted:
            ZStack(alignment: .topLeading) {
                CatPostureView(walk: CatWalkState(), size: Self.catSize, isLifted: true)
                    .frame(width: Self.catSize, height: Self.catSize)
                Image(systemName: "hand.point.up.left.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.5), radius: 2)
                    .offset(x: Self.catSize * 0.45, y: Self.catSize * 0.05)
            }
            // エディタのウィンドウと文書のウィンドウの間の空いている所で持ち上げている
            .position(x: 660, y: 470)
        case .settings:
            // 設定ウィンドウとメニューから離した左下で座っている所
            CatPostureView(walk: CatWalkState(x: 0.2, direction: .left, activity: .sitting), size: Self.catSize)
                .position(x: 300, y: Self.dockTop - Self.catSize / 2)
        }
    }
}

/// Mac のメニューバー。右端にアプリのメニューバーのアイコン (`MenuBarExtra` の `cat.fill`) を置き、`showsMenu` の時はアプリのメニューを開いた状態にする。
private struct MacMenuBar: View {
    /// アプリのメニューを開いた状態にするか。
    let showsMenu: Bool
    /// 文言を引く言語。
    let language: AppStoreScreenshotLanguage

    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack(spacing: 18) {
                Spacer()
                Image(systemName: "cat.fill")
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.white.opacity(showsMenu ? 0.25 : 0))
                    )
                Image(systemName: "wifi")
                Text(iPhoneScreenClockText)
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .frame(width: 1440, height: 30)
            .background(.black.opacity(0.35))
            if showsMenu {
                // `CatWalkApp` の MenuBarExtra の項目
                VStack(alignment: .leading, spacing: 6) {
                    Text("Cat Walk")
                        .foregroundStyle(.white.opacity(0.5))
                    Text(language.app(key: "猫を隠す"))
                    Text(language.app(key: "設定…"))
                    Divider()
                        .overlay(.white.opacity(0.2))
                    Text(language.app(key: "終了"))
                }
                .font(.system(size: 13))
                .foregroundStyle(.white)
                .padding(10)
                .frame(width: 200, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(white: 0.18).opacity(0.95))
                )
                .padding(.top, 34)
                .padding(.trailing, 150)
            }
        }
    }
}

/// Mac の Dock。ほかのアプリを特定させないよう、色の付いた角丸の四角で表す。
private struct MacDock: View {
    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<9, id: \.self) { index in
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(hue: Double(index) / 9, saturation: 0.25, brightness: 0.6))
                    .frame(width: 56, height: 56)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.white.opacity(0.2))
        )
        .padding(.bottom, 6)
    }
}

/// Mac のウィンドウ。作業中の様子を表すだけのため、中身は文字を持たない図形にする。
private struct MacWindow<Content: View>: View {
    /// 幅 (pt)。
    let width: Double
    /// 高さ (pt)。
    let height: Double
    /// ウィンドウの中身。
    let content: Content

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Circle().fill(Color(red: 1, green: 0.37, blue: 0.34)).frame(width: 12, height: 12)
                Circle().fill(Color(red: 1, green: 0.74, blue: 0.18)).frame(width: 12, height: 12)
                Circle().fill(Color(red: 0.16, green: 0.79, blue: 0.25)).frame(width: 12, height: 12)
                Spacer()
            }
            .padding(.horizontal, 14)
            .frame(height: 36)
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(width: width, height: height)
        .background(Color(white: 0.16))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 24, y: 12)
    }
}

/// エディタのウィンドウの中身。行の長さが揃わない色付きの線で、コードを書いている様子を表す。
private struct MacEditorContent: View {
    /// 各行の (字下げの段数, 長さの割合, 色の番号)。
    private static let lines: [(Int, Double, Int)] = [
        (0, 0.42, 0), (1, 0.55, 1), (1, 0.3, 2), (2, 0.62, 1), (2, 0.48, 3), (1, 0.2, 0),
        (0, 0, 0), (0, 0.5, 0), (1, 0.66, 2), (2, 0.4, 1), (2, 0.58, 3), (1, 0.24, 0),
    ]
    /// 構文の色。
    private static let colors: [Color] = [
        Color(red: 0.98, green: 0.47, blue: 0.62),
        Color(red: 0.6, green: 0.78, blue: 0.98),
        Color(red: 0.98, green: 0.82, blue: 0.5),
        Color(red: 0.7, green: 0.9, blue: 0.62),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Self.lines.indices, id: \.self) { index in
                let line = Self.lines[index]
                RoundedRectangle(cornerRadius: 4)
                    .fill(Self.colors[line.2].opacity(0.75))
                    .frame(width: 560 * line.1, height: 10)
                    .padding(.leading, Double(line.0) * 28)
            }
        }
        .padding(28)
    }
}

/// 文書のウィンドウの中身。見出しと段落を灰色の線で表す。
private struct MacDocumentContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 5)
                .fill(.white.opacity(0.7))
                .frame(width: 260, height: 18)
                .padding(.bottom, 8)
            ForEach(0..<8, id: \.self) { index in
                RoundedRectangle(cornerRadius: 4)
                    .fill(.white.opacity(0.28))
                    .frame(width: index % 4 == 3 ? 300 : 520, height: 9)
            }
        }
        .padding(28)
    }
}

/// 設定ウィンドウ。`CatWalkSettingsView` の項目 (表示・大きさ・歩く速さ・ログイン時に起動) と選択肢を、同じ順に並べる。
/// ImageRenderer は macOS の Toggle・Picker を描けないため、同じ見た目を図形で描く。
private struct MacSettingsWindow: View {
    /// 文言を引く言語。
    let language: AppStoreScreenshotLanguage

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Circle().fill(Color(red: 1, green: 0.37, blue: 0.34)).frame(width: 12, height: 12)
                Circle().fill(Color(white: 0.4)).frame(width: 12, height: 12)
                Circle().fill(Color(white: 0.4)).frame(width: 12, height: 12)
                Spacer()
            }
            .padding(.horizontal, 14)
            .frame(height: 36)
            VStack(spacing: 0) {
                MacSettingsRow(title: language.app(key: "猫を表示する")) {
                    MacSwitch(isOn: true)
                }
                MacSettingsRow(title: language.app(key: "大きさ")) {
                    MacSegmentedControl(titles: ["小", "中", "大"].map { language.app(key: $0) }, selectedIndex: 2)
                }
                MacSettingsRow(title: language.app(key: "歩く速さ")) {
                    MacSegmentedControl(titles: ["のんびり", "ふつう", "はやい"].map { language.app(key: $0) }, selectedIndex: 0)
                }
                MacSettingsRow(title: language.app(key: "ログイン時に起動する")) {
                    MacSwitch(isOn: true)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.white.opacity(0.06))
            )
            .padding(20)
        }
        .frame(width: 460)
        .background(Color(white: 0.17))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.white.opacity(0.14), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.4), radius: 30, y: 14)
    }
}

/// 設定ウィンドウの 1 行。左に項目名、右に操作部品を置く。
private struct MacSettingsRow<Control: View>: View {
    /// 項目名。
    let title: String
    /// 右に置く操作部品。
    @ViewBuilder let control: Control

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 14))
                .foregroundStyle(.white)
            Spacer()
            control
        }
        .padding(.horizontal, 14)
        .frame(height: 48)
    }
}

/// macOS のスイッチの見た目。
private struct MacSwitch: View {
    /// オンか。
    let isOn: Bool

    var body: some View {
        Capsule()
            .fill(isOn ? Color.accentColor : Color(white: 0.35))
            .frame(width: 38, height: 22)
            .overlay(alignment: isOn ? .trailing : .leading) {
                Circle()
                    .fill(.white)
                    .frame(width: 18, height: 18)
                    .padding(2)
            }
    }
}

/// macOS のセグメントの見た目。
private struct MacSegmentedControl: View {
    /// 各セグメントの文言。
    let titles: [String]
    /// 選んでいるセグメントの番号。
    let selectedIndex: Int

    var body: some View {
        HStack(spacing: 2) {
            ForEach(titles.indices, id: \.self) { index in
                Text(titles[index])
                    .font(.system(size: 13))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .frame(height: 24)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(index == selectedIndex ? Color(white: 0.42) : .clear)
                    )
            }
        }
        .padding(2)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(white: 0.26))
        )
    }
}

// MARK: - ヘッダー

/// 製品ページのヘッダー (1920 x 823 pt、2 倍で 3840 x 1646 px)。紹介サイトの og.png と同じく、暗い背景の床の線の上を猫が歩き、見出しを添える。
/// 端末ごとに Apple が切り抜くため、見出しと猫は Art Safe Area (3840 x 1646 px のうち x 1097〜2743・y 493〜1154 px) の中に収める。
private struct ProductPageHeader: View {
    /// 文言を引く言語。
    let language: AppStoreScreenshotLanguage

    /// 床の線の y 座標 (pt)。Art Safe Area の下端 (1154 px = 577 pt) の少し上に置き、猫の足を Safe Area に収める。
    private static let floorY: Double = 560

    var body: some View {
        ZStack(alignment: .topLeading) {
            AppStoreScreenshotPalette.background
            Rectangle()
                .fill(AppStoreScreenshotPalette.line)
                .frame(width: 1920, height: 4)
                .offset(y: Self.floorY)
            VStack(spacing: 18) {
                Text(language.copy(key: "header.title"))
                    .font(.system(size: 52, weight: .heavy))
                    .foregroundStyle(AppStoreScreenshotPalette.text)
                Text(language.copy(key: "header.subtitle"))
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(AppStoreScreenshotPalette.accent)
            }
            .multilineTextAlignment(.center)
            .frame(width: 1920)
            .offset(y: 270)
            CatPostureView(walk: CatWalkState(activity: .walking), size: 120)
                .position(x: 1180, y: Self.floorY - 60)
        }
        .frame(width: 1920, height: 823)
        .clipped()
    }
}
