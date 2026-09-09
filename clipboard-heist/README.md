# Clipboard Heist: a spy mission built on copy and paste

A five-objective spy puzzle where **every step must go through the clipboard**.
Nothing can be typed into the mission fields — they only accept pastes — so the
only way to open the vault is to select, copy, paste, paste-as-plain-text, and
put each payload into the right target.

Built with Vite + React + TypeScript. Fully client-side, no backend, no network
calls at runtime; all mission data is bundled.

## Run it

```sh
cd clipboard-heist
npm install
npm run dev      # http://localhost:5173
npm run lint     # oxlint
npm run build    # tsc -b && vite build
```

## Computer-use skill showcased

**Clipboard operations:** mouse text selection + Ctrl+C, select-all inside a
focused region (Ctrl+A) + Ctrl+C, Ctrl+V into the correct target, and
paste-as-plain-text (Ctrl+Shift+V) where a normal rich paste is rejected.

### How the clipboard is wired

- Copy buttons use `navigator.clipboard.writeText` / `navigator.clipboard.write`
  (rich `text/html` + `text/plain`) and fall back to `document.execCommand('copy')`
  when the async API is unavailable or throws.
- Every paste target reads from the `paste` event's `clipboardData`, so pasting
  works even when the site is denied clipboard *read* permission.
- The **Clipboard history** sidebar records everything copied through the app's
  own copy buttons (the system clipboard only ever holds the latest one) and can
  put any older entry back with **Copy again**.
- **Peek** in the sidebar tries `navigator.clipboard.readText()`. If the browser
  blocks it, a permission helper explains that Ctrl+V still works and how to
  re-enable reading in Chrome's site settings.

## The heist

| # | Objective | Clipboard move | Pass condition |
|---|-----------|----------------|----------------|
| 1 | **Intercept** | Select the 12-char access code in the monospace transmission with the mouse, Ctrl+C, Ctrl+V into the keypad | Keypad accepts `Q7X2KM9ZP4LR` (the revoked `MB3T7QLW2ZNX` is rejected). Reveals vault key **ALPHA** |
| 2 | **Manifest** | Click inside the table region, Ctrl+A (selects the whole table only), Ctrl+C, Ctrl+V into the exfil textarea | Parser reports **7 rows arrived · 5 columns · tab-separated** and "Manifest intact". Reveals **BRAVO** |
| 3 | **Dead drop** | Copy the styled message, Ctrl+V into the scanner → **REJECTED** (clipboard carried `text/html`); Ctrl+Shift+V → **ACCEPTED** | Scanner shows ACCEPTED with the plain message. Reveals **CHARLIE** |
| 4 | **Callback** | The handler wants ALPHA, which was copied three objectives ago and is no longer on the system clipboard. Use **Copy again** on the ALPHA entry in Clipboard history, Ctrl+V into the reply field | "IDENTITY CONFIRMED" |
| 5 | **Vault** | Re-copy each key from history and paste into the slots in the required order BRAVO → CHARLIE → ALPHA (each slot unlocks after the previous one) | **Vault opened** screen with copy/paste/rejected stats |

## Browser test scenario

Performed by Devin with real mouse and keyboard in a maximised Chrome window
(no scripted automation).

1. Open `http://localhost:5173`. Expect objective 1 *Intercept* with an empty
   keypad and an empty Clipboard history.
2. Drag-select `Q7X2KM9ZP4LR` in the transmission, press Ctrl+C, click the
   keypad field, press Ctrl+V. **Expected:** keypad slots fill, status
   `ACCESS GRANTED`, transmission line is burned, ALPHA key card appears.
3. Click **Copy ALPHA key** (history shows 1 entry) then **Next objective**.
4. Click inside the agent manifest, press Ctrl+A then Ctrl+C.
   **Expected:** "7 rows selected", then "Copied 7 rows as tab-separated text".
   Click the exfil textarea, press Ctrl+V. **Expected:** `7 rows arrived`,
   `5 columns`, `tab-separated`, "Manifest intact", BRAVO key card appears.
5. Click **Copy BRAVO key**, **Next objective**.
6. Click **Copy styled message**, click the dead-drop scanner, press Ctrl+V.
   **Expected:** `REJECTED — clipboard carried text/html …`, editor wiped,
   Rejected counter increments. Press Ctrl+Shift+V. **Expected:**
   `ACCEPTED — clipboard carried text/plain only`, CHARLIE key card appears.
7. Click **Copy CHARLIE key**, **Next objective**.
8. In Clipboard history click **Copy again** on *Vault key ALPHA*, click the
   reply field, press Ctrl+V. **Expected:** `IDENTITY CONFIRMED`. Click
   **Next objective**.
9. For each vault slot in order: **Copy again** on BRAVO → Ctrl+V into slot 1,
   **Copy again** on CHARLIE → Ctrl+V into slot 2, **Copy again** on ALPHA →
   Ctrl+V into slot 3. **Expected:** each slot shows ENGAGED and unlocks the
   next; after the third the **Vault opened** overlay appears listing the three
   keys in order and the copy/paste/rejected stats.

Recording: _to be added after the showcase run_

## Project layout

```
clipboard-heist/
├── index.html
├── public/favicon.svg
└── src/
    ├── App.tsx                 # mission state, history, stats, stage routing
    ├── data.ts                 # codes, keys, manifest rows, rich snippet
    ├── lib/clipboard.ts        # writeText/write + execCommand fallback, readText
    └── components/
        ├── PasteField.tsx      # paste-only input (typing is refused)
        ├── CopyButton.tsx
        ├── KeyReveal.tsx       # vault key card shown after each objective
        ├── HistoryPanel.tsx    # clipboard history + Peek permission helper
        ├── StageIntercept.tsx  # 1: select + copy + paste
        ├── StageManifest.tsx   # 2: Ctrl+A in region, TSV copy, TSV parser
        ├── StageDeadDrop.tsx   # 3: rich paste rejected, Ctrl+Shift+V accepted
        ├── StageCallback.tsx   # 4: re-copy from history
        ├── StageVault.tsx      # 5: three keys in order
        └── VaultOpened.tsx
```
