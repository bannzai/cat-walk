import Foundation
import Testing

@testable import CatWalkCore

@Suite(.timeLimit(.minutes(1)))
struct CatWalkStateLiveActivityTests {
    /// 端末の暦に依らず同じ結果にするため、UTC のグレゴリオ暦で固定する。
    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    /// 2026-10-21 00:00:00 UTC。
    private static let dayStart = Date(timeIntervalSince1970: 1_792_540_800)

    @Test func endsEightHoursAfterStart() {
        let startDate = Self.dayStart.addingTimeInterval(9 * 60 * 60 + 20 * 60)

        #expect(CatWalkState.liveActivityEndDate(startDate: startDate) == startDate.addingTimeInterval(8 * 60 * 60))
    }

    @Test func refreshesAtNextSlot() {
        #expect(
            CatWalkState.liveActivityNextRefreshDate(date: Self.dayStart.addingTimeInterval(9 * 60 * 60 + 20 * 60), calendar: Self.calendar)
                == Self.dayStart.addingTimeInterval(9 * 60 * 60 + 30 * 60)
        )
    }

    @Test func refreshesAfterSlotWhenDateIsOnSlot() {
        #expect(
            CatWalkState.liveActivityNextRefreshDate(date: Self.dayStart.addingTimeInterval(9 * 60 * 60 + 15 * 60), calendar: Self.calendar)
                == Self.dayStart.addingTimeInterval(9 * 60 * 60 + 30 * 60)
        )
    }

    @Test func refreshesAtNextDayMidnight() {
        #expect(
            CatWalkState.liveActivityNextRefreshDate(date: Self.dayStart.addingTimeInterval(23 * 60 * 60 + 50 * 60), calendar: Self.calendar)
                == Self.dayStart.addingTimeInterval(24 * 60 * 60)
        )
    }

    @Test func contentStateFitsActivityKitLimit() throws {
        // ActivityKit が Live Activity の更新で受け付けるデータの上限 (4 KB)
        // 出典: https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities
        let state = CatWalkState(x: 0.123456789, direction: .left, activity: .grooming, activityElapsed: 1234.56789, activityRemaining: 7.654321)

        #expect(try JSONEncoder().encode(state).count < 4096)
    }
}
