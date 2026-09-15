#!/usr/bin/env python3
"""Actual native UI runner. The sidecar displays inspect.getsource(current_step).

Only the starting PNG is generated. Pixel's project model is never injected.
JSON reads are assertions on documents written by the real Save command.
"""
import inspect
import json
import os
from pathlib import Path
import re
import struct
import subprocess
import sys
import time

ROOT = Path(os.environ.get("PIXEL_DEMO_OUT",
                           str(Path.home() / "PixelDemo-artifacts")))
NATIVE = ROOT / "native"
PROJECT = ROOT / "After Hours.devin"
EXPORT = ROOT / "After Hours.png"
STATE = ROOT / "live.json"
CHECKS = []
CURRENT = None
PACE = float(os.environ.get("PIXEL_DEMO_PACE", "1"))
STROKE = {}


def native(*args):
    return subprocess.check_output([str(NATIVE), *map(str, args)], text=True)


def pause(seconds=0.6):
    time.sleep(seconds * PACE)


def ui():
    return json.loads(native("list"))


def find(role=None, text=None, nth=0):
    matches = [n for n in ui()
               if (role is None or n.get("AXRole") == role)
               and (text is None or text in [
                   n.get(k) for k in ("AXTitle", "AXDescription",
                                     "AXValue", "AXPlaceholderValue")])]
    if len(matches) <= nth:
        raise AssertionError(f"Missing native UI {role=} {text=} {nth=}")
    return matches[nth]


def click_node(node):
    x, y, w, h = node["rect"]
    assert w > 0 and h > 0, f"Not visible: {node}"
    native("click", x + w / 2, y + h / 2)


def click(text, role=None):
    click_node(find(role, text))


KEYS = {"a": 0, "b": 11, "d": 2, "e": 14, "g": 5, "i": 34,
        "j": 38, "m": 46, "n": 45, "o": 31, "s": 1, "t": 17,
        "v": 9, "z": 6, "0": 29, "return": 36, "esc": 53, "tab": 48,
        "down": 125, "up": 126}


def key(name, flags=""):
    native("key", KEYS[name], flags)
    pause(0.2)


def type_text(text):
    native("type", text)


def replace(node, value):
    click_node(node)
    native("selectText", node["index"])
    type_text(str(value))
    key("return")
    pause()


def field(index, value):
    replace(find("AXTextField", nth=index), value)


def hex_color(value):
    replace(find("AXTextField", "Hex"), value)


def tool(name):
    click(name + " tools", "AXButton")
    pause()


def canvas_point(x, y):
    r = next(n["rect"] for n in ui()
             if n.get("AXRole") == "AXScrollArea"
             and n["rect"][2] > 500
             and n["rect"][3] > 500)
    zoom = next(n["AXTitle"] for n in ui()
                if n.get("AXRole") == "AXMenuButton"
                and n.get("AXTitle", "").endswith("%"))
    scale = float(zoom[:-1]) / 100
    return [r[0] + r[2] / 2 + (x - 450) * scale,
            r[1] + r[3] / 2 + (y - 550) * scale]


def canvas_click(x, y):
    native("click", *canvas_point(x, y))
    pause()


def drag(points, evidence=None):
    coords = [canvas_point(x, y) for x, y in points]
    args = ["drag", json.dumps(coords)]
    if evidence:
        args.append(ROOT / evidence)
    native(*args)
    pause()


def ribbon_curve():
    controls = [(150, 810), (310, 605),
                (500, 770), (780, 450)]
    return [[sum(w * p[a] for w, p in zip(
        [(1-t)**3, 3*(1-t)**2*t,
         3*(1-t)*t*t, t**3], controls))
        for a in (0, 1)] for t in
        [i / 16 for i in range(17)]]


def open_file(path):
    key("o", "cmd")
    pause(0.8)
    native("panel")
    key("g", "cmdshift")
    pause(0.6)
    sheet = find("AXSheet")
    field = next(n for n in ui() if n["index"] > sheet["index"]
                 and n.get("AXRole") == "AXTextField")
    click_node(field)
    native("selectText", field["index"])
    type_text(str(path))
    pause(0.7)
    key("return")
    pause(0.8)
    key("return")
    pause(1)


def snapshot(name):
    subprocess.run(["/usr/sbin/screencapture", "-x", str(ROOT / name)],
                   check=True)


def document():
    key("s", "cmd")
    pause(0.5)
    return json.loads(PROJECT.read_text())


def save_panel(path):
    # Go To Folder, then name only (slashes in names become colons).
    key("g", "cmdshift")
    pause(0.6)
    # The Go To sheet field follows the Save As and Tags fields.
    sheet = find("AXSheet")
    path_field = next(n for n in ui() if n["index"] > sheet["index"]
                      and n.get("AXRole") == "AXTextField")
    click_node(path_field)
    native("selectText", path_field["index"])
    type_text(str(path.parent))
    pause(0.8)
    key("return")
    pause(1)
    replace(find("AXTextField"), path.name)
    pause(1)


def update(status):
    source = inspect.getsource(CURRENT) if CURRENT else "# Native run ready"
    STATE.write_text(json.dumps({
        "status": status, "title": CURRENT.__doc__ if CURRENT else "Ready",
        "source": source, "checks": CHECKS}))


def check(condition, label):
    result = "PASS" if condition else "FAIL"
    CHECKS.append(f"{result}  {label}")
    print(CHECKS[-1], flush=True)
    update("RUNNING" if condition else "FAILED")
    assert condition, label


