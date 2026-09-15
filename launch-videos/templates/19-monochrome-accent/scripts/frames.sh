#!/usr/bin/env bash
# Extract review frames from out/video.mp4 and tile them into out/contact-sheet.png.
# Usage: scripts/frames.sh [frame ...]   (defaults to 12 evenly spaced frames)
set -euo pipefail
cd "$(dirname "$0")/.."
VIDEO=out/video.mp4
FPS=30
TOTAL=$(ffprobe -v error -count_frames -select_streams v:0 -show_entries stream=nb_read_frames -of csv=p=0 "$VIDEO" | tr -dc '0-9')
if [ "$#" -gt 0 ]; then FRAMES=("$@"); else
  FRAMES=(); N=12
  for i in $(seq 0 $((N - 1))); do FRAMES+=($(( (TOTAL - 1) * i / (N - 1) ))); done
fi
rm -f out/frame-*.png
for f in "${FRAMES[@]}"; do
  ffmpeg -v error -y -i "$VIDEO" -vf "select=eq(n\,$f)" -vframes 1 "out/frame-$(printf %04d "$f").png"
done
INPUTS=(); for f in out/frame-*.png; do INPUTS+=(-i "$f"); done
COUNT=${#INPUTS[@]}; COUNT=$((COUNT / 2))
COLS=3; ROWS=$(( (COUNT + COLS - 1) / COLS ))
ffmpeg -v error -y "${INPUTS[@]}" \
  -filter_complex "$(for i in $(seq 0 $((COUNT - 1))); do printf '[%d:v]scale=640:-1[s%d];' "$i" "$i"; done)$(for i in $(seq 0 $((COUNT - 1))); do printf '[s%d]' "$i"; done)xstack=inputs=$COUNT:layout=$(for i in $(seq 0 $((COUNT - 1))); do c=$((i % COLS)); r=$((i / COLS)); printf '%s%d_%d' "$([ "$i" -gt 0 ] && echo '|')" $((c * 640)) $((r * 360)); done):fill=black" \
  out/contact-sheet.png
echo "frames: ${FRAMES[*]} (of $TOTAL) -> out/contact-sheet.png"
