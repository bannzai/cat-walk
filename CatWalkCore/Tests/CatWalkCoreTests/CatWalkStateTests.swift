import Foundation
import Testing

@testable import CatWalkCore

@Suite(.timeLimit(.minutes(1)))
struct CatWalkStateTests {
    @Test func movesInFacingDirectionWhileWalking() {
        var random = ZeroRandomNumberGenerator()

        #expect(CatWalkState(x: 10, direction: .right).advanced(elapsedSeconds: 1, width: 100, walkingSpeed: 24, random: &random).x == 34)
    }

    @Test func turnsBackAtRightEdge() {
        var random = ZeroRandomNumberGenerator()
        let next = CatWalkState(x: 90, direction: .right).advanced(elapsedSeconds: 1, width: 100, walkingSpeed: 24, random: &random)

        #expect(next.x == 86)
        #expect(next.direction == .left)
    }

    @Test func turnsBackAtLeftEdge() {
        var random = ZeroRandomNumberGenerator()
        let next = CatWalkState(x: 10, direction: .left).advanced(elapsedSeconds: 1, width: 100, walkingSpeed: 24, random: &random)

        #expect(next.x == 14)
        #expect(next.direction == .right)
    }

    @Test func foldsDistanceLongerThanRoundTrip() {
        var random = ZeroRandomNumberGenerator()
        let next = CatWalkState(x: 0, direction: .right).advanced(elapsedSeconds: 5, width: 100, walkingSpeed: 100, random: &random)

        #expect(next.x == 100)
        #expect(next.direction == .left)
    }

    @Test func staysStillWhileNotWalking() {
        var random = ZeroRandomNumberGenerator()

        #expect(CatWalkState(x: 10, activity: .sitting).advanced(elapsedSeconds: 1, width: 100, walkingSpeed: 24, random: &random).x == 10)
    }

    @Test func tracksElapsedAndRemainingInActivity() {
        var random = ZeroRandomNumberGenerator()
        let next = CatWalkState(activityRemaining: 5).advanced(elapsedSeconds: 1, width: 100, walkingSpeed: 24, random: &random)

        #expect(next.activity == .walking)
        #expect(next.activityElapsed == 1)
        #expect(next.activityRemaining == 4)
    }

    @Test func transitionsWalkingStandingWalkingWithZeroRandom() {
        var random = ZeroRandomNumberGenerator()
        let standing = CatWalkState().advanced(elapsedSeconds: 5, width: 1000, walkingSpeed: 24, random: &random)

        #expect(standing.activity == .standing)
        #expect(standing.activityElapsed == 0)
        #expect(standing.activityRemaining == CatActivity.standing.durationRange.lowerBound)

        let walking = standing.advanced(elapsedSeconds: 2, width: 1000, walkingSpeed: 24, random: &random)

        #expect(walking.activity == .walking)
        #expect(walking.activityRemaining == CatActivity.walking.durationRange.lowerBound)
    }

    @Test func crossesSeveralActivitiesInOneCall() {
        var random = ZeroRandomNumberGenerator()
        let next = CatWalkState().advanced(elapsedSeconds: 7, width: 1000, walkingSpeed: 24, random: &random)

        // 最初の 5 秒だけ歩き、立ち止まる 2 秒の間は動かない
        #expect(next.x == 120)
        #expect(next.activity == .walking)
        #expect(next.activityRemaining == CatActivity.walking.durationRange.lowerBound)
    }

    @Test func followsFixedSeedSequence() {
        var random = SplitMix64(state: 42)
        var state = CatWalkState()
        var activities = [state.activity]
        for _ in 0..<7 {
            state = state.advanced(elapsedSeconds: state.activityRemaining, width: 300, walkingSpeed: 24, random: &random)
            activities.append(state.activity)
        }

        // SplitMix64・unitRandom・候補表・滞在時間を同じ式で Python に写して再計算した並び
        #expect(activities == [.walking, .grooming, .sitting, .standing, .walking, .sitting, .standing, .sitting])
    }

    @Test func clampsIntoNarrowedWidth() {
        var random = ZeroRandomNumberGenerator()

        #expect(CatWalkState(x: 500, activity: .sitting).advanced(elapsedSeconds: 1, width: 100, walkingSpeed: 24, random: &random).x == 100)
    }

    @Test func staysAtZeroWhenWidthIsZero() {
        var random = ZeroRandomNumberGenerator()

        #expect(CatWalkState(x: 10).advanced(elapsedSeconds: 1, width: 0, walkingSpeed: 24, random: &random).x == 0)
    }

    @Test func staysInRangeAndTransitionsAlongCandidatesOverLongRun() throws {
        // 1 秒刻みで進めるため、どの行動も 1 秒より長く続かないと 1 刻みの間の遷移を見落とす
        try #require(CatActivity.allCases.allSatisfy { $0.durationRange.lowerBound > 1 })

        var random = SplitMix64(state: 42)
        var state = CatWalkState()
        var seenActivities: Set<CatActivity> = [state.activity]
        for _ in 0..<10_000 {
            let next = state.advanced(elapsedSeconds: 1, width: 300, walkingSpeed: 24, random: &random)
            #expect((0.0...300.0).contains(next.x))
            if next.activity != state.activity {
                #expect(state.activity.nextCandidates.contains(next.activity))
            }
            seenActivities.insert(next.activity)
            state = next
        }

        #expect(seenActivities == Set(CatActivity.allCases).subtracting([.delighted]))
    }

