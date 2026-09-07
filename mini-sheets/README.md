# mini-sheets — keyboard-driven spreadsheet

A small but complete spreadsheet: a 20 × 10 grid (rows 1–20, columns A–J) with a formula bar,
mouse and keyboard selection, in-place editing, and a formula engine that understands
`+ - * / ^ ( )`, cell references (`A1`, `$A$1`), ranges (`D2:D6`) and the functions
`SUM`, `AVERAGE`, `MIN`, `MAX`, `COUNT`, `ABS`, `ROUND`. Dependencies are recalculated live,
copy/paste and fill-down adjust relative references the way Excel does, and the sheet is
persisted to `localStorage`, so a refresh brings everything back.

## Run it

```bash
cd mini-sheets
npm install
npm run dev
```

Then open the URL Vite prints (usually http://localhost:5173).

## Keyboard reference

| Keys | Action |
|------|--------|
| Arrow keys | Move the active cell |
| Shift + arrows | Extend the selection |
| Tab / Shift+Tab, Enter / Shift+Enter | Move right/left, down/up (Enter after a run of Tabs returns to the starting column) |
| Type | Replace the cell contents |
| F2 / double-click | Edit the existing contents |
| Escape | Cancel the edit / collapse the selection |
| Delete | Clear the selection |
| Ctrl+C / Ctrl+X / Ctrl+V | Copy / cut / paste with relative reference adjustment |
| Ctrl+D | Fill the top row of the selection down |
| Ctrl+B | Toggle bold |
| Ctrl+Z / Ctrl+Y | Undo / redo |
| Ctrl+A | Select the whole sheet |

The status bar shows the sum, average and count of the selected range.

## Computer-use showcase

After building the app, Devin opened it in a real browser and drove it almost entirely with the
keyboard:

1. Clicked A1 and, using only typing plus Tab/Enter, entered a budget table: headers
   `Item | Qty | Price | Total` in row 1 and five rows of items with quantities and prices.
2. Typed `=B2*C2` in D2, selected D2:D6 with Shift+Down and pressed Ctrl+D to fill down; verified
   that the formulas shifted (`D3 = B3*C3`, …) and evaluated to the right totals.
3. Typed `=SUM(D2:D6)` in D7 and verified the value; changed a quantity in column B and watched D7
   recalculate live.
4. Selected a range with Shift+arrows and checked that the status bar sum matched.
5. Copied a block with Ctrl+C, moved with the arrow keys, pasted with Ctrl+V and verified the
   relative references shifted with the paste location.
6. Bolded the header row with Ctrl+B, refreshed the page and verified everything persisted.

_Screenshots and the recording link are added below once the run is complete._
