// 猫の絵 (姿勢ごとの SVG) の唯一の定義。アプリの画像・アプリアイコン・og.png・紹介サイトの猫は、
// どれも build.mjs がこのファイルから書き出すため、見た目を変える時はここだけを直して build.mjs を実行し直す。
// 座標は 128x128 の viewBox で、地面は y = 120、猫は右を向く (左向きは描画側の左右反転で表す)。

/** 絵の方向の案。bannzai に PR で見比べてもらうため、頭と体の比・目・足の長さを軸に変えてある。 */
export const candidates = {
  // 頭と体がほぼ 1:1 のちび体型。縦長の大きな目にハイライトを 2 つ入れ、ほっぺを付ける
  a: { label: "案 A まんまる", headR: 27, bodyRx: 30, bodyRy: 17, legLen: 15, eye: "tall", blush: true },
  // 頭を小さめ (頭:体 = 2:3) にして体を長くし、足もやや長い。目は丸く大きなハイライトを 1 つ
  b: { label: "案 B すらり", headR: 21, bodyRx: 36, bodyRy: 16, legLen: 22, eye: "round", blush: false },
  // 頭と体をくっつけた大福形。足は短い突起だけにし、頭をいちばん大きくする
  c: { label: "案 C おもち", headR: 31, bodyRx: 27, bodyRy: 19, legLen: 7, eye: "tall", blush: true },
};

/** 柄の配色。アプリに入れるのは茶トラだけで、ほかは比較シートで種類の広がりを見てもらうための見本。 */
export const coats = {
  chatora: { label: "茶トラ", base: "#F2A65A", shade: "#DD8A3E", light: "#FFF3E2", stripe: "#D9772E", eye: "#2A2220" },
  mike: { label: "三毛", base: "#FFF9F2", shade: "#E9DFD3", light: "#FFFFFF", patchA: "#F2A65A", patchB: "#3B3330", eye: "#2A2220" },
  kuro: { label: "黒", base: "#38322F", shade: "#262120", light: "#4A4340", eye: "#E9C84A", dark: true },
  shiro: { label: "白", base: "#FFFCF7", shade: "#E8E0D6", light: "#FFFFFF", eye: "#2A2220" },
  sabatora: { label: "サバトラ", base: "#AEB3B8", shade: "#8E949B", light: "#F3F3F1", stripe: "#676D74", eye: "#2A2220" },
  hachiware: { label: "ハチワレ", base: "#38322F", shade: "#262120", light: "#FFFCF7", eye: "#E9C84A", dark: true, hachiware: true },
};

/** アプリが使う姿勢の名前。Asset Catalog の画像名 `cat-<名前>` になる。 */
export const poses = ["walk1", "walk2", "stand", "sit", "sleep", "groom", "delighted", "lifted"];

const pink = "#F4A1A6";
const outlineDark = "#2A2220";

// 要素は role で、色の絵と単色 (ロック画面・コンプリケーション) の絵のどちらに出すかを分ける。
// body: 体の輪郭になる形。単色では白の塗り
// detail: 柄・腹・ほっぺなど色でしか分からない形。単色では出さない
// feature: 目・鼻・口・耳の内側。単色では輪郭から抜く
// highlight: 目のハイライト。単色では抜いた目の中に白で戻す
// deco: 地面の影。単色では出さない
// mark: 眠りの z・喜びのハート。単色でも白で出す
const el = (role, svg) => ({ role, svg });

const f = (n) => Math.round(n * 100) / 100;
const ellipse = (cx, cy, rx, ry, fill, extra = "") => `<ellipse cx="${f(cx)}" cy="${f(cy)}" rx="${f(rx)}" ry="${f(ry)}" fill="${fill}"${extra}/>`;
const stroke = (d, color, width) => `<path d="${d}" fill="none" stroke="${color}" stroke-width="${width}" stroke-linecap="round" stroke-linejoin="round"/>`;
const polygon = (points, fill, round) =>
  `<polygon points="${points.map(([x, y]) => `${f(x)},${f(y)}`).join(" ")}" fill="${fill}"${round ? ` stroke="${fill}" stroke-width="${round}" stroke-linejoin="round"` : ""}/>`;

