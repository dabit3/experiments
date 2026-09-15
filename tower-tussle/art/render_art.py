"""Original Tower Tussle models. Run with Blender 4.5 LTS in background mode."""

import argparse
import math
from pathlib import Path
import random
import sys

import bpy
from mathutils import Vector


ROOT = Path(__file__).resolve().parent
OUT = ROOT / "renders"
TAU = math.tau
ROSTER = ("knight", "archers", "giant", "duelist", "sharpshooter", "gremlins", "bones", "whelp")


def material(name, color, metal=0.0, rough=0.32, glow=0.0):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1)
    mat.use_nodes = True
    shader = mat.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = (*color, 1)
    shader.inputs["Metallic"].default_value = metal
    shader.inputs["Roughness"].default_value = rough
    shader.inputs["Coat Weight"].default_value = 0.24
    if glow:
        shader.inputs["Emission Color"].default_value = (*color, 1)
        shader.inputs["Emission Strength"].default_value = glow
    return mat


def palette():
    return {
        "navy": material("Midnight enamel", (0.035, 0.065, 0.14), 0.5),
        "steel": material("Pearl armor", (0.60, 0.77, 0.87), 0.65),
        "ivory": material("Warm ivory", (0.88, 0.81, 0.62)),
        "gold": material("Champagne gold", (0.95, 0.52, 0.10), 0.72, 0.26),
        "blue": material("Lagoon enamel", (0.02, 0.40, 0.75), 0.35),
        "red": material("Coral enamel", (0.75, 0.065, 0.11), 0.35),
        "cyan": material("Aether", (0.05, 0.78, 1.0), 0.25, glow=1.8),
        "purple": material("Amethyst", (0.31, 0.08, 0.56), 0.25),
        "pink": material("Orchid", (0.72, 0.20, 0.55), 0.25),
        "skin": material("Peach", (0.80, 0.42, 0.22)),
        "hair": material("Amber hair", (0.95, 0.48, 0.10), 0.1),
        "green": material("Jade", (0.08, 0.48, 0.24), 0.12),
        "lime": material("Mint", (0.30, 0.78, 0.39)),
        "wood": material("Walnut", (0.21, 0.095, 0.045)),
        "stone": material("Moonstone", (0.38, 0.48, 0.55), 0.15),
        "grass": material("Emerald turf", (0.13, 0.32, 0.20)),
        "water": material("Turquoise water", (0.01, 0.28, 0.40), 0.55, 0.2),
        "fire": material("Sunfire", (1.0, 0.21, 0.025), 0.2, glow=2.5),
        "white": material("Eyes", (0.95, 0.98, 1.0), 0.0, 0.2),
    }


M = {}


def finish(obj, mat, bevel=0.0, smooth=True):
    obj.data.materials.append(M[mat])
    if bevel:
        modifier = obj.modifiers.new("Soft machined edges", "BEVEL")
        modifier.width = bevel
        modifier.segments = 3
        obj.modifiers.new("Corner normals", "WEIGHTED_NORMAL")
    if smooth:
        for poly in obj.data.polygons:
            poly.use_smooth = True
    return obj


def ball(pos, size, mat):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=16, location=pos)
    obj = bpy.context.object
    obj.scale = size if isinstance(size, tuple) else (size, size, size)
    return finish(obj, mat)


def box(pos, size, mat, bevel=0.06):
    bpy.ops.mesh.primitive_cube_add(size=1, location=pos)
    obj = bpy.context.object
    obj.scale = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish(obj, mat, bevel, False)


def cone(pos, radius, top, depth, mat, vertices=32):
    bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=radius, radius2=top, depth=depth, location=pos)
    return finish(bpy.context.object, mat, 0.035)


def link(start, end, radius, mat, top=None):
    a, b = Vector(start), Vector(end)
    obj = cone((a + b) / 2, radius, radius if top is None else top, (b - a).length, mat, 16)
    obj.rotation_euler = (b - a).to_track_quat("Z", "Y").to_euler()
    return obj


def ring(pos, radius, thickness, mat, rotation=(0, 0, 0)):
    bpy.ops.mesh.primitive_torus_add(major_radius=radius, minor_radius=thickness, major_segments=40, minor_segments=10, location=pos, rotation=rotation)
    return finish(bpy.context.object, mat)


