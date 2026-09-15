# Veyra V1 — testing and parity boundaries

## Reproducible programmatic checks

```sh
cd veyra
npm ci
npm run lint
npm run typecheck
npm test
npm run build
npm run preview
```

The production app serves on port 4173. No authentication, API or backend.
Node 24 and npm 10 were used. Vite uses a relative asset base.

The executable Node tests in `src/model.test.ts` cover the actual model:
snap/rotation transforms, wall length, door projection/host attachment, wall
openings as geometric segments, wall edits and hosted door movement, invalid
dimensions, cascading deletion, undo/redo and history bounds, parser validation,
round-trip persistence, SVG geometry/escaping and CSV quantity/formula handling.

## Deterministic fixture and reset

File → Reset sample project → Reset sample restores the deterministic original
32-element Alder Cultural Pavilion (the count is displayed in the browser).
The reset is undoable. Alternatively, in DevTools run
`localStorage.removeItem('veyra.project.v1')`, then reload.
No randomly placed geometry or remote assets affect the sample.
Only newly placed elements receive random UUIDs.

## Production UI sequence and expected results

1. At 1440 × 900, open the production build. Confirm pale dense ribbon, Properties
   above Project Browser, three view tabs, view cube and a fully rendered
   landscaped, two-level cultural pavilion. Orbit by dragging, use Top/Front/Right
   on the view cube, then Home. No blank canvas or runtime errors.
2. Open Level 1. Click Wall in the Architecture ribbon (or W). Click two empty
   points inside the pavilion, at least 4 m apart, to create a wall. The preview
   snaps to 0.5 m; finished wall is selected and Properties shows its dimensions.
3. Set Element name to `Test gallery wall`, Material to Timber, Height to 3.2,
   then Apply. The wall changes visually and the browser search can find it.
4. Click Door (or D), then near the new wall midpoint. A hosted 1.2 × 2.4 m
   door appears with a swing arc. Selecting the wall/door in the Project Browser
   retains identity between Level 1, South and 3D. The 3D wall has a real opening.
5. Undo the door; it disappears. Redo; it returns. Edit a wall property, undo and
   redo. Select/delete the door, undo; the door returns with its host.
6. Open Visibility / Graphics via the right navigation bar or View ribbon.
   Uncheck Roof, inspect the exposed model, then recheck Roof. Hide/show Timber
   Fins. These states apply to coordinated drawings and persist.
7. Save with Ctrl+S. Reload. Search `Test gallery wall` in Project Browser:
   dimensions/material and wall/door geometry remain. Undo history is intentionally
   session-only, while model and category visibility persist.
8. File → Download project JSON. Verify JSON version 1, the edited wall and hosted
   door. Export drawings & schedule → CSV: verify the edited name and metre
   dimensions. Export SVG: verify vector geometry/current visible Level 1 IDs.
   Open the exported JSON after a reset; edits are restored. Invalid JSON should
   report an error without replacing the current model.
9. Inspect default and changed states at 1920 × 1080 and 1280 × 800. Left panels
   scroll; tabs, primary placement tools, Apply, view cube and exports remain
   available. Small screens below 1000 px use a desktop-sized workspace.
10. Restore the pristine sample and Home view for the final full, uncropped PNG.
    Capture the golden path as an annotated **WebM**, not MP4.

## Results

Initial implementation: lint and TypeScript checks passed; all 17 model tests
passed; production build passed. Browser verification follows PR creation.

## Source references and method

See README for source frames, precise observations and layout measurements.
The single reference is Revit 2025.1 in Autodesk's public 2025 help tutorial:

- https://help.autodesk.com/cloudhelp/2025/ENU/Revit-GetStarted/files/GUID-3197A4ED-323F-4D32-91C0-BA79E794B806.htm
- https://help.autodesk.com/videos/97dfde60-54e0-11ea-86bb-6702fb65b9b8/video.webm
- https://help.autodesk.com/cloudhelp/2025/ENU/Revit-GetStarted/files/GUID-A764EA7A-FE26-469B-857C-F3A70812FC34.htm
- https://help.autodesk.com/cloudhelp/2025/ENU/Revit-GetStarted/files/GUID-C8D3E5A6-02A5-43A9-AFFC-D49DD27398B1.htm

Public documentation and actual video frames were inspected before implementation.
The clone-this plugin's reference/audit/convergence process is used within the
explicit browser V1 assignment. Native execution, matched fixture captures and
zero-pixel-difference comparisons are unavailable; its full-native-parity gate
cannot pass and is not represented as a V1 acceptance test. No parity metrics
are fabricated.

## Honest limitations

- Independent browser V1, not native Autodesk Revit or an RVT/IFC-compatible BIM
  engine. Native source code, commercial licenses and private integrations were
  unavailable and not pursued.
- No MEP, structural analysis, worksharing, families editor, sheets, true section
  cuts, native file formats, photorealistic ray-tracing engine or dimension
  constraint solver. Gray ribbon actions are explicitly disabled.
- Real-time Three.js architecture uses procedural geometry/materials. Camera and
  display style are session controls. Model geometry, properties and visibility
  save locally. Browser storage failure is reported; JSON provides backup.
- Walls are straight rectangles; doors are Level 1 wall-hosted with one rectangular
  opening each. Door placement rejects missing/short hosts, collisions and invalid
  dimensions. Hosted doors move with wall property edits.
- The landscape is a fixed procedural site assembly. Its name and category
  visibility are editable; its dimensions and mixed materials are read-only.
- Floor plan and elevation are projections of the shared model; labels and the
  architectural datum grid describe the original sample and are not a spatial
  room/constraint engine. SVG is a metre-coordinate floor-plan drawing and CSV
  reports gross element volumes, not a construction-certified quantity takeoff.
- Native Segoe UI may fall back to Tahoma/Arial on Linux. Original tiny icons
  replicate the technical style, not Autodesk's copyrighted icon assets.
- Desktop-focused at 1440 × 900, 1920 × 1080, and 1280 × 800. Not a mobile design.
- Single-user local persistence; simultaneous tabs do not merge edits.