/** 頭 (耳・顔・柄) の要素。`eyes` は open / closed (眠り・毛づくろいの ‿) / happy (喜びの ^) / round (持ち上げられて驚いた丸い目)。 */
function head(c, coat, hx, hy, eyes) {
  const r = c.headR;
  const out = [];
  const darkHead = coat.dark;
  const headFill = coat.hachiware ? coat.base : "url(#base)";
  for (const side of [-1, 1]) {
    const ear = [
      [hx + side * 0.92 * r, hy - 0.3 * r],
      [hx + side * 0.78 * r, hy - 1.16 * r],
      [hx + side * 0.22 * r, hy - 0.86 * r],
    ];
    out.push(el("body", polygon(ear, coat.base, 7)));
    const inner = [
      [hx + side * 0.78 * r, hy - 0.42 * r],
      [hx + side * 0.74 * r, hy - 0.98 * r],
      [hx + side * 0.38 * r, hy - 0.8 * r],
    ];
    out.push(el("feature", polygon(inner, darkHead ? "#6B5550" : pink, 3)));
  }
  out.push(el("body", ellipse(hx, hy, r * 1.08, r * 0.95, headFill)));
  if (coat.patchA) {
    out.push(el("detail", `<path d="M${f(hx - 1.05 * r)} ${f(hy - 0.1 * r)} C ${f(hx - 1.0 * r)} ${f(hy - 0.9 * r)}, ${f(hx - 0.4 * r)} ${f(hy - 1.0 * r)}, ${f(hx - 0.12 * r)} ${f(hy - 0.82 * r)} C ${f(hx - 0.3 * r)} ${f(hy - 0.4 * r)}, ${f(hx - 0.6 * r)} ${f(hy - 0.05 * r)}, ${f(hx - 1.05 * r)} ${f(hy - 0.1 * r)} Z" fill="${coat.patchA}"/>`));
    out.push(el("detail", `<path d="M${f(hx + 0.2 * r)} ${f(hy - 0.88 * r)} C ${f(hx + 0.5 * r)} ${f(hy - 1.0 * r)}, ${f(hx + 1.0 * r)} ${f(hy - 0.8 * r)}, ${f(hx + 1.06 * r)} ${f(hy - 0.15 * r)} C ${f(hx + 0.7 * r)} ${f(hy - 0.3 * r)}, ${f(hx + 0.4 * r)} ${f(hy - 0.5 * r)}, ${f(hx + 0.2 * r)} ${f(hy - 0.88 * r)} Z" fill="${coat.patchB}"/>`));
  }
  if (coat.hachiware) {
    // 額の中央から逆 V 字に白を広げる
    out.push(el("detail", `<path d="M${f(hx)} ${f(hy - 0.62 * r)} C ${f(hx - 0.2 * r)} ${f(hy - 0.2 * r)}, ${f(hx - 0.9 * r)} ${f(hy + 0.05 * r)}, ${f(hx - 1.0 * r)} ${f(hy + 0.38 * r)} C ${f(hx - 0.7 * r)} ${f(hy + 1.0 * r)}, ${f(hx + 0.7 * r)} ${f(hy + 1.0 * r)}, ${f(hx + 1.0 * r)} ${f(hy + 0.38 * r)} C ${f(hx + 0.9 * r)} ${f(hy + 0.05 * r)}, ${f(hx + 0.2 * r)} ${f(hy - 0.2 * r)}, ${f(hx)} ${f(hy - 0.62 * r)} Z" fill="${coat.light}"/>`));
  } else {
    out.push(el("detail", ellipse(hx, hy + 0.4 * r, r * 0.6, r * 0.42, coat.light)));
  }
  if (coat.stripe) {
    for (const dx of [-0.22, 0, 0.22]) {
      out.push(el("detail", stroke(`M${f(hx + dx * r)} ${f(hy - 0.86 * r)} L ${f(hx + dx * 0.8 * r)} ${f(hy - (dx === 0 ? 0.52 : 0.6) * r)}`, coat.stripe, 3.4)));
    }
    for (const side of [-1, 1]) {
      out.push(el("detail", stroke(`M${f(hx + side * 1.04 * r)} ${f(hy + 0.02 * r)} L ${f(hx + side * 0.8 * r)} ${f(hy + 0.06 * r)}`, coat.stripe, 3)));
      out.push(el("detail", stroke(`M${f(hx + side * 1.0 * r)} ${f(hy + 0.22 * r)} L ${f(hx + side * 0.78 * r)} ${f(hy + 0.22 * r)}`, coat.stripe, 3)));
    }
  }
  const ey = hy + 0.02 * r;
  for (const side of [-1, 1]) {
    const ex = hx + side * 0.4 * r;
    const lineColor = darkHead && !coat.hachiware ? "#F3E7DA" : outlineDark;
    if (eyes === "closed") {
      out.push(el("feature", stroke(`M${f(ex - 0.17 * r)} ${f(ey)} Q ${f(ex)} ${f(ey + 0.15 * r)} ${f(ex + 0.17 * r)} ${f(ey)}`, lineColor, 2.6)));
    } else if (eyes === "happy") {
      out.push(el("feature", stroke(`M${f(ex - 0.17 * r)} ${f(ey + 0.06 * r)} Q ${f(ex)} ${f(ey - 0.16 * r)} ${f(ex + 0.17 * r)} ${f(ey + 0.06 * r)}`, lineColor, 2.6)));
    } else {
      const rx = c.eye === "tall" && eyes !== "round" ? 0.16 * r : 0.19 * r;
      const ry = c.eye === "tall" && eyes !== "round" ? 0.22 * r : 0.19 * r;
      if (coat.dark) {
        out.push(el("feature", ellipse(ex, ey, rx, ry, coat.eye)));
        out.push(el("feature", ellipse(ex, ey + 0.02 * r, rx * 0.55, ry * 0.8, outlineDark)));
      } else {
        out.push(el("feature", ellipse(ex, ey, rx, ry, coat.eye)));
      }
      if (c.eye === "tall") {
        out.push(el("highlight", ellipse(ex + 0.05 * r, ey - 0.08 * r, 0.075 * r, 0.075 * r, "#FFFFFF")));
        out.push(el("highlight", ellipse(ex - 0.06 * r, ey + 0.1 * r, 0.035 * r, 0.035 * r, "#FFFFFF")));
      } else {
        out.push(el("highlight", ellipse(ex + 0.06 * r, ey - 0.06 * r, 0.09 * r, 0.09 * r, "#FFFFFF")));
      }
    }
  }
  if (c.blush) {
    for (const side of [-1, 1]) {
      out.push(el("detail", ellipse(hx + side * 0.66 * r, hy + 0.3 * r, 0.14 * r, 0.08 * r, pink, ` opacity="${eyes === "happy" ? 0.85 : 0.6}"`)));
    }
  }
  const ny = hy + 0.27 * r;
  out.push(el("feature", `<path d="M${f(hx - 0.08 * r)} ${f(ny)} Q ${f(hx)} ${f(ny - 0.03 * r)} ${f(hx + 0.08 * r)} ${f(ny)} Q ${f(hx + 0.04 * r)} ${f(ny + 0.08 * r)} ${f(hx)} ${f(ny + 0.09 * r)} Q ${f(hx - 0.04 * r)} ${f(ny + 0.08 * r)} ${f(hx - 0.08 * r)} ${f(ny)} Z" fill="${pink}"/>`));
  out.push(el("feature", stroke(`M${f(hx - 0.14 * r)} ${f(ny + 0.13 * r)} Q ${f(hx - 0.07 * r)} ${f(ny + 0.22 * r)} ${f(hx)} ${f(ny + 0.1 * r)} Q ${f(hx + 0.07 * r)} ${f(ny + 0.22 * r)} ${f(hx + 0.14 * r)} ${f(ny + 0.13 * r)}`, coat.dark && !coat.hachiware ? "#F3E7DA" : outlineDark, 1.8)));
  return out;
}

