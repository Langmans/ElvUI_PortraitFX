#!/usr/bin/env bash
# Builds the plugin's icons: each Media/src/<Name>.svg becomes Media/<Name>.tga, 64x64, 32-bit with
# alpha, uncompressed, as the client loads it. Needs ImageMagick 7 with librsvg (magick).
# Run from anywhere: bash tools/icons.sh
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
for svg in "$root"/Media/src/*.svg; do
    name="$(basename "$svg" .svg)"
    magick -background none "$svg" -resize 64x64 -depth 8 -type TrueColorAlpha -compress None \
        "$root/Media/$name.tga"
    echo "Media/$name.tga"
done
