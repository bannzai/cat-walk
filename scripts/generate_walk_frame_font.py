"""ウィジェットで猫をコマ送りで歩かせる試作のフォント `CatWalkFrames-Regular.ttf` を生成する。

数字 0〜9 の字形を、歩く猫の 10 コマにしたフォント。ウィジェットのタイマー表示 (`Text(_, style: .timer)`) は
秒の 1 の位が毎秒変わるため、その 1 文字だけを見せると 1 秒 1 コマで猫が動いて見える。
コマ 0〜4 で右へ歩き、5〜9 で向きを変えて左へ戻る。猫の絵は図形を組み合わせた仮のもので、アプリの猫の絵ではない。

実行: python3 -m venv tmp/fontvenv && tmp/fontvenv/bin/pip install fonttools
      tmp/fontvenv/bin/python scripts/generate_walk_frame_font.py
同じ入力から常に同じフォントを書き出す (冪等)。
"""

import math
from pathlib import Path

from fontTools.fontBuilder import FontBuilder
from fontTools.pens.ttGlyphPen import TTGlyphPen

UNITS_PER_EM = 1000
# 1 文字をウィジェットの横幅いっぱいの歩く範囲にするため、横長の 4 em にする。
# ウィジェット側はフォントの大きさを「横幅 / 4」にして、この字形の幅をウィジェットの幅に合わせる
GLYPH_ADVANCE = 4000
CAT_LENGTH = 1000
FRAME_COUNT = 10
FONT_NAME = "CatWalkFrames"
OUTPUT = Path(__file__).resolve().parent.parent / "CatWalkWidget" / "CatWalkFrames-Regular.ttf"


def ellipse(cx, cy, rx, ry, steps=32):
    """楕円を `steps` 角形で近似した頂点の列を返す。"""
    return [(cx + rx * math.cos(2 * math.pi * i / steps), cy + ry * math.sin(2 * math.pi * i / steps)) for i in range(steps)]


def band(points, width):
    """折れ線 `points` を太さ `width` の帯にした多角形の頂点の列を返す。"""
    left, right = [], []
    for i, (x, y) in enumerate(points):
        (x0, y0), (x1, y1) = points[max(i - 1, 0)], points[min(i + 1, len(points) - 1)]
        length = math.hypot(x1 - x0, y1 - y0) or 1
        nx, ny = -(y1 - y0) / length * width / 2, (x1 - x0) / length * width / 2
        left.append((x + nx, y + ny))
        right.append((x - nx, y - ny))
    return left + right[::-1]


def cat_contours(frame):
    """右向きの猫を、原点を後ろ足の下に置いた座標で多角形の列として返す。`frame` の偶奇で足の前後と体の上下が入れ替わる。"""
    stride = 70 if frame % 2 == 0 else -70
    bob = 15 if frame % 2 == 0 else 0
    tail = [(140 + 10 * t - 100 * t * t, 380 + bob + 300 * t) for t in [i / 8 for i in range(9)]]
    legs = [
        [(x - 30, 260 + bob), (x + 30, 260 + bob), (x + 30 + d, 0), (x - 30 + d, 0)]
        for x, d in [(230, stride), (330, -stride), (580, -stride), (680, stride)]
    ]
    return [
        ellipse(450, 330 + bob, 330, 170),
        ellipse(800, 480 + bob, 150, 150),
        [(690, 560 + bob), (720, 720 + bob), (800, 600 + bob)],
        [(810, 610 + bob), (890, 730 + bob), (910, 560 + bob)],
        band(tail, 60),
        *legs,
    ]


def clockwise(points):
    """TrueType の外側の輪郭の向き (時計回り) に揃えた頂点の列を返す。重なった輪郭を塗りの和として描かせるため、全ての輪郭を同じ向きにする。"""
    area = sum(x0 * y1 - x1 * y0 for (x0, y0), (x1, y1) in zip(points, points[1:] + points[:1]))
    return points[::-1] if area > 0 else points


def frame_glyph(frame):
    """コマ `frame` の字形。0〜4 は右向きで左から右へ、5〜9 は左向きで右から左へ進む。"""
    facing_right = frame < FRAME_COUNT // 2
    progress = frame / (FRAME_COUNT // 2) if facing_right else (FRAME_COUNT - frame) / (FRAME_COUNT // 2)
    offset = progress * (GLYPH_ADVANCE - CAT_LENGTH)
    pen = TTGlyphPen(None)
    for contour in cat_contours(frame):
        transformed = [(round(offset + (x if facing_right else CAT_LENGTH - x)), round(y)) for x, y in contour]
        points = clockwise(transformed)
        pen.moveTo(points[0])
        for point in points[1:]:
            pen.lineTo(point)
        pen.closePath()
    return pen.glyph()


def empty_glyph():
    """何も描かない字形。タイマーの数字以外の文字 (`:` など) と .notdef に使う。"""
    return TTGlyphPen(None).glyph()


def main():
    digit_names = [f"frame{i}" for i in range(FRAME_COUNT)]
    glyph_order = [".notdef", "space", "colon", *digit_names]
    builder = FontBuilder(UNITS_PER_EM, isTTF=True)
    builder.setupGlyphOrder(glyph_order)
    builder.setupCharacterMap({0x20: "space", ord(":"): "colon", **{ord(str(i)): name for i, name in enumerate(digit_names)}})
    builder.setupGlyf({".notdef": empty_glyph(), "space": empty_glyph(), "colon": empty_glyph(), **{name: frame_glyph(i) for i, name in enumerate(digit_names)}})
    # 描画側は字形を「左の余白 (lsb) = 輪郭の左端」として置くため、lsb を 0 にすると全てのコマの猫が左端に寄る。輪郭の左端をそのまま lsb にする
    glyf = builder.font["glyf"]
    builder.setupHorizontalMetrics({name: (GLYPH_ADVANCE, getattr(glyf[name], "xMin", 0)) for name in glyph_order})
    builder.setupHorizontalHeader(ascent=800, descent=-50)
    builder.setupNameTable({"familyName": FONT_NAME, "styleName": "Regular", "psName": f"{FONT_NAME}-Regular"})
    builder.setupOS2(sTypoAscender=800, sTypoDescender=-50, usWinAscent=800, usWinDescent=50)
    builder.setupPost()
    builder.save(OUTPUT)
    print(OUTPUT)


if __name__ == "__main__":
    main()
