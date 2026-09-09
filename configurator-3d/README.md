# 3D Sneaker Configurator (Three.js)

A Three.js product configurator for a stylised sneaker that is built entirely from primitive geometry (extruded sole, capsule upper, torus/cylinder laces, rounded-box heel tab, extruded swoosh-like stripe). There are no external model files, no backend and no runtime network calls; everything is bundled by Vite.

## Features

- **Click-to-select in 3D** – parts are picked with a `THREE.Raycaster`; the hovered part gets a soft white outline and the selected part a cyan `OutlinePass` glow.
- **Six configurable parts** – sole, upper, laces, tongue, heel tab and stripe, each with its own colour and finish.
- **Colours** – 16 swatches plus a native `<input type="color">` and a validated hex field.
- **Finishes** – matte, gloss (clearcoat) or metallic, mapped onto `MeshPhysicalMaterial` roughness/metalness/clearcoat.
- **Engraving** – up to 8 characters rendered to an offscreen canvas and applied as a `CanvasTexture` on the heel tab; ink colour flips automatically for light/dark tabs.
- **Camera** – orbit by dragging, zoom with the wheel (`OrbitControls` with damping), autorotate toggle, four animated presets (Hero, Side, Heel, Top; keys `1`–`4`).
- **Randomise** – a seeded `mulberry32` PRNG so the sequence of random designs is reproducible in a fresh tab (key `R`).
- **Share** – the full design is encoded in the URL hash (`#sole=f5f2eb.matte&upper=…&text=DEVIN&view=hero&spin=0`) and restored on load, so a copied link or a reload in a new tab reproduces the sneaker exactly.
- **Download PNG** – renders a clean frame (outlines removed) and saves `sneaker-<text>.png`.

## Run it

```sh
cd configurator-3d
npm install
npm run dev      # http://localhost:5173
npm run lint     # oxlint
npm run build    # tsc -b && vite build
```

## Computer-use skill showcased

**Orbiting a WebGL scene by dragging, selecting 3D parts, and verifying rendered colours.** The scene is a `<canvas>`; there is no DOM to inspect for the shoe itself, so the agent has to drag to orbit, click on the correct 3D region to pick a part, and confirm from the rendered pixels (and the status pill / part list, which mirror the scene state) that the right part changed colour and finish.

## Browser test scenario

1. Open the app in a maximised Chrome window. **Expect:** navy sneaker with a chalk sole and orange stripe on a dark stage, toolbar at the bottom, parts panel on the right.
2. Drag on the canvas to orbit the shoe. **Expect:** the camera rotates around the sneaker; the "Hero" preset button is no longer highlighted.
3. Click the sole in 3D, then pick a swatch. **Expect:** status pill shows "Sole · Selected", cyan outline on the sole, sole re-renders in the new colour, part list updates.
4. Click the upper in 3D and pick a distinct colour, then set the finish to **Metallic**. **Expect:** the upper turns reflective with a "Metallic" chip in the part list.
5. Click the laces and the stripe in 3D and colour each distinctly. **Expect:** four parts now have visibly different colours.
6. Type `DEVIN` in the engraving field. **Expect:** the text appears on the heel tab (visible from the Heel preset); the counter reads `5/8`.
7. Switch between the Side, Heel, Top and Hero presets. **Expect:** the camera animates to each view and the active preset button is highlighted.
8. Click **Download PNG**. **Expect:** `sneaker-devin.png` lands in the downloads folder and is a non-trivial size (tens of KB or more).
9. Copy/open the share URL in a new tab. **Expect:** the new tab shows the identical sneaker (same colours, metallic upper, `DEVIN` engraving, same camera preset).

## Recording

_Recording link: to be added after the showcase run._