def facet(points, mat):
    mesh = bpy.data.meshes.new("Sculpted panel")
    mesh.from_pydata(points, [], [tuple(range(len(points)))])
    mesh.update()
    obj = bpy.data.objects.new("Sculpted panel", mesh)
    bpy.context.collection.objects.link(obj)
    return finish(obj, mat, smooth=False)


def eye(x, y, z, radius=0.095):
    ball((x, y, z), (radius, radius * 0.48, radius * 1.18), "white")
    ball((x + 0.018, y - radius * 0.40, z), (radius * 0.53, radius * 0.25, radius * 0.74), "navy")
    ball((x + 0.033, y - radius * 0.58, z + 0.025), radius * 0.19, "white")


def sword(start, end, heavy=False):
    a, b = Vector(start), Vector(end)
    delta = b - a
    link(a - delta * 0.2, a, 0.07, "wood")
    ball(a - delta * 0.22, 0.09, "gold")
    link(a + Vector((-0.25, 0, 0)), a + Vector((0.25, 0, 0)), 0.06, "gold")
    obj = box(a + delta * 0.48, (0.20 if heavy else 0.13, 0.07, delta.length * 0.90), "steel", 0.025)
    obj.rotation_euler = delta.to_track_quat("Z", "Y").to_euler()
    link(a + delta * 0.92, b, 0.09, "steel", 0.0)


