import Testing

@testable import CatWalkCore

struct CatWalkingSpeedTests {
    @Test func keepsRawValuesAsStorageFormat() {
        #expect(CatWalkingSpeed.allCases.map(\.rawValue) == ["slow", "normal", "fast"])
    }

    @Test func normalKeepsDefaultWalkingSpeed() {
        #expect(CatWalkingSpeed.normal.pointsPerSecond == CatWalkState.defaultWalkingSpeed)
    }

    @Test func getsFasterFromSlowToFast() {
        #expect(CatWalkingSpeed.slow.pointsPerSecond < CatWalkingSpeed.normal.pointsPerSecond)
        #expect(CatWalkingSpeed.normal.pointsPerSecond < CatWalkingSpeed.fast.pointsPerSecond)
    }
}
