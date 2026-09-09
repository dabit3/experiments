# Chess Arena: checkmate a built-in engine

A full legal-move chess app where you play White against a deterministic,
built-in Black engine. Rules (castling, en passant, promotion, check,
checkmate, stalemate and the draw rules) come from
[`chess.js`](https://github.com/jhlywa/chess.js); everything else is a
Vite + React + TypeScript single-page app with no backend and no runtime
network calls (piece SVGs are bundled).

**Showcase recording:** _(link added after the showcase run)_

## Features

- Click-to-select + click-to-move **and** drag-and-drop for every piece.
- Legal targets are highlighted when a piece is selected (dots for quiet
  moves, rings for captures); the last move and a king in check are tinted.
- Promotion picker (queen / rook / bishop / knight) when a pawn reaches the
  last rank.
- SAN move list on the right, captured pieces + material balance above and
  below the board.
- `New game`, `Undo` (removes your move and the engine's reply), `Flip board`,
  `Copy PGN` (writes a full PGN with headers to the clipboard).
- Big result banner on checkmate, stalemate and the other draws.

## The engine

The engine is intentionally weak and completely deterministic so that every
game is reproducible from its seed:

1. **1-ply greedy capture** - if any capture is available, take the most
   valuable victim (P=1, N=3, B=3, R=5, Q=9).
2. **Otherwise** play the first legal move when all moves are sorted
   alphabetically by SAN.
3. Ties among equal-value captures are broken by a seeded PRNG
   (`mulberry32(seed * 1_000_003 + ply)`), so the same seed always yields
   the same game.

The seed lives in the URL (`?seed=7`, default `7`) and can be changed from
the header; `New game` keeps the current seed.

## Run it

```sh
cd chess-arena
npm install
npm run dev        # http://localhost:5173/?seed=7
npm run lint       # oxlint
npm run build      # tsc -b && vite build
```

## Computer-use skill showcased

**Long-horizon strategic play; reading a full board state from pixels every
move.** Devin has to look at the rendered board after each engine reply,
work out where all 32 pieces are, plan several moves ahead and then execute
that plan with real mouse input (both drag-and-drop and click-click), while
verifying each move landed via the SAN list.

## Browser test scenario (seed 7)

Against seed 7 the engine's replies are fixed, so this exact line always
appears:

```
1. h4 Na6  2. h5 Nb4  3. h6 Nxa2  4. hxg7 Nxc1  5. gxh8=Q Nxe2
6. Qxg8 Nxg1  7. Qh5 Ne2  8. Qgxf7#
```

| # | Step | Expected result |
|---|------|-----------------|
| 1 | Open `http://localhost:5173/?seed=7` in a maximised Chrome window. | Board in the start position, status `White to move`, seed field shows `7`. |
| 2 | Play `h4`, `h5`, `h6` by **dragging** the h-pawn one square at a time. | Each drop lands the pawn, the engine answers `Na6`, `Nb4`, `Nxa2` within half a second and the moves appear in SAN on the right. |
| 3 | Click-click `hxg7` (h6 -> g7). | Pawn captures; engine replies `Nxc1`; captured pieces appear above/below the board. |
| 4 | Click-click the g7 pawn -> `h8` (captures the rook). | The promotion picker opens; choose **Queen**; move list shows `gxh8=Q`; engine replies `Nxe2`. |
| 5 | Click-click `Qxg8`, `Qh5`, `Qgxf7#`. | After `Qgxf7#` the big **Checkmate!** banner appears and the status reads `Checkmate! - White wins`. |
| 6 | Click **Copy PGN**, then focus the address bar and paste (`Ctrl+V`). | The pasted text is the full PGN (`[Event "Chess Arena"] ... 8. Qgxf7# 1-0`). Press `Esc` to discard it. |
| 7 | Click **New game**, drag `e2 -> e4`, wait for `Na6`, click **Undo**. | Both `e4` and the engine's reply disappear; the board is back to the start position and `Undo` is disabled again. |

The showcase also exercises **Flip board** (the board turns so Black is at
the bottom and the coordinates update).
