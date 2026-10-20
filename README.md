# cat-walk
A cat that strolls across your desktop, for macOS, iOS and watchOS

## 開発

- 引数なしの `make` は `make macos` で、Release ビルドを `/Applications/CatWalk.app` へ配置する。人が手元で試す時の入口
- `make build-macos` / `make build-ios` / `make build-watchos` はビルドだけを行う。`make test` は macOS のユニットテストを実行する
- `make ios` は `sim-boot` で起動した iOS Simulator にビルドして起動する
- ビルドとテストの検証は CI (`.github/workflows/ci.yml`) で行う。方針は `AGENTS.md` の「検証方法」を参照