def humanoid(card, phase=0.0, attack=0.0):
    robot = card in ("knight", "duelist")
    bone = card == "bones"
    gremlin = card == "gremlins"
    giant = card == "giant"
    armor = "stone" if giant else ("navy" if card == "duelist" else "steel")
    skin = "ivory" if bone else ("lime" if gremlin else "skin")
    suit = "purple" if card in ("archers", "duelist") else "blue"
    width = 0.55 if giant else (0.29 if bone else 0.38)
    bob = math.sin(phase * 2) * 0.035
    for sign in (-1, 1):
        step = math.sin(phase) * 0.20 * sign
        hip = (sign * width * 0.52, 0, 0.83 + bob)
        ankle = (sign * width * 0.65, step, 0.22)
        link(hip, ankle, 0.11 if bone else 0.15, "ivory" if bone else suit)
        box((ankle[0], ankle[1] - 0.09, 0.15), (0.20 if bone else 0.29, 0.42, 0.28), "ivory" if bone else "navy")
        if not bone:
            ball((ankle[0], step * 0.5 - 0.13, 0.51), (0.16, 0.12, 0.15), armor)
    ball((0, 0, 1.03 + bob), (width, 0.25, 0.42), "ivory" if bone else suit)
    if giant or robot:
        box((0, -0.18, 1.15 + bob), (width * 1.65, 0.26, 0.49), armor, 0.12)
        gem = cone((0, -0.35, 1.22 + bob), 0.12, 0, 0.13, "cyan", 6)
        gem.rotation_euler.x = math.pi / 2
    elif bone:
        for z in (0.91, 1.06, 1.21):
            rib = ring((0, 0, z), 0.24, 0.037, "ivory")
            rib.scale.y = 0.7
    else:
        cone((0, 0, 0.89), width * 1.14, width * 0.80, 0.30, suit)
        box((0, -0.255, 0.96), (0.18, 0.08, 0.14), "gold", 0.03)
    head = 1.79 + bob
    ball((0, 0, head), (0.48 if giant else 0.40, 0.34, 0.43), armor if robot or giant else skin)
    if robot:
        box((0, -0.30, head), (0.65, 0.12, 0.23), "navy", 0.09)
        for x in (-0.16, 0.16):
            box((x, -0.37, head + 0.02), (0.19, 0.04, 0.055), "cyan", 0.02)
        ring((0, 0, head - 0.23), 0.35, 0.05, "gold")
        if card == "knight":
            for i in range(5):
                ball((0, i * 0.11 - 0.19, head + 0.43 + math.sin(i / 4 * math.pi) * 0.10), (0.105, 0.12, 0.14), "blue")
        else:
            for sign in (-1, 1):
                link((sign * 0.29, 0, head + 0.27), (sign * 0.48, 0.02, head + 0.70), 0.13, "gold", 0.01)
    else:
        for x in (-0.16, 0.16):
            if bone:
                ball((x, -0.31, head + 0.04), (0.13, 0.09, 0.145), "navy")
                ball((x, -0.385, head + 0.04), 0.05, "cyan")
            else:
                eye(x, -0.305, head + 0.035, 0.10 if not giant else 0.12)
                brow = box((x, -0.33, head + 0.18), (0.22, 0.075, 0.055), "wood" if not giant else "stone", 0.025)
                brow.rotation_euler.y = x * -0.6
        ball((0, -0.36, head - 0.08), (0.12, 0.12, 0.09), skin if not giant else "stone")
        box((0, -0.305, head - 0.22), (0.28, 0.09, 0.06), "navy", 0.025)
        for x in (-0.085, 0, 0.085):
            box((x, -0.365, head - 0.21), (0.062, 0.035, 0.08), "ivory", 0.018)
        if gremlin:
            for sign in (-1, 1):
                link((sign * 0.32, 0, head + 0.12), (sign * 0.80, 0, head + 0.45), 0.18, "lime", 0.01)
                ball((sign * 0.30, -0.23, head - 0.10), (0.10, 0.055, 0.085), "green")
        if card in ("archers", "sharpshooter"):
            for i in range(7):
                a = i / 6 * math.pi
                ball((math.cos(a) * 0.32, 0.04, head + math.sin(a) * 0.35), (0.17, 0.32, 0.18), "hair")
            if card == "archers":
                ball((-0.28, 0.20, 1.49), (0.17, 0.22, 0.42), "hair")
                cone((0, 0.04, head + 0.36), 0.43, 0.12, 0.26, "purple")
            else:
                box((0, -0.03, head + 0.39), (0.83, 0.70, 0.11), "wood")
                cone((0, 0.02, head + 0.52), 0.34, 0.29, 0.23, "blue")
                for x in (-0.16, 0.16):
                    ring((x, -0.31, head + 0.39), 0.10, 0.034, "gold", (math.pi / 2, 0, 0))
    for sign in (-1, 1):
        shoulder = (sign * (width + 0.09), 0, 1.35 + bob)
        hand = (sign * (width + 0.19), -0.17 - attack * 0.26, 0.94 + attack * 0.32)
        link(shoulder, hand, 0.08 if bone else 0.135, skin if bone or gremlin else suit)
        if not bone:
            ball(shoulder, (0.25 if giant else 0.19, 0.23, 0.20), armor if robot or giant else suit)
        ball(hand, 0.20 if giant else 0.12, armor if giant or robot else skin)
        if sign == 1 and card in ("knight", "duelist", "bones", "gremlins"):
            sword(hand, (hand[0] + 0.15 + attack * 0.65, hand[1] - attack * 0.3, hand[2] + 0.95 - attack * 0.4), card == "duelist")
    if card == "knight":
        box((-0.65, -0.30, 1.02), (0.56, 0.14, 0.72), "gold", 0.14)
        box((-0.65, -0.385, 1.03), (0.45, 0.08, 0.60), "blue", 0.11)
        ball((-0.65, -0.445, 1.04), (0.10, 0.035, 0.14), "cyan")
    if card == "archers":
        points = [(0.70 + 0.24 * math.sin(i / 12 * math.pi), -0.40, 0.55 + i / 12 * 1.3) for i in range(13)]
        for a, b in zip(points, points[1:]):
            link(a, b, 0.05, "gold")
        link(points[0], points[-1], 0.012, "ivory")
        link((0.42, -0.4, 1.13), (1.10, -0.4, 1.13), 0.023, "wood")
    if card == "sharpshooter":
        link((0.27, -0.32, 1.15), (0.96, -0.57, 1.26), 0.13, "wood")
        link((0.8, -0.51, 1.24), (1.45, -0.72, 1.34), 0.085, "gold")
        link((0.5, -0.32, 1.36), (0.85, -0.46, 1.43), 0.10, "navy")
    if giant:
        for x in (-0.49, 0.49):
            cone((x, 0, 1.67), 0.13, 0, 0.40, "cyan", 5)


