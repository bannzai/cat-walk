# iOS 27 の変更点の調査 (cat-walk 向け)

調査日: 2026-10-21。目的: 「iOS のフルスクリーンウィジェット」が iOS 27 で可能になったかと、cat-walk の iOS 設計 (ホーム画面・ロック画面ウィジェット + Live Activity) を見直す必要があるかを確かめる。

## 結論

- **iOS 27 でホーム画面 1 ページ分の「特大 (extra large) ウィジェット」が追加され、第三者アプリも提供できる。** WidgetKit の `WidgetFamily.systemExtraLargePortrait` が iOS 27.0 / macOS 27.0 で使える (このマシンの Xcode 27.1 の iOS SDK の `WidgetKit.swiftinterface` で `@available(iOS 27.0, macOS 27.0, visionOS 26.0, *)` を確認)。サイズは 4×6 で iPhone の縦向きではホーム画面 1 ページを占める。既存のウィジェットとタイムラインプロバイダをそのまま使い、`supportedFamilies` に足すだけでよい
- **ただし「ウィジェットの中で猫が歩き続ける」制約は変わっていない。** 更新は 1 日あたりの予算 (目安 15〜60 分に 1 回) のまま、アニメーションは更新の瞬間の遷移だけ。iOS 27 の「アプリを開いている間はウィジェットがリアルタイムに更新される」は Apple の一覧 (Sweating the Details) に項目名だけあり、公式の技術説明は未確認。WWDC26 のセッションは「フォアグラウンドでの頻繁なリロードは絞られることがある」と述べている
- **Live Activity は iOS 27 で Dynamic Island が横向きでも出る**ようになり (`\.isDynamicIslandLimitedInWidth` 環境値が iOS 27.0 で追加。SDK で確認)、StandBy (充電中の横向き全画面、ロック画面の view を 200% に拡大)・Apple Watch の Smart Stack・Mac のメニューバー・CarPlay に自動転送される。8 時間の上限・4 KB・ネットワーク不可の変更は確認できなかった
- **壁紙やホーム画面の上を自由に歩かせる API は iOS 27 にも無い**。cat-walk の iOS の表現は「特大ウィジェット 1 ページを猫の部屋にして、更新の瞬間に姿勢と位置が変わる」が上限

## 事実 (出典付き)

