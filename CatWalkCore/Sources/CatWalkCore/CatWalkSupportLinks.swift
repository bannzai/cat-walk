import Foundation

/// 紹介サイト (GitHub Pages) の URL。利用規約・プライバシーポリシーはこの下に `<ページ名>-<言語>` で置いている (docs/)。
private let catWalkSiteURL = URL(string: "https://bannzai.github.io/cat-walk/")!

/// お問い合わせのメールの宛先。紹介サイトのサポートの節 (docs/index.html) と同じ宛先にする。
public let catWalkContactEmailAddress = "bannzai.app@gmail.com"

/// お問い合わせのメールを書き始める URL。
public let catWalkContactURL = URL(string: "mailto:\(catWalkContactEmailAddress)")!

/// 端末の言語に合う利用規約のページの URL を返す。
/// - Parameter preferredLanguages: 端末の言語の優先順 (`Locale.preferredLanguages`)。紹介サイトは日本語と英語のページしか持たず、アプリの言語 (9 言語) と一致しないため、端末の言語で選ぶ
public func catWalkTermsURL(preferredLanguages: [String]) -> URL {
    catWalkSiteURL.appending(path: "Terms-\(catWalkSitePageLanguageSuffix(preferredLanguages: preferredLanguages))")
}

/// 端末の言語に合うプライバシーポリシーのページの URL を返す。
/// - Parameter preferredLanguages: 端末の言語の優先順 (`Locale.preferredLanguages`)。紹介サイトは日本語と英語のページしか持たず、アプリの言語 (9 言語) と一致しないため、端末の言語で選ぶ
public func catWalkPrivacyPolicyURL(preferredLanguages: [String]) -> URL {
    catWalkSiteURL.appending(path: "PrivacyPolicy-\(catWalkSitePageLanguageSuffix(preferredLanguages: preferredLanguages))")
}

/// 紹介サイトのページ名の末尾に付ける言語 (`ja` / `en`) を返す。
/// 紹介サイトは日本語と英語のページしか持たないため、最も優先する言語が日本語の時だけ日本語にし、それ以外の言語 (言語が取れない時を含む) は読める人が多い英語にする
private func catWalkSitePageLanguageSuffix(preferredLanguages: [String]) -> String {
    guard let preferredLanguage = preferredLanguages.first, Locale.Language(identifier: preferredLanguage).languageCode == .japanese else {
        return "en"
    }
    return "ja"
}
