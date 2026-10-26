import Foundation

/// 設定で選べる猫の色・柄。絵は `tools/cat-art/cat-art.mjs` の `coats` と同じ名前で、Asset Catalog の画像名 `cat-<柄>-<姿勢>` になる。
/// 保存した設定と Live Activity の属性を後の版でも読めるよう、raw value を保存形式として固定する。
public enum CatCoat: String, CaseIterable, Codable, Sendable {
    /// 茶トラ。
    case chatora
    /// 三毛。
    case mike
    /// 黒。
    case kuro
    /// 白。
    case shiro
    /// サバトラ。
    case sabatora
    /// ハチワレ。
    case hachiware
}

/// iOS・watchOS のアプリとウィジェット (コンプリケーション) が設定を共有する App Group。各 target の entitlements の `com.apple.security.application-groups` と揃える。
/// App Group は端末の中だけで共有されるため、iPhone と Apple Watch の設定はそれぞれの端末で別に持つ。
public let catWalkAppGroupIdentifier = "group.com.bannzai.CatWalk"

extension UserDefaults {
    /// 猫の色・柄を保存するキー。保存形式のため、後の版でも変えない。
    private static let catWalkCoatKey = "catCoat"

    /// iOS・watchOS のアプリとウィジェットが共有する保存先。端末内にだけ置き、外部へ送らない (`documents/adr/0001-local-only-no-backend-infra.md`)。
    /// `UserDefaults(suiteName:)` が nil を返すのは suite 名が使えない名前の時だけで、固定の識別子では起きない。起きても設定画面を動かせるよう、アプリだけの保存先にする (その時ウィジェットは既定の柄で描く)。
    /// `UserDefaults` は Sendable ではないため、グローバルに持たず呼ぶたびに作る。
    public static var catWalkShared: UserDefaults {
        UserDefaults(suiteName: catWalkAppGroupIdentifier) ?? .standard
    }

    /// 猫の色・柄。保存が無い時と読めない値の時は、色・柄を選べるようになる前からアプリに入っていた茶トラにし、更新した人の猫の見た目を変えない。
    public var catWalkCoat: CatCoat {
        get {
            string(forKey: Self.catWalkCoatKey).flatMap(CatCoat.init(rawValue:)) ?? .chatora
        }
        set {
            set(newValue.rawValue, forKey: Self.catWalkCoatKey)
        }
    }
}
