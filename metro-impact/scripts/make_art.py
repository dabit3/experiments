"""Original stepped-palette arcade art. Requires Pillow 11.3.0, used only at authoring time."""
import math
import random
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1] / "Assets"
ROOT.mkdir(exist_ok=True)
rng = random.Random(1994)


def stage():
    im = Image.new("RGB", (640, 360))
    d = ImageDraw.Draw(im)
    for y in range(360):
        if y < 205:
            t = y / 205
            c = (int(42 + 200 * t), int(34 + 105 * t), int(95 - 26 * t))
        else:
            c = (23, 93, 115)
        d.line((0, y, 639, y), fill=c)
    # Terraced clouds and a low sun, above a hand-authored harbor silhouette.
    d.ellipse((426, 55, 513, 142), fill="#ffd184")
    for y in range(107, 145, 7):
        d.rectangle((420, y, 520, y + 2), fill="#df8278")
    for x, y, w in [(28, 74, 122), (184, 51, 127), (353, 93, 137), (520, 60, 112)]:
        for off, col in [(9, "#c27091"), (4, "#f39999"), (0, "#ffc2aa")]:
            d.polygon([(x, y + off + 9), (x + 20, y + off + 9), (x + 28, y + off),
                       (x + 49, y + off), (x + 58, y + off - 8), (x + 76, y + off - 8),
                       (x + 83, y + off), (x + w, y + off + 4), (x + w - 9, y + off + 12),
                       (x, y + off + 12)], fill=col)
    for x in range(10, 640, 24):
        h = rng.randrange(12, 65)
        d.rectangle((x, 198 - h, x + 18, 200), fill="#53436c")
        d.rectangle((x, 198 - h, x + 3, 200), fill="#8e5778")
        for wx in range(x + 6, x + 16, 6):
            for wy in range(201 - h, 195, 9):
                d.rectangle((wx, wy, wx + 2, wy + 3), fill=rng.choice(["#f8b173", "#a46b87", "#6c6086"]))
    # Container ship and crane.
    d.polygon([(242, 191), (399, 191), (381, 209), (257, 209)], fill="#203a5b")
    d.line((244, 192, 398, 192), fill="#e9ad75", width=3)
    for i in range(5):
        x = 260 + i * 22
        d.rectangle((x, 178, x + 20, 190), fill=["#a95560", "#d18666", "#4f7781"][i % 3])
        for j in range(x + 2, x + 20, 4):
            d.line((j, 180, j, 188), fill="#50394f")
    d.rectangle((367, 159, 382, 179), fill="#d2ac89")
    d.rectangle((369, 155, 384, 160), fill="#694d69")
    for x in [148, 557]:
        d.polygon([(x, 188), (x + 9, 188), (x + 9, 80), (x + 2, 80)], fill="#453752")
        d.line((x - 51, 81, x + 43, 81), fill="#47364d", width=5)
        d.line((x - 51, 81, x + 6, 63, x + 43, 81), fill="#6b4762", width=2)
        d.line((x - 45, 83, x - 45, 132), fill="#4e3a55", width=1)
        d.rectangle((x - 48, 130, x - 42, 135), fill="#44364d")
    for _ in range(330):
        x, y = rng.randrange(640), rng.randrange(203, 252)
        d.line((x, y, x + rng.randrange(3, 20), y), fill=rng.choice(["#469dac", "#f0ac7e", "#286b91", "#315576"]))
    # Perspective paving.
    d.rectangle((0, 257, 639, 359), fill="#4a4971")
    for y in [264, 277, 295, 324, 359]:
        d.line((0, y, 639, y), fill="#a5899b", width=2)
        d.line((0, y + 2, 639, y + 2), fill="#252c53", width=2)
    for x in range(-500, 1200, 90):
        d.line((320 + (x - 320) * 0.25, 256, x, 360), fill="#252c53", width=2)
    for _ in range(180):
        x, y = rng.randrange(640), rng.randrange(265, 355)
        d.line((x, y, x + 2, y), fill="#656084")
    # Teal pier balustrade.
    d.rectangle((0, 232, 639, 237), fill="#092f56")
    d.rectangle((0, 230, 639, 232), fill="#9ce7ce")
    d.rectangle((0, 235, 639, 239), fill="#1b8e9d")
    d.rectangle((0, 250, 639, 256), fill="#103556")
    d.line((0, 250, 640, 250), fill="#4cb8bd", width=2)
    for x in range(0, 640, 35):
        d.polygon([(x, 238), (x + 16, 247), (x + 32, 238)], outline="#67d2c8", width=2)
    for x in range(12, 640, 96):
        d.rectangle((x, 226, x + 9, 258), fill="#18567a")
        d.rectangle((x, 226, x + 3, 258), fill="#82ddcd")
        d.rectangle((x - 3, 224, x + 12, 228), fill="#b7f0da")
        d.polygon([(x - 4, 223), (x + 4, 216), (x + 13, 223)], fill="#40adba")
    # Left storefront, lanterns, readable sign.
    d.rectangle((0, 117, 100, 222), fill="#302d51")
    d.rectangle((0, 120, 96, 124), fill="#cb5b60")
    d.polygon([(0, 99), (84, 99), (112, 119), (0, 119)], fill="#17405d")
    for x in range(0, 105, 11):
        d.line((x, 102, x + 12, 117), fill="#47929e", width=3)
    d.rectangle((11, 139, 76, 189), fill="#ec9070")
    d.rectangle((14, 143, 73, 186), fill="#3e2749")
    for y in [147, 157, 167, 177]:
        d.line((16, y, 69, y), fill="#b55765", width=2)
    d.rectangle((21, 127, 80, 140), fill="#102c4d")
    font = ImageFont.truetype("/System/Library/Fonts/Menlo.ttc", 9)
    d.text((25, 128), "PIER 94", font=font, fill="#ffc57b")
    for x in [7, 86]:
        d.line((x, 123, x, 146), fill="#e9be87")
        d.ellipse((x - 6, 145, x + 6, 164), fill="#70293e")
        d.rectangle((x - 5, 149, x + 5, 159), fill="#f56653")
        d.line((x - 1, 148, x - 1, 160), fill="#ffd18a", width=2)
    # Spectators: explicit small original background figures.
    for x, skin, shirt in [(106, "#e6a57b", "#ebbb5c"), (522, "#ad7158", "#e06683"),
                           (544, "#efbc96", "#e4e4b0"), (570, "#c18a65", "#60b5af")]:
        d.rectangle((x - 3, 215, x, 240), fill="#28304c")
        d.rectangle((x + 2, 215, x + 5, 240), fill="#28304c")
        d.polygon([(x - 7, 202), (x + 6, 202), (x + 9, 220), (x - 7, 220)], fill=shirt)
        d.ellipse((x - 5, 190, x + 5, 204), fill=skin)
        d.polygon([(x - 6, 194), (x - 3, 188), (x + 6, 190), (x + 6, 195)], fill="#25243e")
        d.line((x - 6, 205, x - 12, 215), fill=skin, width=4)
    # Wind pennants.
    d.line((110, 128, 532, 117), fill="#dac594")
    for x in range(117, 530, 24):
        y = 128 - int((x - 110) / 38)
        d.polygon([(x, y), (x + 15, y), (x + 9, y + 15)], fill=rng.choice(["#ee8058", "#f3c375", "#48b3b6"]))
    im.save(ROOT / "harbor.png")


