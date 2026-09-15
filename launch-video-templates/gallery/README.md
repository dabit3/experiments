# Offline launch collection

Open `index.html` from an extracted gallery ZIP. All twenty MP4s, PNG posters,
styles and editing guides are local. No server, authentication, JavaScript,
autoplay, external fonts or CDN is required. Kinetic Type has an original beat;
the other videos are silent.

MP4 links download in supporting browsers and open in a player otherwise.
Safari may open the video when this page is viewed as a local file. Every
original is already included in the extracted gallery's `videos` folder.

## Populate from the source project

The checked-in gallery excludes rendered media and generated guide copies.
From `launch-video-templates`, run:

```sh
npm ci
node scripts/build-gallery.mjs
```

The script reads twenty manifests, copies `out/<id>.mp4` to `videos/<id>.mp4`
and `out/<id>-poster.png` to `posters/<id>.png`, generates `guides/<id>.html`
from the source READMEs, and rebuilds `index.html` using `directions.json`.
It checks all inputs before copying. Another media directory can be supplied:

```sh
node scripts/build-gallery.mjs /absolute/path/to/downloaded-media
```

For supplied attachment URLs, download the files first through authenticated
attachment tooling, then place them in that media directory with the names
above. Attachment URLs are not embedded in the offline page. To make fresh
media, run each template's documented render and poster/contact-sheet helper.

## Package

From the source project, after population:

```sh
node scripts/validate-media.mjs
node scripts/validate-gallery.mjs
mkdir -p out
zip -r out/devin-launch-gallery.zip gallery -x '*/.DS_Store'
```

The separate editable-source ZIP contains the Remotion sources and original
assets. Follow the collection README and individual editing guides to change
copy, timing, motion, crops or media. First-time dependency/browser downloads
require network access; previewing the extracted gallery does not.
