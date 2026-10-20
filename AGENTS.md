# Cat Walk

猫がデスクトップ (画面) の上を散歩する macOS / iOS / watchOS の SwiftUI アプリ。

@documents/PROJECT.md

## Xcode プロジェクト構成の変更

`CatWalk.xcodeproj` を唯一の正とする。XcodeGen と `project.yml` は使わず、`xcodegen generate` を実行しない (理由: `documents/adr/0002-manage-xcode-project-directly.md`)。

- 変更は Xcode の GUI か、`project.pbxproj` / `xcshareddata/xcschemes/*.xcscheme` の直接編集で行う
- 機械検査: `bash ~/.agents/skills/create-new-app/scripts/check-setup.sh --root .` の `xcode-project-source` 項目

## 検証方法

ビルド・ユニットテスト・simulator・ブラウザの動作確認は、このマシンで実行せず外部マシンに頼る。public repo のうちは GitHub Actions (CI) と simtunnel、private / internal に変わったら Devin (devin-macos-e2e skill) で行う。理由は開発マシンの負荷を避けるため (起票元: https://github.com/bannzai/IdeaMemo/issues/366 の立ち上げ指示)。

- ビルドとユニットテスト: push して `.github/workflows/ci.yml` の結果で確認する (`gh pr checks <PR番号> --watch`、失敗は `gh run view <run ID> --log-failed`)。ローカルで `xcodebuild` / `make build-*` / `make test` を重ねて実行しない。ログを読む時は全文を warning / error で検査する (`tail` で切り詰めた判定をしない)
- iOS の動作確認 (UI・挙動): `/ios-simulator` skill を起点にし、**特別な理由がない限り simtunnel (GitHub Actions macOS Runner 上のリモート iOS Simulator) で行う**。ローカル simulator (sim-boot) は既定にしない
  - 手順: 検証対象のブランチを push してから `SIMTUNNEL_REPO=bannzai/cat-walk ~/ghq/github.com/bannzai/simtunnel/local/simtunnel up <セッション名> --ref <ブランチ> --wait` で起動する。caller workflow は `.github/workflows/simulator-session.yml`、セッション名は `cat-walk-<worktree 名>`。操作・スクリーンショットは `/ios-simulator` skill の `scripts/ios-wda.sh --session <セッション名>` で行う。確認が終わったら `SIMTUNNEL_REPO=bannzai/cat-walk ~/ghq/github.com/bannzai/simtunnel/local/simtunnel down <セッション名>` で閉じる (macOS runner の並列上限を CI と共有するため放置しない)
  - repo が private / internal に変わった場合は、`/ios-simulator` skill Phase 1 の owner による分岐に従い Devin (devin-macos-e2e skill) を使う。このマシンのローカル simulator には倒さない
  - simtunnel で検証できない場合 (Secrets 未登録・tailnet 未接続等) は、検証できない理由を報告し、確認をユーザー作業の一覧に回す
- macOS の動作確認: `/macos-simtunnel` skill で GitHub Actions の macOS runner 上に起動し、WDA の screenshot で確認する (caller workflow は `.github/workflows/macos-app-session.yml`、`SIMTUNNEL_WORKFLOW=macos-app-session.yml`)。透明オーバーレイの猫が runner の screenshot に写ることを確認の基準にする
- watchOS の動作確認: simtunnel は watchOS simulator を扱わないため、CI のビルドと `CatWalkCore` のユニットテストまでを agent の検証範囲とする。実機・simulator での見た目の確認は「ユーザー作業の一覧」issue の確認のセクションへ回す (`~/.claude/documents/rules/defer-manual-verification-to-release.md`)
- 引数なしの `make` は `macos` (Release ビルドを `/Applications/CatWalk.app` へ配置) で、人が手元で試す時の入口。agent は上の方針によりこのマシンで実行しない

<!-- ai-review-config begin -->
<!--
このブロックは自動生成です。直接編集せず、テンプレートを更新してから再生成してください。
内容は AI コードレビュー時の挙動指示であり、コードベース自体への規約ではありません。
-->

## レビュー時の応答スタイル

- 応答は日本語で行う

## レビュー範囲外

以下は自動レビューで指摘しない (別の検出経路があるため):

- コンパイルエラー・型エラー (ローカル/CI のビルドで検出される)
- Lint/フォーマット違反 (リンター・フォーマッターで検出される)
<!-- ai-review-config end -->