    @Test func pettedEntersDelightedAndKeepsPosition() {
        let petted = CatWalkState(x: 30, direction: .left, activity: .sleeping, activityElapsed: 10, activityRemaining: 50).petted()

        #expect(petted == CatWalkState(x: 30, direction: .left, activity: .delighted, activityElapsed: 0, activityRemaining: CatActivity.delighted.durationRange.lowerBound))
    }

    @Test func returnsFromDelightedToCandidate() {
        var random = ZeroRandomNumberGenerator()
        let next = CatWalkState().petted().advanced(elapsedSeconds: CatActivity.delighted.durationRange.lowerBound, width: 100, walkingSpeed: 24, random: &random)

        #expect(next.activity == CatActivity.delighted.nextCandidates.first)
    }

    @Test func sameSeedGivesSameState() {
        var firstRandom = SplitMix64(state: 7)
        var secondRandom = SplitMix64(state: 7)

        #expect(
            CatWalkState().advanced(elapsedSeconds: 600, width: 300, walkingSpeed: 24, random: &firstRandom)
                == CatWalkState().advanced(elapsedSeconds: 600, width: 300, walkingSpeed: 24, random: &secondRandom)
        )
    }

    @Test func clampsPositionIntoNarrowedWidth() {
        #expect(CatWalkState(x: 900, activity: .sleeping).clamped(width: 500).x == 500)
        #expect(CatWalkState(x: -10).clamped(width: 500).x == 0)
        #expect(CatWalkState(x: 200).clamped(width: 500).x == 200)
        #expect(CatWalkState(x: 200).clamped(width: -1).x == 0)
    }

    @Test func clampingKeepsActivity() {
        let state = CatWalkState(x: 900, direction: .left, activity: .sleeping, activityElapsed: 3, activityRemaining: 42)

        let clamped = state.clamped(width: 500)

        #expect(clamped.direction == .left)
        #expect(clamped.activity == .sleeping)
        #expect(clamped.activityElapsed == 3)
        #expect(clamped.activityRemaining == 42)
    }

    @Test func updatesEveryTickWhileWalking() {
        #expect(CatWalkState(activity: .walking, activityRemaining: 10).secondsUntilNextUpdate(walkingTickSeconds: 1) == 1)
    }

    @Test func updatesAtEndOfWalkingWhenShorterThanTick() {
        #expect(CatWalkState(activity: .walking, activityRemaining: 0.25).secondsUntilNextUpdate(walkingTickSeconds: 1) == 0.25)
    }

    @Test func waitsUntilActivityEndsWhileNotWalking() {
        for activity in CatActivity.allCases where activity != .walking {
            #expect(CatWalkState(activity: activity, activityRemaining: 42).secondsUntilNextUpdate(walkingTickSeconds: 1) == 42)
        }
    }

    @Test func updatesImmediatelyWhenActivityHasNoTimeLeft() {
        #expect(CatWalkState(activity: .sleeping, activityRemaining: -3).secondsUntilNextUpdate(walkingTickSeconds: 1) == 0)
        #expect(CatWalkState(activity: .walking, activityRemaining: 0).secondsUntilNextUpdate(walkingTickSeconds: 1) == 0)
    }

    @Test func walkingStartsOnFirstStep() {
        #expect(CatWalkState().walkingStep(stepSeconds: 1) == 0)
    }

    @Test func walkingStepAlternatesEveryStepSeconds() {
        let steps = (0..<5).map { CatWalkState(activity: .walking, activityElapsed: Double($0)).walkingStep(stepSeconds: 1) }

        #expect(steps == [0, 1, 0, 1, 0])
    }

    @Test func walkingStepKeepsAlternatingWithJitteredUpdates() {
        let steps = [0.98, 2.03, 2.97, 4.01].map { CatWalkState(activity: .walking, activityElapsed: $0).walkingStep(stepSeconds: 1) }

        #expect(steps == [1, 0, 1, 0])
    }

    @Test func walkingStepRoundsPartialTick() {
        #expect(CatWalkState(activity: .walking, activityElapsed: 4.4).walkingStep(stepSeconds: 1) == 0)
        #expect(CatWalkState(activity: .walking, activityElapsed: 4.6).walkingStep(stepSeconds: 1) == 1)
    }

    @Test func roundTripsThroughCodable() throws {
        let state = CatWalkState(x: 12.5, direction: .left, activity: .sleeping, activityElapsed: 3, activityRemaining: 40)

        #expect(try JSONDecoder().decode(CatWalkState.self, from: JSONEncoder().encode(state)) == state)
    }
}