def dragon(phase=0.0, attack=0.0):
    ball((0, 0.12, 0.95), (0.42, 0.39, 0.59), "green")
    ball((0, -0.20, 0.94), (0.30, 0.18, 0.45), "lime")
    ball((0, -0.18, 1.65), (0.49, 0.40, 0.43), "green")
    ball((0, -0.49, 1.44), (0.39, 0.32, 0.23), "lime")
    for sign in (-1, 1):
        eye(sign * 0.23, -0.49, 1.72, 0.14)
        ball((sign * 0.17, -0.77, 1.51), (0.048, 0.025, 0.04), "navy")
        link((sign * 0.32, 0, 1.92), (sign * 0.46, 0.10, 2.27), 0.12, "ivory", 0)
        ball((sign * 0.31, -0.05, 0.44), (0.19, 0.23, 0.19), "green")
        for i in range(3):
            cone((sign * 0.31 + (i - 1) * 0.08, -0.22, 0.41), 0.045, 0, 0.17, "ivory")
        tip = (sign * 1.25, 0.12, 1.60 + math.sin(phase) * 0.42)
        root = (sign * 0.28, 0.25, 1.16)
        elbow = (sign * 0.72, 0.10, 1.94)
        lower = (sign * 0.82, 0.34, 0.95)
        facet([root, elbow, tip, lower], "purple")
        for point in (elbow, tip, lower):
            link(root, point, 0.055, "green")
        link(elbow, tip, 0.055, "green")
    for i in range(6):
        ball((0, 0.37 + i * 0.13, 0.75 - i * 0.055), 0.18 - i * 0.02, "green")
        cone((0, 0.30 + i * 0.14, 1.16 - i * 0.10), 0.09, 0, 0.22, "gold", 5)
    if attack:
        ball((0, -0.82, 1.40), 0.16 + attack * 0.06, "fire")


def character(card, phase=0.0, attack=0.0):
    if card == "whelp":
        dragon(phase, attack)
    else:
        humanoid(card, phase, attack)


def tower(kind="keep", team="blue"):
    keep = kind == "keep"
    radius = 0.9 if keep else 0.70
    cone((0, 0, 0.13), radius * 1.18, radius * 1.18, 0.26, "navy", 8)
    cone((0, 0, 0.28), radius * 1.12, radius * 1.12, 0.13, "gold", 8)
    cone((0, 0, 0.85), radius, radius * 0.85, 1.12, "ivory", 8)
    for z in (0.47, 0.79, 1.11):
        ring((0, 0, z), radius * (1 - (z - 0.3) * 0.12), 0.025, "stone")
    for a in range(0, 360, 90):
        angle = math.radians(a)
        x, y = math.sin(angle) * radius * 0.72, math.cos(angle) * radius * 0.72
        box((x, y, 0.96), (0.22, 0.22, 1.14), "stone", 0.065)
        cone((x, y, 1.62), 0.18, 0.0, 0.35, team, 8)
    box((0, -radius * 0.94, 0.85), (0.46, 0.12, 0.68), "gold", 0.17)
    box((0, -radius * 1.01, 0.85), (0.31, 0.055, 0.52), "navy", 0.13)
    box((0, -radius * 1.05, 0.91), (0.055, 0.025, 0.35), "cyan", 0.01)
    cone((0, 0, 1.40), radius * 1.07, radius * 1.07, 0.18, "gold", 8)
    if keep:
        cone((0, 0, 1.87), radius, radius * 0.18, 0.82, team, 8)
        for i in range(8):
            a = i / 8 * TAU
            link((math.sin(a) * radius, math.cos(a) * radius, 1.5), (math.sin(a) * 0.16, math.cos(a) * 0.16, 2.28), 0.025, "gold")
        cone((0, 0, 2.38), 0.25, 0.31, 0.20, "gold", 8)
        for i in range(5):
            a = i / 5 * TAU
            cone((math.sin(a) * 0.26, math.cos(a) * 0.26, 2.55), 0.085, 0.025, 0.23, "gold", 5)
        ball((0, 0, 2.61), 0.13, "cyan")
    else:
        cone((0, 0, 1.59), radius * 0.92, radius * 0.92, 0.25, team, 8)
        for i in range(8):
            a = i / 8 * TAU
            box((math.sin(a) * radius * 0.8, math.cos(a) * radius * 0.8, 1.84), (0.22, 0.22, 0.32), "ivory")
        link((0, -0.10, 1.78), (0, -0.96, 1.78), 0.17, "navy")
        ring((0, -0.92, 1.78), 0.17, 0.042, "gold", (math.pi / 2, 0, 0))
    link((radius * 0.65, 0.1, 1.5), (radius * 0.65, 0.1, 2.75), 0.025, "gold")
    x = radius * 0.65
    facet([(x, 0.1, 2.67), (x + 0.65, 0.13, 2.63), (x + 0.52, 0.16, 2.35), (x, 0.1, 2.36)], team)


