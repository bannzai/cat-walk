// 猫の絵 (姿勢ごとの SVG) の唯一の定義。アプリの画像・アプリアイコン・og.png・紹介サイトの猫は、
// どれも build.mjs がこのファイルから書き出すため、見た目を変える時はここだけを直して build.mjs を実行し直す。
// 座標は 128x128 の viewBox で、地面は y = 120、猫は右を向く (左向きは描画側の左右反転で表す)。
// 絵は素人が描いた手抜きの落書き調にする (bannzai の返答「猫がちょっと可愛すぎる。もっと素人が書いたような手抜きの絵に」)。
// 線のガタつきは乱数で作るが、乱数の種を案・姿勢・部位の名前から決めるため、同じ入力からは毎回同じ絵になる。

/** 絵の方向の案。bannzai に PR で見比べてもらうため、線の雑さの度合いを軸に変えてある。 */
export const candidates = {
  // 輪郭は少しガタつく程度。塗りは線から少しずれる
  a: { label: "案 A ちょっと雑", points: 12, wobble: 0.05, jitter: 1.0, lineW: 2.8, fill: true, fillShift: 2.2, fillScale: 0.97 },
  // 輪郭の点を減らして角張らせ、ガタつきも大きくする。塗りは大きくずれて、はみ出しと塗り残しがはっきり出る
  b: { label: "案 B かなり雑", points: 8, wobble: 0.1, jitter: 2.2, lineW: 3.2, fill: true, fillShift: 5, fillScale: 0.88 },
  // 塗らずに太いマーカーの線だけで描く、ホワイトボードの落書き。柄は線の色だけで出す
  c: { label: "案 C ホワイトボードの落書き", points: 10, wobble: 0.08, jitter: 1.8, lineW: 4.2, fill: false, fillShift: 0, fillScale: 1 },
};

/** 柄の配色。キーは `CatWalkCore` の `CatCoat` の raw value と同じで、アプリの画像名 `cat-<柄>-<姿勢>` になる。 */
export const coats = {
  chatora: { label: "茶トラ", base: "#F2A65A", stripe: "#C8641E" },
  mike: { label: "三毛", base: "#FFFDF8", patchA: "#F2A65A", patchB: "#3B3330" },
  kuro: { label: "黒", base: "#3A3431", eye: "#F2D24B", dark: true },
  shiro: { label: "白", base: "#FFFDF8" },
  sabatora: { label: "サバトラ", base: "#B4B8BD", stripe: "#5E646B" },
  hachiware: { label: "ハチワレ", base: "#FFFDF8", cap: "#3A3431" },
};

/** アプリが使う姿勢の名前。Asset Catalog の画像名 `cat-<柄>-<名前>` (単色の絵は柄に依らず `cat-<名前>-mono`) になる。 */
export const poses = ["walk1", "walk2", "stand", "sit", "sleep", "groom", "delighted", "lifted"];

/** 線の色 (鉛筆・マーカーの黒)。 */
const ink = "#3A2E29";
/** 紙の色。どの背景 (暗いデスクトップ・紹介サイト) でも猫が見えるよう、絵の下に切り抜いた紙のように敷く。 */
const paper = "#FFFDF7";

// 要素は role で、色の絵と単色 (ロック画面・コンプリケーション) の絵のどちらに出すかを分ける。
// paper: 絵の下に敷く紙の縁。色の絵だけ
// fill: 線からずらして塗った色。色の絵だけ
// silhouette: 線のとおりの形。単色の絵だけで、白で塗る
// line: 輪郭・足・しっぽの線。色の絵は線の色、単色の絵は白
// detail: 縞・ぶち。色の絵だけ
// feature: 目・口。色の絵は線の色、単色の絵は形から抜く
// mark: 眠りの z・喜びのハート。単色の絵でも白で出す
// deco: 地面の線。色の絵だけ

const f = (n) => Math.round(n * 100) / 100;
const pointsAttr = (pts) => pts.map(([x, y]) => `${f(x)},${f(y)}`).join(" ");
const polyline = (pts, color, width) => `<polyline points="${pointsAttr(pts)}" fill="none" stroke="${color}" stroke-width="${f(width)}" stroke-linecap="round" stroke-linejoin="round"/>`;
const polygon = (pts, fill, stroke = "none", width = 0) => `<polygon points="${pointsAttr(pts)}" fill="${fill}"${stroke === "none" ? "" : ` stroke="${stroke}" stroke-width="${f(width)}" stroke-linejoin="round"`}/>`;

