# Devin on Mac — comparison gallery

20 / 20 directions completed. Every default film is silent H.264, 1920 × 1080,
30 fps, 1,200 frames and 40 seconds. The collection preserves every producer's
source files exactly. No samples were re-rendered during integration.

## Open the portable ZIP

Extract the entire ZIP, preserving its folders. Open `index.html` in a modern
browser. The package uses a classic script and relative media paths; no account
or external media request is needed to watch downloaded films. If your browser
restricts local fonts or media, run this from the extracted gallery folder:

```sh
python3 -m http.server 8000 --bind 127.0.0.1
```

Then open `http://127.0.0.1:8000` on that same computer. Python is only needed for
this optional local serving method. Nothing is deployed or published.

Search by number, name or motion. Select a poster to open the expanded player.
Use the native playback/full-screen controls; Previous and Next compare adjacent
directions. Tab navigates controls, Enter activates them, and Escape closes the
dialog and returns focus to its original poster. Videos never autoplay.

Each direction has MP4, poster, contact-sheet and complete editable-props downloads.
The expanded view includes source/render instructions, direction-specific control
documentation, measured verification and a text transcript. `sources/` contains
the original template directory copies for reference. A full repository checkout
with the shared scaffold is needed to render them.

## Work from the repository

Use Node 22.12+, npm, Python 3.9+ and FFmpeg. From `product-launch-videos/`:

```sh
npm ci
npm run assets:setup -- /path/to/shared-assets.zip
npm run assets:check
```

`gallery-manifest.json` is the rehydration index. Download every `video_url`,
`poster_url` and `contact_sheet_url` with authenticated Devin attachment tooling
(for example `download_attachment` with the URLs in batches). Do not curl the
attachment service or use these auth-only URLs as video sources.

Preserve downloads as `<download-root>/<attachment-uuid>/<filename>`. The builtin
download tool already uses this layout. Then:

```sh
npm run gallery:hydrate -- /path/to/download-root
npm run gallery:verify
npm run gallery:comparison
npm run gallery
```

The manifest's producer branches must be fetched before verification; for example:

```sh
node --input-type=module -e '
import fs from "node:fs";
import {execFileSync} from "node:child_process";
const m = JSON.parse(fs.readFileSync("gallery-manifest.json", "utf8"));
execFileSync("git", ["fetch", "origin", ...m.templates.map(t => t.branch)], {stdio: "inherit"});
'
```

The media installer copies final artifacts into ignored `public/renders/<slug>/`.
The catalog generator discovers each independent descriptor, verifies its identity
and metadata, and exports default props. The browser bundle does not include any
template renderer or source footage. The brand font is copied from the installed
original bundle into ignored `public/brand/`; a load failure is displayed rather
than silently substituting typography.

## Edit and render a direction

Change its `src/templates/<slug>/config.ts`, or edit its downloaded complete
`default-props.json`. Keep the enclosing `{"config": ...}` object; props are not
deeply merged.

```sh
npm run render -- --template 01-swiss-grid-in-motion
npm run render -- --template 01-swiss-grid-in-motion --props /path/to/edited-props.json
npm run still -- --template 01-swiss-grid-in-motion --frame 450
```

Each directory's README explains its particular motion inputs and source framing.
The shared contract is documented in `TEMPLATE-CONTRACT.md`; common source
attribution is in `MEDIA-ATTRIBUTION.md`, with direction-specific maps in each
`attribution.json`.

## Check and rebuild the portable package

```sh
npm run lint
npm run typecheck
npm test
npm run assets:check
npm run templates:list
npm run gallery:verify
npm run gallery:comparison
npm run gallery:package
```

`gallery:verify` independently checks every producer directory against its exact
remote commit; only its assigned directory may differ from the foundation.
It measures all 20 videos with ffprobe, counts decoded frames, decodes every MP4
fully with FFmpeg, decodes every poster/contact sheet, and records file sizes and
SHA-256 hashes. Missing or failed entries stay in the manifest with `status: failed`
and an error; verification exits nonzero. Packaging requires all expected entries.

`gallery:comparison` builds a numbered sheet from the actual final posters with
the supplied Regular font. `gallery:package` builds the static frontend and creates
`out/devin-on-mac-gallery.zip`, checking the ZIP CRCs. Move an existing
`out/portable-gallery/` aside before packaging again; it will not be overwritten.
Generated and original binaries are ignored. No public deployment is configured.

## Evidence and limits

- All 20 final videos were independently verified at integration, with no blank
  or corrupt poster visible in the combined comparison sheet.
- Producer sessions reported full default renders and visual review. Eighteen
  also reported a complete alternate-configuration render. Directions 13 and 17
  checked their alternate edits with metadata and stills only.
- This gallery was checked through build, source/data and media integrity checks;
  browser interaction testing is reserved for the parent workflow.
- iPhone/iPad examples are authentic screenshots from separate sessions. Neither
  supplied recording shows a Simulator. Web QA remains explicitly labeled.
- Original report counts are preserved; fine report text needs full-size viewing.
  Captions, crops, font sizes or timings changed later require renewed inspection.
- Optional sound accents in direction 12 were not exercised. Samples are silent.
- Attachment URLs require organization access for rehydration. Once downloaded,
  the portable gallery has no network dependency for its media or font. GitHub
  source links and the product CTA are optional external navigation.
