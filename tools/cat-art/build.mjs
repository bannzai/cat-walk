// cat-art.mjs の猫から、アプリの画像・アプリアイコン・紹介サイトの画像・案の比較シートを書き出す。
// 実行: node tools/cat-art/build.mjs (リポジトリの root で。PNG の書き出しに rsvg-convert を使う)
// 何度実行しても同じ入力から同じファイルを上書きするだけなので冪等。
import { execFileSync } from "node:child_process";
import { mkdirSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { candidates, catSVG, coats, poses } from "./cat-art.mjs";

/** アプリに入れる案と柄。bannzai が PR で別の案を選んだら、ここを変えて実行し直す。 */
const shipped = { candidateKey: "a", coatKey: "chatora" };

const root = process.cwd();
const assetsDir = join(root, "Shared/Assets.xcassets");
const sheetDir = join(root, "documents/design/cat-2026-10-26");

/** `path` に `content` を書く。親ディレクトリが無ければ作る。 */
function write(path, content) {
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, content);
}

/** SVG 文字列 `svg` を `width` x `height` px の PNG にして `path` に書く。`opaque` なら alpha チャンネルを落とす (App Store がアイコンの透過を拒否するため)。 */
function png(svg, path, width, height = width, opaque = false) {
  mkdirSync(dirname(path), { recursive: true });
  execFileSync("rsvg-convert", ["--width", String(width), "--height", String(height), "--output", path], { input: svg });
  if (opaque) {
    // 書き出すたびに日時の chunk が変わって差分が出ないよう、日時を書かせない
    execFileSync("magick", [path, "-alpha", "off", "-define", "png:exclude-chunk=date,time", path]);
  }
}

// Asset Catalog の画像。猫は最大 64pt (macOS の「大」) で描くため、128pt の 1x/2x/3x にすれば縮小だけで済む
write(join(assetsDir, "Contents.json"), JSON.stringify({ info: { author: "xcode", version: 1 } }, null, 2) + "\n");
for (const pose of poses) {
  for (const mono of [false, true]) {
    const name = `cat-${pose}${mono ? "-mono" : ""}`;
    const dir = join(assetsDir, `${name}.imageset`);
    const svg = catSVG({ ...shipped, pose, mono });
    const images = [1, 2, 3].map((scale) => {
      const filename = `${name}@${scale}x.png`;
      png(svg, join(dir, filename), 128 * scale);
      return { filename, idiom: "universal", scale: `${scale}x` };
    });
    // 単色の絵はロック画面・コンプリケーションの色で塗り直されるよう template として扱う
    const properties = mono ? { "template-rendering-intent": "template" } : undefined;
    write(join(dir, "Contents.json"), JSON.stringify({ images, info: { author: "xcode", version: 1 }, ...(properties ? { properties } : {}) }, null, 2) + "\n");
  }
}

/** アプリアイコンの絵 (1024x1024、透過なし)。座った猫を、猫の色が埋もれない夜空色の背景に置く。 */
function iconSVG() {
  const cat = catSVG({ ...shipped, pose: "sit", idPrefix: "icon" }).replace(/^<svg[^>]*>/, "").replace(/<\/svg>$/, "");
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024"><defs><linearGradient id="bg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2F3A5C"/><stop offset="1" stop-color="#1D2440"/></linearGradient></defs><rect width="1024" height="1024" fill="url(#bg)"/><g transform="translate(47 32) scale(7.5)">${cat}</g></svg>`;
}
// アプリアイコン。iOS・watchOS は 1024 の 1 枚から OS が各サイズを作り、macOS は各サイズの PNG を置く
const appIconDir = join(assetsDir, "AppIcon.appiconset");
const macSizes = [16, 32, 128, 256, 512];
const appIconImages = [
  { filename: "AppIcon.png", idiom: "universal", platform: "ios", size: "1024x1024" },
  { filename: "AppIcon.png", idiom: "universal", platform: "watchos", size: "1024x1024" },
];
png(iconSVG(), join(appIconDir, "AppIcon.png"), 1024, 1024, true);
for (const size of macSizes) {
  for (const scale of [1, 2]) {
    const filename = `AppIcon-mac-${size}@${scale}x.png`;
    png(iconSVG(), join(appIconDir, filename), size * scale, size * scale, true);
    appIconImages.push({ filename, idiom: "mac", scale: `${scale}x`, size: `${size}x${size}` });
  }
}
write(join(appIconDir, "Contents.json"), JSON.stringify({ images: appIconImages, info: { author: "xcode", version: 1 } }, null, 2) + "\n");

