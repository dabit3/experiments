# Skybound art direction

Original sculpted toy-fantasy art for Tower Tussle. Moonstone towers, champagne
gold, lagoon enamel, emerald turf, midnight UI, and coral opponents form one
visual language across both native clients. No external models, textures,
fonts, reference screenshots, or third-party game assets are used.

## Reproduce

Use Blender **4.5.3 LTS**, Python **3.9+**, and Pillow **11.3.0**:

```sh
python3 -m venv .venv
.venv/bin/pip install Pillow==11.3.0
blender --background --threads 8 --python render_art.py
.venv/bin/python package_art.py
```

Run these from this directory. Blender can also render `-- --part hero`,
`arena`, `portraits`, `units`, `towers`, or `emblem`. Existing character renders
are retained; remove the affected PNG intermediates before changing a model.
All meshes, materials, lighting, camera positions, and animation poses are
defined in `render_art.py`; intermediates are ignored by Git.

`package_art.py` grades the renders, creates illustrated card backgrounds,
packs atlases, creates matching app icons, and synthesizes four short sound
cues. It writes directly to each native resource directory. Runtime builds do
not need Blender or Python. `assets.json` records dimensions and SHA-256 hashes;
the packager checks that every PNG is nonempty and identical across platforms.

Each troop atlas has six 256 × 256 frames per team: four walk poses and two
attack poses. Player frames occupy row 0, enemy frames row 1. The clients cache
the atlas/frames and composite them with team rings, shadows, hit flashes,
flight motion, projectiles, health bars, and particles. Arena art maps exactly
to the 18 × 32 board, with bridges at x = 3.5 and 14.5.

Python source validation:

```sh
ruff check --select E9,F63,F7,F82 render_art.py package_art.py
```
