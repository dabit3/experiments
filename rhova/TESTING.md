# Rhova V1 — reproducible validation

## Clean installation and commands

```sh
cd rhova
npm ci
npm run lint
npm run typecheck
npm test
npm run build
npm audit
npm run preview -- --port 4173
```

Node 24.19.0 / npm 10.8.3 used during implementation. Preview serves the production build. No authentication is needed. No Python is required.

## Deterministic fixture / reset

Use **File → Reset museum → Reset museum**. This regenerates the six-object/six-layer museum without randomness and is undoable. For an entirely fresh session, clear the localStorage key `rhova.project.v1`, then reload. Do not clear other applications' storage. The fixture contains a 32-rib, 9 m-rise canopy, glass pavilion, site, landscape and two five-point profiles.

Local project state is validated on load/import and automatically saved. Undo/redo history is session-local; model state persists on reload. Project JSON import is limited to 2 MB, 200 objects, 30 layers and 200 points per curve.

## Programmatic coverage

The 13 committed Vitest tests exercise fixture serialization, malformed/oversized/duplicate project rejection, dangling layers and transform validation, undo/redo branching and bounds, Z-up transform/inverse math, interpolated curve endpoints, canopy span/rise behavior, mesh vertex/triangle connectivity, extrusion height, loft sampling across different control counts, layer visibility, occluded control-handle picking, and actual named OBJ vertex/face output.

## Browser golden path and expected results

1. At 1440×900, open the production preview and reset the museum. Confirm four named viewports, shaded ribbed museum, technical elevations, layer rows and object list without clipped critical actions.
2. Select **Canopy / ribbed shell** in Objects. Set **Canopy rise** from 9 to 12 and **Rib count** from 32 to 24. The mesh updates in all four viewports. Undo/redo restores/applies the latest numeric change.
3. Set **Position X** to 2. Reload. Verify rise=12, ribs=24, X=2 in Properties and visibly shifted geometry. Undo history is intentionally reset by reload.
4. Open Layers, hide the canopy layer. The roof disappears in all viewports. Show it again. Change the layer color and verify technical wireframe color. Lock it; its property inputs become disabled; unlock it.
5. Select **Profile A / west**. Show control points, select **P3**, change **Point Z** to 17. Maximize Front and drag P3 with the canopy still visible: the handle follows the pointer and the curve updates on release. Lock Construction curves and confirm dragging cannot change the point; unlock it.
6. Select **Profile B / east** while holding Shift. Choose **Loft two curves**. A new ruled surface appears and is listed in Objects. Undo removes it; redo restores it.
7. Choose **Draw curve**. Click at least three points in the Top viewport outside the museum, then **Finish curve** (or Enter). It becomes a named selected object with editable control points.
8. Set **Extrusion height** to 5 and choose **Extrude**. Confirm a new surface, then set **Surface height** to 7. Export OBJ and inspect actual `v` and `f` records, finite coordinates, nonempty unique `o` part names and meter/Z-up header.
9. Save project JSON. Inspect exported JSON for the new surface, edited canopy/profile data and layer settings. Open this saved project and confirm the state round-trips. Invalid JSON must show an error without replacing the current project.
10. Maximize Perspective via its title or button, orbit with a drag and zoom with the wheel. Restore four views. Check 1920×1080 and 1280×800; critical actions must remain reachable through panels/scrolling.
11. Inspect browser console/runtime diagnostics and failed asset requests. Reset and frame the best clean scene for an uncropped PNG and an annotated full WebM recording.

## Results

Validated on 15 September 2026 in Ubuntu Chrome against the production preview.
Final application revision: `5244ec7a`; later documentation/evidence commits do
not alter the application.

| Check | Result |
| --- | --- |
| Clean `npm ci` | Passed |
| `npm run lint` | 0 warnings, 0 errors |
| `npm run typecheck` | Passed |
| `npm test` | 13 tests passed |
| `npm run build` | Passed; Three.js bundle exceeds Vite's 500 kB advisory threshold |
| `npm audit` | 0 vulnerabilities |
| Editing/history/persistence | Canopy 12 m rise / 24 ribs, X=2, rotation=10°, scale=1.1; undo/redo and reload passed |
| Layer and point workflows | Color/visibility/lock passed; visible P3 drag (0,-8,17) → (1.79,-8,18.45) passed; locked point rejected drag |
| Creation | Two-profile loft with undo/redo, three-point curve and height-7 extrusion passed; final edited model has 9 objects |
| JSON | Exact nine-object round-trip passed; malformed import rejected without replacing current scene |
| OBJ | 34,339 finite vertices, 22,592 faces, 1,149 lines; valid indices and 403 unique nonempty object names |
| Camera/layout | Perspective orbit/zoom/display modes and four-view restore passed; default/edited layouts inspected at 1280×800, 1440×900 and 1920×1080 |
| Runtime | No captured runtime errors; local resources returned HTTP 200 |

Browser testing found and fixed visible control handles being occluded in
raycasting, then blank OBJ object names. Both have executable regressions and were
retested in the browser. The combined annotated WebM includes unchanged-workflow
coverage from `0c23d718` and export/import/view coverage from `5244ec7a`.
Alternate-size screenshots supplement the recording: the recorder stops capturing
when the desktop shrinks below its initial capture dimensions. No screenshot
frames are presented as moving interaction footage.

## Source references

- https://docs.mcneel.com/rhino/8/help/en-us/user_interface/rhino_window.htm
- https://docs.mcneel.com/rhino/8/help/en-us/image/localization/rhinowindow_win.png
- https://docs.mcneel.com/rhino/8/help/en-us/commands/new_viewport_arrangements.htm
- https://docs.mcneel.com/rhino/8/help/en-us/commands/loft.htm

Measured observations and source provenance are in README.md. No literal pixel-parity metric is claimed: the source is an annotated public screenshot with an empty scene, not an executable reference using the same fixture.

## Honest V1 boundaries

- Curves use centripetal Catmull–Rom interpolation. Canopy uses deterministic sampled profiles. Loft/extrusion output open, double-sided polygon surfaces, not watertight NURBS solids. No native NURBS kernel, booleans, trims, SubD, Grasshopper, plug-ins, .3dm import/export, or production structural analysis.
- OBJ exports **visible** meshes/linework in world meters, Z up. Materials are not bundled as MTL. Project JSON retains editable definitions; OBJ does not.
- Native snap checkboxes beyond the first three are disabled. The enabled snap controls share a documented 0.5 m rounding mode; exact native End/Near/Point snapping is not implemented. Ortho/Planar constraints are disabled.
- UI SVG icons are original approximations; density and warm scene palette are V1 adaptations. No commercial application interaction or full pixel matching was possible from the accessible documentation.
- Desktop is the target. 1280×800, 1440×900 and 1920×1080 are supported; the property container scrolls. Below 1050 px wide the app preserves desktop geometry and uses browser overflow rather than a mobile redesign.
- JSON files contain synthetic local data only. No account, network collaboration, backend, cloud save, telemetry or public deployment.
