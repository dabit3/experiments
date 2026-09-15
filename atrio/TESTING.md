# Atrio V1 verification

## Reproduce from a clean checkout

Node 22.12+ or 24 and npm are required. No environment variables, network assets,
authentication or backend are needed to run the app after dependencies install.

```sh
cd atrio
npm ci
npm run lint
npm run typecheck
npm test
npm run build
npm audit
npm run preview -- --port 4173
```

Open the local preview on port 4173. Vite uses `base: './'`; the contents of
`dist/` can also be served under an arbitrary subdirectory.

## Deterministic fixture

The app opens to Oak & Light Arts Campus: three pavilions, a courtyard, a pool,
planted grounds, timber screening, furniture and 25 editable architectural
elements. Geometry and landscaping are deterministic.

Use **File → Restore example campus → Restore campus** to return to this exact
fixture. Reset is undoable. Project data autosaves under `atrio-project-v1` in
the current browser origin's localStorage. Clear that key to reproduce a first
visit. Camera, active view, active tool, layer filters and undo history are
session-only. The local project is the durable state.

## Programmatic checks

`src/model.test.ts` verifies:

1. Deterministic fixture and JSON roundtrip.
2. Correct diagonal wall length/angle, story elevation and short-wall rejection.
3. Positive dimensions and area for reverse-order slab corners.
4. Hosted door placement; following host movement/rotation; duplicate rejection;
   cascade deletion.
5. Story, layer and cutaway filtering.
6. Exact undo/redo snapshots and redo invalidation after a new edit.
7. Unicode project persistence.
8. Invalid JSON/version, duplicate IDs, negative dimensions, invalid material,
   missing door host and oversized door rejection.
9. Actual SVG geometry, escaped text, wall dimensions, story filtering and
   physical export scales of 1:100, 1:200 and 1:500.

`src/scene.test.ts` adds two Three.js raycast tests: timber slats and glass
transoms must leave a hosted doorway clear while the adjacent wall stays solid.

## Browser acceptance sequence

Use the production preview in a maximized Chrome window.

1. Inspect the initial 3D campus at 1440×900, then 1920×1080 and 1280×800.
   The Info Box, Toolbox, view tabs, Navigator and Quick Options remain usable.
   Orbit by dragging, zoom with the wheel, and restore with **Fit in window**.
2. Open **0. Ground Floor**. Choose **Wall**, then click two empty plan locations
   about 6 m apart. The wall is selected and the element count increases to 26.
3. Open **Element settings**, change name, material, length and height, then
   **Apply changes**. Properties and linked model geometry match the edit.
4. Choose **Door**, then click the new wall. The hosted door appears in the
   plan and opens a genuine void in the 3D wall. Editing its host preserves the
   attachment. A second door on that wall is rejected with a visible message.
5. Choose **Slab**, then click two opposite empty corners. Edit its material.
   Undo and redo the edit using toolbar controls or Ctrl/Cmd+Z and
   Ctrl/Cmd+Shift+Z. Counts and properties return to the expected states.
6. Switch to **3D / All**, select **3D Cutaway**, change camera and appearance
   with Quick Options. Roofs disappear under cutaway; surfaces change under
   White model; **Structure only** removes glazing, roofs and landscaping.
7. Select **1. Mezzanine** and **2. Roof** in Navigator. The correct story
   geometry is visible in Plan. Return to Ground Floor for export.
8. Choose a drawing export scale, then **File → Export dimensioned plan**.
   Inspect the downloaded SVG: named real elements, metric dimensions, active
   story/filter and physical millimetre dimensions are present.
9. **File → Save project file**, inspect the downloaded `.atrio.json`, reload,
   and confirm edited project geometry persists. Restore the fixture, then
   **File → Open project file** and select the saved file. Edits return.
10. Try invalid JSON import: a visible rejection appears and current geometry
    remains unchanged. Search Navigator for an element name and select it.
    Open and dismiss Help/Element Settings using Escape; check keyboard focus.
11. Restore a clean campus, return to Axonometry / All elements / Surfaces /
    Afternoon. Capture a full uncropped PNG and an annotated WebM recording.
    Inspect browser console and runtime errors throughout.

## Results

Lint and typecheck pass; all 11 programmatic tests pass; the production build
passes; npm audit reports zero vulnerabilities. Vite reports a bundle-size
advisory for the Three.js application. The first browser run passed the editing,
history, story/filter, export and persistence sequence. It found compact-layout
overflow, a missing favicon and decorative wall meshes crossing door openings.
Those fixes await the final production browser retest.

## Reference and parity boundaries

See [REFERENCES.md](REFERENCES.md) for public Archicad 28 documentation URLs,
source measurements and observed UI hierarchy.

This browser V1 implements original synthetic project data in a workflow
inspired by those references. It does not execute Archicad's commercial engine.
Native PLN/PLA/IFC/DWG compatibility, Teamwork, BIM validation, schedules,
parametric GDL, professional construction documentation and photorealistic
rendering are outside scope. Unsupported tools are visibly disabled.

The floor-plan export is SVG with physical dimensions and a scale bar. It is
not a certified construction drawing. Slabs and straight walls use simple
rectangular geometry; a wall supports one hosted door. Procedural landscaping
and furniture are visual context, not editable BIM objects.

Desktop layout fidelity takes priority. Below 1100 px the workspace has a
minimum width and may need horizontal scrolling. No literal pixel-perfect
match or native-engine parity is claimed: public screenshots use different
projects, and the native reference runtime was not available for matched
source/clone interactions or zero-pixel comparisons.
