# Polyn validation

## Reproducible commands

From a clean clone:

```sh
cd polyn
npm ci
npm run lint
npm run typecheck
npm test
npm run build
npm run preview
```

The preview is served on port 4173. No credentials or backend. For subdirectory verification, serve `dist` from any static host at a nested path; relative asset paths are emitted by Vite.

## Deterministic fixture and reset

The built-in `createProject()` fixture creates the same 15 objects and four cameras every time without randomness or external assets. File → New · Built-in loft → Open loft resets it and preserves the prior document in Undo. Browser storage key: `polyn.project.v1`. To clear all browser state, remove that key and reload. Reload retains document state, not undo history, selection, temporary playback or exposure.

## Executable test coverage

`src/model.test.ts` tests actual object geometry and state: independent default fixtures; immutable edits; clone isolation; add/delete; multistep undo/redo and redo invalidation; bounded history; JSON export/import including materials, cameras and keys; malformed, oversized and incompatible imports; duplicate IDs, invalid transforms, colors and bookmarks; animation interpolation, clamping and replacement; finite geometry bounds; full-height spiral stairs; detailed scene mesh count; Blender Z-up ↔ Three.js Y-up coordinate conversion.

## Browser golden path

1. Open production preview at 1440×900. Confirm the complete cutaway loft, compact workspace chrome, selected Sienna sofa in Outliner and editable Properties. No loading/errors.
2. Click the lounge chair in the Outliner; confirm the orange geometry outline and matching Properties name. Set Location X to 4, Rotation Z to 15 and Scale X to 1.2. Values and real geometry must change.
3. Change the material to the green palette swatch and roughness to 0.35; confirm actual mesh color. Undo and redo and verify values return.
4. Use Add → Mesh · Cube. Rename to “Test plinth”. Use `G X 1 Enter`, `R Z 30 Enter`, `S 0.7 Enter`; inspect numeric fields, duplicate with Shift D, then Delete. Undo/redo delete and confirm Outliner counts.
5. Save with Ctrl S, reload, search “Test plinth” in Outliner, select it and verify saved position, rotation, scale, color and object count.
6. Insert a key at frame 1. Change frame to 120, change Location X, insert a second key, scrub to 60. Verify visible interpolation. Play/Pause changes and stops the frame.
7. Switch actual Solid → Wireframe → Material modes, change saved cameras, orbit and toggle the grid. Save a custom camera through View and verify it appears in the selector.
8. File → Export project. Inspect downloaded JSON for version 1, edited object, transforms, cameras and keyframes. Open/import it and verify scene replacement.
9. Render image, check the real scene in Render Result without selection/grid/transform handles, Save image and verify a nonempty valid PNG of actual canvas dimensions.
10. Check browser console/runtime errors, default and changed-state layouts at 1280×800, 1440×900 and 1920×1080. Restore default loft, material shading and overview camera for the finished screenshot.

## Results

2026-09-15: `npm ci`, lint, typecheck, all 22 Vitest tests, production build and `npm audit` passed. Audit reports zero vulnerabilities. The build reports one non-fatal 850 kB JavaScript chunk warning (Three.js and the editor are loaded together).

Browser validation and evidence are pending on the initial PR revision; the final delivery report will record actual outcomes.

## Source references and observed geometry

See README for explicit observed dimensions, palette and attribution:

- https://docs.blender.org/manual/en/4.2/interface/window_system/introduction.html
- https://docs.blender.org/manual/en/4.2/editors/3dview/introduction.html
- https://docs.blender.org/manual/en/4.2/_images/interface_window-system_introduction_default-startup.png

The clone-this reference/audit/convergence procedure is used within the explicitly requested browser V1 scope. Its full-native/parity gate is not a claim of this demo: a screenshot cannot establish all Blender behavior, and the source project geometry differs. No pixel-diff metrics are fabricated.

## Honest parity boundaries

- This is an independent browser V1. No literal pixel identity or native Blender feature parity is claimed. The accessible 4.2 manual reuses a screenshot labeled 3.2.0 Alpha.
- Object Mode only: no mesh vertex editing, sculpting, UVs, topology modifiers, geometry nodes, simulation, Cycles path tracing, native .blend import/export, animation video rendering or native workspaces. Unavailable controls are disabled and labeled.
- PNG export uses the live WebGL canvas at its current resolution and ACES filmic shading, not Cycles. Material editing recolors the primary material of a composite object; intentionally separate trim/upholstery accents retain their colors.
- Timeline stores whole-object position/Euler rotation/scale keys and linear interpolation only. Document changes return to editing the stored transform; scrub/play previews interpolated values. No curve editor, skeletal rigs or full animation editor.
- Gizmos and typed transforms are in a world-aligned basis. The orientation graphic is decorative and labeled; cameras and real OrbitControls perform navigation.
- Authentication, networking and collaboration are not applicable. Data is synthetic/local; storage failures are reported and JSON export remains available. Undo/redo is session-only.
- 200 editable objects, 250 frames, 30 saved cameras, 2 MB import limit. Geometry is detailed procedural mesh content, not external textures/models.
- Desktop UI is targeted at 1280×800 and above; below 1060 px it keeps a minimum-width desktop workspace instead of a separate mobile layout. Properties and Outliner scroll independently.
