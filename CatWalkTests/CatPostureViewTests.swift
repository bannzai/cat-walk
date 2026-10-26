import AppKit
import CatWalkCore
import Testing

@testable import CatWalk

struct CatPostureViewTests {
    @Test func mapsEachActivityToItsPose() {
        let names = CatActivity.allCases.map { CatWalkState(activity: $0).artworkName(isLifted: false, isMonochrome: false) }

        #expect(names == ["cat-walk1", "cat-stand", "cat-sit", "cat-sleep", "cat-groom", "cat-delighted"])
    }

    @Test func walkingAlternatesTwoFrames() {
        let names = [0.0, CatPostureView.walkingStepSeconds].map { CatWalkState(activity: .walking, activityElapsed: $0).artworkName(isLifted: false, isMonochrome: false) }

        #expect(names == ["cat-walk1", "cat-walk2"])
    }

    @Test func liftedOverridesActivity() {
        for activity in CatActivity.allCases {
            #expect(CatWalkState(activity: activity).artworkName(isLifted: true, isMonochrome: false) == "cat-lifted")
        }
    }

    @Test func monochromeUsesMonoVariant() {
        #expect(CatWalkState(activity: .sleeping).artworkName(isLifted: false, isMonochrome: true) == "cat-sleep-mono")
        #expect(CatWalkState().artworkName(isLifted: true, isMonochrome: true) == "cat-lifted-mono")
    }

    /// テストのホストは macOS アプリのため、アプリに同梱した Asset Catalog から絵を読めることを確かめる。
    @Test func everyArtworkResolvesInAppBundle() {
        let walks = CatActivity.allCases.map { CatWalkState(activity: $0) } + [CatWalkState(activity: .walking, activityElapsed: CatPostureView.walkingStepSeconds)]
        for walk in walks {
            for isLifted in [false, true] {
                for isMonochrome in [false, true] {
                    let name = walk.artworkName(isLifted: isLifted, isMonochrome: isMonochrome)
                    #expect(NSImage(named: name) != nil, "\(name) が Asset Catalog に無い")
                }
            }
        }
    }
}
