# Devin Creative

## Architecture

This repository contains a native macOS suite with twelve editors and a launcher. The package has no third-party dependencies.

`Sources/DevinCore` contains the document model, validation, history, animation channels, vector commands, sequence timing, and SVG serialization.

`Sources/DevinStudio` contains the AppKit lifecycle, SwiftUI interfaces, native editor surfaces, renderers, exporters, and integration checks.

Pixel, Form, Press, Motion, and Cut have independent workspaces and native menu structures. The other editors retain the original studio interface.

Each generated app contains the same executable. The `DevinTool` entry in its `Info.plist` selects the editor.

`NativeEditing.swift` contains raster operations, vector geometry, and CoreText layout. `MediaEngine.compose` supports explicit clip positions and overlapping tracks.

`Animation.swift` contains independent property channels and work-area timing. The renderer evaluates legacy and current animation through the same interface.

`ParityLedger.swift` records individual features, missing behavior, implementation paths, reference links, and acceptance gates for all twelve apps.

The ledger is an audit baseline, not an exhaustive feature denominator. Unlisted features are not presumed supported. Local tests do not establish Adobe parity.

A `verified` parity status requires version-pinned differential evidence. The current ledger records no verified parity claims.

`PixelToolRail.swift` defines grouped tools. `PixelRasterTools.swift` and `RasterAlgorithms.swift` implement the new local raster operations.

The sampled healing algorithm uses tone correction. It does not match Photoshop healing diffusion. The CPU region tools have a 16-megapixel limit.

## Development

Run these commands from the repository root:

- Build the executable: `swift build`
- Open the launcher: `swift run DevinStudio`
- Open one editor: `swift run DevinStudio --tool pixel`
- Run the model tests: `swift test`
- Run all verification: `bash scripts/verify.sh`
- Print the parity summary: `swift run DevinStudio --parity-summary`
- Print the JSON parity ledger: `swift run DevinStudio --parity-report`
- Build the app bundles: `bash scripts/build-apps.sh`
- Open the packaged launcher: `open -n "dist/v0.4/Devin Studio.app"`

The build requires Xcode and macOS 14 or later. The integration checks require a macOS graphical session and a Metal-capable GPU.

The integration checks create synthetic media and exported files in a unique temporary directory. The command prints its location.

`ProfessionalVerification.swift` exercises the original creative workflows. `AuditVerification.swift` covers regressions, masks, clipboard operations, work areas, imports, camera persistence, and web errors.

The verification command captures all twelve workspaces. Media and PDF workspaces use generated test assets. Clipboard tests use a private pasteboard.

The app bundles use ad-hoc signatures for local use. The build does not notarize or install the apps.

The v0.4 patch releases go into `dist/v0.4`. `DEVIN_DIST` overrides this destination. The user keeps only the newest packaged release.

`DocumentWorkspace.swift` owns document tabs for Pixel, Form, Press, Folio, and Code. A tab owns its session, history, URL, and dirty state.

New/Open reuse the matching workspace. Closing a tab does not close other documents. Closing the window checks every dirty or busy tab.

`GroupedToolControl.swift` owns native toolbar click, hold, triangle, and right-click behavior. Its flyouts use real `NSMenu` items.

## Parity repair loop

Run one comparison cycle with `bash scripts/parity-loop.sh 1`.

Run automatic repairs with `bash scripts/parity-loop.sh 5 "$PWD/.devin/parity-repair.sh"`.

The loop defaults to the `workspace` scope. It runs build checks, gate-model tests, document-tab interactions, and grouped-menu contracts.

Use `bash scripts/parity-loop.sh 1 "" full` for the complete local suite after concurrent work is stable.

Workspace reports use `.build/parity-cycles/latest-workspace.json`. Full-suite reports use `latest.json`. Each cycle also has its own artifact directory.

Another agent owns the Pixel tool engine and its tests. This worker owns only document tabs, grouped-menu controls, and loop infrastructure.

Broad automatic repairs are paused. Worker file permissions restrict edits to DocumentWorkspace.swift, GroupedToolControl.swift, and WorkspaceBehaviorVerification.swift.

