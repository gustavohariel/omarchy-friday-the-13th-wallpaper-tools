#!/bin/bash
# Rebuilds backgrounds/0*-*.jpg: free-licence daylight fog photos from Wikimedia Commons,
# graded into Crystal Lake at night (lake-teal gradient map, vignette, film grain).
# Needs curl and magick. Originals are cached in cache (gitignored); results land in backgrounds/.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
cache=$here/cache; out=$here/backgrounds
W=3840 H=2160
mkdir -p "$cache" "$out"

fetch() { [[ -s $cache/$1 ]] || curl -fsSL -A "omarchy-friday-the-13th-theme" -o "$cache/$1" "$2"; }
fetch jetty.jpg  "https://upload.wikimedia.org/wikipedia/commons/4/4a/Jetty_in_fog_at_Holl%C3%A4ndar%C3%B6d_1.jpg"
fetch woods.jpg  "https://upload.wikimedia.org/wikipedia/commons/c/c2/Las_w_porannej_mgle%2C_gmina_Czernich%C3%B3w%2C_Rudnia%C5%84ski_Park_Krajobrazowy%2C_20240225_0810_6628.jpg"
fetch island.jpg "https://upload.wikimedia.org/wikipedia/commons/e/e6/Trustom_Pond_in_the_fog_%2812453p%292.jpg"
fetch lone.jpg   "https://upload.wikimedia.org/wikipedia/commons/f/f8/Lonely_tree_at_Fairy_lake.jpg"
fetch oaks.jpg   "https://upload.wikimedia.org/wikipedia/commons/1/1d/D%C3%BClmen%2C_Leuste%2C_B%C3%A4ume_im_Nebel_--_2020_--_5041.jpg"
fetch ridge.jpg  "https://upload.wikimedia.org/wikipedia/commons/0/02/Forested_hills_in_Lysekil_in_fog_-_wide_-_B%26W.jpg"

# Night gradient map: black water -> lake teal -> moonlit fog, all from the palette's family.
magick xc:'#040606' xc:'#0a1211' xc:'#152522' xc:'#2a443e' xc:'#557269' xc:'#93aca3' \
  +append -filter Triangle -resize 256x1! "$cache/night.png"
magick -size $((W*19/16))x$((H*13/9)) radial-gradient:white-'#141414' -gravity center \
  -crop ${W}x${H}+0+0 +repage -gamma 1.6 "$cache/vignette.png"

# grade <src> <dest> <gamma> [gravity]
grade() {
  magick "$cache/$1" -resize ${W}x${H}^ -gravity "${4:-center}" -extent ${W}x${H} -modulate 100,0 -gamma "$3" \
    "$cache/night.png" -clut "$cache/vignette.png" -compose multiply -composite \
    -attenuate 0.12 +noise Gaussian -quality 90 -sampling-factor 4:2:0 "$out/$2"
}
grade jetty.jpg  01-crystal-lake-dock.jpg     0.9
grade woods.jpg  02-the-woods.jpg             1.15
grade lone.jpg   03-lone-tree.jpg             0.8
grade oaks.jpg   04-oaks-in-fog.jpg           0.85
grade island.jpg 05-island.jpg                0.8
grade ridge.jpg  06-treeline.jpg              1.0
# The score's whisper ("ki ki ki, ma ma ma") over the dock, in chevron red.
mono=$(fc-match -f '%{file}' "Nimbus Mono PS:bold")
magick "$out/01-crystal-lake-dock.jpg" -font "$mono" -pointsize 64 -kerning 18 -fill '#c8323a' \
  -gravity southeast -annotate +260+250 'ki ki ki . ma ma ma' \
  -quality 90 -sampling-factor 4:2:0 "$out/07-ki-ki-ki.jpg"
echo "wrote $(ls "$out"/0*.jpg | wc -l) wallpapers"
