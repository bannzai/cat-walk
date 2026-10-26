#!/usr/bin/env bash
#
# generate.sh - App Store のスクリーンショットと製品ページのヘッダーを書き出して検査する
#
# CatWalkTests の AppStoreScreenshotTests (AppStoreScreenshots/) を macOS で実行し、
# ImageRenderer で描いた PNG を出力ディレクトリに書き出してから、枚数・寸法・透過の無いことを検査する。
# 開発マシンの負荷を避けるため CI (.github/workflows/app-store-screenshots.yml) で実行する (CLAUDE.md「検証方法」)。
#
# 使い方:
#   scripts/generate_screenshots/generate.sh [出力ディレクトリ]   # 既定は tmp/app-store-screenshots
#   scripts/generate_screenshots/generate.sh --check-only <出力ディレクトリ>   # 書き出し済みの PNG の検査だけ行う
#
# 出力ディレクトリの構成 (fastlane の deliver の screenshots_path にそのまま渡せる形):
#   screenshots/ios/<locale>/*.png      iPhone 6.9 インチ 1320x2868
#   screenshots/mac/<locale>/*.png      Mac 2880x1800
#   creative_assets/<locale>/product_page_header.png   製品ページのヘッダー 3840x1646
#
# 終了コード:
#   0: 書き出しと検査が通った
#   1: テストが失敗した、または検査に通らない PNG がある
#   2: 引数が不正

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

check_only=0
if [[ "${1-}" == "--check-only" ]]; then
  check_only=1
  shift
  [[ $# -eq 1 ]] || { echo "使い方: $0 --check-only <出力ディレクトリ>" >&2; exit 2; }
fi
output_dir="${1:-$ROOT/tmp/app-store-screenshots}"
mkdir -p "$output_dir"
output_dir="$(cd "$output_dir" && pwd)"

# 言語ごとに書き出すページの数と、ページの種類ごとの寸法 (AppStoreScreenshotTests の pixelSize と揃える)
LOCALES=(ja en-US)
EXPECTED=(
  "screenshots/ios:3:1320:2868"
  "screenshots/mac:3:2880:1800"
  "creative_assets:1:3840:1646"
)

if [[ $check_only -eq 0 ]]; then
  # 前回の書き出しが残っていると検査が古い PNG を数えるため、出力ディレクトリの中身を作り直す
  find "$output_dir" -name '*.png' -type f -delete
  echo "出力先: $output_dir"
  # xcodebuild は TEST_RUNNER_ を付けた環境変数を、接頭辞を外してテストのプロセスに渡す (man xcodebuild の「TEST_RUNNER_<VAR>」)
  TEST_RUNNER_SCREENSHOTS_OUTPUT_DIR="$output_dir" xcodebuild \
    -project "$ROOT/CatWalk.xcodeproj" \
    -scheme CatWalk \
    -destination 'platform=macOS' \
    -derivedDataPath "$ROOT/tmp/DerivedData" \
    -only-testing:CatWalkTests/AppStoreScreenshotTests \
    CODE_SIGNING_ALLOWED=NO \
    test
fi

failures=0
for locale in "${LOCALES[@]}"; do
  for expected in "${EXPECTED[@]}"; do
    IFS=: read -r kind count width height <<<"$expected"
    dir="$output_dir/$kind/$locale"
    actual_count=$(find "$dir" -maxdepth 1 -name '*.png' -type f 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$actual_count" -ne "$count" ]]; then
      echo "NG: $kind/$locale の PNG が $actual_count 枚 (期待は $count 枚)" >&2
      failures=$((failures + 1))
      continue
    fi
    for png in "$dir"/*.png; do
      info=$(sips -g pixelWidth -g pixelHeight -g hasAlpha "$png")
      actual_width=$(awk '/pixelWidth/ {print $2}' <<<"$info")
      actual_height=$(awk '/pixelHeight/ {print $2}' <<<"$info")
      has_alpha=$(awk '/hasAlpha/ {print $2}' <<<"$info")
      if [[ "$actual_width" == "$width" && "$actual_height" == "$height" && "$has_alpha" == "no" ]]; then
        echo "OK: ${png#"$output_dir"/} (${actual_width}x${actual_height}, alpha なし)"
      else
        echo "NG: ${png#"$output_dir"/} (${actual_width}x${actual_height}, hasAlpha=$has_alpha。期待は ${width}x${height}, alpha なし)" >&2
        failures=$((failures + 1))
      fi
    done
  done
done

if [[ $failures -gt 0 ]]; then
  echo "NG: $failures 件の検査に通らない" >&2
  exit 1
fi
echo "OK: すべての PNG が検査に通った"
