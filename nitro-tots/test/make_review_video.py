#!/usr/bin/env python3
"""Cuts the Nitro Tots verification evidence into an edited review video.

Instead of handing over the raw screen recordings, this assembles a
programmatic edit with ffmpeg: a title card, one chapter per topic, caption
lower-thirds, per-platform screenshot slides, side-by-side comparisons and
a closing summary of what was verified live versus build-only. The edit is
driven entirely by files on disk, so re-running it on a new evidence run
produces the same structure with the new footage.

Sources (all optional except the e2e run):

  --e2e     multiplayer e2e run directory (four-way-match.mp4/.mov,
            result.json, screenshots/, logs/e2e.log for the timeline)
  --manual  manual UI evidence directory (a raw *.mp4 recording, optional
            *annotations.json from the recorder with test_start/assertion
            source timestamps, plus the PNGs listed in its README). With
            annotations, every assertion becomes its own captioned clip
            (the seconds leading up to the check) with a PASS/FAIL chip; a
            fixes.json {assertion_substring: note} marks defects fixed later.
  --parity  visual parity directory (visual_parity.json, reference/, clone/)
  --design  directory of design-pass captures (PNG, sorted by name; an
            optional captions.json maps file stem -> caption)

Outputs <out>.mp4 with embedded chapters, <out>.chapters.json and <out>.md
(the edit decision list). Cards are rendered by review_cards.mjs with the
game's own fonts because this ffmpeg build has no drawtext filter.

  python3 test/make_review_video.py --e2e <run> --manual <dir> --parity <dir> \\
      --design <dir> --out <dir>/review
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path

W, H = 1280, 720
FPS = 30
BG = "0x16122A"
HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
MUSIC = ROOT / "app" / "assets" / "audio" / "music_menu.wav"
FFMPEG = shutil.which("ffmpeg") or "/opt/homebrew/bin/ffmpeg"
FFPROBE = shutil.which("ffprobe") or "/opt/homebrew/bin/ffprobe"
NODE = shutil.which("node") or "/opt/homebrew/bin/node"


def run(cmd: list[str]) -> None:
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        sys.stderr.write(proc.stderr[-4000:])
        raise SystemExit(f"command failed: {' '.join(cmd[:3])} ...")


def duration(path: Path) -> float:
    out = subprocess.run(
        [FFPROBE, "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", str(path)],
        capture_output=True,
        text=True,
        check=True,
    ).stdout.strip()
    return float(out)


def fit() -> str:
    return f"scale={W}:{H}:force_original_aspect_ratio=decrease:flags=lanczos,pad={W}:{H}:(ow-iw)/2:(oh-ih)/2:color={BG},setsar=1"


def encode_args() -> list[str]:
    return ["-r", str(FPS), "-c:v", "libx264", "-preset", "medium", "-crf", "20", "-pix_fmt", "yuv420p", "-an", "-flags", "+bitexact", "-fflags", "+bitexact", "-map_metadata", "-1"]


@dataclass
class Segment:
    chapter: str
    kind: str
    seconds: float
    source: str
    out: Path | None = None


@dataclass
class Edit:
    work: Path
    cards: dict[str, Path] = field(default_factory=dict)
    segments: list[Segment] = field(default_factory=list)
    _n: int = 0

    def next_out(self, tag: str) -> Path:
        self._n += 1
        return self.work / f"seg{self._n:02d}_{tag}.mp4"

    # -- primitives ---------------------------------------------------------

    def still(self, chapter: str, png: Path, seconds: float, label: str) -> None:
        out = self.next_out(label)
        vf = f"{fit()},fade=t=in:st=0:d=0.4,fade=t=out:st={seconds - 0.4:.2f}:d=0.4"
        run([FFMPEG, "-y", "-loglevel", "error", "-loop", "1", "-framerate", str(FPS), "-t", f"{seconds:.3f}", "-i", str(png), "-vf", vf, *encode_args(), str(out)])
        self.segments.append(Segment(chapter, "card", seconds, png.name, out))

    def clip(self, chapter: str, video: Path, start: float, length: float, speed: float, caption: Path | None, label: str, tag: Path | None = None) -> None:
        out = self.next_out(label)
        seconds = length / speed
        inputs = ["-ss", f"{start:.3f}", "-t", f"{length:.3f}", "-i", str(video)]
        chain = f"[0:v]setpts=PTS/{speed},fps={FPS},{fit()}[v0]"
        last = "v0"
        idx = 1
        if caption is not None:
            inputs += ["-loop", "1", "-t", f"{seconds:.3f}", "-i", str(caption)]
            chain += f";[{last}][{idx}:v]overlay=0:0:enable='between(t,0.3,{seconds - 0.3:.2f})'[v{idx}]"
            last = f"v{idx}"
            idx += 1
        if tag is not None:
            inputs += ["-loop", "1", "-t", f"{seconds:.3f}", "-i", str(tag)]
            chain += f";[{last}][{idx}:v]overlay=0:0[v{idx}]"
            last = f"v{idx}"
            idx += 1
        chain += f";[{last}]fade=t=in:st=0:d=0.3,fade=t=out:st={seconds - 0.3:.2f}:d=0.3[v]"
        run([FFMPEG, "-y", "-loglevel", "error", *inputs, "-filter_complex", chain, "-map", "[v]", "-t", f"{seconds:.3f}", *encode_args(), str(out)])
        self.segments.append(Segment(chapter, f"clip x{speed:g}", seconds, f"{video.name} @{start:.0f}s+{length:.0f}s", out))

    def slides(self, chapter: str, images: list[tuple[Path, Path | None]], each: float, label: str, tag: Path | None = None) -> None:
        """Sequence of stills, each with its own caption overlay."""
        out = self.next_out(label)
        inputs: list[str] = []
        chain = ""
        parts = []
        idx = 0
        for i, (img, cap) in enumerate(images):
            inputs += ["-loop", "1", "-framerate", str(FPS), "-t", f"{each:.3f}", "-i", str(img)]
            chain += f"[{idx}:v]{fit()},fade=t=in:st=0:d=0.25,fade=t=out:st={each - 0.25:.2f}:d=0.25[s{i}]"
            idx += 1
            if cap is not None:
                inputs += ["-loop", "1", "-framerate", str(FPS), "-t", f"{each:.3f}", "-i", str(cap)]
                chain += f";[s{i}][{idx}:v]overlay=0:0[c{i}]"
                idx += 1
                parts.append(f"[c{i}]")
            else:
                parts.append(f"[s{i}]")
            chain += ";"
        chain += "".join(parts) + f"concat=n={len(images)}:v=1:a=0[cat]"
        last = "cat"
        if tag is not None:
            inputs += ["-loop", "1", "-framerate", str(FPS), "-t", f"{each * len(images):.3f}", "-i", str(tag)]
            chain += f";[cat][{idx}:v]overlay=0:0[v]"
            last = "v"
        run([FFMPEG, "-y", "-loglevel", "error", *inputs, "-filter_complex", chain, "-map", f"[{last}]", *encode_args(), str(out)])
        self.segments.append(Segment(chapter, "slides", each * len(images), ", ".join(p.name for p, _ in images), out))

    def compare(self, chapter: str, left: Path, right: Path, seconds: float, caption: Path | None, label: str, tag: Path | None = None) -> None:
        """Side-by-side of two stills, each fitted into half the frame."""
        out = self.next_out(label)
        half = W // 2 - 12
        cell = f"scale={half}:{H - 160}:force_original_aspect_ratio=decrease:flags=lanczos,pad={half}:{H - 160}:(ow-iw)/2:(oh-ih)/2:color={BG}"
        inputs = ["-loop", "1", "-framerate", str(FPS), "-t", f"{seconds:.3f}", "-i", str(left), "-loop", "1", "-framerate", str(FPS), "-t", f"{seconds:.3f}", "-i", str(right)]
        chain = f"[0:v]{cell}[l];[1:v]{cell}[r];[l][r]hstack=inputs=2,pad={W}:{H}:(ow-iw)/2:40:color={BG},setsar=1[base]"
        last = "base"
        idx = 2
        for png in (caption, tag):
            if png is None:
                continue
            inputs += ["-loop", "1", "-framerate", str(FPS), "-t", f"{seconds:.3f}", "-i", str(png)]
            chain += f";[{last}][{idx}:v]overlay=0:0[o{idx}]"
            last = f"o{idx}"
            idx += 1
        chain += f";[{last}]fade=t=in:st=0:d=0.3,fade=t=out:st={seconds - 0.3:.2f}:d=0.3[v]"
        run([FFMPEG, "-y", "-loglevel", "error", *inputs, "-filter_complex", chain, "-map", "[v]", *encode_args(), str(out)])
        self.segments.append(Segment(chapter, "side-by-side", seconds, f"{left.name} | {right.name}", out))

    def grid(self, chapter: str, cells: list[Path], seconds: float, caption: Path | None, label: str) -> None:
        """2x2 grid of stills (platform matrix)."""
        out = self.next_out(label)
        cw, ch = W // 2, (H - 120) // 2
        inputs: list[str] = []
        chain = ""
        for i, img in enumerate(cells[:4]):
            inputs += ["-loop", "1", "-framerate", str(FPS), "-t", f"{seconds:.3f}", "-i", str(img)]
            chain += f"[{i}:v]scale={cw - 8}:{ch - 8}:force_original_aspect_ratio=decrease:flags=lanczos,pad={cw}:{ch}:(ow-iw)/2:(oh-ih)/2:color={BG}[g{i}];"
        chain += f"[g0][g1][g2][g3]xstack=inputs=4:layout=0_0|w0_0|0_h0|w0_h0,pad={W}:{H}:0:0:color={BG},setsar=1[base]"
        last = "base"
        idx = 4
        if caption is not None:
            inputs += ["-loop", "1", "-framerate", str(FPS), "-t", f"{seconds:.3f}", "-i", str(caption)]
            chain += f";[base][{idx}:v]overlay=0:0[cap]"
            last = "cap"
        chain += f";[{last}]fade=t=in:st=0:d=0.3,fade=t=out:st={seconds - 0.3:.2f}:d=0.3[v]"
        run([FFMPEG, "-y", "-loglevel", "error", *inputs, "-filter_complex", chain, "-map", "[v]", *encode_args(), str(out)])
        self.segments.append(Segment(chapter, "grid", seconds, ", ".join(p.name for p in cells[:4]), out))


# -- evidence readers ---------------------------------------------------------


def e2e_timeline(run_dir: Path) -> list[tuple[float, str]]:
    """Room status changes as (seconds since recording start, status)."""
    log = run_dir / "logs" / "e2e.log"
    if not log.exists():
        return []
    stamps: list[tuple[datetime, str]] = []
    rec_start: datetime | None = None
    for line in log.read_text().splitlines():
        m = re.match(r"\[e2e (\d\d:\d\d:\d\d)\] (.*)", line)
        if not m:
            continue
        t = datetime.strptime(m.group(1), "%H:%M:%S")
        msg = m.group(2)
        if "screen recording started" in msg:
            rec_start = t
        sm = re.match(r"room status: (\w+)", msg)
        if sm and rec_start is not None:
            stamps.append((t, sm.group(1)))
    if rec_start is None:
        return []
    return [((t - rec_start).total_seconds(), s) for t, s in stamps]


def e2e_video(run_dir: Path) -> Path | None:
    for name in ("four-way-match.mp4", "four-way-match.mov"):
        p = run_dir / name
        if p.exists():
            return p
    return None


def load_json(path: Path) -> dict:
    return json.loads(path.read_text()) if path.exists() else {}


def platform_label(pid: str) -> str:
    return {"web": "Web (Chromium via Playwright)", "ios": "iOS Simulator", "macos": "Native macOS", "android": "Android"}.get(pid, pid)


# -- main -------------------------------------------------------------------


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--e2e", type=Path, required=True)
    ap.add_argument("--manual", type=Path)
    ap.add_argument("--parity", type=Path)
    ap.add_argument("--design", type=Path)
    ap.add_argument("--out", type=Path, required=True, help="output path without extension")
    ap.add_argument("--android-note", default="APK builds from the shared codebase; the arm64 emulator cannot boot on this VM (no nested virtualization), so no live Android seat.")
    ap.add_argument("--music", type=Path, default=MUSIC)
    ap.add_argument("--keep-work", action="store_true")
    args = ap.parse_args()

    e2e = args.e2e.resolve()
    result = load_json(e2e / "result.json")
    if not result:
        raise SystemExit(f"no result.json in {e2e}")
    shots = e2e / "screenshots"
    live = list(result.get("platformsVerified") or result.get("clientHashes", {}).keys())
    server_hash = result.get("serverHash", "?")
    status = "PASS" if result.get("passed") else "FAIL"
    timeline = e2e_timeline(e2e)
    video = e2e_video(e2e)

    args.out = args.out.resolve()
    work = args.out.parent / f".{args.out.name}.work"
    if work.exists():
        shutil.rmtree(work)
    work.mkdir(parents=True)
    edit = Edit(work=work)

    # ---- cards ---------------------------------------------------------
    cards: list[dict] = []

    def card(cid: str, kind: str, **fields) -> Path:
        cards.append({"id": cid, "kind": kind, **fields})
        p = work / "cards" / f"{cid}.png"
        edit.cards[cid] = p
        return p

    def caption(cid: str, text: str, detail: str = "", verdict: str = "") -> Path:
        return card(cid, "caption", text=text, detail=detail, verdict=verdict)

    def label(cid: str, text: str) -> Path:
        return card(cid, "label", text=text)

    def chapter(cid: str, eyebrow: str, title: str, subtitle: str) -> Path:
        return card(cid, "chapter", eyebrow=eyebrow, title=title, subtitle=subtitle)

    live_names = " + ".join(platform_label(p).split(" (")[0] for p in live)
    c_title = card(
        "title",
        "title",
        title="Verification review",
        subtitle=f"Cross-platform Grand Prix · room {result.get('room', '?')} · seed {result.get('seed', '?')}",
        lines=[
            f"Live clients: {live_names} + bots",
            f"Server result hash {server_hash} matched on every client ({status})",
            "Android: release APK build only (emulator unavailable on this VM)",
            f"Rendered {datetime.now().strftime('%Y-%m-%d')} from the clone-this evidence directory",
        ],
    )
    c_ch_match = chapter("ch_match", "Chapter 1", "Automated four-way match", f"{live_names} race the Sugar Cup through one authoritative server")
    c_ch_platforms = chapter("ch_platforms", "Chapter 2", "Platform by platform", "Lobby → racing → results → final standings on each client")
    c_ch_compare = chapter("ch_compare", "Chapter 3", "Same result everywhere", "Final standings, points and hash compared across clients")
    c_ch_parity = chapter("ch_parity", "Chapter 4", "Visual parity", "Web baseline vs native macOS after normalization")
    c_ch_manual = chapter("ch_manual", "Chapter 5", "Manual play-through", "Testing-agent session: Grand Prix, rejoin, time trial, touch HUD")
    c_ch_design = chapter("ch_design", "Chapter 6", "Design pass", "Kart-racer HUD and menu layout conventions, original Nitro Tots art")
    c_android = card("android", "notice", eyebrow="Build-only platform", title="Android", lines=[args.android_note, "Same Flutter/Flame codebase, same protocol, same test hooks", "The seat can be added live on a host with virtualization"])

    cap_lobby = caption("cap_lobby", "Lobby: three live clients join room " + str(result.get("room", "")), "Host starts once every seat is ready; bots fill the remaining slots")
    cap_race = caption("cap_race", "Race start: countdown, lights, GO!", "Server-authoritative 30 Hz simulation · client prediction + interpolation")
    cap_results = caption("cap_results", "Race results and running cup total", "Points 15/12/10/9/8/7/6/5 carried across the four races")
    cap_final = caption("cap_final", f"Final standings · hash {server_hash}", "Every client reports the same order, points and hash")
    cap_plat = {p: caption(f"cap_{p}", platform_label(p), "Lobby → racing → results → match over") for p in live}
    cap_grid = caption("cap_grid", "Final standings side by side", "Identical order and points on each live client")
    cap_parity: dict[str, Path] = {}
    cap_manual = caption("cap_manual", "Manual play-through (testing agent)", "Release web build + native macOS app")
    tag_e2e = label("tag_e2e", "Automated e2e")
    tag_manual = label("tag_manual", "Manual UI")
    tag_design = label("tag_design", "Design pass")

    parity = load_json(args.parity / "visual_parity.json") if args.parity else {}
    parity_screens: list[tuple[str, int, int]] = []
    if parity:
        for r in parity.get("results", []):
            name = str(r["screen"])
            diff = int(r["different_pixels"])
            total = int(r["total_pixels"])
            parity_screens.append((name, diff, total))
            cap_parity[name] = caption(f"cap_parity_{name}", f"{name.title()}: web (left) vs native macOS (right)", f"{diff}/{total} differing normalized pixels")

    manual = args.manual.resolve() if args.manual else None
    manual_slides: list[tuple[Path, Path | None]] = []
    manual_video: Path | None = None
    manual_cuts: list[tuple[float, Path]] = []
    if manual and manual.exists():
        manual_video = next(iter(sorted(manual.glob("*.mp4"))), None)
        fixes = load_json(manual / "fixes.json")
        ann_file = next(iter(sorted(manual.glob("*annotations.json"))), None)
        if ann_file is not None:
            for i, a in enumerate(load_json(ann_file).get("annotations", [])):
                if a.get("type") != "assertion":
                    continue
                text = str(a.get("assertion", ""))
                fixed_note = next((note for key, note in fixes.items() if key in text), None)
                verdict = "FIXED" if fixed_note else ("PASS" if a.get("test_result") == "passed" else "FAIL")
                detail = fixed_note or str(a.get("test", ""))
                manual_cuts.append((float(a["source_time_ms"]) / 1000.0, caption(f"cap_a{i:03d}", text, detail, verdict)))
        wanted = [
            # manual-ui (first pass)
            ("cup_race1_results.png", "Grand Prix race 1 results", "Fixed rival roster, points table"),
            ("cup_race4_results.png", "Grand Prix race 4 results", "Cumulative totals after the last race"),
            ("cup_final_standings.png", "Cup final standings", "Podium + points, same roster all cup"),
            ("title_rejoin_banner.png", "Rejoin banner after a mid-race refresh", "Reconnect/resume credentials persisted"),
            ("resumed_live_race.png", "Resumed into the live race", "Same player id and slot, no duplicate seat"),
            ("time_trial_hud_vs_results_fixed.png", "Time trial: HUD clock equals results time", "Countdown excluded from the race clock"),
            ("touch_hud_400px.png", "Touch HUD at 400 px", "Speedo + minimap sit above the on-screen controls"),
            ("web_online_final.png", "Web: online final standings", ""),
            ("macos_online_final.png", "macOS: online final standings", ""),
            # manual-ui-2 (design pass)
            ("title_desktop_1280x800.png", "Title: mode tiles at 1280x800", ""),
            ("title_phone_400_truncated_labels.png", "Title at 400 px: labels truncated (defect found)", "Fixed after the run: tiles drop to one column below 480 px"),
            ("title_phone_400_fixed.png", "Title at 400 px after the fix", "Full labels and hints, single column"),
            ("garage_desktop_selected.png", "Garage: tot roster + kart list", ""),
            ("cup_desktop_one_lap.png", "Cup select with race options", ""),
            ("countdown_three_lights.png", "Start lights", ""),
            ("countdown_green_go.png", "GO!", ""),
            ("quick_race_hud.png", "Race HUD", "Item slot · lap/clock/ping · place · speedo · minimap"),
            ("quick_race_paused.png", "Pause overlay, clock frozen", ""),
            ("quick_results_1280x800.png", "Results table at 1280x800", "Rank · portrait · kart · time · +pts, local row highlighted"),
            ("quick_results_1024x700_scrolled.png", "Results table at 1024x700 (scrolled)", ""),
            ("gp_race1_totals.png", "Grand Prix race 1: running totals", ""),
            ("gp_race4_totals.png", "Grand Prix race 4: cumulative totals", ""),
            ("gp_final_podium_standings.png", "Cup podium + final standings", ""),
            ("online_web_final_results.png", "Online: web final standings", ""),
            ("online_native_final_results.png", "Online: native macOS final standings", "Same order, points and hash as web"),
            ("touch_hud_400x900.png", "Touch HUD at 400x900", "Speedo + minimap above the on-screen controls"),
        ]
        for fname, text, detail in wanted:
            p = manual / fname
            if p.exists():
                manual_slides.append((p, caption(f"cap_m_{p.stem}", text, detail)))

    design_slides: list[tuple[Path, Path | None]] = []
    if args.design and args.design.exists():
        captions = load_json(args.design / "captions.json")
        for p in sorted(args.design.glob("*.png")):
            text = captions.get(p.stem) or p.stem.split("_", 1)[-1].replace("_", " ").replace("-", " ").capitalize()
            design_slides.append((p, caption(f"cap_d_{p.stem}", text, "Original Nitro Tots art · layout follows documented kart-racer conventions")))

    standings = result.get("standings") or []
    summary_rows = [
        ["Live platforms", " · ".join(platform_label(p).split(" (")[0] for p in live), "ok"],
        ["Result hash", f"{server_hash} on server + {len(live)} clients", "ok" if result.get("passed") else "warn"],
        ["Races", f"{result.get('races', '?')} (Sugar Cup)", "info"],
        ["Winner", f"{standings[0]['name']} · {standings[0]['points']} pts" if standings else "—", "info"],
        ["Visual parity", (f"{sum(1 for _, d, _ in parity_screens if d == 0)}/{len(parity_screens)} screens 0 diffs" if parity_screens else "not run"), "ok" if parity_screens and all(d == 0 for _, d, _ in parity_screens) else "warn"],
        ["Android", "release APK build only", "warn"],
    ]
    c_summary = card("summary", "summary", title="What this run verified", rows=summary_rows)

    spec = {"width": W, "height": H, "cards": cards}
    (work / "cards.json").write_text(json.dumps(spec, indent=2))
    run([NODE, str(HERE / "review_cards.mjs"), str(work / "cards.json"), str(work / "cards")])

    # ---- edit ---------------------------------------------------------------
    edit.still("Intro", c_title, 5.0, "title")

    ch = "Automated four-way match"
    edit.still(ch, c_ch_match, 3.0, "ch1")
    if video is not None and video.exists():
        vlen = duration(video)
        racing = [t for t, s in timeline if s == "racing"]
        results_t = [t for t, s in timeline if s == "results"]
        over = [t for t, s in timeline if s == "matchOver"]
        lobby_start = min((t for t, s in timeline if s == "lobby"), default=2.0)
        first_race = racing[0] if racing else lobby_start + 8
        edit.clip(ch, video, lobby_start, max(2.0, first_race - lobby_start), 1.0, cap_lobby, "lobby", tag_e2e)
        edit.clip(ch, video, first_race - 2.0, 14.0, 1.0, cap_race, "race_start", tag_e2e)
        mid_len = (results_t[0] - first_race - 12.0) if results_t else 30.0
        if mid_len > 4:
            edit.clip(ch, video, first_race + 12.0, mid_len, 6.0, None, "race1_fast", tag_e2e)
        if results_t:
            edit.clip(ch, video, results_t[0] + 0.5, 6.0, 1.0, cap_results, "race1_results", tag_e2e)
        if len(racing) > 1 and results_t:
            span_start = racing[1]
            span_end = (over[0] if over else vlen) - 1.0
            if span_end - span_start > 10:
                edit.clip(ch, video, span_start, span_end - span_start, 12.0, None, "races_2_4_fast", tag_e2e)
        if over:
            edit.clip(ch, video, over[0] + 0.5, min(7.0, vlen - over[0] - 0.6), 1.0, cap_final, "match_over", tag_e2e)
        else:
            edit.clip(ch, video, max(0.0, vlen - 8.0), 7.0, 1.0, cap_final, "match_over", tag_e2e)

    ch = "Platform by platform"
    edit.still(ch, c_ch_platforms, 3.0, "ch2")
    for p in live:
        seq = [shots / f"{p}_{phase}.png" for phase in ("lobby", "racing", "racing_mid", "results", "matchOver")]
        seq = [s for s in seq if s.exists()]
        if seq:
            edit.slides(ch, [(s, cap_plat[p]) for s in seq], 2.2, f"plat_{p}", tag_e2e)
    edit.still(ch, c_android, 5.0, "android")

    ch = "Same result everywhere"
    edit.still(ch, c_ch_compare, 3.0, "ch3")
    finals = [shots / f"{p}_matchOver.png" for p in live if (shots / f"{p}_matchOver.png").exists()]
    if len(finals) >= 2:
        edit.compare(ch, finals[0], finals[1], 6.0, cap_grid, "compare_final", tag_e2e)
    if len(finals) >= 3 and (shots / "desktop_matchOver.png").exists():
        edit.grid(ch, [*finals[:3], shots / "desktop_matchOver.png"], 6.0, cap_grid, "grid_final")

    if parity_screens and args.parity:
        ch = "Visual parity"
        edit.still(ch, c_ch_parity, 3.0, "ch4")
        for name, _, _ in parity_screens:
            ref = args.parity / "reference" / f"web_{name}.png"
            cln = args.parity / "clone" / f"macos_{name}.png"
            if ref.exists() and cln.exists():
                edit.compare(ch, ref, cln, 3.5, cap_parity[name], f"parity_{name}")

    if manual and manual.exists():
        ch = "Manual play-through"
        edit.still(ch, c_ch_manual, 3.0, "ch5")
        if manual_video is not None:
            mlen = duration(manual_video)
            if manual_cuts:
                lead = 7.0
                for i, (t, cap) in enumerate(manual_cuts):
                    start = max(0.0, t - lead)
                    length = min(lead + 1.0, mlen - start)
                    if length > 2:
                        edit.clip(ch, manual_video, start, length, 1.0, cap, f"assert{i:02d}", tag_manual)
            else:
                edit.clip(ch, manual_video, 0.0, min(mlen, 40.0), 1.0, cap_manual, "manual_intro", tag_manual)
                if mlen > 60:
                    edit.clip(ch, manual_video, 40.0, mlen - 41.0, 16.0, None, "manual_fast", tag_manual)
        if manual_slides:
            edit.slides(ch, manual_slides, 3.2, "manual_slides", tag_manual)

    if design_slides:
        ch = "Design pass"
        edit.still(ch, c_ch_design, 3.0, "ch6")
        edit.slides(ch, design_slides, 3.0, "design_slides", tag_design)

    edit.still("Summary", c_summary, 7.0, "summary")

    # ---- assemble -------------------------------------------------------
    concat = work / "concat.txt"
    concat.write_text("".join(f"file '{s.out}'\n" for s in edit.segments))
    chapters = []
    t = 0.0
    for s in edit.segments:
        actual = duration(s.out)
        s.seconds = actual
        if not chapters or chapters[-1]["title"] != s.chapter:
            chapters.append({"title": s.chapter, "start": round(t, 3)})
        t += actual
    total = t
    for i, c in enumerate(chapters):
        c["end"] = chapters[i + 1]["start"] if i + 1 < len(chapters) else round(total, 3)
    meta = [";FFMETADATA1", "title=Nitro Tots verification review", ""]
    for c in chapters:
        meta += ["[CHAPTER]", "TIMEBASE=1/1000", f"START={int(c['start'] * 1000)}", f"END={int(c['end'] * 1000)}", f"title={c['title']}", ""]
    metafile = work / "chapters.ffmeta"
    metafile.write_text("\n".join(meta))

    out_mp4 = args.out.with_suffix(".mp4")
    cmd = [FFMPEG, "-y", "-loglevel", "error", "-f", "concat", "-safe", "0", "-i", str(concat)]
    if args.music and Path(args.music).exists():
        cmd += ["-stream_loop", "-1", "-i", str(args.music), "-i", str(metafile), "-map_metadata", "2", "-filter_complex", f"[1:a]volume=0.28,afade=t=in:st=0:d=1.5,afade=t=out:st={total - 3.0:.2f}:d=3[a]", "-map", "0:v", "-map", "[a]", "-c:a", "aac", "-b:a", "128k"]
    else:
        cmd += ["-i", str(metafile), "-map_metadata", "1", "-map", "0:v"]
    cmd += ["-c:v", "copy", "-t", f"{total:.3f}", "-movflags", "+faststart", "-flags", "+bitexact", "-fflags", "+bitexact", str(out_mp4)]
    run(cmd)

    (args.out.parent / f"{args.out.name}.chapters.json").write_text(json.dumps({"duration": round(total, 3), "chapters": chapters, "segments": [{"chapter": s.chapter, "kind": s.kind, "seconds": round(s.seconds, 3), "source": s.source} for s in edit.segments]}, indent=2))
    md = [f"# Review video edit list ({total:.0f}s, {W}x{H}@{FPS})", "", f"Output: `{out_mp4.name}` · chapters embedded as MP4 metadata", "", "| Start | Chapter | Segment | Source |", "|---|---|---|---|"]
    t = 0.0
    for s in edit.segments:
        md.append(f"| {int(t // 60)}:{int(t % 60):02d} | {s.chapter} | {s.kind} ({s.seconds:.1f}s) | {s.source} |")
        t += s.seconds
    (args.out.parent / f"{args.out.name}.md").write_text("\n".join(md) + "\n")

    if not args.keep_work:
        shutil.rmtree(work)
    print(f"review video: {out_mp4} ({total:.1f}s, {len(chapters)} chapters, {len(edit.segments)} segments)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