/** 歩く・立ち止まる姿勢 (横向きの体)。`step` は歩く 2 コマの 0 / 1、立ち止まる時は null。 */
function standing(c, coat, step) {
  const groundY = 120;
  const legTop = groundY - c.legLen;
  const bodyCx = 58;
  const bodyCy = legTop - c.bodyRy * 0.35;
  const hx = bodyCx + c.bodyRx * 0.9;
  const hy = bodyCy - c.bodyRy * 0.55 - c.headR * 0.5;
  const out = [el("deco", ellipse(bodyCx + 6, groundY + 1.5, c.bodyRx + 8, 3.5, "rgba(0,0,0,0.13)"))];
  const tailBase = [bodyCx - c.bodyRx * 0.85, bodyCy - c.bodyRy * 0.1];
  const tail = step === null
    ? `M${f(tailBase[0])} ${f(tailBase[1])} C ${f(tailBase[0] - 18)} ${f(tailBase[1] - 4)}, ${f(tailBase[0] - 18)} ${f(tailBase[1] - 30)}, ${f(tailBase[0] - 6)} ${f(tailBase[1] - 36)}`
    : `M${f(tailBase[0])} ${f(tailBase[1])} C ${f(tailBase[0] - 16)} ${f(tailBase[1] - 2)}, ${f(tailBase[0] - 22)} ${f(tailBase[1] - 20)}, ${f(tailBase[0] - 16)} ${f(tailBase[1] - (step === 0 ? 30 : 26))}`;
  out.push(el("body", stroke(tail, coat.base, 9)));
  if (coat.stripe) {
    out.push(el("detail", `<path d="${tail}" fill="none" stroke="${coat.stripe}" stroke-width="9" stroke-dasharray="5 6" stroke-dashoffset="-4"/>`));
  }
  const legW = Math.min(12, c.bodyRx * 0.36);
  const legs = [
    { x: bodyCx - c.bodyRx * 0.55, far: false, phase: 0 },
    { x: bodyCx - c.bodyRx * 0.2, far: true, phase: 1 },
    { x: bodyCx + c.bodyRx * 0.35, far: false, phase: 1 },
    { x: bodyCx + c.bodyRx * 0.68, far: true, phase: 0 },
  ];
  const leg = (l, fill, pawFill) => {
    // 2 コマを交互に出した時に足の入れ替わりが小さい表示でも分かる振り幅にする
    const angle = step === null ? 0 : (l.phase === step ? 22 : -22);
    const x = l.x - legW / 2;
    return `<g transform="rotate(${angle} ${f(l.x)} ${f(legTop - 4)})"><rect x="${f(x)}" y="${f(legTop - 6)}" width="${f(legW)}" height="${f(c.legLen + 6)}" rx="${f(legW / 2)}" fill="${fill}"/><ellipse cx="${f(l.x)}" cy="${f(groundY - legW * 0.3)}" rx="${f(legW / 2)}" ry="${f(legW * 0.32)}" fill="${pawFill}"/></g>`;
  };
  for (const l of legs.filter((l) => l.far)) {
    out.push(el("body", leg(l, coat.shade, coat.shade)));
  }
  out.push(el("body", ellipse(bodyCx, bodyCy, c.bodyRx, c.bodyRy, coat.hachiware ? coat.base : "url(#base)")));
  if (coat.patchA) {
    out.push(el("detail", ellipse(bodyCx - c.bodyRx * 0.35, bodyCy - c.bodyRy * 0.35, c.bodyRx * 0.42, c.bodyRy * 0.55, coat.patchB)));
    out.push(el("detail", ellipse(bodyCx + c.bodyRx * 0.3, bodyCy - c.bodyRy * 0.5, c.bodyRx * 0.3, c.bodyRy * 0.4, coat.patchA)));
  }
  if (coat.stripe) {
    for (const dx of [-0.5, -0.15, 0.2]) {
      out.push(el("detail", stroke(`M${f(bodyCx + dx * c.bodyRx)} ${f(bodyCy - c.bodyRy * 0.95)} Q ${f(bodyCx + (dx + 0.06) * c.bodyRx)} ${f(bodyCy - c.bodyRy * 0.55)} ${f(bodyCx + (dx + 0.02) * c.bodyRx)} ${f(bodyCy - c.bodyRy * 0.2)}`, coat.stripe, 3.4)));
    }
  }
  out.push(el("detail", ellipse(bodyCx + c.bodyRx * 0.15, bodyCy + c.bodyRy * 0.48, c.bodyRx * 0.6, c.bodyRy * 0.42, coat.light)));
  for (const l of legs.filter((l) => !l.far)) {
    out.push(el("body", leg(l, coat.base, coat.hachiware ? coat.light : coat.base)));
  }
  out.push(...head(c, coat, hx, hy, "open"));
  return out;
}

