import CatWalkCore
import Testing

struct CatWalkSmokeTests {
    @Test func coreIsLinkedIntoTestBundle() {
        var random = SystemRandomNumberGenerator()

        #expect(CatWalkState(x: 0, direction: .right).advanced(elapsedSeconds: 1, width: 10, walkingSpeed: 1, random: &random).x == 1)
    }
}
