import CoreGraphics
import Foundation
import ImageIO
import SwiftUI
import Testing
import UniformTypeIdentifiers

@testable import CatWalk

/// スクリーンショットの言語。fastlane の locale (書き出し先のディレクトリ名) と、訳を引く lproj を対応づける。
/// テストの引数に渡すため Sendable にし、既定の MainActor に閉じ込めないよう nonisolated にする。
nonisolated struct AppStoreScreenshotLanguage: Sendable {
    /// 書き出す言語。ストアのメタデータ (`fastlane/metadata/`) と同じ日本語と英語にする。
    static let all: [AppStoreScreenshotLanguage] = [
        AppStoreScreenshotLanguage(fastlaneLocale: "ja", lprojName: "ja"),
        AppStoreScreenshotLanguage(fastlaneLocale: "en-US", lprojName: "en"),
    ]

    /// fastlane の metadata・screenshots のディレクトリ名。
    let fastlaneLocale: String
    /// 訳を引く lproj の名前。
    let lprojName: String

    /// キャッチコピー (`AppStoreScreenshots.xcstrings`) の `key` の訳。
    func copy(key: String) -> String {
        localized(key: key, table: "AppStoreScreenshots", bundle: Bundle(for: AppStoreScreenshotBundleToken.self))
    }

    /// アプリの文言 (`Shared/Localizable.xcstrings`) の `key` の訳。テストのホストの macOS アプリに同梱したカタログから引く。
    func app(key: String) -> String {
        localized(key: key, table: nil, bundle: .main)
    }

    /// `bundle` のこの言語の lproj から `key` の訳を引く。ImageRenderer で言語ごとに描き分けるため、端末の言語ではなくこの言語の訳を使う。
    /// 訳が無い時はキーのまま描かれた画像を書き出さないよう、生成を止める。
    private func localized(key: String, table: String?, bundle: Bundle) -> String {
        let missingValue = "\u{0}missing"
        guard let path = bundle.path(forResource: lprojName, ofType: "lproj"), let languageBundle = Bundle(path: path) else {
            preconditionFailure("\(bundle.bundlePath) に \(lprojName).lproj が無い")
        }
        let value = languageBundle.localizedString(forKey: key, value: missingValue, table: table)
        precondition(value != missingValue, "\(lprojName).lproj の \(table ?? "Localizable") に \(key) の訳が無い")
        return value
    }
}

/// キャッチコピーのカタログを同梱したテストのバンドルを `Bundle(for:)` で引くための型。`Bundle(for:)` が class しか受け取らないため class にする。
private final class AppStoreScreenshotBundleToken {}

extension AppStoreScreenshotPage {
    /// 書き出し先の出力ディレクトリからの相対パス。`<locale>` を言語に置き換える。fastlane の deliver は 1 回の実行で 1 つの platform を扱うため、iPhone と Mac を分ける。
    var outputPathTemplate: String {
        switch self {
        case .iPhoneLockScreen:
            "screenshots/ios/<locale>/01_lock_screen.png"
        case .iPhoneHomeScreen:
            "screenshots/ios/<locale>/02_home_screen.png"
        case .iPhonePetting:
            "screenshots/ios/<locale>/03_petting.png"
        case .macDesktop:
            "screenshots/mac/<locale>/01_desktop.png"
        case .macLifting:
            "screenshots/mac/<locale>/02_lifting.png"
        case .macSettings:
            "screenshots/mac/<locale>/03_settings.png"
        case .productPageHeader:
            "creative_assets/<locale>/product_page_header.png"
        }
    }

    /// 書き出す画像の幅と高さ (px)。iPhone は App Store Connect の 6.9 インチ、Mac は 16:10 の最大、ヘッダーは 21:9 の固定サイズ。
    /// 出典: https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications と、appstore-header-creative skill の `references/asset-spec.md` (ASC の `appAssetLibraryRefData` の実測)
    var pixelSize: (width: Int, height: Int) {
        switch self {
        case .iPhoneLockScreen, .iPhoneHomeScreen, .iPhonePetting:
            (1320, 2868)
        case .macDesktop, .macLifting, .macSettings:
            (2880, 1800)
        case .productPageHeader:
            (3840, 1646)
        }
    }

    /// 描く倍率。各ページの view は pt で描き、この倍率で `pixelSize` になる。
    var scale: Double {
        switch self {
        case .iPhoneLockScreen, .iPhoneHomeScreen, .iPhonePetting:
            3
        case .macDesktop, .macLifting, .macSettings, .productPageHeader:
            2
        }
    }
}

/// App Store のスクリーンショットとヘッダークリエイティブを PNG に書き出す。
/// 書き出しはストア素材を作り直す時だけ行うため、環境変数 `SCREENSHOTS_OUTPUT_DIR` (xcodebuild には `TEST_RUNNER_SCREENSHOTS_OUTPUT_DIR` で渡す) がある時だけ動かし、`make test` では飛ばす。
/// 手順は `scripts/generate_screenshots/README.md`。
@Suite(.enabled(if: ProcessInfo.processInfo.environment["SCREENSHOTS_OUTPUT_DIR"] != nil))
struct AppStoreScreenshotTests {
    @Test(arguments: AppStoreScreenshotLanguage.all)
    func writesEveryPage(language: AppStoreScreenshotLanguage) throws {
        let outputDirectory = URL(filePath: try #require(ProcessInfo.processInfo.environment["SCREENSHOTS_OUTPUT_DIR"]))
        for page in AppStoreScreenshotPage.allCases {
            let renderer = ImageRenderer(content: AppStoreScreenshotPageView(page: page, language: language).environment(\.locale, Locale(identifier: language.lprojName)))
            renderer.scale = page.scale
            renderer.isOpaque = true
            let image = try opaqueImage(image: try #require(renderer.cgImage, "\(page) を描けない"))
            #expect(image.width == page.pixelSize.width && image.height == page.pixelSize.height, "\(page) が \(image.width)x\(image.height) px")

            let url = outputDirectory.appending(path: page.outputPathTemplate.replacingOccurrences(of: "<locale>", with: language.fastlaneLocale))
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            let destination = try #require(CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil))
            CGImageDestinationAddImage(destination, image, nil)
            #expect(CGImageDestinationFinalize(destination), "\(url.path) に書き出せない")
            print("SCREENSHOT_WRITTEN=\(url.path)")
        }
    }

    /// `image` を alpha を持たない sRGB の画像に描き直して返す。App Store Connect はスクリーンショットとヘッダーの透過を受け付けないため。
    private func opaqueImage(image: CGImage) throws -> CGImage {
        let context = try #require(CGContext(
            data: nil,
            width: image.width,
            height: image.height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: try #require(CGColorSpace(name: CGColorSpace.sRGB)),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ))
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        return try #require(context.makeImage())
    }
}