/** 座る姿勢と、それを元にした毛づくろい・喜ぶ姿勢。`variant` は sit / groom / delighted。 */
function sitting(c, coat, variant) {
  const groundY = 120;
  const bodyRy = c.bodyRy * 1.35 + c.legLen * 0.25;
  const bodyRx = c.bodyRx * 0.78;
  const bodyCx = 62;
  const bodyCy = groundY - bodyRy;
  const hx = bodyCx;
  const hy = bodyCy - bodyRy * 0.7 - c.headR * 0.5;
  const out = [el("deco", ellipse(bodyCx, groundY + 1.5, bodyRx + 12, 3.5, "rgba(0,0,0,0.13)"))];
  const tail = variant === "delighted"
    ? `M${f(bodyCx - bodyRx * 0.6)} ${f(groundY - 6)} C ${f(bodyCx - bodyRx - 22)} ${f(groundY - 4)}, ${f(bodyCx - bodyRx - 18)} ${f(bodyCy - bodyRy * 0.9)}, ${f(bodyCx - bodyRx - 4)} ${f(bodyCy - bodyRy * 1.05)}`
    : `M${f(bodyCx - bodyRx * 0.4)} ${f(groundY - 3)} C ${f(bodyCx - bodyRx - 24)} ${f(groundY)}, ${f(bodyCx - bodyRx - 22)} ${f(groundY - 26)}, ${f(bodyCx - bodyRx - 12)} ${f(groundY - 32)}`;
  out.push(el("body", stroke(tail, coat.base, 9)));
  if (coat.stripe) {
    out.push(el("detail", `<path d="${tail}" fill="none" stroke="${coat.stripe}" stroke-width="9" stroke-dasharray="5 6" stroke-dashoffset="-4"/>`));
  }
  for (const side of [-1, 1]) {
    out.push(el("body", ellipse(bodyCx + side * bodyRx * 0.62, groundY - bodyRy * 0.4, bodyRx * 0.48, bodyRy * 0.42, coat.base)));
  }
  out.push(el("body", ellipse(bodyCx, bodyCy, bodyRx, bodyRy, coat.hachiware ? coat.base : "url(#base)")));
  if (coat.patchA) {
    out.push(el("detail", ellipse(bodyCx - bodyRx * 0.55, bodyCy - bodyRy * 0.1, bodyRx * 0.45, bodyRy * 0.5, coat.patchB)));
    out.push(el("detail", ellipse(bodyCx + bodyRx * 0.6, bodyCy + bodyRy * 0.25, bodyRx * 0.35, bodyRy * 0.4, coat.patchA)));
  }
  if (coat.stripe) {
    for (const side of [-1, 1]) {
      for (const dy of [-0.3, 0.1]) {
        out.push(el("detail", stroke(`M${f(bodyCx + side * bodyRx * 0.98)} ${f(bodyCy + dy * bodyRy)} Q ${f(bodyCx + side * bodyRx * 0.8)} ${f(bodyCy + (dy + 0.04) * bodyRy)} ${f(bodyCx + side * bodyRx * 0.68)} ${f(bodyCy + (dy + 0.12) * bodyRy)}`, coat.stripe, 3.2)));
      }
    }
  }
  out.push(el("detail", ellipse(bodyCx, bodyCy + bodyRy * 0.15, bodyRx * 0.52, bodyRy * 0.62, coat.light)));
  const pawW = Math.max(6, bodyRx * 0.24);
  const pawFill = coat.hachiware || coat.patchA ? coat.light : coat.base;
  for (const side of [-1, 1]) {
    if (variant === "groom" && side === 1) {
      continue;
    }
    out.push(el("body", ellipse(bodyCx + side * pawW * 1.05, groundY - pawW * 0.55, pawW, pawW * 0.62, pawFill)));
  }
  out.push(...head(c, coat, hx, hy, variant === "sit" ? "open" : variant === "groom" ? "closed" : "happy"));
  if (variant === "groom") {
    const px = hx + c.headR * 0.42;
    const py = hy + c.headR * 0.62;
    out.push(el("body", stroke(`M${f(bodyCx + bodyRx * 0.35)} ${f(bodyCy + bodyRy * 0.2)} Q ${f(px + 6)} ${f(py + 12)} ${f(px)} ${f(py)}`, coat.base, pawW * 1.6)));
    out.push(el("body", ellipse(px, py, pawW * 0.95, pawW * 1.05, pawFill)));
    out.push(el("feature", ellipse(px - pawW * 0.7, py - pawW * 0.4, pawW * 0.32, pawW * 0.45, pink)));
  }
  if (variant === "delighted") {
    const x = hx + c.headR * 1.05;
    const y = hy - c.headR * 1.0;
    out.push(el("mark", `<path d="M${f(x)} ${f(y + 9)} C ${f(x - 11)} ${f(y + 1)}, ${f(x - 7)} ${f(y - 8)}, ${f(x)} ${f(y - 3)} C ${f(x + 7)} ${f(y - 8)}, ${f(x + 11)} ${f(y + 1)}, ${f(x)} ${f(y + 9)} Z" fill="#F47C8A"/>`));
  }
  return out;
}