The worker uses the normal CLI login and project-local permissions. An alternate `--config` path can trigger separate onboarding.

Exit 0 means the declared scope passed all evidence gates. Exit 1 means a local failure. Exit 2 means unresolved parity. Exit 3 means no repair progress.

The final cycle always verifies before stopping. The loop does not repeat unchanged failures indefinitely.

Reference contracts live in `Tests/ReferenceContracts`. Documentation-derived expectations are not observed Adobe output. Do not fabricate reference captures or weaken the gate.

The current scope remains unapproved and incomplete. Passing local checks does not complete the full parity request.

## Project conventions

Use four-space indentation. The repository has no configured formatter gate.

Keep shared document behavior in `DevinCore`.

Add regression tests for changes to the document model.

Keep the feature inventory consistent with the implemented controls and exports.

Use `StudioSession.mutate` for document changes that require undo.

Use a local document copy inside mutation closures to avoid overlapping Swift access.

Keep image and PDF data inside the project. Media clips reference local source files by absolute URL.

Write exports to temporary destinations before replacement. Keep batch exports in a new subfolder.

Set `AVAssetExportSession.timeRange` to the full sequence range. Implicit export ranges can shorten overlapping compositions.

Keep the original source files unchanged.

Do not overwrite an executable while its app runs. Close the app or use a new build destination.

Use Apple frameworks before adding a dependency.

Remap text-frame identifiers when copying pages. Remove incoming links when deleting a linked frame.

Do not read the system clipboard during automated tests. Use `NSPasteboard.withUniqueName()` for clipboard checks.

Do not claim Creative Cloud feature parity or pixel identity without verification against the original apps.

## Project compatibility

The project format is JSON with the `.devin` extension. New saves use schema version 3.

The loader accepts versions 1 and 2. Optional fields preserve compatibility with existing layers and media.

Legacy bundled keyframes become independent channels when edited. The migration preserves their evaluated poses and interpolation.

Version 3 prevents earlier app releases from silently discarding the new editing properties.

## Visual references

The v0.2 reference baseline used Photoshop 27.10.0 and After Effects 26.3.0. The other workspace references came from public Adobe documentation and tutorials.

Direct Adobe screenshot comparison requires authorized screen capture or supplied screenshots. Public workspace descriptions are not pixel-level specifications for those releases.

## Current limits

The suite does not support native Adobe project formats, cloud collaboration, Adobe plug-ins, or the complete tool sets of the original apps.

Pixel supports hard and soft brushes, selection shapes, editable masks, transparency, and blend modes. Advanced healing, automatic selections, and Smart Objects remain absent.

Vector paths support cubic curves and shape operations. The suite does not provide complete Illustrator file compatibility.

Page exports use RGB color and PDF points. They do not provide a CMYK prepress workflow. Paragraph styles are presets, not linked style definitions.

Motion supports independent transform channels and work areas. Expressions, parenting, video/audio footage layers, camera rigs, and advanced effects remain absent.

Cut and Sound support overlapping clips and audio mixing. Advanced transitions, grading, recording, spectral editing, and proxy workflows remain absent.

Space supports primitives, materials, and a saved export camera. Mesh editing, UV tools, and node materials remain absent.

The HTML preview uses a nonpersistent WebKit data store and a reserved `.invalid` origin. External assets require a network connection or embedded data.

The preview console is bounded. It is not a full JavaScript debugger or a site deployment system.

## Pixel tool regression checks

Run `swift run DevinStudio --verify-pixel-tools` for the native Pixel tool checks.
The command creates synthetic images and uses a private pasteboard. It prints the directory that contains its artifacts.
`pixel-tool-audit.json` records results for each implemented tool. Disabled tools do not count as implemented tools.

`StudioSession.clearSelection` clears selected pixels or mask regions. `deleteSelection` removes layers explicitly.
Pixel strokes commit on mouse-up after the target, session, tool, and selection pass validation.
Empty selections, zero opacity, and zero effect strength do not create undo entries.
`VectorPathEditor.moveNode` keeps the incoming and outgoing handles attached to their anchor.

Do not run another repair worker against these source files during a build or tool audit.
Before replacing a packaged app, check that its executable is not running.
