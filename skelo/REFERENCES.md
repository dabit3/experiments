# Reference audit

## Coherent source

The official help article embeds a screenshot whose title explicitly says **SketchUp Pro 2023**. This Windows desktop screenshot is the visual baseline, even though the surrounding help article was updated in August 2026.

- https://help.sketchup.com/en/sketchup/user-interface
- https://images.ctfassets.net/yd21npj2ir9g/5b4dff15e18ee3b39cdd12/d31967bca9f7e25f473ccea057027c42/su-user-interface.png
- https://help.sketchup.com/en/sketchup/managing-dialog-boxes-windows

The original 1117 × 718 PNG was downloaded and visually inspected before implementation. It remains untracked under `.devin/clone-this/skelo/evidence/reference/`.

## Observed measurements and appearance

Coordinates measured by inspection of the official 1117 × 718 image:

- Title bar: approximately y=15–46, 31 px, light warm gray; compact 12 px system text.
- Menu bar: y=46–66, 20 px, black text and no pill backgrounds.
- Two toolbar rows: y=66–102 and y=103–138; light gray background, thin separators, approximately 24 px icons. Blue outlines with red arrows, yellow/tan fills on some tools. Selected tool has pale blue fill and a thin blue border.
- Drawing area: x=14–763, y=139–671. Blue sky to y≈306, gray ground, red/green/blue axes, thin outlined scale figure.
- Default Tray: x≈768–1102, approximately 334 px wide in this capture. Blue-gray title strip, shallow gray section headers, small black disclosure triangles; white content, thin gray rules, tabs and compact fields.
- Status bar: y≈673–700, 27 px. Tool instructions on left; Measurements and a plain recessed input on the far right.
- Right-side trays collapse independently. Official docs describe trays pinned to the right and panel title toggles.

## Implementation decisions and evidence boundaries

Skelo preserves desktop geometry, square controls, system typography, blue/red icon language, outlined 3D style, Default Tray hierarchy and Measurements placement. It adds a docked two-column Large Tool Set, scene tabs, and an original populated project as requested. At 1440 px the tray is 288 px and tool rail 64 px; at 1280 px the tray is 260 px. This is a reference-informed V1, not a measured pixel-identical reproduction.

Public documentation and the screenshot were accessible. The licensed native application, its modeling kernel and native interactions were not executed. Therefore behavioral details implemented from the assignment are explicit V1 decisions, not claims of observed native behavior. The clone-this audit/convergence process is used within this bounded demo scope; its full-native parity/zero-pixel gate remains unclaimed. No proprietary source, logos, component assets or project files are copied.

## Inventory

| ID | Requirement / verification |
|---|---|
| UI-01 | Desktop title, menus, dense toolbars, left tools, scene tabs, tray and status; browser review at 1440×900, 1920×1080 and 1280×800 |
| GEO-01 | Real outlined architecture, furniture, timber, glazing, roof seams, landscape and trees; visible WebGL scene and OBJ geometry |
| EDIT-01 | Selection, multi-selection, group/delete; model tests and browser golden path |
| EDIT-02 | Two-click rectangle and measured volume, parametric push/pull; bounds tests and visible edit |
| MAT-01 | Material painting, tags, shadow/time controls; persisted data and viewport updates |
| NAV-01 | Orbit/pan/zoom, standard views, named scene capture/recall |
| DATA-01 | Versioned validated persistence, undo/redo, JSON import/export and OBJ export |
| REL-01 | Clean install, lint, strict typecheck, production build, browser console and responsive layouts |
