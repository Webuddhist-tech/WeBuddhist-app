# Tibetan fonts

All Tibetan fonts are shipped as WeBuddhist builds with **rewritten vertical
metrics**. Do not replace them with the upstream files — the upstream
ascender/descender values are what caused clipped vowel signs and
off-centre button labels (see `lib/core/theme/FONT_SYSTEM_GUIDE.md`,
section "Tibetan vertical metrics").

| Family (pubspec)     | Files                              | Upstream                               | Metrics (asc / desc, UPM) |
| -------------------- | ---------------------------------- | -------------------------------------- | ------------------------- |
| `NotoSerifTibetanWB` | `NotoSerifTibetanWB-{Regular,Medium,SemiBold,Bold}.ttf` | Noto Serif Tibetan v2.103, unhinted (OFL 1.1, no RFN) | 1220 / -580 (1000) |
| `WBTibetanContent`   | `WBTibetanContent.ttf`             | BabelStone Tibetan v10.011 (OFL 1.1, RFN "BabelStone") | 1024 / -614 (1024) |
| `WBTibetanUchen`     | `WBTibetanUchen.ttf`               | Jomolhari 1.000 (Google Fonts `ofl/jomolhari`; OFL 1.1, RFN "Jomolhari") | 1248 / -400 (1024) |

`WBTibetanContent` and `WBTibetanUchen` are renamed because the OFL forbids
using the Reserved Font Names "BabelStone" and "Jomolhari" on a modified
build. Licenses: `OFL-NotoSerifTibetan.txt`, `OFL-BabelStoneTibetan.txt`,
`OFL-Jomolhari.txt`.

`WBTibetanUchen` is a reader font choice, not a UI font. Upstream Jomolhari's
hhea values (1248 / -392) were close to its ink already (vowel signs to
+1.08 em, at most +1.10; stacks to -0.19, deepest -0.39), but it does not set
USE_TYPO_METRICS, so Flutter read its win values (1302 / 610) and centred
the box 0.1 em below the ink.

To rebuild from upstream files:

```sh
pip install fonttools
python tool/patch_tibetan_font_metrics.py \
  --noto-dir <unhinted NotoSerifTibetan-*.ttf> \
  --babelstone <BabelStoneTibetan.ttf> \
  --jomolhari <Jomolhari-Regular.ttf> \
  --out assets/fonts
```
