# 3D Sneaker Configurator (Three.js)

A Three.js product configurator for a low-top court sneaker in the spirit of the Nike Air Force 1. The shoe is built entirely from procedural geometry: a lofted "last" surface (superellipse cross-sections swept along a Hermite profile) forms the upper, and every overlay panel (toe cap with perforations, mudguard, eyestays, heel counter, swoosh) is a thin shell offset from that same surface, so panels sit flush no matter how the profile is tuned. The chunky cupsole and gum outsole are extruded from the last's footprint and bent with the toe spring. There are no external model files, no backend and no runtime network calls; everything is bundled by Vite.

## Features

- **Click-to-select in 3D** – parts are picked with a `THREE.Raycaster`; the hovered part gets a black inverted-hull outline and the selected part an orange one. A status chip in the viewer mirrors the selection.
- **Eight configurable parts** – Base (quarter, vamp and collar), Overlays (toe cap, mudguard, eyestays, heel counter), Swoosh, Laces, Tongue, Heel tab, Midsole and Outsole, each with its own colour and finish.
- **Colours** – 16 named swatches plus a native `<input type="color">` and a validated hex field.
- **Finishes** – matte, gloss or metallic, mapped onto `MeshStandardMaterial` roughness/metalness with a `RoomEnvironment` PMREM for reflections.
- **Engraving** – up to 8 characters rendered to an offscreen canvas and applied as a `CanvasTexture` on the heel pull tab; ink colour flips automatically for light/dark tabs. The engraving also becomes the giant watermark behind the shoe.
- **Camera** – orbit by dragging, zoom with the wheel, autorotate toggle (`Space`), four animated presets (Hero, Side, Heel, Top; keys `1`–`4`).
- **Randomise** – a seeded `mulberry32` PRNG so the sequence of random designs is reproducible in a fresh tab (key `R`).
- **Share** – the full design is encoded in the URL hash (`#upper=1f4bd8.metallic&stripe=c8102e.gloss&…&text=DEVIN&view=hero`) and restored on load, so a copied link or a reload in a new tab reproduces the sneaker exactly.
- **Download PNG** – renders a clean transparent frame (outlines removed) and saves `sneaker-<text>.png`.
- **Software-GL friendly** – direct `WebGLRenderer.render` (no post-processing passes), adaptive render scale while orbiting, and a painted floor shadow instead of shadow maps, so it stays fluid even on SwiftShader.

## Run it

```sh
cd configurator-3d
npm install
npm run dev      # http://localhost:5173
npm run lint     # oxlint
npm run build    # tsc -b && vite build
```

## Computer-use skill showcased

**Orbiting a WebGL scene by dragging, selecting 3D parts, and verifying rendered colours.** The scene is a `<canvas>`; there is no DOM to inspect for the shoe itself, so the agent has to drag to orbit, click on the correct 3D region to pick a part, and confirm from the rendered pixels (and the status chip / parts list, which mirror the scene state) that the right part changed colour and finish.

## Browser test scenario

1. Open the app in a maximised Chrome window. **Expect:** a white-on-white "Court Classic" with black swoosh and gum outsole on a light stage, camera toolbar at the bottom of the viewer, parts panel on the right.
2. Drag on the canvas to orbit the shoe and scroll to zoom. **Expect:** the camera rotates around the sneaker and the shoe grows/shrinks.
3. Click the midsole in 3D, then pick a swatch. **Expect:** status chip shows "Midsole · Selected", orange outline on the cupsole wall, midsole re-renders in the new colour, parts list updates.
4. Click the base (quarter panel or collar) in 3D and pick a distinct colour, then set the finish to **Metallic**. **Expect:** the base turns reflective with a "Metallic" chip in the parts list.
5. Click the laces and the swoosh in 3D and colour each distinctly. **Expect:** four parts now have visibly different colours.
6. Type `DEVIN` in the engraving field and switch to the Heel preset. **Expect:** the text appears on the heel tab; the counter reads `5/8`; the watermark behind the shoe reads DEVIN.
7. Switch between the Hero, Side, Heel and Top presets and toggle Auto-rotate on and off. **Expect:** the camera animates to each view, the active preset pill is highlighted, and the shoe spins while auto-rotate is on.
8. Click **Download PNG**. **Expect:** `sneaker-devin.png` lands in the downloads folder and is a non-trivial size (hundreds of KB).
9. Copy the share URL and open it in a new tab. **Expect:** the new tab shows the identical sneaker (same colours, metallic base, `DEVIN` engraving, same camera preset).

## Recording

Recording: https://app.devin.ai/attachments/aa2f8184-dc8c-40d2-8855-7654bb2aff82/court-classic-showcase-edited.mp4
