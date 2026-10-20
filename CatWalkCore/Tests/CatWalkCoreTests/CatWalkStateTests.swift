import Testing

@testable import CatWalkCore

struct CatWalkStateTests {
    @Test func movesInFacingDirection() {
        let state = CatWalkState(x: 10, direction: .right, stride: 5)

        #expect(state.step(in: 100).x == 15)
    }

    @Test func turnsBackAtRightEdge() {
        let state = CatWalkState(x: 98, direction: .right, stride: 5)
        let next = state.step(in: 100)

        #expect(next.x == 100)
        #expect(next.direction == .left)
    }

    @Test func turnsBackAtLeftEdge() {
        let state = CatWalkState(x: 2, direction: .left, stride: 5)
        let next = state.step(in: 100)

        #expect(next.x == 0)
        #expect(next.direction == .right)
    }
}
