import SwiftUI
import WidgetKit

/// iOS の Widget Extension の入口。ホーム画面・ロック画面のウィジェットと、散歩に出した猫の Live Activity を 1 つの extension で提供する。
@main
struct CatWalkWidgetBundle: WidgetBundle {
    var body: some Widget {
        CatWalkWidget()
        CatWalkLiveActivity()
    }
}
