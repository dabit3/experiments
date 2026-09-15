# Keystone

A native macOS structural design studio for preliminary truss studies. Shape a bridge, compare independent load cases, assign section properties, screen member resistance and deflection, and export a reproducible engineering record. The workspace pairs an ink-blue project rail with an ivory drafting sheet, copper tension members, native result tables and a dedicated study-check panel.

## Version 2

- Independent named load cases with horizontal and vertical nodal forces, a case factor, optional member self-weight, duplication and undoable removal.
- Section catalog with computed area and inertia, custom section input, Euler buckling screening, adjustable effective length and resistance divisor, and an explicit **incomplete** state when compression inertia is missing.
- Vertical serviceability and material budget checks with user-defined criteria.
- Drawing and Schedules workspaces; selectable member/joint tables, demand sorting, compression/tension/over-limit filters and CSV export.
- Precise coordinate/load/section fields, zoom, pan, Fit, support reaction labels and adjustable deformation magnification.
- Project notes, direct Save, Save As, file-change status, recoverable incomplete drafts and automatic migration of version 1 documents.

## Run

Prerequisites: macOS 14 or newer, Xcode with Swift 6.0+ selected by `xcode-select`. Verified on Apple Silicon macOS 26.5.2 with Xcode 26.6 / Swift 6.3.3. No packages, generator, network, account, signing identity, or simulator is required.

```sh
cd native-demos/macos/keystone
bash scripts/build.sh
bash scripts/run.sh
```

This reproducible Swift Package builds a native SwiftUI/AppKit executable, creates `dist/Keystone.app`, generates its original icon with AppKit, and signs the bundle locally with an ad hoc signature. It is not notarized or an App Store release. Open `Package.swift` in Xcode to browse/debug, or run the scripts for the complete `.app` bundle. The compiled artifact uses the host architecture.

## The desk

- **Design library:** Warren (3 m rise), Highline (4.5 m), and Low profile (1.5 m), each with a 12 m span, nine joints, fifteen members, a left pin, a right Y roller and a central 100 kN downward load. Loading an example is undoable.
- **Select:** click any member or joint to inspect it. Drag a node to reshape the span; coordinates snap to a 0.5 m grid. Use the coordinate fields for exact values without snapping. Dragging onto an existing joint or collapsing a member is rejected. In deflection view, nodes can be inspected but geometry edits require Geometry or Stress view.
- **Node:** click empty canvas to add a joint. **Member:** click two distinct joints to connect them. Duplicate connections are rejected. Crossed members are not connected unless they share a node.
- **Load:** click a joint to place 100 kN downward in the active case, then edit horizontal and vertical fields or clear that case's load. Positive input is rightward/downward; negative is leftward/upward. Choose free, pin (X/Y fixed), or roller (Y fixed) support. Reports and tables use conventional +X right / +Y up signs.
- **Member inspector:** inspect signed force/stress, section area, minimum inertia, effective-length factor K and resistance screening. Choose a catalog section or type custom properties. Editing area clears the section name and inertia because area alone cannot determine inertia. Inertia 0 means unspecified. Remove a member to test a mechanism.
- **Run analysis:** solve and enter stress view. Subsequent edits recompute the active case. Copper is tension; blue is compression; gray is near-zero force. Labels are signed MPa. Opacity reflects axial yield utilization; geometry-view beam width reflects section area.
- **Deflection:** choose 1×, 10×, 50×, 100×, 250× or 500× magnification, with the original geometry dashed. Large magnification may move geometry outside the view; reduce magnification, zoom out or pan. Numeric displacement remains physical mm.
- **Pan / zoom / Fit:** drag with Pan to reposition the drawing, use +/− to change zoom (50–300%), or Fit to restore the automatic geometry framing. Grid dots coarsen when zoomed out; node snapping remains 0.5 m.
- **Support reactions:** toggle reaction labels in kN; full Rx/Ry values also appear in the selected-joint inspector and joint schedule.
- **Material:** steel (E 200 GPa, yield 250 MPa, 7,850 kg/m³, $2.40/kg) or aluminum (E 69 GPa, yield 240 MPa, 2,700 kg/m³, $5.20/kg). Raw-material budget and member mass are calculated from actual lengths and areas.
- **Assign section to all:** apply a catalog section to every member in one undoable edit. The first successful Run analysis establishes a displacement reference shown under Checks. Case/load changes, example/open reset it; geometry and section changes can be compared against it.
- **Schedules:** select a member/joint row to edit it in the inspector. Members can be sorted by descending demand or length, or ascending ID; filter tension, compression or over-limit results. An asterisk on a compression demand ratio means buckling is unchecked.
- **Typed fields:** Return or leaving a field applies a valid number. Out-of-range/non-numeric input keeps the previous model value and shows an inline message. Invalid geometry is rejected with an alert.
- **Undo / redo:** toolbar or ⌘Z / ⇧⌘Z, with up to 100 design edits. View preferences and file operations are not undoable. The history is session-only.