def step(function):
    global CURRENT
    CURRENT = function
    update("RUNNING")
    print(f"\nSTEP {function.__name__}", flush=True)
    pause(2)
    function()
    update("PASSED")
    pause(2)


def starting_input():
    """01 / Open the starting landscape"""
    open_file(ROOT / "inputs" / "After Hours.png")
    key("s", "cmdshift")
    pause(1)
    save_panel(PROJECT)
    d = document()
    check(len(d["elements"]) == 1,
          "One starting image layer")
    check((d["width"], d["height"]) ==
          (900, 1100), "900 × 1100 canvas")


def grade_landscape():
    """02 / Lift the evening light"""
    label = find("AXStaticText", "Exposure")
    x, y, _, _ = label["rect"]
    native("click", x + 145, y + 25)
    exposure = document()["elements"][0][
        "adjustments"]["exposure"]
    check(0.1 < exposure < 0.8,
          "Exposure lift saved")


def prepare_ribbon():
    """03 / Select the light-ribbon region"""
    key("n", "cmdshift")
    tool("Marquee")
    drag([(110, 405), (790, 920)])
    verify_marquee()
    snapshot("selection.png")
    pause(1)


def verify_marquee():
    dimensions = next(n["AXValue"] for n in ui()
        if n.get("AXValue", "").startswith("W: "))
    w, h = map(int, re.findall(r"\d+", dimensions))
    check(abs(w-680) <= 1 and abs(h-515) <= 1,
          "Marquee 680 × 515 px")


def paint_ribbon():
    """04 / Paint a real curved gesture"""
    tool("Brush")
    hex_color("F9BA77")
    field(0, 26)
    field(1, 85)
    field(2, 70)
    blank = document()["elements"][-1]
    drag(ribbon_curve(), "stroke-held.png")
    painted = document()["elements"][-1]
    check(painted["imageData"] !=
          blank["imageData"], "Real stroke saved")
    STROKE.update(blank=blank, painted=painted)


def undo_redo():
    """05 / Undo, redo & screen blend"""
    key("z", "cmd")
    current = document()["elements"][-1]
    check(current == STROKE["blank"],
          "Undo restores blank layer")
    pause(1)
    key("z", "cmdshift")
    current = document()["elements"][-1]
    check(current == STROKE["painted"],
          "Redo restores exact paint")
    key("d", "cmd")
    click("Normal")
    click("Screen", "AXMenuItem")
    current = document()["elements"][-1]
    check(current["blendMode"] == "screen",
          "Screen blend persisted")


def typography(text, x, y, width, height, size):
    tool("Type")
    canvas_click(x, y)
    native("move", 1040, 600)
    native("scroll", 1200)
    pause()
    for label, value in [("W", width), ("H", height),
                         ("X", x), ("Y", y), ("Size", size)]:
        replace(find("AXTextField", label), value)
    native("move", 1040, 780)
    native("scroll", -240)
    pause()
    editor = find("AXTextArea")
    click_node(editor)
    native("selectText", editor["index"])
    type_text(text)
    native("click", 700, 116)
    pause()
    native("move", 1040, 600)
    native("scroll", 1200)
    pause()


def title_lettering():
    """06 / Set the editable cover title"""
    hex_color("243844")
    typography("AFTER\nHOURS",
               50, 28, 800, 310, 124)
    layer = document()["elements"][-1]
    check(layer["text"] == "AFTER\nHOURS"
          and layer["fontSize"] == 124,
          "124 pt editable title saved")


def edition_line():
    """07 / Add the edition signature"""
    typography("A STUDY IN LIGHT / VOL. 01",
               50, 1015, 800, 55, 23)
    layer = document()["elements"][-1]
    check(layer["text"] ==
          "A STUDY IN LIGHT / VOL. 01",
          "Edition line is editable")
    tool("Move")
    canvas_click(875, 1060)
    snapshot("final-artwork.png")


def save_and_export():
    """08 / Save the project & export PNG"""
    saved = document()
    check(len(saved["elements"]) == 4,
          "Four-layer editable project")
    click("Export", "AXButton")
    pause(1)
    check(find("AXPopUpButton", "Format")[
        "AXValue"] == "PNG image  (.png)",
        "Native PNG export selected")
    click("Export…", "AXButton")
    pause(1)
    save_panel(EXPORT)
    pause(2)
    size = struct.unpack(">II",
                         EXPORT.read_bytes()[16:24])
    check(size == (900, 1100),
          "900 × 1100 PNG exported")


def reopen_project():
    """09 / Reopen the editable original"""
    before = json.loads(PROJECT.read_text())
    click("Close document After Hours")
    open_file(PROJECT)
    after = document()
    check(before == after,
          "Reopened project is identical")
    tool("Move")
    canvas_click(875, 1060)
    check(len(after["elements"]) == 4,
          "Image, paint & two type layers")
    snapshot("final-desktop.png")
    pause(5)


if __name__ == "__main__":
    native("activate")
    native("frame")
    try:
        for function in [starting_input, grade_landscape,
                         prepare_ribbon, paint_ribbon, undo_redo,
                         title_lettering, edition_line,
                         save_and_export, reopen_project]:
            if os.environ.get("PIXEL_DEMO_INTERACTIVE") == "1":
                input(f"READY {function.__name__} [Return]")
            step(function)
        update("PASSED")
        snapshot("final-desktop.png")
        pause(5)
    except Exception:
        update("FAILED")
        snapshot("failure-desktop.png")
        raise
