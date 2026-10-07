# Tibetan fonts

Both Tibetan fonts are shipped as WeBuddhist builds with **rewritten vertical
metrics**. Do not replace them with the upstream files — the upstream
ascender/descender values are what caused clipped vowel signs and
off-centre button labels (see `lib/core/theme/FONT_SYSTEM_GUIDE.md`,
section "Tibetan vertical metrics").

| Family (pubspec)     | Files                              | Upstream                               | Metrics (asc / desc, UPM) |
| -------------------- | ---------------------------------- | -------------------------------------- | ------------------------- |
| `NotoSerifTibetanWB` | `NotoSerifTibetanWB-{Regular,Medium,SemiBold,Bold}.ttf` | Noto Serif Tibetan v2.103, unhinted (OFL 1.1, no RFN) | 1220 / -580 (1000) |
| `WBTibetanContent`   | `WBTibetanContent.ttf`             | BabelStone Tibetan v10.011 (OFL 1.1, RFN "BabelStone") | 1024 / -614 (1024) |

`WBTibetanContent` is renamed because the OFL forbids using the Reserved Font
Name "BabelStone" on a modified build. Licenses: `OFL-NotoSerifTibetan.txt`,
`OFL-BabelStoneTibetan.txt`.

To rebuild from upstream files:

```sh
pip install fonttools
python tool/patch_tibetan_font_metrics.py \
  --noto-dir <unhinted NotoSerifTibetan-*.ttf> \
  --babelstone <BabelStoneTibetan.ttf> \
  --out assets/fonts
```
