import AppKit
import CatWalkCore
import Testing

@testable import CatWalk

struct CatPostureViewTests {
    @Test func mapsEachActivityToItsPose() {
        let names = CatActivity.allCases.map { CatWalkState(activity: $0).artworkName(coat: .chatora, isLifted: false, isMonochrome: false) }

        #expect(names == ["cat-chatora-walk1", "cat-chatora-stand", "cat-chatora-sit", "cat-chatora-sleep", "cat-chatora-groom", "cat-chatora-delighted"])
    }

    @Test func colorArtworkUsesTheChosenCoat() {
        let names = CatCoat.allCases.map { CatWalkState(activity: .sitting).artworkName(coat: $0, isLifted: false, isMonochrome: false) }

        #expect(names == ["cat-chatora-sit", "cat-mike-sit", "cat-kuro-sit", "cat-shiro-sit", "cat-sabatora-sit", "cat-hachiware-sit"])
    }

    @Test func walkingAlternatesTwoFrames() {
        let names = [0.0, CatPostureView.walkingStepSeconds].map { CatWalkState(activity: .walking, activityElapsed: $0).artworkName(coat: .kuro, isLifted: false, isMonochrome: false) }

        #expect(names == ["cat-kuro-walk1", "cat-kuro-walk2"])
    }

    @Test func liftedOverridesActivity() {
        for activity in CatActivity.allCases {
            #expect(CatWalkState(activity: activity).artworkName(coat: .mike, isLifted: true, isMonochrome: false) == "cat-mike-lifted")
        }
    }

    @Test func monochromeIsSharedByEveryCoat() {
        for coat in CatCoat.allCases {
            #expect(CatWalkState(activity: .sleeping).artworkName(coat: coat, isLifted: false, isMonochrome: true) == "cat-sleep-mono")
            #expect(CatWalkState().artworkName(coat: coat, isLifted: true, isMonochrome: true) == "cat-lifted-mono")
        }
    }

    @Test func mirrorsOnlyWhenFacingLeft() {
        #expect(!CatWalkState(direction: .right, activity: .walking).isArtworkMirrored(isLifted: false))
        #expect(CatWalkState(direction: .left, activity: .walking).isArtworkMirrored(isLifted: false))
    }

    @Test func doesNotMirrorSleepingSoTheZStaysReadable() {
        #expect(!CatWalkState(direction: .left, activity: .sleeping).isArtworkMirrored(isLifted: false))
        #expect(CatWalkState(direction: .left, activity: .sleeping).isArtworkMirrored(isLifted: true))
    }

    /// テストのホストは macOS アプリのため、アプリに同梱した Asset Catalog から全柄・全姿勢の絵を読めることを確かめる。
    @Test func everyArtworkResolvesInAppBundle() {
        let walks = CatActivity.allCases.map { CatWalkState(activity: $0) } + [CatWalkState(activity: .walking, activityElapsed: CatPostureView.walkingStepSeconds)]
        for coat in CatCoat.allCases {
            for walk in walks {
                for isLifted in [false, true] {
                    for isMonochrome in [false, true] {
                        let name = walk.artworkName(coat: coat, isLifted: isLifted, isMonochrome: isMonochrome)
                        #expect(NSImage(named: name) != nil, "\(name) が Asset Catalog に無い")
                    }
                }
            }
        }
    }
}