/** 丸まって眠る姿勢。 */
function sleeping(c, coat) {
  const groundY = 120;
  const bodyRx = c.bodyRx * 1.3;
  const bodyRy = c.bodyRy + 2;
  const bodyCx = 56;
  const bodyCy = groundY - bodyRy;
  const hr = c.headR * 0.85;
  const hx = bodyCx + bodyRx * 0.62;
  const hy = groundY - hr * 0.98;
  const out = [el("deco", ellipse(bodyCx + 8, groundY + 1.5, bodyRx + 12, 3.5, "rgba(0,0,0,0.13)"))];
  out.push(el("body", ellipse(bodyCx, bodyCy, bodyRx, bodyRy, coat.hachiware ? coat.base : "url(#base)")));
  if (coat.patchA) {
    out.push(el("detail", ellipse(bodyCx - bodyRx * 0.4, bodyCy - bodyRy * 0.3, bodyRx * 0.4, bodyRy * 0.55, coat.patchB)));
    out.push(el("detail", ellipse(bodyCx + bodyRx * 0.05, bodyCy - bodyRy * 0.45, bodyRx * 0.3, bodyRy * 0.4, coat.patchA)));
  }
  if (coat.stripe) {
    for (const dx of [-0.6, -0.3, 0]) {
      out.push(el("detail", stroke(`M${f(bodyCx + dx * bodyRx)} ${f(bodyCy - bodyRy * 0.95)} Q ${f(bodyCx + (dx + 0.05) * bodyRx)} ${f(bodyCy - bodyRy * 0.5)} ${f(bodyCx + (dx + 0.02) * bodyRx)} ${f(bodyCy - bodyRy * 0.15)}`, coat.stripe, 3.4)));
    }
  }
  // しっぽを体の手前に巻き付け、丸まって眠っている形にする
  const tail = `M${f(bodyCx - bodyRx * 0.92)} ${f(bodyCy + bodyRy * 0.05)} C ${f(bodyCx - bodyRx * 1.0)} ${f(groundY - 2)}, ${f(bodyCx - bodyRx * 0.1)} ${f(groundY - 1)}, ${f(bodyCx + bodyRx * 0.4)} ${f(groundY - 9)}`;
  out.push(el("body", stroke(tail, coat.base, 8)));
  if (coat.stripe) {
    out.push(el("detail", `<path d="${tail}" fill="none" stroke="${coat.stripe}" stroke-width="8" stroke-dasharray="5 7" stroke-dashoffset="-6"/>`));
  }
  const sleepCoat = { ...coat };
  out.push(...head({ ...c, headR: hr }, sleepCoat, hx, hy, "closed"));
  const zx = hx + hr * 0.6;
  const zy = hy - hr * 1.45;
  out.push(el("mark", stroke(`M${f(zx)} ${f(zy)} h7 l-7 7 h7`, "#8FA3C8", 2.4)));
  out.push(el("mark", stroke(`M${f(zx + 10)} ${f(zy - 10)} h5 l-5 5 h5`, "#8FA3C8", 2)));
  return out;
}