OUTLINE = "#17182f"


def fighter(character, pose, frame):
    im = Image.new("RGBA", (192, 192))
    d = ImageDraw.Draw(im)
    rhea = character == "rhea"
    skin = ["#a7573e", "#e09a67", "#ffd1a0"] if not rhea else ["#a86349", "#e9a16b", "#ffdaa7"]
    cloth = ["#24354c", "#49637a", "#84a1ac"] if not rhea else ["#4a264e", "#81527b", "#bd7895"]
    top = ["#a89e9d", "#e2dbc2", "#fff4d2"] if not rhea else ["#ab3d30", "#ee763b", "#ffbe62"]
    accent = "#e6434c" if not rhea else "#59d4d1"
    shift = (frame % 2) if pose in ["idle", "walk", "block"] else 0
    hip = (83, 111 + shift)
    shoulder = (82, 64 + shift)
    head = (85, 43 + shift)
    knees = [(64, 133), (99, 133)]
    feet = [(46, 166), (118, 166)]
    elbows = [(62, 81), (111, 79)]
    fists = [(71, 60), (124, 59)]
    if pose == "walk":
        stride = [-10, 0, 10, 0][frame % 4]
        feet = [(53 + stride, 166), (110 - stride, 166)]
        knees = [(65 + stride // 2, 134), (96 - stride // 2, 138)]
    if pose == "crouch" or pose == "low":
        hip = (83, 139); shoulder = (79, 101); head = (81, 79)
        knees = [(53, 147), (116, 149)]; feet = [(49, 168), (131, 168)]
        elbows = [(63, 119), (107, 114)]; fists = [(72, 97), (116, 93)]
        if pose == "low": elbows[1] = (117, 122); fists[1] = (159, 127)
    if pose == "jump":
        knees = [(55, 126), (115, 103)]; feet = [(76, 153), (103, 132)]
        elbows = [(55, 68), (110, 60)]; fists = [(52, 44), (111, 37)]
    if pose == "light":
        elbows[1] = [(113, 76), (125, 65), (114, 77)][frame % 3]
        fists[1] = [(125, 57), (164, 64), (130, 58)][frame % 3]
        shoulder = (87, 64); head = (89, 44)
    if pose == "heavy":
        shoulder = (71, 64); head = (73, 43)
        knees[1] = [(111, 112), (120, 96), (117, 114)][frame % 3]
        feet[1] = [(134, 120), (166, 79), (139, 123)][frame % 3]
        elbows = [(51, 78), (94, 82)]; fists = [(44, 60), (110, 65)]
    if pose in ["fire", "super"]:
        shoulder = (84, 67); head = (85, 44)
        elbows = [(110, 84), (113, 79)]
        fists = [(139, 79), (140, 67)] if frame else [(101, 104), (112, 99)]
        knees = [(65, 136), (111, 139)]; feet = [(40, 168), (134, 168)]
    if pose == "block":
        elbows = [(100, 82), (117, 79)]; fists = [(99, 39), (116, 44)]
        shoulder = (77, 67); head = (74, 43)
    if pose == "hurt":
        shoulder = (64, 70); head = (56, 45); elbows = [(40, 87), (102, 83)]
        fists = [(23, 77), (128, 78)]
    if pose == "win":
        elbows = [(56, 43), (110, 45)]; fists = [(57, 14), (111, 16)]
        feet = [(59, 167), (112, 167)]
    if pose == "ko":
        base = fighter(character, "hurt", 0).rotate(78, resample=Image.Resampling.NEAREST)
        crop = base.getbbox()
        base = base.crop(crop)
        if base.width > 187:
            base = base.resize((187, int(base.height * 187 / base.width)), Image.Resampling.NEAREST)
        im.alpha_composite(base, ((192 - base.width) // 2, 182 - base.height))
        return im

    def poly(points, fill, width=2):
        d.polygon(points, fill=fill)
        d.line(points + [points[0]], fill=OUTLINE, width=width)

    def limb(a, b, w1, w2, palette):
        dx, dy = b[0] - a[0], b[1] - a[1]
        length = max(1, math.hypot(dx, dy))
        nx, ny = -dy / length, dx / length
        points = [(int(a[0] + nx * w1), int(a[1] + ny * w1)),
                  (int(b[0] + nx * w2), int(b[1] + ny * w2)),
                  (int(b[0] - nx * w2), int(b[1] - ny * w2)),
                  (int(a[0] - nx * w1), int(a[1] - ny * w1))]
        poly(points, palette[1])
        d.polygon([points[0], points[1], b, a], fill=palette[0])
        d.line((a[0] - nx * w1 / 2, a[1] - ny * w1 / 2,
                b[0] - nx * w2 / 2, b[1] - ny * w2 / 2), fill=palette[2], width=3)
        d.line(points + [points[0]], fill=OUTLINE, width=2)

    for i in range(2):
        h = (hip[0] + (-11 if i == 0 else 11), hip[1])
        limb(h, knees[i], 13, 11, cloth)
        limb(knees[i], (feet[i][0], feet[i][1] - 8), 11, 8, cloth)
        x, y = feet[i]
        poly([(x - 9, y - 11), (x + 7, y - 11), (x + 9, y - 5),
              (x + 20, y - 3), (x + 20, y + 2), (x - 11, y + 2)], skin[1] if not rhea else top[1])
        d.line((x - 5, y - 7, x + 5, y - 5), fill=skin[2], width=2)
    sx, sy = shoulder; hx, hy = hip
    # Rear arm before chest, front arm after chest.
    limb((sx - 18, sy + 8), elbows[0], 10, 8, skin)
    limb(elbows[0], fists[0], 8, 7, skin)
    poly([(sx - 21, sy), (sx - 7, sy - 7), (sx + 16, sy - 3),
          (sx + 26, sy + 14), (hx + 17, hy - 3), (hx - 19, hy - 2),
          (sx - 25, sy + 18)], top[1])
    d.polygon([(sx - 21, sy + 6), (sx - 10, sy + 18), (hx - 7, hy - 3),
               (hx - 18, hy - 2), (sx - 25, sy + 18)], fill=top[0])
    d.polygon([(sx + 6, sy + 6), (sx + 19, sy + 12), (hx + 10, hy - 9),
               (sx - 1, sy + 27)], fill=top[2])
    # Gi lapels / kickboxing singlet and muscle planes.
    poly([(sx - 9, sy - 5), (sx + 13, sy - 3), (sx + 7, sy + 20), (sx - 2, sy + 29)], skin[1], 1)
    d.line((sx - 11, sy - 5, sx + 2, sy + 31, hx - 5, hy - 7), fill=top[0], width=4)
    d.line((sx + 15, sy - 1, sx + 4, sy + 30), fill=top[2], width=3)
    d.line((sx - 4, sy + 8, sx + 9, sy + 9), fill=skin[0], width=2)
    poly([(hx - 20, hy - 7), (hx + 19, hy - 8), (hx + 20, hy), (hx - 21, hy + 2)], accent)
    poly([(hx + 1, hy), (hx + 10, hy), (hx + 20 + frame * 2, hy + 22),
          (hx + 11, hy + 26)], accent)
    # Neck and expressive pixel face.
    x, y = head
    poly([(x - 8, y + 12), (x + 9, y + 12), (x + 10, y + 23), (x - 8, y + 24)], skin[0])
    if rhea:
        poly([(x - 8, y - 10), (x - 21, y - 18), (x - 35, y - 8),
              (x - 27, y + 4), (x - 16, y - 2)], "#f3c76a")
    poly([(x - 14, y - 9), (x + 8, y - 14), (x + 17, y - 5),
          (x + 17, y + 3), (x + 23, y + 8), (x + 17, y + 11),
          (x + 15, y + 20), (x + 3, y + 23), (x - 8, y + 14)], skin[1])
    d.polygon([(x + 2, y - 3), (x + 14, y - 2), (x + 15, y + 11),
               (x + 7, y + 18), (x + 1, y + 12)], fill=skin[2])
    hair = "#ebbb61" if rhea else "#242437"
    poly([(x - 15, y + 5), (x - 17, y - 10), (x - 10, y - 17), (x - 2, y - 19),
          (x + 2, y - 23), (x + 6, y - 17), (x + 16, y - 14), (x + 18, y - 6),
          (x + 3, y - 7), (x - 2, y + 2), (x - 6, y - 1), (x - 8, y + 9)], hair)
    d.line((x - 10, y - 12, x + 3, y - 16, x + 12, y - 10), fill="#ffe498" if rhea else "#555467", width=3)
    d.line((x + 5, y + 3, x + 14, y + 1), fill=OUTLINE, width=2)
    d.rectangle((x + 10, y + 4, x + 14, y + 6), fill="#fff6db")
    d.rectangle((x + 13, y + 4, x + 14, y + 6), fill=OUTLINE)
    d.line((x + 8, y + 16, x + 16, y + 15), fill=OUTLINE, width=2)
    if not rhea:
        d.line((x - 14, y - 3, x + 16, y - 5), fill=accent, width=4)
        poly([(x - 13, y - 2), (x - 29, y + 4), (x - 36 - frame * 2, y - 1),
              (x - 25, y + 10), (x - 13, y + 2)], accent, 1)
    limb((sx + 19, sy + 10), elbows[1], 11, 9, skin)
    limb(elbows[1], fists[1], 9, 7, skin)
    for x, y in fists:
        poly([(x - 8, y - 7), (x + 5, y - 9), (x + 10, y - 4),
              (x + 10, y + 4), (x + 4, y + 8), (x - 8, y + 6)], accent)
        d.line((x - 6, y - 4, x + 5, y - 5), fill="#ffc2a0", width=2)
        d.line((x + 3, y, x + 9, y), fill="#722c46", width=2)
    return im


def title():
    font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Impact.ttf", 92)
    im = Image.new("RGBA", (590, 205))
    for text, y, x in [("METRO", -3, 57), ("IMPACT", 80, 20)]:
        layer = Image.new("RGBA", im.size)
        ld = ImageDraw.Draw(layer)
        ld.text((x + 7, y + 9), text, font=font, fill="#9e2849", stroke_width=5, stroke_fill="#172039")
        ld.text((x, y), text, font=font, fill="#ffb42d", stroke_width=3, stroke_fill="#411f39")
        ld.text((x, y - 2), text, font=font, fill="#ffd65c")
        im.alpha_composite(layer)
    im = im.transform(im.size, Image.Transform.AFFINE, (1, 0.18, -25, 0, 1, 0), resample=Image.Resampling.NEAREST)
    d = ImageDraw.Draw(im)
    for i in range(14):
        x, y = rng.randrange(42, 480), rng.randrange(45, 190)
        d.line((x, y, x + rng.randrange(10, 46), y - 3), fill="#ec7f2b", width=2)
    im.save(ROOT / "title.png")


stage()
title()
for c in ["kai", "rhea"]:
    for pose, count in {"idle": 2, "walk": 4, "jump": 2, "crouch": 2, "low": 3,
                        "block": 2, "light": 3, "heavy": 3, "fire": 3, "super": 3,
                        "hurt": 2, "ko": 1, "win": 2}.items():
        for f in range(count):
            fighter(c, pose, f).save(ROOT / f"{c}_{pose}_{f}.png")
    portrait = fighter(c, "idle", 0).crop((37, 17, 124, 104)).resize((174, 174), Image.Resampling.NEAREST)
    portrait.save(ROOT / f"{c}_portrait.png")
print("Authored harbor, lettering, portraits, and 64 original animation frames.")
