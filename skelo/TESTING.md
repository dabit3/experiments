# Skelo — reproducible validation

## Clean installation and shell checks

Node 24 (native TypeScript stripping for the executable tests), npm 10.

```sh
cd skelo
npm ci
npm run lint
npm run typecheck
npm test
npm run build
npm run preview -- --port 4173
```

Open the browser preview on port 4173. No auth is used. Vite `base: './'` allows a subdirectory deployment. Runtime assets and all geometry are local.

## Deterministic fixture / reset

Use **File → Restore built-in house → Restore house**. This resets entities, materials, tags, shadows and scene definitions. It is undoable. To test a completely fresh session, remove the `skelo.project.v1` localStorage key and reload. The fixture is Komorebi House with 9 editable entities and 3 named scenes. Geometry uses seeded pseudo-randomness for foliage and gravel. Units are meters.

## Programmatic coverage

`src/model.test.ts` exercises project round-trips, rectangle coordinate normalization and degeneracy/capacity limits, immutable push/pull and paint changes, grouped selection, undo/redo and branch invalidation, history bounds, strict import validation, measurement parsing, actual Three.js bounds, full-model finite geometry, tag visibility, OBJ vertices/faces, and camera-fit projection of default/maximum-size geometry at the three desktop aspect ratios.

## Browser golden path and expected results

1. Open the production build; inspect the full desktop at 1440×900. The courtyard has three furnished pavilions, roofs, timber, glazing, a stone garden, terraces and surrounding trees. Check 1920×1080 and 1280×800 as well.
2. Orbit by dragging with Orbit selected; pan with Pan; zoom with the scroll wheel or zoom buttons. Click Overview, Courtyard, Plan and the standard views. Geometry stays coherent; each scene changes the camera.
3. Expand/scroll to Outliner. Select Living pavilion. Entity Info shows its name and 14×3.6×5.5 m dimensions. Change Height to 4.2; geometry and bounding volume change. Undo restores 3.6; Redo restores 4.2.
4. Choose Rectangle and click two ground corners. A blue preview appears between clicks and creates a solid on the second click. Push/Pull drag modifies the selected mass. Also test exact measurements: select Rectangle, enter `3, 2, 1.5` in Dimensions, Enter. The selected Volume has width 3, depth 2, height 1.5.
5. Enter `2.5` in Measurements or Height. The volume height becomes 2.5. Rename it `Garden study`. Choose Burnished terracotta and Paint selected. The mass changes color and its Entity Info retains the name and dimensions.
6. Shift-click two outliner objects, Make Group, then select a member again: the group selects together. Undo and redo preserve group state. Delete is undoable.
7. Hide Study in Tags: the new volume disappears. Restore it. Toggle Landscape and shadows; move the Time slider and confirm lighting direction changes.
8. Orbit to a useful view and Save scene as `Garden study view`. Change cameras; recall the new scene. The camera and tag visibility return.
9. Save project through File. Inspect the downloaded `.skelo.json`: version=1; the named entity has correct size and material; the saved scene and tags are present. Export 3D model as OBJ; inspect real `v` and `f` records with finite numeric values.
10. Reload. Changes persist. Restore house and open the exported JSON. The edited geometry, scene and properties return. Try invalid JSON: a visible error must appear without replacing the current project.
11. Return to a clean overview, capture a full uncropped screenshot and verify no browser console/runtime errors. Record the meaningful editing journey with setup/test/assertion annotations. Final video must be WebM VP8/VP9, never MP4.
12. Regression: create a `50,50,50` volume and use Zoom extents/Fit model. The full visible model must fit with a margin, preserving viewing direction. Restore house; inspect default framing and Front/Right views for supported approach stairs. Try saving a blank scene name: the error must appear within the dialog.

## Results

Shell checks and browser results are recorded after execution, with final artifact URLs delivered alongside the PR. No native-app pixel parity metrics are claimed.

## Reference and honest boundaries

See [REFERENCES.md](REFERENCES.md) for the exact official SketchUp Pro 2023 screenshot, source URLs and measured observations.

- The browser V1 uses original procedural geometry, synthetic/local data and no commercial engine. It does not load or export SKP, DWG or BIM; no extensions, 3D Warehouse, cloud sync, geo-location provider, native license or physically based offline renderer is included.
- Push/Pull resizes parametric components, not arbitrary native face topology. Rectangle creates a rectangular prism on the y=0.7 modeling plane; Measurements creates a volume in the clear front-right study area. There are no freeform line/arc/boolean tools.
- Material painting changes the primary material of a component; roofs, glass, framing and furnishings retain architectural finishes. OBJ is geometry-only, in meters, includes the site and visible tags, and has no MTL/textures. JSON preserves editable components and all material assignments.
- Tags apply to the editable components in Outliner. The fixed site context (terraces, approach, decorative bushes, fence and lantern) remains visible.
- Camera views use perspective projection (including the top view). Scenes capture camera and tag visibility, not a full animation track. The compass is a fixed north marker for the scene, not a dynamic orbit indicator.
- Changes autosave in one browser; multi-tab merging is not supported. Undo history is intentionally session-local and limited to 50 operations. Imports are capped at 2 MB, 300 components and 30 scenes.
- Desktop 1280×800 and up is the target. Under 1000 px, the desktop workspace scrolls horizontally instead of hiding core panels or introducing a mobile redesign.
- Public source documentation/screenshots were inspected; the licensed native app was inaccessible. Literal pixel equivalence and native behavioral parity are not asserted. The clone-this full-native completion gate is intentionally not presented as passing.
