// cat-art.mjs の猫から、アプリの画像・アプリアイコン・紹介サイトの画像・案の比較シートを書き出す。
// 実行: node tools/cat-art/build.mjs (リポジトリの root で。PNG の書き出しに rsvg-convert を使う)
// 何度実行しても同じ入力から同じファイルを上書きするだけなので冪等。
import { execFileSync } from "node:child_process";
import { mkdirSync, readdirSync, rmSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { candidates, catSVG, coats, poses } from "./cat-art.mjs";

/**
 * アプリに入れる案と、アプリアイコン・紹介サイト・単色の絵に使う柄。bannzai が PR で別の案を選んだら、ここを変えて実行し直す。
 * 柄は設定の既定 (`CatWalkCore` の `catWalkCoat` の既定) と同じ茶トラにし、アイコンと初回起動の猫を同じ見た目にする。
 */
const shipped = { candidateKey: "b", coatKey: "chatora" };

const root = process.cwd();
const assetsDir = join(root, "Shared/Assets.xcassets");
const sheetDir = join(root, "documents/design/cat-2026-10-27");

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

// Asset Catalog の画像。猫は最大 64pt (macOS の「大」) で描くため、128pt の 1x/2x/3x にすれば縮小だけで済む。
// 色の絵は柄ごとに `cat-<柄>-<姿勢>`、単色の絵は柄を描かず形だけのため柄に依らず `cat-<姿勢>-mono` の 1 組にする
write(join(assetsDir, "Contents.json"), JSON.stringify({ info: { author: "xcode", version: 1 } }, null, 2) + "\n");
/** `name`.imageset に `svg` の 1x/2x/3x の PNG と Contents.json を書く。`mono` なら template として扱わせる。 */
function imageSet(name, svg, mono) {
  const dir = join(assetsDir, `${name}.imageset`);
  const images = [1, 2, 3].map((scale) => {
    const filename = `${name}@${scale}x.png`;
    png(svg, join(dir, filename), 128 * scale);
    return { filename, idiom: "universal", scale: `${scale}x` };
  });
  // 単色の絵はロック画面・コンプリケーションの色で塗り直されるよう template として扱う
  const properties = mono ? { "template-rendering-intent": "template" } : undefined;
  write(join(dir, "Contents.json"), JSON.stringify({ images, info: { author: "xcode", version: 1 }, ...(properties ? { properties } : {}) }, null, 2) + "\n");
  return `${name}.imageset`;
}
const catImageSets = new Set();
for (const pose of poses) {
  for (const coatKey of Object.keys(coats)) {
    catImageSets.add(imageSet(`cat-${coatKey}-${pose}`, catSVG({ candidateKey: shipped.candidateKey, coatKey, pose }), false));
  }
  catImageSets.add(imageSet(`cat-${pose}-mono`, catSVG({ ...shipped, pose, mono: true }), true));
}
// 姿勢・柄の名前を変えた時に、前の名前の絵が Asset Catalog に残らないよう、書き出さなかった猫の imageset を消す
for (const entry of readdirSync(assetsDir)) {
  if (entry.startsWith("cat-") && entry.endsWith(".imageset") && !catImageSets.has(entry)) {
    rmSync(join(assetsDir, entry), { recursive: true });
  }
}

/** アプリアイコンの絵 (1024x1024、透過なし)。座った猫を、落書きした紙のような生成り色の背景に置く。 */
function iconSVG() {
  const cat = catSVG({ ...shipped, pose: "sit", idPrefix: "icon" }).replace(/^<svg[^>]*>/, "").replace(/<\/svg>$/, "");
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024"><rect width="1024" height="1024" fill="#F3EEE3"/><g transform="translate(-9 -150) scale(8.4)">${cat}</g></svg>`;
}
// アプリアイコン。iOS・watchOS は 1024 の 1 枚から OS が各サイズを作り、macOS は各サイズの PNG を置く。
// watchOS の項目を AppIcon に入れると macOS の actool が「unassigned child」と警告するため、watchOS は WatchAppIcon に分ける
/** `name`.appiconset に `images` (Contents.json の項目に、書き出す一辺の px `px` を足したもの) を書き出す。 */
function appIconSet(name, images) {
  const dir = join(assetsDir, `${name}.appiconset`);
  for (const { filename, px } of images) {
    png(iconSVG(), join(dir, filename), px, px, true);
  }
  write(join(dir, "Contents.json"), JSON.stringify({ images: images.map(({ px, ...image }) => image), info: { author: "xcode", version: 1 } }, null, 2) + "\n");
}
const macSizes = [16, 32, 128, 256, 512];
const appIconImages = [{ filename: "AppIcon-ios.png", idiom: "universal", platform: "ios", size: "1024x1024", px: 1024 }];
for (const size of macSizes) {
  for (const scale of [1, 2]) {
    appIconImages.push({ filename: `AppIcon-mac-${size}@${scale}x.png`, idiom: "mac", scale: `${scale}x`, size: `${size}x${size}`, px: size * scale });
  }
}
appIconSet("AppIcon", appIconImages);
appIconSet("WatchAppIcon", [{ filename: "WatchAppIcon.png", idiom: "universal", platform: "watchos", size: "1024x1024", px: 1024 }]);

// 紹介サイト。ヒーローで歩かせる 2 コマと、SNS で共有された時の og.png (1200x630)
write(join(root, "docs/images/cat-walk1.svg"), catSVG({ ...shipped, pose: "walk1", idPrefix: "w1" }));
write(join(root, "docs/images/cat-walk2.svg"), catSVG({ ...shipped, pose: "walk2", idPrefix: "w2" }));
// 文字の配置と色は #11 で決めた og.png (アプリ名・キャッチコピー・対応 OS を左に、猫を右の地面に) に合わせ、猫だけをアプリの絵にする
const ogCat = catSVG({ ...shipped, pose: "walk1", idPrefix: "og" }).replace(/^<svg[^>]*>/, "").replace(/<\/svg>$/, "");
png(
  `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1200 630" width="1200" height="630"><rect width="1200" height="630" fill="#1d1f23"/><rect x="0" y="520" width="1200" height="6" fill="#3a3e46"/><text x="96" y="230" font-family="Hiragino Sans, sans-serif" font-weight="800" font-size="104" fill="#eceef1">Cat Walk</text><text x="96" y="320" font-family="Hiragino Sans, sans-serif" font-weight="700" font-size="56" fill="#f0a05a">作業中の画面に猫がいる</text><text x="96" y="400" font-family="Hiragino Sans, sans-serif" font-weight="400" font-size="34" fill="#a8aeb8">Mac・iPhone・Apple Watch</text><g transform="translate(790 184) scale(2.8)">${ogCat}</g></svg>`,
  join(root, "docs/og.png"),
  1200,
  630,
);

// 案の比較シート。3 案の姿勢、アプリに入れた案の柄の種類、単色の絵 (どの柄でも共通) を並べ、PR で見比べてもらう
const cell = (svg, caption, bg = "#2b2f36") => `<figure style="margin:0;display:flex;flex-direction:column;align-items:center;gap:6px"><div style="background:${bg};border-radius:12px;padding:8px;width:136px;height:136px;display:flex;align-items:center;justify-content:center">${svg}</div><figcaption style="font-size:13px;color:#cfd3da">${caption}</figcaption></figure>`;
const poseLabels = { walk1: "歩く 1", walk2: "歩く 2", stand: "立ち止まる", sit: "座る", sleep: "眠る", groom: "毛づくろい", delighted: "撫でられて喜ぶ", lifted: "持ち上げられる (macOS)" };
let id = 0;
const row = (title, cells) => `<section style="margin:0 0 28px"><h2 style="font-size:16px;margin:0 0 12px;color:#eceef1">${title}</h2><div style="display:flex;flex-wrap:wrap;gap:12px">${cells.join("")}</div></section>`;
const sections = [];
for (const [key, c] of Object.entries(candidates)) {
  sections.push(row(`${c.label}${key === shipped.candidateKey ? " (このPRでアプリに入れた案)" : ""}`, poses.map((pose) => cell(catSVG({ candidateKey: key, coatKey: "chatora", pose, idPrefix: `s${id++}` }), poseLabels[pose]))));
}
sections.push(row(`柄の種類 (${candidates[shipped.candidateKey].label}で描いた、設定で選べる 6 柄)`,Object.entries(coats).flatMap(([coatKey, coat]) => ["sit", "walk1"].map((pose) => cell(catSVG({ candidateKey: shipped.candidateKey, coatKey, pose, idPrefix: `s${id++}` }), `${coat.label} ${poseLabels[pose]}`)))));
sections.push(row("ロック画面・コンプリケーションの単色の絵", poses.map((pose) => cell(catSVG({ ...shipped, pose, mono: true, idPrefix: `s${id++}` }), poseLabels[pose], "#000000"))));
write(
  join(sheetDir, "index.html"),
  `<!doctype html>\n<html lang="ja"><head><meta charset="utf-8"><title>猫の絵の案</title></head><body style="margin:0;padding:24px;background:#1d1f23;font-family:-apple-system,'Hiragino Sans',sans-serif">${sections.join("")}</body></html>\n`,
);
console.log("done");
