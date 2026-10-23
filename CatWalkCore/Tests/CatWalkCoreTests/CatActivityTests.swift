import Testing

@testable import CatWalkCore

struct CatActivityTests {
    @Test func zeroUnitRandomPicksFirstCandidate() {
        #expect(CatActivity.walking.nextActivity(unitRandom: 0) == .standing)
        #expect(CatActivity.standing.nextActivity(unitRandom: 0) == .walking)
    }

    @Test func unitRandomJustBelowOnePicksLastCandidate() {
        for activity in CatActivity.allCases {
            #expect(activity.nextActivity(unitRandom: 0.999_999) == activity.nextCandidates.last)
        }
    }

    @Test func zeroUnitRandomPicksLowerBoundDuration() {
        for activity in CatActivity.allCases {
            #expect(activity.duration(unitRandom: 0) == activity.durationRange.lowerBound)
        }
    }

    @Test func durationLowerBoundIsPositive() {
        for activity in CatActivity.allCases {
            #expect(activity.durationRange.lowerBound > 0)
        }
    }

    @Test func candidatesExcludeItself() {
        for activity in CatActivity.allCases {
            #expect(!activity.nextCandidates.contains(activity))
        }
    }

    @Test func everyActivityExceptDelightedIsReachable() {
        // 喜ぶ行動は撫でた時にだけ入る
        #expect(Set(CatActivity.allCases.flatMap(\.nextCandidates)) == Set(CatActivity.allCases).subtracting([.delighted]))
    }
}
