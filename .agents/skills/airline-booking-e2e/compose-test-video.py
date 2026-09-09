#!/usr/bin/env python3
"""Compose the test video: screen recording on the left, live test-flow panel on the right.

The panel is driven purely by the recording's annotation JSON (setup / test_start / assertion
events with their edited-video timestamps), so it shows exactly what the agent asserted, when.

usage: compose.py <edited.mp4> <annotations.json> <out.mp4> [--title NAME] [--subtitle TEXT]
needs: ffmpeg, pillow (and fonttools+brotli to reuse the app's Manrope/Instrument Serif fonts;
       falls back to DejaVu Sans otherwise)
"""
import json, math, os, subprocess, sys, tempfile
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
APP_NODE_MODULES = os.path.normpath(os.path.join(HERE, "..", "..", "..", "airline-booking", "node_modules"))
FONT_CACHE = os.path.join(tempfile.gettempdir(), "airline-booking-e2e-fonts")
DEJAVU = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
DEJAVU_BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
DEJAVU_SERIF = "/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf"

WOFF2 = {
    "manrope.ttf": "@fontsource-variable/manrope/files/manrope-latin-wght-normal.woff2",
    "instrument-serif.ttf": "@fontsource/instrument-serif/files/instrument-serif-latin-400-normal.woff2",
}


def font_path(name):
    """Return a TTF for one of the app's bundled fonts, converting the woff2 once, else None."""
    out = os.path.join(FONT_CACHE, name)
    if os.path.exists(out):
        return out
    src = os.path.join(APP_NODE_MODULES, WOFF2[name])
    if not os.path.exists(src):
        return None
    try:
        from fontTools.ttLib import TTFont
    except ImportError:
        return None
    os.makedirs(FONT_CACHE, exist_ok=True)
    f = TTFont(src)
    f.flavor = None
    f.save(out)
    return out

# ---- palette (matches the Contrail Air app / dark Devin UI) -------------------------------------
BG = (9, 12, 20)
PANEL = (14, 18, 30)
LINE = (30, 37, 56)
TEXT = (234, 238, 247)
MUTED = (139, 149, 173)
DIM = (86, 95, 118)
BLUE = (79, 140, 255)
GREEN = (52, 199, 122)
AMBER = (245, 176, 60)
RED = (239, 91, 91)
CARD = (18, 23, 38)
CARD_ACTIVE = (21, 29, 50)


def font(name, size, weight=None):
    path = font_path({"ui": "manrope.ttf", "serif": "instrument-serif.ttf"}[name])
    if path is None:
        if name == "serif":
            return ImageFont.truetype(DEJAVU_SERIF, size)
        return ImageFont.truetype(DEJAVU_BOLD if (weight or 0) >= 700 else DEJAVU, size)
    f = ImageFont.truetype(path, size)
    if weight is not None:
        try:
            f.set_variation_by_axes([weight])
        except Exception:
            pass
    return f


def mono(size):
    for p in ("/usr/share/fonts/truetype/jetbrains-mono/JetBrainsMono-Regular.ttf",
              "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"):
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()


ARROW_FONT = ImageFont.truetype(DEJAVU, 15)


def tlen(draw, text, f):
    return sum(draw.textlength(seg, font=f) if seg != "→" else draw.textlength("→", font=ARROW_FONT) + 4
               for seg in split_arrows(text))


def split_arrows(text):
    out, cur = [], ""
    for ch in text:
        if ch == "→":
            if cur:
                out.append(cur)
            out.append("→")
            cur = ""
        else:
            cur += ch
    if cur:
        out.append(cur)
    return out


def dtext(draw, xy, text, f, fill):
    """draw.text that renders → with a fallback font (Manrope's latin subset has no arrows)."""
    x, y = xy
    for seg in split_arrows(text):
        if seg == "→":
            af = ARROW_FONT.font_variant(size=f.size)
            draw.text((x + 2, y + 1), "→", font=af, fill=fill)
            x += draw.textlength("→", font=af) + 4
        else:
            draw.text((x, y), seg, font=f, fill=fill)
            x += draw.textlength(seg, font=f)