// 紹介サイト。ヒーローで歩かせる 2 コマと、SNS で共有された時の og.png (1200x630)
write(join(root, "docs/images/cat-walk1.svg"), catSVG({ ...shipped, pose: "walk1", idPrefix: "w1" }));
write(join(root, "docs/images/cat-walk2.svg"), catSVG({ ...shipped, pose: "walk2", idPrefix: "w2" }));
const ogCats = ["walk1", "sit", "sleep"]
  .map((pose, i) => `<g transform="translate(${160 + i * 330} 250) scale(2.3)">${catSVG({ ...shipped, pose, idPrefix: `og${i}` }).replace(/^<svg[^>]*>/, "").replace(/<\/svg>$/, "")}</g>`)
  .join("");
png(
  `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1200 630" width="1200" height="630"><rect width="1200" height="630" fill="#1d1f23"/><rect y="530" width="1200" height="8" fill="#3a3e46"/><text x="600" y="150" text-anchor="middle" font-family="Hiragino Sans, sans-serif" font-weight="800" font-size="64" fill="#eceef1">作業中の画面に<tspan fill="#f0a05a">猫がいる</tspan></text><text x="600" y="215" text-anchor="middle" font-family="Hiragino Sans, sans-serif" font-size="30" fill="#a8aeb8">Mac・iPhone・Apple Watch のアプリ Cat Walk</text>${ogCats}</svg>`,
  join(root, "docs/og.png"),
  1200,
  630,
);

// 案の比較シート。3 案の姿勢、案 A の柄の種類、単色の絵を並べ、PR で見比べてもらう
const cell = (svg, caption, bg = "#2b2f36") => `<figure style="margin:0;display:flex;flex-direction:column;align-items:center;gap:6px"><div style="background:${bg};border-radius:12px;padding:8px;width:136px;height:136px;display:flex;align-items:center;justify-content:center">${svg}</div><figcaption style="font-size:13px;color:#cfd3da">${caption}</figcaption></figure>`;
const poseLabels = { walk1: "歩く 1", walk2: "歩く 2", stand: "立ち止まる", sit: "座る", sleep: "眠る", groom: "毛づくろい", delighted: "撫でられて喜ぶ", lifted: "持ち上げられる (macOS)" };
let id = 0;
const row = (title, cells) => `<section style="margin:0 0 28px"><h2 style="font-size:16px;margin:0 0 12px;color:#eceef1">${title}</h2><div style="display:flex;flex-wrap:wrap;gap:12px">${cells.join("")}</div></section>`;
const sections = [];
for (const [key, c] of Object.entries(candidates)) {
  sections.push(row(`${c.label}${key === shipped.candidateKey ? " (このPRでアプリに入れた案)" : ""}`, poses.map((pose) => cell(catSVG({ candidateKey: key, coatKey: "chatora", pose, idPrefix: `s${id++}` }), poseLabels[pose]))));
}
sections.push(row(`柄の種類 (${candidates[shipped.candidateKey].label}で描いた見本。アプリに入れたのは茶トラだけ)`, Object.entries(coats).flatMap(([coatKey, coat]) => ["sit", "walk1"].map((pose) => cell(catSVG({ candidateKey: shipped.candidateKey, coatKey, pose, idPrefix: `s${id++}` }), `${coat.label} ${poseLabels[pose]}`)))));
sections.push(row("ロック画面・コンプリケーションの単色の絵", poses.map((pose) => cell(catSVG({ ...shipped, pose, mono: true, idPrefix: `s${id++}` }), poseLabels[pose], "#000000"))));
write(
  join(sheetDir, "index.html"),
  `<!doctype html>\n<html lang="ja"><head><meta charset="utf-8"><title>猫の絵の案</title></head><body style="margin:0;padding:24px;background:#1d1f23;font-family:-apple-system,'Hiragino Sans',sans-serif">${sections.join("")}</body></html>\n`,
);
console.log("done");
