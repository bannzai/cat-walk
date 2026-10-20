# 0002. Xcode プロジェクトを直接管理する

## Status
Accepted (2026-10-20)

## Context
初期作成に XcodeGen を使ったが、`project.yml` と `CatWalk.xcodeproj/project.pbxproj` の二重管理を避けるため、生成直後に `project.yml` を削除した。

二重管理では、片方だけが更新されても差異を検出する仕組みがなく、後から XcodeGen を実行した時に初めて設定の不一致やビルドエラーが表面化する。Xcode の GUI で加えた変更は `project.yml` に反映されず、次の生成で失われる。複数のブランチが同じターゲットを変更すると、生成のたびに `project.pbxproj` が広範囲に書き換わって競合しやすい。

## Decision
`CatWalk.xcodeproj` をプロジェクト構成の唯一の正として直接管理する。ターゲット、ファイル、ビルド設定、Scheme、Swift Package の変更には Xcode の GUI を使う。自動化が必要な場合は、プロジェクト構成を `project.pbxproj`、Scheme を `xcshareddata/xcschemes/*.xcscheme` で直接編集する。XcodeGen は使わず、`xcodegen generate` を実行しない。

## Consequences

**良い点:**
- `project.yml` と `project.pbxproj` の二重管理がなくなり、両者の不一致による遅延したビルド失敗を防げる
- Xcode の GUI で行った変更が後の再生成で失われない
- ブランチ統合時に生成物全体が書き換わることによる不要な競合を避けられる

**悪い点 / 引き受けるリスク:**
- `project.pbxproj` の差分は構造化された YAML より読みづらいため、変更時に意図しない差分がないか確認する必要がある
- Xcode の GUI 操作や直接編集で不正な構成を作る可能性があるため、プロジェクト構成の変更後は CI のビルドとテストで検証する必要がある
