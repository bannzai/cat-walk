import Foundation
import Testing

/// `Shared/Localizable.xcstrings` がアプリに入り、対応するすべての言語に訳があることを確かめる。
/// CI の xcodebuild はコミットしたカタログにキーを足さないため、カタログの言語の欠けをここで捕まえる。テストのホストの macOS アプリ (`Bundle.main`) の lproj を読む。
struct LocalizableTests {
    /// アプリが対応する言語。`translate-app.config.json` の原文と訳の言語。テストの引数は既定の MainActor の外で評価されるため nonisolated にする。
    nonisolated static let languages = ["ja", "en", "de", "es", "fr", "ko", "pt-BR", "zh-Hans", "zh-Hant"]

    @Test(arguments: languages)
    func everyLanguageHasEveryJapaneseKey(language: String) throws {
        let japaneseKeys = Set(try localizableTable(language: "ja").keys)
        let keys = Set(try localizableTable(language: language).keys)

        #expect(!japaneseKeys.isEmpty)
        #expect(japaneseKeys.subtracting(keys).isEmpty, "\(language) に無いキー: \(japaneseKeys.subtracting(keys).sorted())")
    }

    @Test(arguments: languages.filter { $0 != "ja" })
    func translatesAwayFromJapanese(language: String) throws {
        for (key, value) in try localizableTable(language: language) {
            // 漢字は中国語の訳にも出るため、平仮名・片仮名が残っているかで日本語のままの訳を見つける。中黒 (・) と長音符 (ー) はほかの言語でも使うため数えない
            #expect(!value.unicodeScalars.contains { (0x3041...0x3096).contains($0.value) || (0x30A1...0x30FA).contains($0.value) }, "\(language) の \(key) が日本語のまま: \(value)")
        }
    }

    /// アプリの `language` の lproj にコンパイルされた `Localizable.strings` の キーと訳を返す。
    private func localizableTable(language: String) throws -> [String: String] {
        let url = try #require(Bundle.main.url(forResource: "Localizable", withExtension: "strings", subdirectory: nil, localization: language), "\(language).lproj に Localizable.strings が無い")
        return try #require(NSDictionary(contentsOf: url) as? [String: String])
    }
}
