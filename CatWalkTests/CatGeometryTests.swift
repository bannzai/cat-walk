import CoreGraphics
import Testing

@testable import CatWalk

struct CatGeometryTests {
    @Test func walkingRectIsOffsetByPanelOrigin() {
        let rect = walkingCatScreenRect(panelFrame: CGRect(x: 100, y: 50, width: 800, height: 600), walkX: 30, catSize: 44)

        #expect(rect == CGRect(x: 130, y: 72, width: 44, height: 44))
    }

    @Test func walkingRectFollowsCatSize() {
        let rect = walkingCatScreenRect(panelFrame: CGRect(x: 0, y: 0, width: 800, height: 600), walkX: 200, catSize: 32)

        #expect(rect == CGRect(x: 200, y: 16, width: 32, height: 32))
    }

    @Test func pointBesideCatIsOutsideWalkingRect() {
        let rect = walkingCatScreenRect(panelFrame: CGRect(x: 0, y: 0, width: 800, height: 600), walkX: 200, catSize: 44)

        #expect(rect.contains(CGPoint(x: 222, y: 44)))
        #expect(!rect.contains(CGPoint(x: 260, y: 44)))
        #expect(!rect.contains(CGPoint(x: 222, y: 120)))
    }

    @Test func interpolatesHalfwayThroughAnimation() {
        #expect(interpolatedWalkX(previousWalkX: 10, walkX: 58, elapsedSeconds: 0.5, durationSeconds: 1) == 34)
        #expect(interpolatedWalkX(previousWalkX: 58, walkX: 10, elapsedSeconds: 0.25, durationSeconds: 1) == 46)
    }

    @Test func interpolationStaysAtEndpoints() {
        #expect(interpolatedWalkX(previousWalkX: 10, walkX: 58, elapsedSeconds: -1, durationSeconds: 1) == 10)
        #expect(interpolatedWalkX(previousWalkX: 10, walkX: 58, elapsedSeconds: 120, durationSeconds: 1) == 58)
        #expect(interpolatedWalkX(previousWalkX: 10, walkX: 58, elapsedSeconds: 0, durationSeconds: 0) == 58)
    }

    @Test func liftedCenterFlipsWindowCoordinatesToTopLeftOrigin() {
        #expect(liftedCatCenter(locationInWindow: CGPoint(x: 300, y: 100), panelSize: CGSize(width: 800, height: 600), catSize: 44) == CGPoint(x: 300, y: 500))
    }

    @Test func liftedCenterStaysInsidePanel() {
        let panelSize = CGSize(width: 800, height: 600)

        #expect(liftedCatCenter(locationInWindow: CGPoint(x: -50, y: 700), panelSize: panelSize, catSize: 44) == CGPoint(x: 22, y: 22))
        #expect(liftedCatCenter(locationInWindow: CGPoint(x: 900, y: -20), panelSize: panelSize, catSize: 44) == CGPoint(x: 778, y: 578))
    }
}
