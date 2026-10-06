#!/usr/bin/env python3
"""Rebuild the app's Tibetan fonts with vertical metrics fitted to the ink.

Why this exists
---------------
Both upstream fonts declare ascender/descender values far larger than the
glyphs they actually draw:

  Noto Serif Tibetan   ascender 1.466 em, descender 1.349 em (2.815 em/line)
  BabelStone Tibetan   ascender 1.102 em, descender 1.901 em (3.003 em/line)

Flutter derives every line box from these numbers.  As soon as a style sets
`height:` (the app uses 1.55 / 1.25 for Tibetan) the box is shrunk around
the *baseline*, not around the glyphs, so:

  * vowel signs on the first line poke out above the box and are clipped
    whenever a paragraph clips itself (maxLines + ellipsis) or an ancestor
    clips (ClipRRect, Material(clipBehavior), ...);
  * short labels sit well above centre inside buttons and chips, because
    the box centre is near the baseline while Tibetan ink is centred
    ~0.3 em above it.

The values below come from shaping every string in app_bo.arb with
HarfBuzz and measuring the ink (see the numbers in
lib/core/theme/FONT_SYSTEM_GUIDE.md):

  Noto Serif Tibetan WB   ascender 1220 / descender -580  (1.80 em/line)
      common vowel top 1.08 em, superscript+vowel 1.16 em,
      single subjoined stack -0.47 em, deep stacks -0.70 em
  WB Tibetan Content      ascender 1024 / descender -614  (1.60 em/line)
      vowel top 0.84 em (max 0.93), stacks down to -0.62 em

usWinAscent/usWinDescent keep the full glyph extents (GDI clips to them),
USE_TYPO_METRICS is set so every platform reads the same numbers, and the
fonts are renamed: Noto has no Reserved Font Name, BabelStone does, so its
derivative must not carry the BabelStone name (OFL 1.1, condition 3).

Usage
-----
  pip install fonttools
  python tool/patch_tibetan_font_metrics.py \
      --noto-dir  <dir containing NotoSerifTibetan-{Regular,Medium,SemiBold,Bold}.ttf> \
      --babelstone <BabelStoneTibetan.ttf> \
      --out assets/fonts

Noto source: https://github.com/notofonts/tibetan/releases (unhinted/ttf,
v2.103 at the time of writing).  BabelStone source: the previous
assets/fonts/BabelStoneTibetan.ttf (v10.011) or https://www.babelstone.co.uk/Fonts/.
"""
import argparse
import os
import sys

try:
    from fontTools.ttLib import TTFont
except ImportError:  # pragma: no cover
    sys.exit("fontTools is required: pip install fonttools")

USE_TYPO_METRICS = 1 << 7

NOTO_WEIGHTS = ("Regular", "Medium", "SemiBold", "Bold")


def patch(src, dst, asc, desc, family, ps_family, note):
    font = TTFont(src)
    upm = font["head"].unitsPerEm
    glyf = font["glyf"]
    y_max = max(getattr(glyf[g], "yMax", 0) for g in glyf.keys())
    y_min = min(getattr(glyf[g], "yMin", 0) for g in glyf.keys())

    hhea, os2 = font["hhea"], font["OS/2"]
    hhea.ascent, hhea.descent, hhea.lineGap = asc, -desc, 0
    os2.sTypoAscender, os2.sTypoDescender, os2.sTypoLineGap = asc, -desc, 0
    os2.usWinAscent = max(y_max, asc)
    os2.usWinDescent = max(-y_min, desc)
    os2.fsSelection |= USE_TYPO_METRICS

    name = font["name"]
    old_family = name.getDebugName(16) or name.getDebugName(1)
    # Typographic subfamily (e.g. "SemiBold"); nameID 2 only knows the
    # legacy Regular/Bold/Italic split.
    style = name.getDebugName(17) or name.getDebugName(2)
    legacy_style = name.getDebugName(2)
    for rec in name.names:
        text = rec.toUnicode()
        if rec.nameID == 1:
            # Legacy family name carries the style unless it is one of the
            # four legacy styles.
            text = family if style == legacy_style else f"{family} {style}"
        elif rec.nameID == 16:
            text = family
        elif rec.nameID == 4:
            text = family if style == "Regular" else f"{family} {style}"
        elif rec.nameID == 6:
            text = f"{ps_family}-{style}"
        elif rec.nameID == 3:
            text = f"{ps_family}-{style};WB;{text}"
        elif rec.nameID == 5:
            text = f"{text}; {note}"
        else:
            continue
        rec.string = text

    font.save(dst)
    print(
        f"{dst}: {old_family} {style} -> {family} {style}; "
        f"ascender {asc / upm:.3f} em, descender {desc / upm:.3f} em "
        f"({(asc + desc) / upm:.2f} em/line); win {os2.usWinAscent}/{os2.usWinDescent}"
    )


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("--noto-dir", help="directory with NotoSerifTibetan-<Weight>.ttf")
    parser.add_argument("--babelstone", help="path to BabelStoneTibetan.ttf")
    parser.add_argument("--out", default="assets/fonts")
    args = parser.parse_args()
    if not args.noto_dir and not args.babelstone:
        parser.error("give --noto-dir and/or --babelstone")
    os.makedirs(args.out, exist_ok=True)

    if args.noto_dir:
        for weight in NOTO_WEIGHTS:
            patch(
                os.path.join(args.noto_dir, f"NotoSerifTibetan-{weight}.ttf"),
                os.path.join(args.out, f"NotoSerifTibetanWB-{weight}.ttf"),
                asc=1220,
                desc=580,
                family="Noto Serif Tibetan WB",
                ps_family="NotoSerifTibetanWB",
                note="WeBuddhist build: vertical metrics fitted to Tibetan ink (1220/-580)",
            )

    if args.babelstone:
        patch(
            args.babelstone,
            os.path.join(args.out, "WBTibetanContent.ttf"),
            asc=1024,
            desc=614,
            family="WB Tibetan Content",
            ps_family="WBTibetanContent",
            note=(
                "WeBuddhist build of BabelStone Tibetan, renamed per OFL Reserved Font Name: "
                "vertical metrics fitted to Tibetan ink (1024/-614)"
            ),
        )


if __name__ == "__main__":
    main()
