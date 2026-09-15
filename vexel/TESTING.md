# Vexel — verification and reproduction

## Clean install and checks

From the repository root:

```sh
cd vexel
npm ci
npm run lint
npm run typecheck
npm test
npm run build
npm run preview -- --port 4173
```

No backend, Python setup, credentials or downloaded scene assets are required. Node 22.12+; tested tooling is Node 24.19.0 and npm 10.8.3.

## Deterministic fixture / reset

Use **File → New · reset gallery… → Reset gallery**. This restores Forma Gallery and remains undoable. For a completely fresh persistence fixture, remove only `localStorage['vexel.project.v1']` in browser developer tools and reload. No other apps' storage is touched. Default selection is Continuum; it has rotation keys at frames 0 and 100. The scene starts at frame 0 and the perspective is the active fourth viewport.

## Programmatic coverage

`src/model.test.ts` executes actual state/geometry/export logic:

1. Deterministic independent 25-object gallery fixture and eleven arch ribs.
2. Unique primitive IDs and default coordinates.
3. Immutable object edits.
4. Undo/redo, divergent redo truncation, no-op identity and bounded history.
5. Animation interpolation, endpoint clamping, key replacement/sorting, and elapsed-time playback across skipped frames and loop boundaries.
6. Editing already-keyed objects at current frame and Auto Key frame-zero preservation.
7. JSON round trips and rejection of malformed documents, invalid values, duplicate IDs, unordered keys and oversized files.
8. Every fixture creates finite nonempty world geometry.
9. Twist changes real vertices while preserving Y and radial distance.
10. Numeric position/scale/degree rotation applies in world coordinates.
11. OBJ exports actual transformed triangles, excludes hidden objects, sanitizes names, bakes modifiers and samples the requested animation frame.

## Browser golden path

Run against the production preview at desktop **1440 × 900**, then inspect **1920 × 1080** and **1280 × 800**.

1. Reset the gallery. Inspect four labeled viewports, actual wireframes, shaded geometry, yellow active outline, Scene Explorer, Command Panel and bottom timeline.
2. Select **Continuum · bronze study** in Scene Explorer. Set position X to `1.5`, press Enter. Expect object movement in all views and X=1.5; undo and redo should reverse/reapply it.
3. Use **Create → Box**. Expect Box 001 in Explorer and selected in Modify. Set scale Y=`3` and scale Z=`0.35`; set Twist angle=`135`. Expect a visibly deformed tall mesh.
4. Open **Material**; use **Patinated copper**, then set roughness=`0.4`. Expect a visibly different material. Reload; selected object may return to Continuum, but Box 001 and its edited properties must remain. Reselect Box 001 and verify numeric/material values.
5. Enable **Auto Key**. Move to frame 50, edit Box position X=`4`. Expect keys at 0 and 50. Scrub to 0 and 50, verify positions differ. Play/pause; expect real motion and advancing frame.
6. Maximize Perspective via corner button, orbit by dragging, zoom, restore four viewports. Verify active view label/border, preserved scene and no overlap.
7. File → Export project (.json). Inspect downloaded JSON for version 1, edited box transform, twist, material and animation keys.
8. File → Export visible geometry (.obj). Inspect real vertex/face lines and object names, finite coordinates and nonempty output.
9. Hide Box 001 with its eye button, verify disappearance in all viewports; Undo restores it. File → Open Vexel project imports the prior JSON with edited data intact.
10. Finish with the best composed gallery scene, take a full uncropped PNG, and inspect browser console for uncaught errors.

The testing agent owns browser/server setup and records setup, named test starts and consolidated assertions. Delivery requires WebM (VP9/VP8), not MP4. A conversion, if needed, must preserve the full recording and be validated using `ffprobe`.

## Results

Pending final programmatic and production browser verification; updated after execution.

## Reference access, fidelity and boundaries

Reference URLs and explicit source measurements are in [README.md](README.md). The public 3ds Max 2025 overview, UI screenshot and Command Panel documentation were inspected. Native interaction and commercial engine access are unavailable. The clone-this reference/audit/convergence workflow was consulted and run data is kept untracked under `.devin/clone-this/vexel/`. Its strict zero-difference/native parity gate is **not claimed**: this requested V1 has a different scene and brand, a browser renderer and no matched running native reference. No pixel-diff metric has been fabricated.

- Browser-only original geometry, not .max compatibility. No Arnold/offline rendering, asset server, plugins, MAXScript, mesh vertex/edge sub-object editing, native rigging/physics, advanced Graphite tools, or native camera/light creation. Unavailable chrome controls are explicitly disabled.
- Numeric world transforms are accurate; colored axis indicators are visual aids, not draggable transform handles.
- Orthographic views support selection and scroll zoom. Perspective supports orbit/pan/zoom. Four-view geometry remains synchronized.
- Position, rotation and scale interpolate linearly; no curve editor, easing or skeletal animation. Animation is sampled at 24 FPS rather than a production DCC timing engine.
- OBJ contains transformed triangle geometry and object names, not materials, UV texture files or animation tracks. JSON preserves the editable project and keyframes.
- Compound gallery objects have fixed internal component materials; their editable base color applies to their principal material. Primitive materials are fully editable.
- Local persistence is browser/origin-specific; no cloud or collaboration. Export JSON to transfer or back up a project. Storage failures are surfaced. Corrupt persisted state falls back to the original gallery.
- Maximum 200 objects, 101 animation keys per object, 2 MB JSON import and 60 undo snapshots.
- Desktop widths 1280–1920 are the intended UI; below 1120 px the professional workspace has a minimum width rather than an invented mobile layout.
