# App Privacy の回答

App Store Connect の App Privacy (「App のプライバシー」) には「データを収集しない」と答える。回答の定義は `fastlane/app_privacy_details.json` (`DATA_NOT_COLLECTED` の 1 エントリ) で、`bash ~/.agents/skills/appstore-app-privacy/scripts/privacy_validate_json.sh fastlane/app_privacy_details.json` で検証する。App Store Connect への適用は申請時に appstore-app-privacy skill で行う。

## 根拠

2026-10-26 に、このリポジトリで次を確かめた。

- 外部の SDK を入れていない: `CatWalk.xcodeproj/project.pbxproj` の Swift Package の参照は、リポジトリ内のローカルパッケージ `CatWalkCore` (`XCLocalSwiftPackageReference "CatWalkCore"`) だけで、`XCRemoteSwiftPackageReference` は 0 件。`CatWalkCore/Package.swift` も外部のパッケージに依存しない
- アプリが通信しない: Swift のソース全体を `URLSession|import Network|NWConnection|WKWebView|Firebase|Analytics|URLRequest` で検索して 0 件
- 設定と猫の状態は端末の中にだけ置く: macOS の保存先は `UserDefaults` (`CatWalk/UserDefaults+CatWalk.swift`)。iOS の Live Activity は ActivityKit にアプリから状態を渡すだけで、push の token を取得・送信していない (`CatWalkiOS/CatWalkActivity.swift`)
- お問い合わせは `mailto:` のリンク (`CatWalkCore/Sources/CatWalkCore/CatWalkSupportLinks.swift` の `catWalkContactURL`) で、利用者のメールアプリを開くだけ。送るかどうかと送る内容は利用者が決め、アプリはメールの内容を受け取らない
- Analytics・Crashlytics を入れない方針: `documents/adr/0001-local-only-no-backend-infra.md`

利用規約・プライバシーポリシーの Web ページ (GitHub Pages) は、アプリの外のブラウザで開く。

## 見直す時

外部の SDK・通信・課金を足す時は、この回答を見直し、appstore-app-privacy skill の `references/sdk_privacy_answers.md` で回答を決め直す。プライバシーポリシー (`docs/PrivacyPolicy-ja.md`・`docs/PrivacyPolicy-en.md`) も合わせて直す。
