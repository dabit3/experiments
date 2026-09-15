# Havik — verification and reproduction

## Clean installation and commands

From the repository:

```sh
cd havik
npm ci
npm run lint
npm run typecheck
npm test
npm run build
npm run preview -- --host 0.0.0.0 --port 4173
```

Open the server on port 4173 through the session's browser preview. Node 22.12+ or 24; no backend/auth/remote services. The test suite runs entirely in Node using Vitest.

## Deterministic fixture and reset

The initial model comes from `createProject()` in `src/model.ts`; coordinates are metres, 2D display scales to 40 SVG units/metre, and exported dimensions are millimetres. The initial floor is 20 × 13 m = **260 m²** in seven non-overlapping rooms.

Use **File → Restore sample lake house → Restore sample**. Reset is undoable. For a completely fresh browser state remove localStorage key `havik.project.v1` and reload. A sample reset does not clear undo history or view controls; choose **Dollhouse Overview**, turn roof off, enable landscaping and Floor 1, and click **Fill window** for the default visual fixture.

## Automated coverage

Executable tests in `src/model.test.ts` cover:

1. Room area accounting and non-overlap across the complete floor.
2. Wall segments around real openings, exact total length and continuity.
3. Opening overflow, missing wall reference, and overlap rejection.
4. Snapped placement of every library object, without mutation.
5. Room/material changes and placement through exact undo/redo, redo invalidation after branching, 50-edit history bound, and no-op/empty history.
6. Edited full-project persistence round trip.
7. Invalid JSON, unknown version, missing collections, invalid materials, non-finite coordinates, negative lengths, duplicate IDs and object-limit rejection.
8. Sanitization of unexpected imported properties.
9. SVG geometry, updated labels, dimensions, door arcs, selection and XML escaping.

## UI golden path and expected outcomes

Run against the production build, at 1440 × 900 first; inspect 1920 × 1080 and 1280 × 800 as well.

1. **Default fixture:** Confirm the furnished lake house renders in Dollhouse Overview, with kitchen island, beds, deck, trees, lake and plan navigator. Check console/network for errors.
2. **Room edit:** Open Floor Plan; select Great Room (or Project Browser → Great Room). Change Object name to **Lake Lounge**, Material to **Smoked walnut**, Ceiling height to **3.4**, Apply. Confirm changed room label/fill. Undo then redo and confirm exact restoration.
3. **Wall edit:** Select a solid exterior wall segment; change Wall thickness to **0.30**, Apply. Confirm thicker plan linework and the stored wall value. Use the selected wall's geometry rather than furniture or glazing.
4. **Opening edit:** Select the living-room north glazing; change Opening width to **5.5**, Apply. Confirm shorter glazing and correct wall infill. An overflowing width/offset must show a real error and preserve the old opening.
5. **Library placement:** Search **lounge** in All Content, select Oak lounge chair, click the plan in Great Room. Confirm selection and furniture count increase. Set Position X **5.5**, Position Y **5.2**, Rotation **45**, Apply. Drag the object and verify changed coordinates. Undo/redo placement or movement.
6. **Persistence:** Save and reload. Confirm **Lake Lounge**, walnut material, modified wall/opening and furniture are present in localStorage and visible after selecting the room/object.
7. **View/layers:** Switch to Dollhouse, orbit and zoom, use camera presets, show/hide Roof, disable/re-enable Floor 1 through Layers, toggle landscaping. Verify actual geometry changes. Switch to Lakeside Camera and back.
8. **Exports:** Export plan SVG, current PNG, and Havik JSON. Inspect SVG for `<svg>`, actual paths, dimensions and **LAKE LOUNGE**; verify JSON values and object count; verify PNG dimensions/header and nonempty rendered content.
9. **Import:** Import the just-exported JSON. Confirm geometry and edited values survive. Invalid JSON must show an error and leave the current model unchanged.
10. **Layout and final evidence:** Inspect default and changed states at all target sizes. Right dock scrolls rather than losing specification actions. Capture a clean uncropped PNG and an annotated full WebM screen recording. Deliver no MP4.

## Results

Initial clean-install verification on Node 24.19.0: `npm ci`, lint (zero warnings), TypeScript, all **20 Vitest tests**, and production build passed. `npm audit` reported **zero vulnerabilities** after selecting patched Vite 7.3.6 and Vitest 4.1.11. Vite reports a non-failing bundle-size advisory for the included Three.js renderer.

Production browser verification and evidence are added after the PR is opened. No native reference parity or fabricated pixel-diff score is asserted.

## References and access boundaries

- Chief Architect Premier X16 Reference Manual, pages 12–13 and 979–980: https://cloud.chiefarchitect.com/1/pdf/documentation/chief-architect-x16-reference-manual.pdf
- X16 floor plan tutorial documentation: https://cloud.chiefarchitect.com/1/pdf/documentation/chief-architect-x16-tutorial-guide.pdf
- Toolbar reference: https://www.chiefarchitect.com/support/article/KB-00811/customizing-toolbars.html

`README.md` records observed panel geometry and implementation measurements. Source screenshots were inspected from the official PDF. No licensed native instance was available; behavior is implemented for the authorized browser V1 rather than asserted as observed commercial-engine parity. The strict clone-this zero-pixel gate remains outside the claims of this demo.

## Honest V1 limitations

- Single model level. Room rectangles are the fixed seven-room fixture; you can edit their names, materials and ceiling metadata. New partition walls do not recalculate room boundaries or area; wall deletion likewise does not merge rooms.
- Room ceiling height is saved metadata; roof elevation uses the demonstration roof generator, not a structural roof solver.
- Wall editing supports thickness and height. New walls use an orthogonal two-click partition tool; no free-angle/dynamic wall joins or construction validation.
- Glazing in cutaway view follows the cutaway wall height. Full-height walls appear in perspective or with the roof visible.
- Library content is eight original procedural object types, not the commercial manufacturer catalog.
- No native `.plan`, BIM/IFC/DWG, framing schedules, code compliance, photoreal path tracing, structural analysis, collaboration, cloud sync, licensing or authentication.
- Browser localStorage retains the model, not undo history or camera/display settings across reload. Concurrent-tab editing is not synchronized.
- Desktop only: 1000 px minimum app width. At narrower sizes, use a larger viewport; no invented mobile workspace.
- Requires WebGL for 3D. The editable vector plan remains available if WebGL is unavailable.
- Light traditional workspace hierarchy is faithful to the inspected X16 reference, with new branding, original icons/content and a sage/ivory palette. No claim of literal pixel identity.
