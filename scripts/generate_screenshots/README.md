# App Store のスクリーンショットとヘッダーの書き出し

`AppStoreScreenshots/` の SwiftUI の view (背景・キャッチコピー・端末の画面) を、CatWalkTests の `AppStoreScreenshotTests` が ImageRenderer で PNG に書き出す。キャッチコピーは `AppStoreScreenshots/AppStoreScreenshots.xcstrings`、画面の中のアプリの文言は `Shared/Localizable.xcstrings` から言語ごとに引く。

## 書き出す

開発マシンでは実行せず、GitHub Actions の `app-store-screenshots` workflow で書き出す (`CLAUDE.md`「検証方法」)。

```sh
gh workflow run app-store-screenshots.yml --ref <ブランチ>
gh run list --workflow app-store-screenshots.yml --branch <ブランチ> --limit 1
gh run download <run ID> -n app-store-screenshots -D tmp/app-store-screenshots-artifact
```

`AppStoreScreenshots/`・`Shared/`・`scripts/generate_screenshots/` を変えた PR では自動で動く。

## 配置する

artifact の PNG を見た目で確かめてから、fastlane の置き場所へコピーしてコミットする。

```sh
scripts/generate_screenshots/generate.sh --check-only tmp/app-store-screenshots-artifact/app-store-screenshots
rsync -a --delete tmp/app-store-screenshots-artifact/app-store-screenshots/screenshots/ fastlane/screenshots/
rsync -a --delete tmp/app-store-screenshots-artifact/app-store-screenshots/creative_assets/ fastlane/creative_assets/
```

| 置き場所 | 中身 | 寸法 |
| --- | --- | --- |
| `fastlane/screenshots/ios/<locale>/` | iPhone 3 枚 | 1320 x 2868 (6.9 インチ) |
| `fastlane/screenshots/mac/<locale>/` | Mac 3 枚 | 2880 x 1800 |
| `fastlane/creative_assets/<locale>/product_page_header.png` | 製品ページのヘッダー | 3840 x 1646 (21:9) |

fastlane の deliver は 1 回の実行で 1 つの platform を扱うため、iPhone と Mac を分けて置く (`deliver --platform ios --screenshots_path fastlane/screenshots/ios` と `--platform osx --screenshots_path fastlane/screenshots/mac`)。ヘッダーは deliver の対象ではなく、appstore-custom-product-page skill の「Creative Asset (header / search results) の入稿」で App Store Connect の Asset Library に入れる。