The drafting window has a 1120×720 minimum size. Both sidebars scroll while the header, canvas controls and status footer stay visible. Coordinate bounds are ±100 m. Documents support up to 100 nodes, 300 members and 12 load cases. Session history retains 100 edits.

## Cases and study criteria

The service case uses the original document's nodal loads. New empty cases start with no loads. Duplicating a case copies its current loads, factor and self-weight switch; subsequent edits are independent. Changing active case does not combine or envelope cases. The service case can be renamed but not deleted. Removing a node removes its loads from every case; undo restores them.

Case factors (0.01–10) multiply **both** explicit nodal loads and member self-weight. Self-weight uses actual member length, area, material density and g = 9.80665 m/s², split equally between each member's end nodes. It is a lumped-load approximation, with no transverse bending calculation. Load arrows display the resulting factored total.

The SHS catalog spans 80×80×4 to 200×200×10 mm. For outer side B and wall t, A = B² − (B−2t)² and I = (B⁴ − (B−2t)⁴)/12, converted to cm²/cm⁴. These ideal sharp-corner properties are **not manufacturer-certified values**. Custom inertia must represent the least relevant axis; effective length KL assumes adequate bracing over that length.

The Checks panel screens each member against:

```text
Pcr = π²EI / (KL)²
compression capacity = min(A fy, Pcr) / γ
tension capacity = A fy / γ
demand / capacity = |axial force| / capacity
```

The user-selected resistance divisor γ defaults to 1.5 (range 1–5); it is not a design-code factor. Missing inertia in a compressed member leaves Euler unchecked; the model explicitly reports **incomplete** instead of claiming a passing resistance check. The displayed numeric demand ratio then covers yield only.

Vertical serviceability compares max |Uy| to the horizontal extent of the model / a user-selected ratio, default 360 (range 50–2,000). With zero horizontal extent the span check is unavailable. This geometric extent can include overhangs; it is not automatically the clear support span. Material budget includes raw material only. These screens are user-defined study criteria, not regulatory approval.

## Save, reopen and export

The working design automatically persists to `~/Library/Application Support/Keystone/Workspace.keystone`. Valid saved geometry, materials, support constraints and loads are restored on relaunch. Analysis is recomputed when requested; selection, view, undo history and comparison reference are not persisted.

- **Project details:** edit title and design notes; both persist, and notes appear in the engineering report.
- **Save / ⌘S:** choose a `.keystone` path the first time, then write directly to that file. **Save As / ⇧⌘S:** choose a new copy. The header distinguishes local autosave from file changes. A restarted workspace is untitled until explicitly opened or saved; the previous file path is not assumed.
- **Open / ⌘O:** read a `.keystone` or JSON document using the native open panel. Files are versioned and validated before replacing the current design.
- **Export → Engineering report:** produces a standalone HTML report with project notes, active-case settings, vector diagram, sections, forces, stresses, yield/demand ratios, nodal loads/displacements, support reactions, study criteria, numerical residual and assumptions. Requires a solvable design.
- **Export → Vector drawing:** choose an SVG path. Includes geometry, nodal loads, support symbols, dimensions in the model and solved member stress labels when available. All assets are inline vector markup; no external requests.

