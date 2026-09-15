#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
for sheet in heroes attacks; do
  for id in 0 1 2 3 4 5; do
    x=$(( (id % 3) * 512 + 6 ))
    y=$(( (id / 3) * 512 + 6 ))
    ffmpeg -y -loglevel error -i "ArtSource/$sheet-sheet.png" \
      -vf "crop=500:500:$x:$y,format=rgba,colorkey=0x00ff00:0.28:0.1,despill=green:mix=0.4" \
      -frames:v 1 "App/Resources/$sheet-$id.png"
  done
done
