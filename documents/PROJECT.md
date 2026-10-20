# Cat Walk

猫が画面の上を散歩する macOS / iOS / watchOS アプリ。方向性 (仮説・判定基準・決めたこと) は `documents/DIRECTION.md`。

## コンセプト

Mac で作業する人 (と同じ人の iPhone / Apple Watch) に、作業の邪魔にならない常駐の癒しとして、画面の上を歩き回る 1 匹の猫を出す。macOS では透明でクリックを通す最前面のウィンドウの中を猫が歩き、iOS ではウィジェット・Live Activity・Dynamic Island で、watchOS ではコンプリケーションと watch アプリで、同じ猫が「動いて見える」。ログイン・サーバー・広告・育成要素を持たない。

## 対象ユーザーと場面

- Mac で長時間作業する人 (開発者・デザイナー・事務作業の人)
- 作業中に視界の端で動く小さな癒しが欲しいが、邪魔になるものは嫌な人
- 同じ人が iPhone のホーム画面・ロック画面・Dynamic Island と Apple Watch の文字盤でも同じ猫を見る
- 場面は、全画面のアプリを使っている時、複数ディスプレイで作業している時を含む

## 機能 (MVP)

### macOS

- メニューバー常駐 (`MenuBarExtra`、Dock に出ない) と、透明・クリック透過・最前面のオーバーレイ。全 Space・他アプリのフルスクリーン・複数ディスプレイの上に出る
- 猫の歩行の状態機械 (歩く・立ち止まる・座る・眠る・毛づくろい)。画面下端を歩く。CPU はアイドル時 1% 未満を目標
- 猫をドラッグで持ち上げて置ける (猫の上だけマウスを受け、それ以外はクリックを通す)
- 設定: 猫の表示 / 非表示、サイズ、歩く速さ、ログイン時に起動。状態 (位置・設定) の保存

### iOS

- ホーム画面・ロック画面ウィジェット (猫の姿勢と位置をタイムラインで切り替え、タップで反応)
- Live Activity / Dynamic Island で猫が歩く (最大 8 時間)
- アプリ本体: 猫が歩く画面と撫でる操作

### watchOS

- コンプリケーション (accessory widget) と watch アプリ (前面では通常のアニメーション、Always On では静止)

### 共通

- 歩行ロジックを共有する Swift Package (`CatWalkCore`) と、3 OS で同じ猫の見た目 (デザインの段階で決める)
- 利用規約・プライバシーポリシー・紹介サイト (GitHub Pages) と、設定画面からの導線

### MVP に入れないもの (後続)

- 育成・餌・ミニゲーム
- 複数の猫
- 自分の猫の柄の再現
- 季節のイベント
- 課金

## 技術

- SwiftUI、Swift 6、deployment target 26.0
- ローカル Swift Package `CatWalkCore` に歩行の状態機械
- macOS: `NSPanel` (`nonactivatingPanel`・`ignoresMouseEvents`・`canJoinAllSpaces` / `fullScreenAuxiliary` / `stationary`) と `MenuBarExtra` (`LSUIElement`)。App Sandbox 有効 [^collection]
- iOS: WidgetKit (更新は 1 日 40〜70 回、アニメーションは最大 2 秒) [^widget-update] [^widget-animation] と ActivityKit (最大 8 時間・4 KB) [^activity]
- watchOS: accessory widget

[^collection]: `NSWindow.CollectionBehavior` (`canJoinAllSpaces`・`fullScreenAuxiliary`・`stationary`): https://developer.apple.com/documentation/appkit/nswindow/collectionbehavior-swift.struct
[^widget-update]: ウィジェットの更新頻度: https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date
[^widget-animation]: ウィジェットのアニメーション: https://developer.apple.com/documentation/widgetkit/animating-data-updates-in-widgets-and-live-activities
[^activity]: Live Activity の継続時間とデータ量: https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities

## 配信・計測

- 配信先は Mac App Store と App Store (iOS / watchOS)
- 計測は App Store のレビュー (appstore-research skill) と App Store Connect の表示回数
- Analytics・Crashlytics は入れない (`documents/adr/0001-local-only-no-backend-infra.md`。このブランチには無いファイルだが PR #1 で入るので参照だけ書く)

## 参考にした競合

- Pets Therapy (macOS、無料、窓の縁を歩く): https://apps.apple.com/us/app/pets-therapy-desktop-pets/id1575542220
- Dockitty (macOS、Dock の猫): https://apps.apple.com/us/app/dockitty-a-cat-in-your-dock/id6743999434
- RunCat Neo (macOS メニューバー): https://apps.apple.com/us/app/runcat-neo/id6757801838
- Pixel Pals (iOS、Dynamic Island): https://apps.apple.com/us/app/pixel-pals-widget-pet-game/id6443919232
- Watch Pet (watchOS): https://apps.apple.com/us/app/watch-pet-widget-watch-pets/id1548674329
