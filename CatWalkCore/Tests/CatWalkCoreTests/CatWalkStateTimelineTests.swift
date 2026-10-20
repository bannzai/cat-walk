import Foundation
import Testing

@testable import CatWalkCore

@Suite(.timeLimit(.minutes(1)))
struct CatWalkStateTimelineTests {
    /// 端末の暦に依らず同じ結果にするため、UTC のグレゴリオ暦で固定する。
    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    /// 2026-10-21 00:00:00 UTC。
    private static let dayStart = Date(timeIntervalSince1970: 1_792_540_800)

    @Test func datesStartAtSlotBeforeDateAndAreSpacedByInterval() {
        let dates = CatWalkState.timelineDates(date: Self.dayStart.addingTimeInterval(20 * 60), count: 3, calendar: Self.calendar)

        #expect(dates == [15, 30, 45].map { Self.dayStart.addingTimeInterval(Double($0) * 60) })
    }

    @Test func sameSlotGivesSameState() {
        let slot = Self.dayStart.addingTimeInterval(9 * 60 * 60)

        #expect(
            CatWalkState.timelineState(date: slot, calendar: Self.calendar, width: 1, walkingSpeed: 0.1)
                == CatWalkState.timelineState(date: slot.addingTimeInterval(14 * 60), calendar: Self.calendar, width: 1, walkingSpeed: 0.1)
        )
    }

    @Test func startsFromInitialStateAtMidnight() {
        #expect(CatWalkState.timelineState(date: Self.dayStart, calendar: Self.calendar, width: 1, walkingSpeed: 0.1) == CatWalkState())
    }

    @Test func changesBetweenConsecutiveEntries() {
        let states = CatWalkState.timelineDates(date: Self.dayStart.addingTimeInterval(9 * 60 * 60), count: 16, calendar: Self.calendar)
            .map { CatWalkState.timelineState(date: $0, calendar: Self.calendar, width: 1, walkingSpeed: 0.1) }

        for (previous, next) in zip(states, states.dropFirst()) {
            #expect(previous.activity != next.activity)
            #expect(previous.x != next.x)
            #expect((0.0...1.0).contains(next.x))
        }
    }

    @Test(arguments: 0..<7)
    func changesAcrossMidnight(dayOffset: Int) {
        let states = CatWalkState.timelineDates(date: Self.dayStart.addingTimeInterval(Double(dayOffset * 24 + 21) * 60 * 60), count: 16, calendar: Self.calendar)
            .map { CatWalkState.timelineState(date: $0, calendar: Self.calendar, width: 1, walkingSpeed: 0.1) }

        for (previous, next) in zip(states, states.dropFirst()) {
            #expect(previous.activity != next.activity)
            #expect(previous.x != next.x)
        }
    }

    @Test func activitiesDoNotDependOnWidth() {
        let date = Self.dayStart.addingTimeInterval(13 * 60 * 60)

        #expect(
            CatWalkState.timelineState(date: date, calendar: Self.calendar, width: 1, walkingSpeed: 0.1).activity
                == CatWalkState.timelineState(date: date, calendar: Self.calendar, width: 300, walkingSpeed: 24).activity
        )
    }
}
