import CatWalkCore
import Testing

struct CatWalkSmokeTests {
    @Test func coreIsLinkedIntoTestBundle() {
        let state = CatWalkState(x: 0, direction: .right, stride: 1)

        #expect(state.step(in: 10).x == 1)
    }
}