| 項目 | 内容 | 出典 |
| --- | --- | --- |
| 特大ウィジェットの API | `WidgetFamily.systemExtraLargePortrait`。`@available(iOS 27.0, macOS 27.0, visionOS 26.0, *)`、tvOS / watchOS は unavailable | Xcode 27.1 の iOS SDK `WidgetKit.framework/Modules/WidgetKit.swiftmodule/arm64e-apple-ios.swiftinterface` (2026-10-21 に grep) |
| 同上 (Apple の説明) | "The system extra large portrait family was introduced in visionOS 26. New in macOS, iOS, and iPadOS 27, the system extra large portrait family is now available." 既存の widget と timeline provider を再利用して新サイズの view を作る | WWDC26 WidgetKit foundations https://developer.apple.com/videos/play/wwdc2026/277/ |
| サイズと操作 | 4×6 グリッド。iPhone の縦向きではホーム画面 1 ページを占める。iPhone は縦向きのみ、iPad は横向きのみ、Mac は両方。既存ウィジェットを長押しして右下のハンドルで拡大できる | Apple Unfiltered (Developer Beta 1 時点) https://appleunfiltered.substack.com/p/ios-27s-full-page-widgets-make-your 、9to5Mac https://9to5mac.com/2026/10/14/ios-27-adds-brand-new-widgets-for-your-iphones-home-screen/ |
| 第三者アプリの対応 | LookUp・Mercury Weather・Launcher・Lock Launcher が特大ウィジェットを出荷済み | MacStories の iOS 27 レビュー https://www.macstories.net/stories/ios-and-ipados-27-review/3/ 。Home Assistant の実装 PR https://github.com/home-assistant/iOS/pull/5789 (large と同じ幅で約 2 倍の高さ) |
| 更新頻度 | "each widget is given a budget for updates" のまま。"frequent reloads while your app is in the foreground might be throttled" | WWDC26 WidgetKit foundations (同上) |
| アプリを開いている間のリアルタイム更新 | WWDC26 の "Sweating the Details" の一覧に項目名だけ。Apple の技術説明は未確認 (開発者フォーラムでも仕組みを問う投稿あり) | TidBITS https://tidbits.com/2026/06/11/all-264-items-on-apples-wwdc26-sweating-the-details-slide/ |
| Live Activity の横向き | "In iOS 27, the Dynamic Island compact and minimal views are visible in both portrait and landscape." 横向きでは幅が固定され、`@Environment(\.isDynamicIslandLimitedInWidth)` で分岐する | WWDC26 Live Activities essentials https://developer.apple.com/videos/play/wwdc2026/223/ 。SDK で `@available(iOS 27.0, *)` を確認 |
| Live Activity の表示先 | StandBy (ロック画面の view を 200% 拡大)、Apple Watch の Smart Stack、macOS のメニューバー、CarPlay に自動転送。Watch / CarPlay は `.supplementalActivityFamilies([.small])` で専用の見た目 | 同上 |
| ロック画面 | 時計を小さくして上の行に寄せられる、Now Playing をスワイプで消せる (再生は止まらない)。ウィジェットの新 API は無し | MacStories (同上)、9to5Mac https://9to5mac.com/2026/08/05/ios-27-lock-screen-customization/ |
| StandBy | iOS 27 固有の変更は見つからず。Live Activity の表示先として言及されるのみ | 検索結果に該当なし (不在の証明ではない) |
| ウィジェットのその他 | "widgets can now be customized through App Intents and dynamic styling" | WWDC26 iOS guide https://developer.apple.com/wwdc26/guides/ios/ |

## 未確認

- Apple の iOS 27 release notes と WidgetKit / ActivityKit のドキュメントページは WebFetch で本文が取れず (JavaScript 描画)、SDK の swiftinterface と WWDC のトランスクリプトで代替した
- 「アプリを開いている間のリアルタイム更新」の正確な仕様 (予算に数えるか、頻度)
- Live Activity の 8 時間上限・staleDate の挙動の iOS 27 での変更の有無 (SDK の `ActivityContent(state:staleDate:relevanceScore:)` に変化なし)
- 特大ウィジェットが StandBy に出るか

## cat-walk への影響と提案

1. **iOS の「必要な機能」に特大ウィジェット (`systemExtraLargePortrait`) を足す。** ホーム画面 1 ページ全体を猫の部屋 (床・窓・家具) にし、タイムラインで 15 分ごとに猫の位置と姿勢が変わる。「フルスクリーンウィジェット」の要望に iOS 27 の正規の手段で応えられる。既存の `CatWalkWidget` に family を 1 つ足し、専用の view を作るだけで済む (#8 の延長。新しい子 issue にする)。deployment target が 26.0 のため `#available(iOS 27, *)` で分岐する
2. **Live Activity (#10、PR #23) に iOS 27 の横向き Dynamic Island の対応を足す** (`isDynamicIslandLimitedInWidth` で compact を幅固定の表現にする)。StandBy でロック画面の view が 200% になるため、ロック画面の view を大きく表示しても崩れない作りにする
3. **「歩き続ける」はウィジェットでは引き続き不可能**。歩き続けを見せたいなら、アプリ本体を全画面にした時 (今の「部屋を歩く 1 画面」) に限られる。構想 (DIRECTION.md) の「更新の瞬間に動いて見える」の方針は変えなくてよい

## セッション再開

```sh
cd /Users/bannzai/ghq/github.com/bannzai/cat-walk
claude --resume 4d7f1b77-65ff-4a3b-acee-fce246455559
```
