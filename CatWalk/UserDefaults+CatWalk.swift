import CatWalkCore
import Foundation

/// 猫の設定と状態の保存先。端末内の `UserDefaults` にだけ置き、外部へ送らない (プライバシーポリシーの記述と `documents/adr/0001-local-only-no-backend-infra.md`)。
extension UserDefaults {
    /// 保存に使うキー。保存形式のため、後の版でも変えない。
    private enum CatWalkKey {
        /// 猫のオーバーレイを出すか。
        static let isCatVisible = "isCatVisible"
        /// 猫の大きさ (`CatSize` の raw value)。
        static let catSize = "catSize"
        /// 猫の歩く速さ (`CatWalkingSpeed` の raw value)。
        static let walkingSpeed = "walkingSpeed"
        /// ディスプレイ ID の文字列ごとの `CatWalkState` の JSON。
        static let catWalkStates = "catWalkStates"
    }

    /// 猫のオーバーレイを出すか。保存が無い初回起動は、起動してすぐ猫が見えるよう出す。
    var catWalkIsCatVisible: Bool {
        get {
            object(forKey: CatWalkKey.isCatVisible) as? Bool ?? true
        }
        set {
            set(newValue, forKey: CatWalkKey.isCatVisible)
        }
    }

    /// 猫の大きさ。保存が無い時と読めない値の時は、立ち上げ時の大きさを引き継ぐ中にする。
    var catWalkSize: CatSize {
        get {
            string(forKey: CatWalkKey.catSize).flatMap(CatSize.init(rawValue:)) ?? .medium
        }
        set {
            set(newValue.rawValue, forKey: CatWalkKey.catSize)
        }
    }

    /// 猫の歩く速さ。保存が無い時と読めない値の時は、立ち上げ時の速さを引き継ぐふつうにする。
    var catWalkWalkingSpeed: CatWalkingSpeed {
        get {
            string(forKey: CatWalkKey.walkingSpeed).flatMap(CatWalkingSpeed.init(rawValue:)) ?? .normal
        }
        set {
            set(newValue.rawValue, forKey: CatWalkKey.walkingSpeed)
        }
    }

    /// ディスプレイの UUID の文字列 (`displayStorageKey(displayID:)`) ごとの猫の位置と行動。外したディスプレイの状態も、付け直した時に戻せるよう残す。
    /// 読めない値は、猫を出せなくなるより初回の状態から歩き直す方がよいため空として扱う。
    /// JSON にできない値 (NaN 等) の時は、前に保存した状態を消さないよう書き込まない。
    var catWalkStates: [String: CatWalkState] {
        get {
            data(forKey: CatWalkKey.catWalkStates).flatMap { try? JSONDecoder().decode([String: CatWalkState].self, from: $0) } ?? [:]
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue) else {
                return
            }
            set(data, forKey: CatWalkKey.catWalkStates)
        }
    }
}
