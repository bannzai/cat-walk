---
status: evaluating        # evaluating | building | launched | pivoting | retiring | retired
decision_date:            # 次の判定日 (YYYY-MM-DD)。判定のたびに cycle_days 後へ進める
cycle_days: 14            # 判定の周期 (7 または 14)
veto_wait_hours: 12       # 公開後の無人ループの拒否権の待ち時間 (既定 12)
daily_issue_cap: 3        # 1 日に生成してよい改善 issue の上限 (扱いは issue-worth-doing-checklist.md。既定 3)
launched_at:              # 公開日 (YYYY-MM-DD)。公開前は空
---

# 方向性: Cat Walk

## 仮説

Mac で作業する人 (と同じ人の iPhone / Apple Watch) に、作業の邪魔にならない常駐の癒しとして、画面の上を歩き回る 1 匹の猫を出す。macOS では透明でクリックを通す最前面のウィンドウの中を猫が歩き、iOS ではウィジェット・Live Activity・Dynamic Island で、watchOS ではコンプリケーションと watch アプリで、同じ猫が「動いて見える」。ログイン・サーバー・広告・育成要素を持たない (出典: 評価レポート https://github.com/bannzai/IdeaMemo/issues/366#issuecomment-6280604722 )。

## 判定基準

| 指標 | 計測元 (skill / コマンド) | 継続のしきい値 | 打ち切り条件 | 転換の条件 |
| --- | --- | --- | --- | --- |
| Mac App Store (jp + us) の直近 14 日の ★1〜2 レビュー数 | appstore-research skill: `bash ~/.agents/skills/appstore-research/scripts/fetch-reviews.sh <adamId> --country jp --pages 1` と `--country us` の出力で `date` が直近 14 日かつ `rating` が 2 以下の行数 | <= 1 | >= 3 x2 (2 回連続) | 低評価が「フルスクリーンで消える」「クリックを邪魔する」「CPU を食う」に集中していたら、新しい猫の動きより常駐の信頼性を改善 issue の最優先にする |
| Mac App Store (jp + us) の累積レビュー件数 (RSS で取れる本文付きレビュー) | 同上の出力の行数 (`--pages 2`) | 公開 28 日後に >= 5 | 公開 56 日後に 0 x2 | 公開 56 日後に iOS 側のレビューだけが付いていたら、iOS (Live Activity / ウィジェット) を主軸にする転換 |
| 買い切りの購入数 (課金を入れた場合) | App Store Connect の売上レポート | 公開 28 日後に >= 10 本 | 公開 56 日後に < 10 本 x2 | 購入 0 で表示回数が 3,530/月 を超えていたら価格・課金面の転換 (無料 + 季節の猫の買い切り等) |

平均評価は公開直後 0 件のため判定基準に入れない。10 件を超えたら agent が `>= 4.0` / `< 3.5 x2` の行を足す。Crashlytics・Analytics は入れない (`documents/adr/0001-local-only-no-backend-infra.md`) ため、クラッシュ・継続率の指標は置かない。adamId は App Store Connect でアプリを作った時に埋める。

## 必要な機能

構想の段階 (関門 1) の返答待ち。下は agent の提案で、bannzai の返答で確定する。

macOS:
- [ ] メニューバー常駐 (`MenuBarExtra`、Dock に出ない) と、透明・クリック透過・最前面のオーバーレイ。全 Space・他アプリのフルスクリーン・複数ディスプレイの上に出る
- [ ] 猫の歩行の状態機械 (歩く・立ち止まる・座る・眠る・毛づくろい)。画面下端を歩く。CPU はアイドル時 1% 未満を目標
- [ ] 猫をドラッグで持ち上げて置ける (猫の上だけマウスを受け、それ以外はクリックを通す)
- [ ] 設定: 猫の表示 / 非表示、サイズ、歩く速さ、ログイン時に起動。状態 (位置・設定) の保存
iOS:
- [ ] ホーム画面・ロック画面ウィジェット (猫の姿勢と位置をタイムラインで切り替え、タップで反応)
- [ ] Live Activity / Dynamic Island で猫が歩く (最大 8 時間)
- [ ] アプリ本体: 猫が歩く画面と撫でる操作
watchOS:
- [ ] コンプリケーション (accessory widget) と watch アプリ (前面では通常のアニメーション、Always On では静止)
共通:
- [ ] 歩行ロジックを共有する Swift Package (`CatWalkCore`) と、3 OS で同じ猫の見た目 (デザインの段階で決める)
- [ ] 利用規約・プライバシーポリシー・紹介サイト (GitHub Pages) と、設定画面からの導線 (お問い合わせ (メール) の導線を含む)

MVP に入れないもの (後続): 育成・餌・ミニゲーム、複数の猫、自分の猫の柄の再現、季節のイベント、課金 (関門 1 の返答で決まるまで)。

## デザインの方向

(デザインの段階 (関門 2) で、`documents/design/` 配下のモックへの参照と決めた方向を書く)

## 決めたこと

| 日付 | 場面 | 決めたこと | 決めた人 |
| --- | --- | --- | --- |
| 2026-10-20 | 評価 | evaluate-service-idea の判定は「作る」。決め手は、需要が iOS の競合の評価件数で実測できる一方、本命の体験 (画面の上を歩く) を出せる macOS には評価件数が付いた定番が無いこと。作り手の目的は未確認のため 4 通りの判定を並べ、収益以外の 3 つは作る、収益は到達可能性が未判定のまま作る (判定日で早く見切る)。レポート: https://github.com/bannzai/IdeaMemo/issues/366#issuecomment-6280604722 | agent |
| 2026-10-20 | 評価 | 判定基準の計測元は Mac App Store のレビュー (appstore-research skill) と App Store Connect の売上・表示回数にし、Analytics・Crashlytics は入れない (ADR 0001) | agent |

## agent に任せること

文書に無い問いはすべて。関門 1 の返答で「任せる」とされた項目をここに足す。
