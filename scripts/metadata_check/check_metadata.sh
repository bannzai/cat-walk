#!/usr/bin/env bash
#
# check_metadata.sh - fastlane/metadata の文字数が App Store Connect の上限に収まっているかを検査する
#
# 使い方:
#   scripts/metadata_check/check_metadata.sh              # 全 locale を検査
#   scripts/metadata_check/check_metadata.sh ja en-US     # 指定した locale だけ検査
#
# 上限 (出典: https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information
#       と https://developer.apple.com/help/app-store-connect/reference/app-information/app-information ):
#   name.txt 30 文字 / subtitle.txt 30 文字 / keywords.txt 100 バイト / promotional_text.txt 170 文字 / description.txt 4000 文字
#   keywords だけは Apple の説明が「up to 100 bytes」のため UTF-8 のバイト数で数える (日本語は 1 文字 3 バイト)
#   末尾の改行は数えない (fastlane の deliver は前後の空白を取り除いて送るため)
#
# 終了コード:
#   0: すべて上限以内
#   1: 上限を超えたファイルがある
#   2: 引数の locale のディレクトリが無い、または metadata が 1 つも無い
#
# bannzai/Focus の scripts/metadata_check/ (commit 368eb5137fa3f25921a1cfefeeb7aa1231d03fa0) を元に、
# 検査するファイルに promotional_text と description を足して 1 本にまとめた

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
METADATA_DIR="${METADATA_DIR:-$SCRIPT_DIR/../../fastlane/metadata}"

# ファイル名:上限:数え方 (m = 文字数、c = バイト数。wc のオプション)
LIMITS=(
  "name.txt:30:m"
  "subtitle.txt:30:m"
  "keywords.txt:100:c"
  "promotional_text.txt:170:m"
  "description.txt:4000:m"
)

if [[ $# -gt 0 ]]; then
  locales=("$@")
else
  locales=()
  for dir in "$METADATA_DIR"/*/; do
    [[ -d "$dir" ]] || continue
    # deliver が locale と同じ階層に置く審査連絡先 (review_information) と全 locale 共通の値 (default) は、name 等を持たないため検査しない
    case "$(basename "$dir")" in
      review_information | default) continue ;;
    esac
    locales+=("$(basename "$dir")")
  done
fi

if [[ ${#locales[@]} -eq 0 ]]; then
  echo "エラー: $METADATA_DIR に locale のディレクトリが無い" >&2
  exit 2
fi

error_count=0
checked_count=0
for locale in "${locales[@]}"; do
  locale_dir="$METADATA_DIR/$locale"
  if [[ ! -d "$locale_dir" ]]; then
    echo "エラー: locale のディレクトリが無い: $locale_dir" >&2
    exit 2
  fi
  locale_checked_count=$checked_count
  for limit in "${LIMITS[@]}"; do
    IFS=: read -r name max unit <<<"$limit"
    file="$locale_dir/$name"
    [[ -f "$file" ]] || continue
    count=$(printf '%s' "$(cat "$file")" | LC_ALL=en_US.UTF-8 wc "-$unit" | tr -d ' ')
    checked_count=$((checked_count + 1))
    if [[ "$count" -le "$max" ]]; then
      echo "OK: $locale/$name ($count / $max)"
    else
      echo "NG: $locale/$name ($count / $max) 上限を超えている" >&2
      error_count=$((error_count + 1))
    fi
  done
  if [[ $checked_count -eq $locale_checked_count ]]; then
    echo "エラー: $locale_dir に検査するファイルが 1 つも無い" >&2
    exit 2
  fi
done

if [[ $error_count -gt 0 ]]; then
  echo "NG: $error_count 件が上限を超えている ($checked_count 件を検査)" >&2
  exit 1
fi
echo "OK: すべて上限以内 ($checked_count 件を検査)"