def group_at(builder, pos, scale=1.0, rotation=0.0):
    before = set(bpy.context.scene.objects)
    builder()
    objects = set(bpy.context.scene.objects) - before
    bpy.ops.object.empty_add(location=pos)
    parent = bpy.context.object
    for obj in objects:
        obj.parent = parent
    parent.scale = (scale,) * 3
    parent.rotation_euler.z = rotation


def tree(pos, scale=1.0):
    def build():
        cone((0, 0, 0.25), 0.12, 0.08, 0.5, "wood")
        for z, r in ((0.5, 0.48), (0.79, 0.39), (1.05, 0.28)):
            cone((0, 0, z), r, 0.05, 0.56, "green", 8)
    group_at(build, pos, scale)


def set_camera(pos, target, ortho):
    bpy.ops.object.camera_add(location=pos)
    cam = bpy.context.object
    cam.rotation_euler = (Vector(target) - cam.location).to_track_quat("-Z", "Y").to_euler()
    cam.data.type = "ORTHO"
    cam.data.ortho_scale = ortho
    bpy.context.scene.camera = cam


def area(pos, color, power, size, target=(0, 0, 0.8)):
    bpy.ops.object.light_add(type="AREA", location=pos)
    obj = bpy.context.object
    obj.data.energy = power
    obj.data.color = color
    obj.data.shape = "DISK"
    obj.data.size = size
    obj.rotation_euler = (Vector(target) - obj.location).to_track_quat("-Z", "Y").to_euler()


def reset():
    global M
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for data in (bpy.data.meshes, bpy.data.materials):
        for item in list(data):
            if item.users == 0:
                data.remove(item)
    M = palette()
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 24
    scene.cycles.use_denoising = True
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.view_settings.view_transform = "AgX"
    scene.world.use_nodes = True
    scene.world.node_tree.nodes.get("Background").inputs[0].default_value = (0.36, 0.48, 0.65, 1)
    scene.world.node_tree.nodes.get("Background").inputs[1].default_value = 0.5
    area((-3, -4, 7), (1, 0.85, 0.66), 700, 5)
    area((4, 2, 5), (0.33, 0.69, 1), 950, 4)
    area((-4, 3, 3), (0.78, 0.38, 1), 600, 3)


def render(name, width, height, samples=24):
    scene = bpy.context.scene
    scene.render.resolution_x = width
    scene.render.resolution_y = height
    scene.render.resolution_percentage = 100
    scene.cycles.samples = samples
    scene.render.filepath = str(OUT / f"{name}.png")
    bpy.ops.render.render(write_still=True)
    print(f"ART_COMPLETE {name}", flush=True)


def units(only=None):
    for card in ROSTER:
        if only and card != only:
            continue
        for team in ("blue", "red"):
            for frame in range(6):
                name = f"unit_{card}_{frame}" + ("_red" if team == "red" else "")
                if (OUT / f"{name}.png").exists():
                    continue
                reset()
                if team == "red":
                    M["blue"] = M["red"]
                    M["purple"] = M["red"]
                character(card, frame / 4 * TAU if frame < 4 else 0, (frame - 3) / 2 if frame >= 4 else 0)
                set_camera((4, -8, 5.2), (0, 0, 1.15), 3.25)
                render(name, 256, 256, 16)


def portraits():
    for i, card in enumerate((*ROSTER, "meteor", "volley")):
        if (OUT / f"card_{card}.png").exists():
            continue
        reset()
        if card in ROSTER:
            character(card, 0.65, 0.3)
        elif card == "meteor":
            ball((0, 0, 1.2), 0.67, "navy")
            rng = random.Random(4)
            for j in range(18):
                a = rng.random() * TAU
                ball((math.sin(a) * 0.60, math.cos(a) * 0.60, 1.2 + rng.uniform(-0.4, 0.4)), rng.uniform(0.06, 0.14), "fire")
            for j in range(7):
                link((0.20, 0.25, 1.5), (0.3 + j * 0.05, 0.3 + j * 0.09, 2.3 + j * 0.05), 0.19 - j * 0.02, "fire", 0)
        else:
            for j in range(5):
                x = (j - 2) * 0.28
                link((x, 0, 0.55 + abs(j - 2) * 0.12), (x + 0.42, 0, 2.35), 0.035, "gold")
                cone((x, 0, 0.50 + abs(j - 2) * 0.12), 0.12, 0, 0.30, "steel", 4).rotation_euler.y = math.pi
                box((x + 0.38, 0, 2.19), (0.23, 0.04, 0.24), "purple", 0.03)
        cone((0, 0, 0.015), 1.0, 1.0, 0.10, "navy", 64)
        ring((0, 0, 0.08), 0.91, 0.025, "gold")
        set_camera((3.6, -8, 4.0), (0.04, 0, 1.20), 2.90)
        render(f"card_{card}", 448, 560, 32)


