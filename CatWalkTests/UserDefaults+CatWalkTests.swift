import CatWalkCore
import Foundation
import Testing

@testable import CatWalk

struct UserDefaultsCatWalkTests {
    /// テストごとに別の保存先を使い、アプリの設定と他のテストの値を読み書きしないようにする。
    private func withIsolatedDefaults(body: (UserDefaults) throws -> Void) throws {
        let suiteName = "CatWalkTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }
        try body(defaults)
    }

    @Test func usesFirstLaunchValuesWhenNothingIsSaved() throws {
        try withIsolatedDefaults { defaults in
            #expect(defaults.catWalkIsCatVisible)
            #expect(defaults.catWalkSize == .medium)
            #expect(defaults.catWalkWalkingSpeed == .normal)
            #expect(defaults.catWalkCoat == .chatora)
            #expect(defaults.catWalkStates.isEmpty)
        }
    }

    @Test func roundTripsSettings() throws {
        try withIsolatedDefaults { defaults in
            defaults.catWalkIsCatVisible = false
            defaults.catWalkSize = .large
            defaults.catWalkWalkingSpeed = .fast
            defaults.catWalkCoat = .hachiware

            #expect(!defaults.catWalkIsCatVisible)
            #expect(defaults.catWalkSize == .large)
            #expect(defaults.catWalkWalkingSpeed == .fast)
            #expect(defaults.catWalkCoat == .hachiware)
        }
    }

    /// 次の起動で作り直したオーバーレイが、前回の起動で保存した柄から始まる。
    @Test func overlayStartsWithSavedCoat() throws {
        try withIsolatedDefaults { defaults in
            defaults.catWalkCoat = .sabatora

            #expect(OverlayWindowController(defaults: defaults).catCoat == .sabatora)
        }
    }

    @Test func roundTripsStatesPerDisplay() throws {
        try withIsolatedDefaults { defaults in
            let states: [String: CatWalkState] = [
                "37D8832A-2D66-02CA-B9F7-8F30A301B230": CatWalkState(x: 120, direction: .left, activity: .sleeping, activityElapsed: 3, activityRemaining: 40),
                "69733382": CatWalkState(x: 8, activity: .sitting),
            ]
            defaults.catWalkStates = states

            #expect(defaults.catWalkStates == states)
        }
    }

    @Test func treatsUnreadableStatesAsEmpty() throws {
        try withIsolatedDefaults { defaults in
            defaults.set(Data("not json".utf8), forKey: "catWalkStates")

            #expect(defaults.catWalkStates.isEmpty)
        }
    }

    @Test func fallsBackWhenSavedSettingIsUnknown() throws {
        try withIsolatedDefaults { defaults in
            defaults.set("huge", forKey: "catSize")
            defaults.set("sprint", forKey: "walkingSpeed")

            #expect(defaults.catWalkSize == .medium)
            #expect(defaults.catWalkWalkingSpeed == .normal)
        }
    }
}