/** 首の後ろをつままれて持ち上げられた姿勢 (macOS のドラッグ中)。 */
function lifted(c, coat) {
  const hx = 64;
  const hy = 12 + c.headR * 1.15;
  const bodyRx = c.bodyRx * 0.62;
  const bodyRy = c.bodyRy * 1.4 + c.legLen * 0.3;
  const bodyCy = hy + c.headR * 0.55 + bodyRy * 0.85;
  const out = [];
  const legW = Math.min(11, bodyRx * 0.45);
  const legTop = bodyCy + bodyRy * 0.55;
  const legLen = Math.max(c.legLen, 8) + 4;
  const tail = `M${f(hx + bodyRx * 0.3)} ${f(bodyCy + bodyRy * 0.6)} C ${f(hx + bodyRx * 0.5)} ${f(bodyCy + bodyRy * 1.3)}, ${f(hx + bodyRx * 1.4)} ${f(bodyCy + bodyRy * 1.1)}, ${f(hx + bodyRx * 1.5)} ${f(bodyCy + bodyRy * 0.7)}`;
  out.push(el("body", stroke(tail, coat.base, 8)));
  for (const dx of [-0.55, 0.55]) {
    out.push(el("body", `<rect x="${f(hx + dx * bodyRx - legW / 2)}" y="${f(legTop)}" width="${f(legW)}" height="${f(legLen)}" rx="${f(legW / 2)}" fill="${coat.base}"/>`));
  }
  out.push(el("body", ellipse(hx, bodyCy, bodyRx, bodyRy, coat.hachiware ? coat.base : "url(#base)")));
  out.push(el("detail", ellipse(hx, bodyCy + bodyRy * 0.12, bodyRx * 0.58, bodyRy * 0.68, coat.light)));
  if (coat.stripe) {
    for (const side of [-1, 1]) {
      out.push(el("detail", stroke(`M${f(hx + side * bodyRx * 0.98)} ${f(bodyCy - bodyRy * 0.1)} L ${f(hx + side * bodyRx * 0.72)} ${f(bodyCy)}`, coat.stripe, 3)));
    }
  }
  for (const side of [-1, 1]) {
    out.push(el("body", stroke(`M${f(hx + side * bodyRx * 0.8)} ${f(bodyCy - bodyRy * 0.6)} Q ${f(hx + side * bodyRx * 1.15)} ${f(bodyCy - bodyRy * 0.1)} ${f(hx + side * bodyRx * 0.75)} ${f(bodyCy + bodyRy * 0.15)}`, coat.base, legW)));
  }
  out.push(...head(c, coat, hx, hy, "round"));
  return out;
}