def wrap(draw, text, f, width):
    words, lines, cur = text.split(), [], ""
    for w in words:
        t = (cur + " " + w).strip()
        if tlen(draw, t, f) <= width:
            cur = t
        else:
            if cur:
                lines.append(cur)
            cur = w
    if cur:
        lines.append(cur)
    return lines


def fmt_t(s):
    s = max(0, int(s))
    return f"{s // 60:02d}:{s % 60:02d}"


# ---- state model --------------------------------------------------------------------------------
class Model:
    def __init__(self, ann):
        self.events = [a for a in ann if a["type"] in ("setup", "test_start", "assertion")]
        self.tests = []
        for e in self.events:
            if e["type"] == "test_start" and e["test"] not in self.tests:
                self.tests.append(e["test"])

    def state_at(self, t):
        setup, started, results = [], [], {name: [] for name in self.tests}
        for e in self.events:
            if e["edited_time_s"] > t:
                break
            if e["type"] == "setup":
                setup.append(e["description"])
            elif e["type"] == "test_start":
                started.append(e["test"])
            else:
                results.setdefault(e["test"], []).append((e["test_result"], e["assertion"]))
        return setup, started, results


# ---- rendering ----------------------------------------------------------------------------------
class Panel:
    def __init__(self, w, h, title, subtitle, model, duration):
        self.w, self.h, self.title, self.subtitle, self.model, self.duration = w, h, title, subtitle, model, duration
        self.f_eyebrow = font("ui", 13, 700)
        self.f_title = font("serif", 40)
        self.f_sub = font("ui", 15, 500)
        self.f_test = font("ui", 17, 700)
        self.f_assert = font("ui", 14, 500)
        self.f_small = font("ui", 13, 600)
        self.f_mono = mono(15)
        self.f_big = font("ui", 22, 800)
        self.pad = 34

    def icon(self, d, cx, cy, kind, pulse=0.0):
        r = 11
        if kind == "pending":
            d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=DIM, width=2)
        elif kind == "running":
            glow = int(3 + 3 * math.sin(pulse * math.tau))
            d.ellipse([cx - r - glow, cy - r - glow, cx + r + glow, cy + r + glow], outline=(BLUE[0], BLUE[1], BLUE[2]), width=1)
            d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=BLUE)
            d.ellipse([cx - 4, cy - 4, cx + 4, cy + 4], fill=TEXT)
        elif kind == "passed":
            d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=GREEN)
            d.line([(cx - 5, cy), (cx - 1, cy + 4), (cx + 6, cy - 4)], fill=(6, 30, 18), width=3, joint="curve")
        elif kind == "failed":
            d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=RED)
            d.line([(cx - 5, cy - 5), (cx + 5, cy + 5)], fill=TEXT, width=3)
            d.line([(cx - 5, cy + 5), (cx + 5, cy - 5)], fill=TEXT, width=3)
        elif kind == "untested":
            d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=AMBER)
            d.line([(cx - 5, cy), (cx + 5, cy)], fill=(40, 28, 4), width=3)

    def small_icon(self, d, cx, cy, result):
        r = 7
        col = {"passed": GREEN, "failed": RED, "untested": AMBER}[result]
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=col)
        if result == "passed":
            d.line([(cx - 3, cy), (cx - 1, cy + 2), (cx + 4, cy - 3)], fill=(6, 30, 18), width=2)
        elif result == "failed":
            d.line([(cx - 3, cy - 3), (cx + 3, cy + 3)], fill=TEXT, width=2)
            d.line([(cx - 3, cy + 3), (cx + 3, cy - 3)], fill=TEXT, width=2)
        else:
            d.line([(cx - 3, cy), (cx + 3, cy)], fill=(40, 28, 4), width=2)

    def render(self, t):
        setup, started, results = self.model.state_at(t)
        tests = self.model.tests
        finished = t >= self.model.events[-1]["edited_time_s"] + 0.5
        n_pass = sum(1 for v in results.values() for r, _ in v if r == "passed")
        n_fail = sum(1 for v in results.values() for r, _ in v if r == "failed")
        n_unt = sum(1 for v in results.values() for r, _ in v if r == "untested")
        n_total_shown = n_pass + n_fail + n_unt

        img = Image.new("RGB", (self.w, self.h), PANEL)
        d = ImageDraw.Draw(img)
        d.line([(0, 0), (0, self.h)], fill=LINE, width=2)
        x0, y = self.pad, 30
        text_w = self.w - 2 * self.pad

        # header
        d.ellipse([x0, y + 1, x0 + 10, y + 11], fill=BLUE)
        d.text((x0 + 18, y - 2), "DEVIN  ·  COMPUTER-USE TEST", font=self.f_eyebrow, fill=BLUE)
        y += 26
        d.text((x0, y), self.title, font=self.f_title, fill=TEXT)
        y += 52
        for ln in wrap(d, self.subtitle, self.f_sub, text_w):
            d.text((x0, y), ln, font=self.f_sub, fill=MUTED)
            y += 21
        y += 10
        # status strip
        done_tests = sum(1 for name in tests if results.get(name) and (len(started) > tests.index(name) + 1 or finished))
        strip = f"{fmt_t(t)} / {fmt_t(self.duration)}"
        d.text((x0, y), strip, font=self.f_mono, fill=MUTED)
        right = f"{n_pass} passed" + (f" · {n_fail} failed" if n_fail else "") + (f" · {n_unt} untested" if n_unt else "")
        d.text((self.w - self.pad - d.textlength(right, font=self.f_small), y + 2), right, font=self.f_small,
               fill=GREEN if not n_fail else RED)
        y += 26
        # progress bar
        d.rounded_rectangle([x0, y, x0 + text_w, y + 4], 2, fill=LINE)
        d.rounded_rectangle([x0, y, x0 + int(text_w * min(1, t / self.duration)), y + 4], 2, fill=BLUE)
        y += 22
        d.line([(x0, y), (x0 + text_w, y)], fill=LINE, width=1)
        y += 18

        # setup row (dropped once the run is over to make room for the verdict)
        if setup and not finished:
            self.small_icon(d, x0 + 7, y + 8, "passed")
            for i, ln in enumerate(wrap(d, "Setup — " + setup[-1], self.f_assert, text_w - 26)):
                d.text((x0 + 26, y), ln, font=self.f_assert, fill=MUTED)
                y += 18
            y += 12

        # tests — laid out onto a tall canvas, then scrolled so the active block is visible
        blocks = []
        for idx, name in enumerate(tests):
            res = results.get(name, [])
            is_started = name in started
            is_active = is_started and (started[-1] == name) and not finished
            if not is_started:
                kind = "pending"
            elif is_active:
                kind = "running"
            elif any(r == "failed" for r, _ in res):
                kind = "failed"
            elif any(r == "untested" for r, _ in res):
                kind = "untested"
            else:
                kind = "passed"
            blocks.append((idx, name, res, kind, is_active))

        canvas_h = 4000
        tall = Image.new("RGB", (self.w, canvas_h), PANEL)
        td = ImageDraw.Draw(tall)
        ty = 0
        active_span = (0, 0)
        for idx, name, res, kind, is_active in blocks:
            top = ty
            title_lines = wrap(td, f"{idx + 1}.  {name}", self.f_test, text_w - 44)
            block_h = 13 + len(title_lines) * 22 + 6
            a_lines = []
            for r, a in res:
                ls = wrap(td, a, self.f_assert, text_w - 44 - 24)
                a_lines.append((r, ls))
                block_h += len(ls) * 18 + 6
            block_h += 8 if res else 4
            fill = CARD_ACTIVE if is_active else CARD
            td.rounded_rectangle([x0 - 10, top, x0 + text_w + 10, top + block_h], 12, fill=fill,
                                 outline=BLUE if is_active else LINE, width=2 if is_active else 1)
            self.icon(td, x0 + 12, top + 13 + 11, kind, pulse=(t * 0.8) % 1)
            yy = top + 13
            col = TEXT if kind != "pending" else DIM
            for ln in title_lines:
                dtext(td, (x0 + 34, yy), ln, self.f_test, col)
                yy += 22
            yy += 6
            for r, ls in a_lines:
                self.small_icon(td, x0 + 41, yy + 8, r)
                for ln in ls:
                    dtext(td, (x0 + 58, yy), ln, self.f_assert, TEXT if r == "passed" else (RED if r == "failed" else AMBER))
                    yy += 18
                yy += 6
            if is_active:
                active_span = (top, top + block_h)
            ty = top + block_h + 10
        content_h = ty

        avail = self.h - y - (70 if finished else 24)
        scroll = 0
        if content_h > avail:
            if finished:
                scroll = content_h - avail
            else:
                a_top, a_bot = active_span
                # keep active block fully visible, preferring to show as much history as possible
                scroll = max(0, min(a_bot - avail + 10, content_h - avail))
                if a_top - scroll < 0:
                    scroll = a_top
        crop = tall.crop((0, scroll, self.w, scroll + avail))
        img.paste(crop, (0, y))
        # footer verdict
        if finished:
            fy = self.h - 62
            verdict = "FAILED" if n_fail else ("PASS WITH GAPS" if n_unt else "PASS")
            col = RED if n_fail else (AMBER if n_unt else GREEN)
            d.rounded_rectangle([x0 - 10, fy, x0 + text_w + 10, fy + 46], 12, fill=(col[0] // 6, col[1] // 6, col[2] // 6),
                                outline=col, width=2)
            d.text((x0 + 8, fy + 11), verdict, font=self.f_big, fill=col)
            summ = f"{len(tests)} tests · {n_total_shown} assertions"
            d.text((x0 + text_w - d.textlength(summ, font=self.f_sub), fy + 15), summ, font=self.f_sub, fill=MUTED)
        return img


def main():
    args = sys.argv[1:]
    title, subtitle = "airline-booking-e2e", "Skill run in a maximised Chrome window — mouse and keyboard only, no scripted automation."
    if "--title" in args:
        i = args.index("--title"); title = args[i + 1]; del args[i:i + 2]
    if "--subtitle" in args:
        i = args.index("--subtitle"); subtitle = args[i + 1]; del args[i:i + 2]
    video, ann_path, out = args
    ann = json.load(open(ann_path))["annotations"]
    probe = subprocess.run(["ffprobe", "-v", "error", "-select_streams", "v:0", "-show_entries",
                            "stream=width,height,duration", "-of", "csv=p=0", video], capture_output=True, text=True)
    vw, vh, dur = probe.stdout.strip().split(",")
    vw, vh, dur = int(vw), int(vh), float(dur)
    pw = 700
    model = Model(ann)
    panel = Panel(pw, vh, title, subtitle, model, dur)

    fps = 4  # panel frames per second (timer + pulse); video keeps its own frame rate
    tmp = tempfile.mkdtemp(prefix="panel-")
    n = int(math.ceil(dur * fps)) + fps
    for i in range(n):
        panel.render(i / fps).save(os.path.join(tmp, f"p{i:05d}.png"))
    subprocess.run([
        "ffmpeg", "-y", "-v", "error",
        "-framerate", str(fps), "-i", os.path.join(tmp, "p%05d.png"),
        "-i", video,
        "-filter_complex", f"[0:v]fps=24,format=rgb24[p];[1:v]fps=24[v];[v][p]hstack=inputs=2,format=yuv420p[o]",
        "-map", "[o]", "-map", "1:a?", "-shortest",
        "-c:v", "libx264", "-crf", "20", "-preset", "medium", "-movflags", "+faststart", out,
    ], check=True)
    print(out, f"{vw + pw}x{vh}", f"{dur:.1f}s", "frames:", n)


if __name__ == "__main__":
    main()
