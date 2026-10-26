import Foundation
import Testing

@testable import CatWalkCore

struct CatCoatTests {
    /// テストごとに別の保存先を使い、アプリの設定と他のテストの値を読み書きしないようにする。
    private func withIsolatedSuite(body: (String) throws -> Void) throws {
        let suiteName = "CatWalkCoreTests-\(UUID().uuidString)"
        defer {
            UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
        }
        try body(suiteName)
    }

    @Test func keepsRawValuesAsStorageFormat() {
        #expect(CatCoat.allCases.map(\.rawValue) == ["chatora", "mike", "kuro", "shiro", "sabatora", "hachiware"])
    }

    @Test func usesChatoraWhenNothingIsSaved() throws {
        try withIsolatedSuite { suiteName in
            let defaults = try #require(UserDefaults(suiteName: suiteName))

            #expect(defaults.catWalkCoat == .chatora)
        }
    }

    @Test func fallsBackToChatoraWhenSavedValueIsUnknown() throws {
        try withIsolatedSuite { suiteName in
            let defaults = try #require(UserDefaults(suiteName: suiteName))
            defaults.set("calico", forKey: "catCoat")

            #expect(defaults.catWalkCoat == .chatora)
        }
    }

    /// アプリが書いた柄を、別のプロセスのウィジェットが同じ suite 名で開いた保存先から読める。別のインスタンスで開いて確かめる。
    @Test func readsCoatWrittenByAnotherInstanceOfTheSameSuite() throws {
        try withIsolatedSuite { suiteName in
            for coat in CatCoat.allCases {
                try #require(UserDefaults(suiteName: suiteName)).catWalkCoat = coat

                let reopenedDefaults = try #require(UserDefaults(suiteName: suiteName))

                #expect(reopenedDefaults.catWalkCoat == coat)
            }
        }
    }
}