/** 姿勢 `pose` の要素の並び (描く順)。 */
function elements(c, coat, pose) {
  switch (pose) {
    case "walk1":
      return standing(c, coat, 0);
    case "walk2":
      return standing(c, coat, 1);
    case "stand":
      return standing(c, coat, null);
    case "sit":
      return sitting(c, coat, "sit");
    case "groom":
      return sitting(c, coat, "groom");
    case "delighted":
      return sitting(c, coat, "delighted");
    case "sleep":
      return sleeping(c, coat);
    case "lifted":
      return lifted(c, coat);
    default:
      throw new Error(`unknown pose: ${pose}`);
  }
}

/**
 * 案 `candidateKey`・柄 `coatKey`・姿勢 `pose` の SVG 文字列を返す。
 * `mono` が true なら、ロック画面・コンプリケーション向けに白 1 色の輪郭から目・鼻・口を抜いた絵にする。
 * `idPrefix` は同じ HTML に複数の SVG を並べる時に gradient・mask の id が衝突しないようにするための接頭辞。
 */
export function catSVG({ candidateKey, coatKey, pose, mono = false, idPrefix = "" }) {
  const c = candidates[candidateKey];
  const coat = coats[coatKey];
  const items = elements(c, coat, pose);
  const gradientId = `${idPrefix}base`;
  const fix = (svg) => svg.replaceAll("url(#base)", `url(#${gradientId})`);
  if (!mono) {
    // 均一なフラット塗りにしないよう、左上から光が当たる柔らかい陰影を体と頭に付ける
    const defs = `<defs><radialGradient id="${gradientId}" cx="0.38" cy="0.32" r="0.75"><stop offset="0" stop-color="${mix(coat.base, "#FFFFFF", coat.dark ? 0.12 : 0.28)}"/><stop offset="0.65" stop-color="${coat.base}"/><stop offset="1" stop-color="${coat.shade}"/></radialGradient></defs>`;
    return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128" width="128" height="128">${defs}${items.map((i) => fix(i.svg)).join("")}</svg>`;
  }
  const maskId = `${idPrefix}mono`;
  const white = (svg) => svg.replace(/(fill|stroke)="(?!none)[^"]*"/g, '$1="#FFFFFF"').replaceAll("url(#base)", "#FFFFFF");
  const black = (svg) => svg.replace(/(fill|stroke)="(?!none)[^"]*"/g, '$1="#000000"');
  const maskBody = items
    .map((i) => {
      switch (i.role) {
        case "body":
          return white(i.svg);
        case "feature":
          return black(i.svg);
        case "highlight":
          return white(i.svg);
        default:
          return "";
      }
    })
    .join("");
  const marks = items.filter((i) => i.role === "mark").map((i) => white(i.svg)).join("");
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128" width="128" height="128"><defs><mask id="${maskId}" maskUnits="userSpaceOnUse" x="0" y="0" width="128" height="128">${maskBody}</mask></defs><rect width="128" height="128" fill="#FFFFFF" mask="url(#${maskId})"/>${marks}</svg>`;
}

/** 16 進の色 `a` と `b` を `t` (0〜1) の割合で混ぜた色を返す。 */
function mix(a, b, t) {
  const pa = [1, 3, 5].map((i) => parseInt(a.slice(i, i + 2), 16));
  const pb = [1, 3, 5].map((i) => parseInt(b.slice(i, i + 2), 16));
  return `#${pa.map((v, i) => Math.round(v + (pb[i] - v) * t).toString(16).padStart(2, "0")).join("")}`;
}