- **Export → Member & reaction schedule:** writes CSV with project/case metadata, section properties, signed forces/stresses, demand ratios, nodal loads and reactions. Metadata strings are quoted and prefixed with an apostrophe to prevent spreadsheet formula interpretation. Export files contain the active case only.

Export locations are user-selected. An invalid file shows an alert and leaves the current design intact. Geometrically valid but unstable designs, empty drafts and incomplete member arrangements can be saved and restored; analysis still requires a stable connected system. Files are capped at 2 MB on decode. Version 1 documents migrate to version 2 with zero horizontal loads, one service case, self-weight off and unspecified inertia, preserving the original axial analysis. Version 2 files cannot be opened by the original version 1 app. No undo history or display settings are embedded in design files.

## Solver and modeling scope

For member direction cosines `c,s`, length `L`, area `A` and modulus `E`, the solver assembles

```text
b = [-c, -s, c, s]
k = (EA / L) bᵀb
K_free u_free = F_free
stress = E ((u_b - u_a) · [c,s]) / L
force = stress A
reaction = Ku - F at constrained degrees of freedom
```

Reduced stiffness is solved with Cholesky factorization. A non-finite pivot or a diagonal remainder ≤ `1e-10` times the largest original free diagonal is rejected as a mechanism or ill-conditioned system. A singular result clears all stresses/displacements; no fallback colors or fabricated solution is displayed. No artificial stabilizing springs are added. Fixed degrees of freedom are exactly zero. Free-degree equilibrium residual is included in reports.

This is **preliminary linear, small-displacement, 2D pin-jointed truss analysis**, with homogeneous linear-elastic material and nodal forces. Euler screening is ideal elastic buckling only. There is no distributed live-load conversion, bending, local/inelastic buckling, joint capacity, out-of-plane stability model, support settlement, dynamics, geometric nonlinearity, load-combination envelope or design-code check. A green study check is not a safety certification or permission to build. Costs are illustrative raw-material estimates only; material defaults are examples, not procurement specifications.

## Checks

```sh
bash scripts/check.sh
# Separately:
xcrun swift-format lint --strict --recursive Sources Tests Package.swift scripts/Icon.swift
swift test
bash scripts/build.sh
```

Native formatting/lint is supplied by Xcode's `swift-format`; no external linter is required. Swift compilation provides type and concurrency checks.

Fifteen XCTest cases cover the original analytic displacement/force, equilibrium, instability, persistence and history tests, plus horizontal-load and self-weight equilibrium, independent cases and factors, ideal SHS properties and Euler/K² scaling, incomplete-check semantics, actual version 1 JSON migration, version 2/draft round trips, invalid cases/sections, and signed export schedules.

### Native UI demonstration

1. Load Warren, Run analysis, inspect computed forces and the incomplete buckling check.
2. Assign SHS sections; compare resistance/deflection and material cost in Checks.
3. Duplicate a case, rename it, add a horizontal/uplift load, set its factor and enable self-weight. Switch cases and confirm independent results.
4. Use precise coordinate and section fields; reject an invalid value, drag a joint and undo. Remove a diagonal and recover from the unstable warning.
5. Inspect sorted/filtered member schedules and joint reactions. Zoom/pan/Fit; inspect magnified deflection.
6. Edit project notes; Save, modify, Save As/reopen and export HTML, SVG and CSV.
7. Quit/relaunch and confirm cases, sections, notes and active case persist. Check compact and fullscreen layouts.

UI verification is performed through the native `.app` window, with an annotated recording and full screenshots delivered separately rather than committed to the repository.
