import CatWalkCore
import CoreGraphics
import Testing

@testable import CatWalk

struct CatWalkModelTests {
    @Test func dropPutsWalkingCatUnderReleasedPoint() {
        let model = CatWalkModel(walk: CatWalkState(x: 10, direction: .left, activity: .sleeping), catSize: 44, coat: .chatora, walkingSpeed: 24)
        model.travelWidth = 500
        defer {
            model.stop()
        }

        model.lift(center: CGPoint(x: 100, y: 50))
        model.drop()

        #expect(model.liftedCenter == nil)
        #expect(model.walk.x == 78)
        #expect(model.walk.direction == .left)
        #expect(model.walk.activity == .walking)
        #expect(model.previousWalkX == model.walk.x)
    }

    @Test func dropClampsIntoTravelWidth() {
        let model = CatWalkModel(walk: CatWalkState(), catSize: 44, coat: .chatora, walkingSpeed: 24)
        model.travelWidth = 500
        defer {
            model.stop()
        }

        model.lift(center: CGPoint(x: 900, y: 50))
        model.drop()

        #expect(model.walk.x == 500)
    }

    @Test func liftKeepsCatStillUntilDropped() {
        let model = CatWalkModel(walk: CatWalkState(x: 10, activity: .sitting, activityRemaining: 8), catSize: 44, coat: .chatora, walkingSpeed: 24)
        model.travelWidth = 500
        model.start()

        model.lift(center: CGPoint(x: 100, y: 50))
        model.start()

        #expect(model.liftedCenter == CGPoint(x: 100, y: 50))
        #expect(model.currentWalk == model.walk)
    }

    @Test func dropWithoutLiftDoesNothing() {
        let walk = CatWalkState(x: 10, activity: .sitting)
        let model = CatWalkModel(walk: walk, catSize: 44, coat: .chatora, walkingSpeed: 24)
        model.travelWidth = 500

        model.drop()

        #expect(model.walk == walk)
        #expect(model.currentWalk == walk)
    }

    @Test func narrowingTravelWidthClampsPreviousPosition() {
        let model = CatWalkModel(walk: CatWalkState(x: 400), catSize: 44, coat: .chatora, walkingSpeed: 24)
        model.travelWidth = 500

        model.travelWidth = 100

        #expect(model.walk.x == 100)
        #expect(model.previousWalkX == 100)
    }
}
