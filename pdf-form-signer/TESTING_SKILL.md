---
name: testing-pdf-form-signer
description: Run a real mouse-and-keyboard signing flow and verify PDF and audit downloads.
---

# Local setup

Run `npm install` when dependencies are absent, then `npm run dev` in `pdf-form-signer`.
Open localhost:5173 in Chrome. No backend or authentication is required.
Reload starts a fresh in-memory agreement, so do not reload mid-scenario.
Maximize Chrome before recording with `wmctrl -r :ACTIVE: -b add,maximized_vert,maximized_horz`.

## Devin Secrets Needed

None.

# UI execution

Use native mouse and keyboard for the four steps. Initials canvases are in the paper footers.
Capture the canvas again after the first initials stroke: its horizontal position can change
when the toolbar changes from “Draw with your mouse” to the stroke count.
For native date fields, click month, day and year segments separately and type each value.
Do not combine segment auto-advance with an extra Right press, which can skip a segment.
After each form section, visually verify values before proceeding.
Use multiple multi-point curved strokes for handwritten initials and signatures.
The audit list scrolls separately from the document; capture early validation events and
recent PDF events in separate full screenshots when all events cannot fit at once.

# Artifact verification

Verify the downloaded PDF with Python pypdf; inspect all page text, including the certificate.
Render every page with pymupdf and inspect images for signatures, initials, glyph errors,
and pagination. Do not assume a fixed page count: audit volume can add certificate pages.
Export audit JSON through the UI, then verify its document ID, timestamps, and event kinds.