def towers():
    for kind in ("keep", "guard"):
        for team in ("blue", "red"):
            name = f"tower_{kind}_{team}"
            if (OUT / f"{name}.png").exists():
                continue
            reset()
            tower(kind, team)
            set_camera((3, -7, 5), (0, 0, 1.22), 3.6)
            render(name, 448, 448, 32)


def arena():
    reset()
    rng = random.Random(71)
    box((0, 0, -0.40), (18, 32, 0.8), "navy", 0.20)
    box((0, 0, -0.03), (17.8, 31.8, 0.22), "grass", 0.15)
    for i in range(7):
        mat = material(f"Turf {i}", (0.08, 0.24, 0.08), rough=0.95)
        nodes = mat.node_tree.nodes
        shader = nodes.get("Principled BSDF")
        shader.inputs["Coat Weight"].default_value = 0
        noise = nodes.new("ShaderNodeTexNoise")
        noise.inputs["Scale"].default_value = 70
        ramp = nodes.new("ShaderNodeValToRGB")
        ramp.color_ramp.elements[0].color = (0.035 + i * 0.002, 0.14 + i * 0.006, 0.045, 1)
        ramp.color_ramp.elements[1].color = (0.15 + i * 0.003, 0.31 + i * 0.007, 0.11, 1)
        mat.node_tree.links.new(noise.outputs["Fac"], ramp.inputs["Fac"])
        mat.node_tree.links.new(ramp.outputs["Color"], shader.inputs["Base Color"])
        bump = nodes.new("ShaderNodeBump")
        bump.inputs["Strength"].default_value = 0.25
        bump.inputs["Distance"].default_value = 0.045
        mat.node_tree.links.new(noise.outputs["Fac"], bump.inputs["Height"])
        mat.node_tree.links.new(bump.outputs["Normal"], shader.inputs["Normal"])
        M[f"turf{i}"] = mat
    for x in range(-8, 9):
        for y in range(-15, 16):
            if abs(y) < 2:
                continue
            box((x, y, 0.095), (1.015, 1.015, 0.08), f"turf{(x // 2 + y // 2) % 2 * 3 + rng.randrange(2)}", 0.005)
    box((0, 0, 0.10), (18, 2.08, 0.14), "water", 0.08)
    for side in (-1, 1):
        for x in range(-9, 9):
            box((x + 0.5, side * 1.15, 0.21), (0.95, 0.31, 0.28), "stone", 0.08)
        for x in (-5.5, 5.5):
            for y in range(2, 15):
                box((x, side * y, 0.18), (1.45, 0.90, 0.15), "stone", 0.12)
                if y % 3 == 0:
                    box((x, side * y, 0.265), (0.22, 0.33, 0.025), "gold", 0.02)
    for x in (-5.5, 5.5):
        for j in range(9):
            box((x, -1.45 + j * 0.36, 0.35), (2.0, 0.32, 0.26), "wood", 0.05)
        for sign in (-1, 1):
            link((x + sign * 1.0, -1.6, 0.69), (x + sign * 1.0, 1.6, 0.69), 0.07, "gold")
            for y in (-1.5, 1.5):
                box((x + sign * 1.0, y, 0.48), (0.22, 0.25, 0.80), "navy")
                ball((x + sign * 1.0, y, 0.94), 0.13, "cyan")
    for side in (-1, 1):
        for y in range(-15, 16):
            box((side * 8.67, y, 0.36), (0.45, 0.95, 0.72), "stone")
            if y % 3 == 0:
                box((side * 8.67, y, 0.78), (0.52, 0.44, 0.30), "ivory")
        for x in range(-8, 9):
            box((x, side * 15.65, 0.35), (0.95, 0.5, 0.70), "stone")
        for y in (side * 4, side * 8, side * 12, side * 14.7):
            for x in (-7.8, 7.8):
                tree((x, y, 0.18), rng.uniform(0.60, 0.85))
        for y in (side * 5, side * 11):
            ring((0, y, 0.16), 1.15, 0.035, "gold")
            for j in range(4):
                a = j / 4 * TAU
                cone((math.sin(a) * 0.60, y + math.cos(a) * 0.60, 0.19), 0.12, 0, 0.11, "gold", 4)
    for i in range(75):
        x, y = rng.uniform(-7.6, 7.6), rng.uniform(-14.7, 14.7)
        if abs(y) < 2 or abs(abs(x) - 5.5) < 1.1:
            continue
        ball((x, y, 0.18), (0.07, 0.07, 0.06), "lime" if i % 4 else "ivory")
    for obj in list(bpy.context.scene.objects):
        if obj.type == "LIGHT":
            bpy.data.objects.remove(obj, do_unlink=True)
    area((-12, -10, 25), (1.0, 0.89, 0.73), 5500, 12)
    area((12, 10, 18), (0.32, 0.68, 1.0), 4000, 10)
    set_camera((0, 0, 45), (0, 0, 0), 32)
    render("arena", 900, 1600, 32)


