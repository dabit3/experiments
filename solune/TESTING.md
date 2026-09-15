# Solune — reproducible testing

## Clean installation and programmatic checks

From the repository root:

```sh
cd solune
npm ci
npm run lint
npm run typecheck
npm test
npm run build
npm run preview -- --port 4173
```

Open the preview with a current WebGL 2 browser. No accounts or secrets.

The Vitest tests exercise document validation, all editable fields through JSON roundtrip, invalid/duplicate/oversized data, isolated deterministic reset fixtures, terrain placement bounds, history branching/capacity/no-op behavior, multi-edit undo/redo, sunlight coordinates, and actual merged architectural/vegetation geometry. They do not replace browser verification of rendering.

## Deterministic fixture/reset

Use **Project files → Restore Casa del Mar → Restore original project**. This reset is undoable. Alternatively remove only `localStorage['solune.project.v1']` and reload. Default: 18:24, clear weather, 24% clouds, 80% interior light, travertine, eight movable objects plus the villa, four camera shots. Project state persists; exploratory orbit/pan is only committed with **Update camera**.

## Browser golden path and expected outcomes

1. Reset and inspect the default build scene at 1440×900. Villa, glazing, landscaped island, lit interiors and pool reflection render as geometry. Drag to orbit; scroll to zoom; right-drag to pan. Restore the current camera.
2. Drag **Time of day** to noon, then twilight. Sky, sunlight and water visibly change. Select **Mist**, then **Clear**; atmosphere changes. Adjust cloud and interior intensity. Undo/redo should restore the last gesture.
3. Open **Materials**. Select **Terracotta** then **Limestone**; architectural exterior stone changes. Adjust roughness. Confirm the selected material is visible and in localStorage.
4. Open **Objects**, search “olive”, select **Mediterranean olive**, and click visible landscape. Object count increments and the selection bounds plus transform inspector appear. Edit X/Z, rotation and scale. Duplicate; undo, redo, then delete the duplicate.
5. Open **Scene objects** and select the placed olive. Confirm the expected transform values. Reload and confirm the object count, material, lighting and transform persist.
6. Enter **Photo mode**. Switch between four actual camera presets. Orbit to a new view; **Update camera** saves it. **New photo** adds another named camera. Toggle grid, change exposure, saturation, bloom and vignette; visible image changes.
7. **Render photo → Full HD → Export image** creates a genuine PNG. Inspect PNG signature and dimensions (1920×1080). It must contain the scene with effects and no interface or selection box.
8. **Project files → Export project** creates JSON containing edited materials, weather, objects and cameras. Restore the fixture, then **Open project** and import that JSON. Verify the edited scene returns. Import invalid JSON; a readable error appears and the current project remains intact.
9. Inspect default and edited layouts at 1920×1080, 1440×900 and 1280×800. Critical controls remain reachable. Check browser console/runtime and local network requests.
10. Capture a full uncropped PNG of the finished scene and an annotated complete WebM recording. If capture tooling emits MP4, convert the entire video to VP9/VP8 WebM and verify using `ffprobe`; distribute only WebM.

## Results

Verified on 2026-09-15, Ubuntu Linux, Node 24.19.0, npm 10.8.3, Chrome with WebGL software rendering. Application revision: `bb539d73` (subsequent documentation commits do not change the tested application).

| Check | Result |
| --- | --- |
| Clean `npm ci` | Passed |
| Incremental `npm install` | Passed |
| `npm run lint` | Passed, no warnings |
| `npm run typecheck` | Passed |
| `npm test` | 25 tests passed in 2 files |
| `npm run build` | Passed; relative-base production assets |
| `npm audit` | 0 vulnerabilities |
| Production preview | Passed on port 4173 |
| Browser golden path above | Passed |
| Desktop Build/Photo layouts | Passed at 1280×800, 1440×900, 1920×1080 |
| Full HD PNG | Valid signature, 1920×1080, nonblank rendered scene |
| JSON/persistence | Exact export → reset → import and reload equality |
| Invalid import | Visible modal error; saved scene unchanged |
| Browser runtime exceptions | None observed |
| Test recording | VP9 WebM, 1440×900, 138.584 seconds; complete processed capture |

The first browser run identified missing palm fronds from mixed geometry attributes and pool/terrace z-fighting. Both were corrected before the complete final run. Regression tests now verify the batched palm crown and raycast clearance over the pool.

The testing agent used actual mouse and keyboard input, plus read-only state/file inspection to validate outcomes. No screenshot backdrop substitutes for the 3D scene. All five final camera thumbnails loaded at 320px; camera/FOV history and persistence were verified.

Testing infrastructure emitted SwiftShader/readPixels performance warnings and 26 failed requests to a sanitized placeholder `blob:http://localhost:4173/...` during computer-tool DOM capture. Actual UUID blob thumbnails were valid; the placeholder failures stopped when the same view/render actions were performed without that capture tool. These are recorded separately from application findings. Hardware-GPU performance and other browsers were not assessed.

The PR contains the full editor screenshot and rendered scene; its associated session supplies the complete WebM and detailed browser report. Native reference parity remains outside the authorized V1 boundary, with no fabricated pixel-diff result.

## Reference URLs

- https://lumion.com/news/lumion-2024-release
- https://lumion.com/tips-guides/real-skies-guide-2024
- https://a.storyblok.com/f/180614/x/1dd79904e4/real-skies-ui.mp4
- https://a.storyblok.com/f/180614/x/d6862fed7b/camera-control-schemes-sketchup-new-2024.mp4

See README for explicit source-frame measurements and implementation adaptations. Reference-video URLs are attribution references, not test deliverables.

## Honest limitations

- This browser V1 implements its own original procedural scene and a finite local editing workflow. It is not literal pixel parity, native Lumion interoperability, or the full commercial asset library.
- WebGL rasterization, planar pool reflection and procedural atmosphere; no native ray tracing/denoising, physically accurate caustics, HDRI import, global illumination baking, or commercial-quality foliage scans.
- Movie mode is visibly disabled. Native BIM/CAD import, movie/panorama output, team/cloud sync, materials beyond four stone finishes and native project formats are outside scope.
- Scene assets are bounded to the island and the library is four meaningful procedural kinds. Up to 100 movable objects and twelve cameras. Architecture itself is a fixed original model.
- Effects are global project settings, not independent per-camera effect stacks. Camera images are snapshots refreshed on capture/update; thumbnails are not persisted.
- Desktop first. Panels adapt to 1280×800 and scroll when needed; below 1000 px the desktop workspace remains usable with collapsed panels, but no separate mobile design is claimed.
- LocalStorage may be unavailable or cleared by browser policy. The status indicates save failure; JSON export is the portable backup. History remains in memory for the current session.
