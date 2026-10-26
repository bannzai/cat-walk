# documents/design

見た目と体験の方向の判断に使うモックと、受領したデザインの置き場。

Claude Design の canvas (Artifact) の URL はアカウントの切り替えや削除で開けなくなることがあるため、判断に使ったモックはリポジトリに保存する。

## 紹介サイトの OGP 画像

`docs/og.png` (1200x630) は、アプリと同じ猫の絵から `node tools/cat-art/build.mjs` が書き出す (#12。#11 で作った `og.svg` の文字の配置と色を引き継いだ)。文字や配置を変える時は `tools/cat-art/build.mjs` を直す。

## mock-2026-10-21/

Cat Walk の 3 OS (macOS / iOS / watchOS) の見た目と体験の方向を判断するために作ったモック。

- `canvas.json` と `*.dc.html` (7 枚): Claude Design の canvas から取り出したそのままのファイル。各ファイルは `./support.js` (Claude Design の canvas 側の実行環境) を参照するため単独では描画できず、canvas に戻す時に使う。canvas の URL: https://claude.ai/artifact/UBrra8BTMETv7KV45wwVHp
- `index.html`: 7 枚の artboard を縦に並べた、`support.js` に依存しない単独の HTML (ブラウザでの表示は未確認。HTML を読んで確認した)。プロパティ (`{{accent}}` 等) は各ファイルの既定値に置き換えてある

## cat-2026-10-27/

PR #29 への返答「猫がちょっと可愛すぎるな。もっと素人が書いたような手抜きの絵にして欲しい」を受けて作った、線の雑さを変えた落書き調の 3 案と柄の見本の比較シート (#12)。`index.html` は `node tools/cat-art/build.mjs` が書き出すため、手で編集しない。その前に作った可愛く寄せた 3 案のシート (`cat-2026-10-26/`) は、この返答で使わなくなったため消した (git の履歴に残る)。
