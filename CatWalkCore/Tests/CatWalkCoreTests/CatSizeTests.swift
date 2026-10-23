import Testing

@testable import CatWalkCore

struct CatSizeTests {
    @Test func keepsRawValuesAsStorageFormat() {
        #expect(CatSize.allCases.map(\.rawValue) == ["small", "medium", "large"])
    }

    @Test func mediumKeepsLaunchSize() {
        #expect(CatSize.medium.points == 44)
    }

    @Test func growsFromSmallToLarge() {
        #expect(CatSize.small.points < CatSize.medium.points)
        #expect(CatSize.medium.points < CatSize.large.points)
    }
}
