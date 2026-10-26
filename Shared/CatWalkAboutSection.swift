import CatWalkCore
import SwiftUI

/// 設定画面の「このアプリについて」の節。App Store の審査 (App Review Guidelines 1.5) がアプリ内の連絡手段を求め、紹介サイトも「アプリ内の設定画面の『お問い合わせ』からも送れます」と案内しているため、3 OS の設定画面に置く。
struct CatWalkAboutSection: View {
    var body: some View {
        Section("このアプリについて") {
            #if os(watchOS)
            // watchOS の Link は Web ページを開けず (出典: https://developer.apple.com/forums/thread/650324 の Apple の回答)、メールも送れないため、iPhone の設定画面へ案内する
            Text("利用規約・プライバシーポリシーの表示とお問い合わせは iPhone の Cat Walk の設定画面から行えます")
            // iPhone のアプリを入れていない人も問い合わせられるよう、宛先も出す
            Text("お問い合わせ: \(catWalkContactEmailAddress)")
                .foregroundStyle(.secondary)
            #else
            Link("利用規約", destination: catWalkTermsURL(preferredLanguages: Locale.preferredLanguages))
                .accessibilityIdentifier("settings-terms")
            Link("プライバシーポリシー", destination: catWalkPrivacyPolicyURL(preferredLanguages: Locale.preferredLanguages))
                .accessibilityIdentifier("settings-privacy-policy")
            Link("お問い合わせ", destination: catWalkContactURL)
                .accessibilityIdentifier("settings-contact")
            #endif
        }
    }
}
