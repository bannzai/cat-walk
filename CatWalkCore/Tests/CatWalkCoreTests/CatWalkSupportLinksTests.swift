import Foundation
import Testing

@testable import CatWalkCore

struct CatWalkSupportLinksTests {
    @Test(arguments: [["ja-JP"], ["ja"], ["ja-JP", "en-US"]])
    func opensJapanesePagesWhenJapaneseComesFirst(preferredLanguages: [String]) {
        #expect(catWalkTermsURL(preferredLanguages: preferredLanguages).absoluteString == "https://bannzai.github.io/cat-walk/Terms-ja")
        #expect(catWalkPrivacyPolicyURL(preferredLanguages: preferredLanguages).absoluteString == "https://bannzai.github.io/cat-walk/PrivacyPolicy-ja")
    }

    @Test(arguments: [["en-US"], ["en-JP", "ja-JP"], ["zh-Hans-JP"], ["fr"], []])
    func opensEnglishPagesOtherwise(preferredLanguages: [String]) {
        #expect(catWalkTermsURL(preferredLanguages: preferredLanguages).absoluteString == "https://bannzai.github.io/cat-walk/Terms-en")
        #expect(catWalkPrivacyPolicyURL(preferredLanguages: preferredLanguages).absoluteString == "https://bannzai.github.io/cat-walk/PrivacyPolicy-en")
    }

    @Test func contactsTheSupportAddressOfTheSite() {
        #expect(catWalkContactURL.absoluteString == "mailto:bannzai.app@gmail.com")
    }
}
