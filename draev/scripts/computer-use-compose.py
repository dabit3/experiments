#!/usr/bin/env python3
"""Composite uncut desktop LEFT and timestamp-synchronized executable code RIGHT.

Requires Pillow, ffmpeg and ffprobe. Never crops or time-compresses app footage.
Usage: /usr/bin/python3 scripts/computer-use-compose.py EVIDENCE_DIR
"""
import json
import os
import subprocess
import sys
import textwrap
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

root = Path(sys.argv[1]).resolve()
source = (root / "executed-script.mjs").read_text().splitlines()
events = [json.loads(s) for s in (root / "events.jsonl").read_text().splitlines()]
metadata = json.loads((root / "run.json").read_text())
probe = json.loads(subprocess.check_output([
    "ffprobe", "-v", "error", "-show_format", "-show_streams", "-of", "json",
    str(root / "desktop.mkv")]))
duration = float(probe["format"]["duration"])
font_file = os.environ.get("CU_FONT",
    "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf")
font = ImageFont.truetype(font_file, 18)
small = ImageFont.truetype(font_file, 16)
title_font = ImageFont.truetype(font_file, 23)
starts = [i for i,line in enumerate(source) if "// STEP " in line]
starts.append(next(i for i,line in enumerate(source) if "} catch" in line))
panels = root / "code-panels"
panels.mkdir(exist_ok=True)
latest_passes = []

def render(event, name):
    """Only the overlay is generated; the application image is never modified."""
    im = Image.new("RGB", (2560,1080), "#101823")
    d = ImageDraw.Draw(im)
    d.rectangle((0,90,1599,989), fill="black")  # Full video inserted here.
    d.rectangle((1600,0,2559,1079), fill="#111e2d")
    d.line((1600,0,1600,1080), fill="#3f6074", width=2)
    d.text((26,21), "DRAEV / PRODUCTION COMPUTER-USE TEST", font=title_font,
        fill="#edf4fa")
    d.text((26,55), f"Native pointer + keyboard | {metadata['commit'][:9]} | "
        "Full app frame, scaled without cropping", font=small, fill="#a7c0d2")
    d.text((26,1010), "REAL APP VIDEO  /  uncut  /  24 fps", font=title_font,
        fill="#6cddc2")
    d.text((26,1046), "Right pane: actual executed source + timestamped assertions"
        " (postprocessed composite)", font=small, fill="#a7c0d2")
    d.text((1624,22), "EXECUTABLE TEST SCRIPT", font=title_font, fill="#edf4fa")
    d.text((1624,58), "scripts/computer-use-test.mjs", font=small, fill="#a7c0d2")
    step = event["step"]
    heading = f"STEP {step}/7" if step else "SETUP"
    d.rectangle((1624,94,2535,136), fill="#193f4b")
    d.text((1637,103), heading+"  |  "+event["type"].upper(),
        font=font, fill="#8decd1")
    # Scroll to the real current executable callback, preserving source lines.
    lo = starts[step-1] if step else 0
    hi = starts[step] if step else starts[0]
    lo = max(0, lo)
    y = 163
    for i in range(lo, min(hi, len(source))):
        line = source[i]
        chunks = textwrap.wrap(line, width=77, replace_whitespace=False,
            drop_whitespace=False) or [""]
        for j,chunk in enumerate(chunks):
            d.rectangle((1624,y-3,2535,y+25), fill="#18323f")
            d.text((1633,y), f"{i+1:3}" if j == 0 else "  >",
                font=small, fill="#7193a8")
            color = "#83c6a7" if line.lstrip().startswith("//") else "#edf4fa"
            d.text((1682,y),chunk,font=font,fill=color)
            y += 29
    d.text((1624,755), "OBSERVED ASSERTIONS",font=font,fill="#a7c0d2")
    if event["type"] == "test_start":
        latest_passes.clear()
    if event["type"] in ("assertion", "summary"):
        prefix = "PASS" if event.get("result") == "passed" else "FAIL"
        latest_passes.append(prefix+"  "+event["label"])
    status = latest_passes[-3:] or [event["label"]]
    y = 792
    for item in status:
        color = "#f4999c" if item.startswith("FAIL") else "#8decd1"
        for line in textwrap.wrap(item,width=85)[:3]:
            d.text((1624,y),line,font=small,fill=color)
            y += 24
    d.text((1624,1045), f"Video timestamp {max(event['time'],0):06.2f}s"
        " | fail-fast assertions",font=small,fill="#7193a8")
    im.save(panels / name)

# One code/status panel per actual event. The full uncut source video is retained.
timeline = []
for i,e in enumerate(events):
    start = max(0, e["time"])
    if start >= duration:
        continue
    name = f"{i:04}.png"
    render(e, name)
    timeline.append((start,name))
timeline[0] = (0,timeline[0][1])
concat = []
for i,(start,name) in enumerate(timeline):
    end = timeline[i+1][0] if i+1 < len(timeline) else duration
    if end <= start: continue
    concat += [f"file '{name}'", f"duration {end-start:.6f}"]
concat.append(f"file '{timeline[-1][1]}'")
(panels / "timeline.txt").write_text("\n".join(concat)+"\n")
output = root / "computer-use-split.webm"
cmd = ["ffmpeg", "-y", "-hide_banner", "-loglevel", "warning",
    "-i", str(root / "desktop.mkv"),
    "-f", "concat", "-safe", "0", "-i", str(panels / "timeline.txt"),
    "-filter_complex",
    "[0:v]scale=1600:900:flags=lanczos,setsar=1[app];"
    "[1:v]fps=24[panel];[panel][app]overlay=0:90:shortest=1[out]",
    "-map", "[out]", "-t", str(duration), "-an",
    "-c:v", "libvpx-vp9", "-b:v", "0", "-crf", "24",
    "-cpu-used", "4", "-row-mt", "1", "-threads", "4", str(output)]
subprocess.run(cmd, check=True)
validation = subprocess.check_output(["ffprobe","-v","error",
    "-show_entries","stream=codec_name,width,height",
    "-show_entries","format=format_name,duration,size","-of","json",str(output)])
(root / "webm-validation.json").write_bytes(validation)
v = json.loads(validation)
assert v["streams"][0]["codec_name"] in ("vp8","vp9")
assert "webm" in v["format"]["format_name"]
assert abs(float(v["format"]["duration"]) - duration) < 0.2
# Screenshot during the committed property edit, before Undo changes it.
e = next(e for e in events if e["step"] == 3 and
    e["label"].startswith("Geometry") and '"y":2000' in e["label"])
subprocess.run(["ffmpeg","-y","-loglevel","error","-ss",str(e["time"]+0.35),
    "-i",str(output),"-frames:v","1",str(root / "split-view.png")],check=True)
print(output)
print(validation.decode())
