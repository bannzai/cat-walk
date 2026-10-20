# documents/design

見た目と体験の方向の判断に使うモックと、受領したデザインの置き場。

Claude Design の canvas (Artifact) の URL はアカウントの切り替えや削除で開けなくなることがあるため、判断に使ったモックはリポジトリに保存する。

## mock-2026-10-21/

Cat Walk の 3 OS (macOS / iOS / watchOS) の見た目と体験の方向を判断するために作ったモック。

- `canvas.json` と `*.dc.html` (7 枚): Claude Design の canvas から取り出したそのままのファイル。canvas の URL: https://claude.ai/artifact/UBrra8BTMETv7KV45wwVHp
- `index.html`: 7 枚の artboard を縦に並べた単独の HTML。ブラウザでそのまま開ける (`support.js` 不要)。プロパティ (`{{accent}}` 等) は各ファイルの既定値に置き換えてある