/** 文字列 `s` の 32bit のハッシュ (FNV-1a)。乱数の種に使う。 */
function hash(s) {
  let h = 2166136261;
  for (const ch of s) {
    h ^= ch.codePointAt(0);
    h = Math.imul(h, 16777619);
  }
  return h >>> 0;
}

/** 種 `seed` から 0 以上 1 未満の乱数を順に返す関数を作る (mulberry32)。 */
function mulberry32(seed) {
  let a = seed;
  return () => {
    a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

/** 1 枚の絵を描く間の状態。描いた要素を role 付きで `items` に積む。 */
class Doodle {
  /** `mono` は単色の絵を描くか。単色の絵はロック画面・コンプリケーションの 22〜24pt で目・口が潰れないよう、目・口だけを太くする。 */
  constructor(candidate, coat, seedBase, mono) {
    this.c = candidate;
    this.coat = coat;
    this.seedBase = seedBase;
    this.featureScale = mono ? 1.8 : 1;
    this.items = [];
  }

  /** 部位 `name` ごとに決まった乱数の列。部位を足しても他の部位の形が変わらないよう、部位ごとに種を分ける。 */
  rng(name) {
    const r = mulberry32(hash(`${this.seedBase}:${name}`));
    return (amp = 1) => (r() * 2 - 1) * amp;
  }

  push(role, svg) {
    this.items.push({ role, svg });
  }

  /** 体の塗りの色。ハチワレは白い体に黒い帽子 (頭の detail) を描く。 */
  get bodyColor() {
    return this.coat.base;
  }

  /** 目・口の色。黒猫は黒い塗りに線の色が埋もれるため目の色で描く。 */
  get featureColor() {
    return this.coat.dark ? this.coat.eye : ink;
  }

  /** 中心 (`cx`, `cy`)・半径 (`rx`, `ry`) の楕円を、点を減らしてガタつかせた多角形の点の列。 */
  blobPoints(name, cx, cy, rx, ry) {
    const n = this.rng(name);
    const count = this.c.points;
    const start = n(Math.PI);
    return Array.from({ length: count }, (_, i) => {
      const a = start + (i * 2 * Math.PI) / count + n(0.15);
      const k = 1 + n(this.c.wobble);
      return [cx + Math.cos(a) * rx * k + n(this.c.jitter), cy + Math.sin(a) * ry * k + n(this.c.jitter)];
    });
  }

  /** 線 `pts` を、途中の点をずらし、区間ごとに太さを変えた手描きの線として描く。 */
  line(name, pts, { color = ink, width = this.c.lineW, role = "line", onPaper = true } = {}) {
    const n = this.rng(name);
    const shaky = pts.map(([x, y], i) => (i === 0 || i === pts.length - 1 ? [x + n(this.c.jitter * 0.4), y + n(this.c.jitter * 0.4)] : [x + n(this.c.jitter * 0.7), y + n(this.c.jitter * 0.7)]));
    if (onPaper) {
      this.push("paper", polyline(shaky, paper, width + 5));
    }
    for (let i = 0; i < shaky.length - 1; i++) {
      this.push(role, polyline([shaky[i], shaky[i + 1]], color, width * (0.75 + Math.abs(n(0.55)))));
    }
  }

  /** 点の列 `pts` で囲まれた部位を、紙・ずれた塗り・輪郭の線で描く。輪郭は閉じきらずに描き始めを少し越えて終わる。 */
  part(name, pts, fill = this.bodyColor) {
    const n = this.rng(`${name}:fill`);
    this.push("paper", polygon(pts, paper, paper, 5));
    if (this.c.fill) {
      const cx = pts.reduce((s, p) => s + p[0], 0) / pts.length;
      const cy = pts.reduce((s, p) => s + p[1], 0) / pts.length;
      const angle = n(Math.PI);
      const dx = Math.cos(angle) * this.c.fillShift;
      const dy = Math.sin(angle) * this.c.fillShift;
      this.push("fill", polygon(pts.map(([x, y]) => [cx + (x - cx) * this.c.fillScale + dx, cy + (y - cy) * this.c.fillScale + dy]), fill));
    }
    this.push("silhouette", polygon(pts, "#FFFFFF"));
    const overshoot = [pts[1][0] * 0.4 + pts[0][0] * 0.6 + n(2), pts[1][1] * 0.4 + pts[0][1] * 0.6 + n(2)];
    this.line(`${name}:line`, [...pts, pts[0], overshoot], { onPaper: false });
  }

  /** 楕円の部位 (体・頭) を描く。 */
  blob(name, cx, cy, rx, ry, fill) {
    this.part(name, this.blobPoints(name, cx, cy, rx, ry), fill);
  }

  /** 色の絵だけに出す、雑に塗ったぶち。 */
  patch(name, cx, cy, rx, ry, color) {
    this.push("detail", polygon(this.blobPoints(name, cx, cy, rx, ry), color));
  }

  /** 縞を短い線で描く (案 C は塗りが無いため、縞の線が柄の色になる)。 */
  stripes(name, segments) {
    if (!this.coat.stripe) {
      return;
    }
    segments.forEach((seg, i) => this.line(`${name}${i}`, seg, { color: this.coat.stripe, width: this.c.lineW * 0.8, role: "detail", onPaper: false }));
  }

  /** 目・口などの線を、紙を敷かずに描く。 */
  feature(name, pts, width = 1.8) {
    const n = this.rng(name);
    this.push("feature", polyline(pts.map(([x, y]) => [x + n(0.4), y + n(0.4)]), this.featureColor, width * this.featureScale));
  }

  dot(name, x, y, r) {
    const n = this.rng(name);
    this.push("feature", `<circle cx="${f(x + n(0.6))}" cy="${f(y + n(0.6))}" r="${f(r * (1 + n(0.2)) * this.featureScale)}" fill="${this.featureColor}"/>`);
  }
}

/**
 * 頭 (耳・顔・柄・目・口・ひげ) を描く。`eyes` は open (点) / closed (眠り・毛づくろいの -) / happy (喜びの ^) / round (持ち上げられて驚いた大きめの点)。
 * 左右の耳の高さと目の位置をわざと揃えない。
 */
function head(d, hx, hy, r, eyes) {
  const n = d.rng("head:shape");
  for (const side of [-1, 1]) {
    const tipUp = side === -1 ? 1.25 + n(0.12) : 1.05 + n(0.12);
    d.part(`ear${side}`, [
      [hx + side * r * 0.95, hy - r * 0.2],
      [hx + side * (r * 0.72 + n(2)), hy - r * tipUp],
      [hx + side * r * 0.15, hy - r * 0.78],
    ]);
  }
  d.blob("head", hx, hy, r * 1.1, r * 0.9);
  if (d.coat.cap) {
    d.patch("cap", hx + r * 0.1, hy - r * 0.55, r * 0.95, r * 0.38, d.coat.cap);
  }
  if (d.coat.patchA) {
    d.patch("headPatch", hx - r * 0.55, hy - r * 0.45, r * 0.45, r * 0.32, d.coat.patchA);
  }
  d.stripes("headStripe", [
    [[hx - r * 0.2, hy - r * 0.85], [hx - r * 0.15, hy - r * 0.5]],
    [[hx + r * 0.15, hy - r * 0.88], [hx + r * 0.12, hy - r * 0.55]],
  ]);
  const ey = hy + r * 0.05;
  const eyePos = [[hx - r * 0.42 + n(1.2), ey + n(1.5)], [hx + r * 0.33 + n(1.2), ey + n(1.5)]];
  eyePos.forEach(([ex, y], i) => {
    if (eyes === "closed") {
      d.feature(`eye${i}`, [[ex - 3, y], [ex + 3, y + n(0.8)]]);
    } else if (eyes === "happy") {
      d.feature(`eye${i}`, [[ex - 3, y + 1.5], [ex, y - 1.5], [ex + 3, y + 1.5]]);
    } else {
      // 大きめの点の目は、単色の絵で 1.8 倍にすると口とつながるため 1.4 倍に抑える
      d.dot(`eye${i}`, ex, y, eyes === "round" ? 2.6 * (d.featureScale > 1 ? 1.4 / d.featureScale : 1) : 1.8);
    }
  });
  // 単色の絵は目・口を太くするため、目と口の抜きがつながらないよう口を下げる。
  // 閉じた目は縦に細く隙間が残りやすい一方、眠る姿勢は頭が小さく口が顎からはみ出すため、下げ幅を小さくする
  const my = hy + r * (d.featureScale > 1 ? (eyes === "closed" ? 0.48 : 0.56) : 0.42);
  const mx = hx - r * 0.04 + n(1);
  d.feature("mouth", [[mx - 3.2, my - 0.6], [mx - 1.6, my + 1.4], [mx, my - 0.2], [mx + 1.6, my + 1.4], [mx + 3.2, my - 0.6]], 1.5);
  for (const side of [-1, 1]) {
    d.line(`whisker${side}`, [[hx + side * r * 0.75, hy + r * 0.3], [hx + side * r * 1.45, hy + r * 0.2 + n(2)]], { width: d.c.lineW * 0.45 });
  }
}

/** 地面の線。色の絵だけに出す。 */
function ground(d, x0, x1) {
  d.line("ground", [[x0, 121], [(x0 + x1) / 2, 121.5], [x1, 120.5]], { color: "#C9C1B5", width: 1.6, role: "deco", onPaper: false });
}

/** 歩く・立ち止まる姿勢 (横向きの体)。`step` は歩く 2 コマの 0 / 1、立ち止まる時は null。足としっぽは線 1 本で描く。 */
function standing(d, step) {
  ground(d, 20, 100);
  const legs = [36, 47, 67, 77];
  legs.forEach((x, i) => {
    const swing = step === null ? 0 : (i % 2 === step ? 8 : -8);
    d.line(`leg${i}`, [[x, 100], [x + swing * 0.4, 110], [x + swing, 119]]);
  });
  const tipY = step === 1 ? 58 : 62;
  d.line("tail", [[30, 92], [20, 88], [15, 76], [19, tipY]]);
  d.blob("body", 56, 96, 30, 14);
  if (d.coat.patchB) {
    d.patch("bodyPatchB", 46, 92, 10, 7, d.coat.patchB);
    d.patch("bodyPatchA", 64, 96, 8, 6, d.coat.patchA);
  }
  if (d.coat.cap) {
    d.patch("bodyCap", 50, 88, 12, 5, d.coat.cap);
  }
  d.stripes("bodyStripe", [
    [[44, 84], [46, 94]],
    [[54, 83], [55, 93]],
    [[64, 84], [63, 92]],
  ]);
  head(d, 86, 78, 17, "open");
}

/** 座る姿勢と、それを元にした毛づくろい・喜ぶ姿勢。`variant` は sit / groom / delighted。 */
function sitting(d, variant) {
  ground(d, 26, 98);
  d.line("tail", variant === "delighted" ? [[48, 116], [34, 114], [28, 100], [32, 86]] : [[50, 118], [34, 119], [24, 113], [27, 104]]);
  d.blob("body", 62, 100, 20, 19);
  if (d.coat.patchB) {
    d.patch("bodyPatchB", 54, 98, 8, 9, d.coat.patchB);
    d.patch("bodyPatchA", 70, 106, 6, 6, d.coat.patchA);
  }
  d.stripes("bodyStripe", [
    [[46, 96], [52, 98]],
    [[46, 104], [52, 105]],
    [[78, 95], [72, 97]],
  ]);
  d.line("pawL", [[56, 108], [55, 119]]);
  if (variant !== "groom") {
    d.line("pawR", [[68, 108], [69, 119]]);
  }
  head(d, 62, 67, 18, variant === "sit" ? "open" : variant === "groom" ? "closed" : "happy");
  if (variant === "groom") {
    d.line("pawR", [[70, 104], [77, 92], [70, 80]]);
  }
  if (variant === "delighted") {
    d.line("heart", [[88, 52], [81, 44], [83, 38], [88, 41], [93, 37], [96, 43], [88, 52]], { color: "#E2566A", width: 2.4, role: "mark" });
  }
}

/** 丸まって眠る姿勢。しっぽを体の手前に回す。 */
function sleeping(d) {
  ground(d, 16, 108);
  d.blob("body", 56, 108, 36, 12);
  if (d.coat.patchB) {
    d.patch("bodyPatchB", 44, 104, 10, 6, d.coat.patchB);
    d.patch("bodyPatchA", 62, 102, 8, 5, d.coat.patchA);
  }
  if (d.coat.cap) {
    d.patch("bodyCap", 50, 100, 14, 4, d.coat.cap);
  }
  d.stripes("bodyStripe", [
    [[38, 98], [40, 107]],
    [[50, 97], [51, 106]],
    [[62, 98], [61, 106]],
  ]);
  d.line("tail", [[22, 108], [28, 117], [56, 119], [74, 115]]);
  head(d, 86, 103, 15, "closed");
  d.line("z1", [[94, 78], [101, 78], [94, 85], [101, 85]], { color: "#6F86B8", width: 2.2, role: "mark" });
  d.line("z2", [[105, 66], [110, 66], [105, 71], [110, 71]], { color: "#6F86B8", width: 1.8, role: "mark" });
}

/** 首の後ろをつままれて持ち上げられた姿勢 (macOS のドラッグ中)。足はだらんと下がる。 */
function lifted(d) {
  d.line("legL", [[58, 88], [56, 100], [57, 110]]);
  d.line("legR", [[70, 88], [72, 99], [71, 110]]);
  d.line("tail", [[66, 92], [72, 104], [82, 106], [88, 98]]);
  d.blob("body", 64, 70, 14, 24);
  if (d.coat.patchB) {
    d.patch("bodyPatchB", 60, 64, 7, 9, d.coat.patchB);
    d.patch("bodyPatchA", 68, 78, 5, 6, d.coat.patchA);
  }
  d.stripes("bodyStripe", [
    [[52, 66], [58, 68]],
    [[52, 76], [58, 77]],
    [[76, 66], [70, 68]],
  ]);
  d.line("armL", [[54, 54], [49, 64], [50, 72]]);
  d.line("armR", [[74, 54], [79, 64], [78, 72]]);
  head(d, 64, 30, 17, "round");
}

/** 姿勢 `pose` を `d` に描く。 */
function drawPose(d, pose) {
  switch (pose) {
    case "walk1":
      return standing(d, 0);
    case "walk2":
      return standing(d, 1);
    case "stand":
      return standing(d, null);
    case "sit":
      return sitting(d, "sit");
    case "groom":
      return sitting(d, "groom");
    case "delighted":
      return sitting(d, "delighted");
    case "sleep":
      return sleeping(d);
    case "lifted":
      return lifted(d);
    default:
      throw new Error(`unknown pose: ${pose}`);
  }
}

/**
 * 案 `candidateKey`・柄 `coatKey`・姿勢 `pose` の SVG 文字列を返す。
 * `mono` が true なら、ロック画面・コンプリケーション向けに白 1 色の形から目・口を抜いた絵にする。
 * `idPrefix` は同じ HTML に複数の SVG を並べる時に mask の id が衝突しないようにするための接頭辞。
 */
export function catSVG({ candidateKey, coatKey, pose, mono = false, idPrefix = "" }) {
  // 柄で形が変わらないよう、乱数の種には案と姿勢だけを使う
  const d = new Doodle(candidates[candidateKey], coats[coatKey], `${candidateKey}:${pose}`, mono);
  drawPose(d, pose);
  const items = d.items;
  if (!mono) {
    // 紙はどの部位の線にも重ならないよう、いちばん下にまとめて敷く
    const ordered = [...items.filter((i) => i.role === "paper"), ...items.filter((i) => i.role !== "paper" && i.role !== "silhouette")];
    return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128" width="128" height="128">${ordered.map((i) => i.svg).join("")}</svg>`;
  }
  const maskId = `${idPrefix}mono`;
  const white = (svg) => svg.replace(/(fill|stroke)="(?!none)[^"]*"/g, '$1="#FFFFFF"');
  const black = (svg) => svg.replace(/(fill|stroke)="(?!none)[^"]*"/g, '$1="#000000"');
  const maskBody = items
    .map((i) => {
      switch (i.role) {
        case "silhouette":
        case "line":
          return white(i.svg);
        case "feature":
          return black(i.svg);
        default:
          return "";
      }
    })
    .join("");
  const marks = items.filter((i) => i.role === "mark").map((i) => white(i.svg)).join("");
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128" width="128" height="128"><defs><mask id="${maskId}" maskUnits="userSpaceOnUse" x="0" y="0" width="128" height="128">${maskBody}</mask></defs><rect width="128" height="128" fill="#FFFFFF" mask="url(#${maskId})"/>${marks}</svg>`;
}
