#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
VIDEO="$ROOT/out/10-frosted-depth.mp4"
OUT="$ROOT/out/10-frosted-depth-qa"
mkdir -p "$OUT"

ffprobe -v error -select_streams v:0 \
  -show_entries stream=codec_name,width,height,r_frame_rate,pix_fmt,nb_frames \
  -show_entries format=duration -of json "$VIDEO" > "$OUT/ffprobe.json"

ffmpeg -hide_banner -loglevel error -y -i "$VIDEO" \
  -vf 'select=eq(n\,60)' -frames:v 1 "$ROOT/out/10-frosted-depth-poster.png"

FRAMES=(0 60 101 111 121 180 221 231 241 315 371 381 391 480 519 551 561 571 660 731 741 751 840 911 921 931 1005 1061 1071 1081 1170 1199)
SELECT=""
for frame in "${FRAMES[@]}"; do
  SELECT="${SELECT:+$SELECT+}eq(n\\,$frame)"
done
ffmpeg -hide_banner -loglevel error -y -i "$VIDEO" \
  -vf "select='$SELECT',scale=640:360,pad=640:396:0:0:color=0x17303b,tile=4x8:padding=6:margin=6:color=0x17303b" \
  -frames:v 1 "$ROOT/out/10-frosted-depth-contact-sheet.png"

if [[ "$(uname -s)" == "Darwin" ]]; then
  swift "$ROOT/templates/10-frosted-depth/label-contact-sheet.swift" \
    "$ROOT/out/10-frosted-depth-contact-sheet.png" "${FRAMES[@]}"
fi

for frame in 60 180 315 480 660 840 1005 1170; do
  ffmpeg -hide_banner -loglevel error -y -i "$VIDEO" \
    -vf "select=eq(n\\,$frame)" -frames:v 1 "$OUT/scene-$frame.png"
done

printf 'Review ffprobe.json, the full-frame poster, all scene frames and the 32-frame contact sheet in out/.\n'
