import CatWalkCore
import Foundation
import WidgetKit

/// iOS・watchOS の設定画面で選んだ柄 `coat` を、ウィジェット (コンプリケーション) と共有する保存先に書き、ウィジェットを描き直させる。
/// ウィジェットはタイムラインを作る時に柄を読むため、描き直させないと次の再読み込み (最長 4 時間後) まで前の柄のまま残る。同じ値で何度呼んでも結果は同じ (冪等)。
func saveSharedCatCoat(coat: CatCoat) {
    UserDefaults.catWalkShared.catWalkCoat = coat
    WidgetCenter.shared.reloadAllTimelines()
}