def hero():
    reset()
    cone((0, 0, -0.30), 2.55, 3.25, 0.60, "navy", 12)
    cone((0, 0, -0.06), 3.22, 3.22, 0.12, "gold", 12)
    cone((0, 0, 0.035), 3.12, 3.12, 0.11, "grass", 12)
    for i in range(12):
        a = i / 12 * TAU
        cone((math.sin(a) * 2.55, math.cos(a) * 2.55, -0.64), 0.05, 0.46, 0.72, "stone", 5)
    group_at(lambda: tower("keep"), (0, 0.66, 0.10), 1.18)
    group_at(lambda: tower("guard"), (-1.72, 0, 0.10), 0.77)
    group_at(lambda: tower("guard"), (1.72, 0, 0.10), 0.77)
    group_at(lambda: character("knight", 0.5, 0.3), (-0.67, -1.47, 0.12), 0.64, -0.18)
    group_at(lambda: character("archers", 0.7), (0.79, -1.45, 0.12), 0.58, 0.2)
    group_at(lambda: dragon(1.1), (1.90, 0.90, 2.10), 0.65, -0.5)
    for x, y in ((-2, 1.2), (2, 1.4), (-2.3, -1), (2.2, -1.1)):
        tree((x, y, 0.1), 0.72)
    for x in (-0.35, 0.35):
        for y in (-0.5, -0.9, -1.3, -1.7, -2.1, -2.5):
            box((x, y, 0.13), (0.57, 0.33, 0.09), "ivory")
    ring((0, 0, -0.8), 2.0, 0.06, "cyan")
    ring((0, 0, -1.04), 1.38, 0.035, "gold")
    set_camera((5, -10, 7), (0, 0, 0.8), 7.8)
    render("hero", 1200, 1100, 48)


def emblem():
    reset()
    cone((0, 0, 0.12), 0.8, 0.8, 0.24, "navy", 8)
    cone((0, 0, 0.26), 0.75, 0.75, 0.08, "gold", 8)
    cone((0, 0, 0.48), 0.38, 0.24, 0.4, "gold")
    cone((0, 0, 0.77), 0.26, 0.65, 0.25, "gold")
    cone((0, 0, 1.08), 0.58, 0.72, 0.40, "gold", 10)
    ring((0, 0, 1.23), 0.67, 0.07, "gold")
    for i in range(5):
        a = i / 5 * TAU
        link((math.sin(a) * 0.60, math.cos(a) * 0.60, 1.14), (math.sin(a) * 0.79, math.cos(a) * 0.79, 1.75), 0.15, "gold", 0.06)
        ball((math.sin(a) * 0.79, math.cos(a) * 0.79, 1.76), 0.105, "gold")
    ball((0, -0.60, 1.20), (0.15, 0.09, 0.19), "cyan")
    set_camera((3, -7, 4.2), (0, 0, 1.0), 2.8)
    render("emblem", 512, 512, 48)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--part", choices=("all", "units", "portraits", "towers", "arena", "hero", "emblem"), default="all")
    parser.add_argument("--only")
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [])
    OUT.mkdir(parents=True, exist_ok=True)
    actions = {"units": lambda: units(args.only), "portraits": portraits, "towers": towers, "arena": arena, "hero": hero, "emblem": emblem}
    if args.part == "all":
        for action in actions.values():
            action()
    else:
        actions[args.part]()


if __name__ == "__main__":
    main()
