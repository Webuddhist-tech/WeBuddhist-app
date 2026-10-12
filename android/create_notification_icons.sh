#!/bin/bash
# Regenerates android/app/src/main/res/drawable-*/ic_notification.png from the app logo.
# Uses the full-colour logo so OEM skins that skip tinting show it as-is; stock Android
# tints the alpha mask with notification_accent. Requires ImageMagick.

set -e

cd "$(dirname "$0")"
SRC="../assets/images/webuddhist_logo.png"
RES_DIR="app/src/main/res"

[ -f "$SRC" ] || { echo "Error: logo not found at $SRC"; exit 1; }
command -v magick >/dev/null || { echo "Error: ImageMagick (magick) not installed"; exit 1; }

for item in mdpi:24 hdpi:36 xhdpi:48 xxhdpi:72 xxxhdpi:96; do
    density=${item%%:*}
    size=${item##*:}
    mkdir -p "$RES_DIR/drawable-$density"
    # Trim transparent margin, then leave ~8% padding inside the icon box.
    magick "$SRC" -trim +repage -resize "$((size * 84 / 100))x$((size * 84 / 100))" \
        -gravity center -background none -extent "${size}x${size}" \
        "$RES_DIR/drawable-$density/ic_notification.png"
    echo "Created $RES_DIR/drawable-$density/ic_notification.png (${size}px)"
done
cp "$RES_DIR/drawable-mdpi/ic_notification.png" "$RES_DIR/drawable/ic_notification.png"
echo "Done."
