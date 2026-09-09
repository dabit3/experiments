# Wordle Seeded

Wordle with reproducible seeds and a hard mode. Five-letter words, six guesses,
a 2,315-word answer list and a 12,972-word valid-guess dictionary bundled as
JSON, and an answer that is chosen deterministically from `?seed=N` so any
puzzle can be replayed exactly.

- **Seeded puzzles** — `?seed=42` always gives the same answer (mulberry32 PRNG over the answer list). The seed badge in the header opens a dialog to jump to any seed, the next one, or a random one, and the URL stays in sync.
- **Physical + on-screen keyboard** — type letters, `Enter`, `Backspace` on the real keyboard or click the big on-screen keys.
- **Feedback** — tiles flip one-by-one to green / yellow / grey with correct duplicate-letter handling; keyboard keys recolour to the strongest state seen so far.
- **Validation** — unknown words shake the row and show a toast.
- **Hard mode** — toggle in the header (locked once a game has started). Green letters must stay in place and yellow letters must be reused; violations are rejected with an explanatory toast (`Guess must contain N`, `2nd letter must be O`).
- **Share** — copies a `Wordle Seeded #42 3/6` emoji grid (🟩🟨⬛) to the clipboard. A 2.4 KB subset of Noto Color Emoji is bundled so the preview renders the same on every OS.
- **Statistics** — games played, win %, current / max streak and a guess-distribution chart, persisted in `localStorage`.

No backend, no runtime network calls; everything is bundled.

## Run it

```sh
cd wordle-seeded
npm install
npm run dev        # http://localhost:5173/?seed=42
npm run lint
npm run build
```

## Computer-use skill

**Keyboard entry plus multi-step reasoning from colour feedback.** Devin plays
the game the way a person does: it types guesses on the physical keyboard,
reads the green / yellow / grey tiles after each flip, narrows down the
candidate words, and picks the next guess accordingly. Hard mode adds a
constraint-satisfaction layer — every revealed hint must be honoured, and the
app rejects guesses that ignore one.

## Browser test scenario

Recording: **https://app.devin.ai/attachments/571ff954-facb-4b35-84ef-c35e66fa5093/wordle-seeded-showcase.mp4**

Start from a clean profile (no `wordle-seeded:*` keys in `localStorage`) with
the dev server running.

| # | Step | Expected result |
|---|------|-----------------|
| 1 | Open `http://localhost:5173/?seed=42`. | Empty 6×5 board, seed badge shows `#42`, hard mode off. |
| 2 | Type `crane` on the physical keyboard and press Enter. | Tiles flip left-to-right; `C R N` grey, `A E` yellow; keyboard keys recolour to match. |
| 3 | Type an unknown word such as `zzzzz` and press Enter. | Row shakes, toast **Not in word list**, row stays editable. |
| 4 | Reason from the hints and keep guessing until the answer (`PEDAL`) is entered. | Row turns fully green and bounces; the Statistics modal opens showing 1 played, 100 % win, streak 1. |
| 5 | Close the modal, turn on the **Hard mode** switch, open `?seed=43`. | Board resets, switch stays on, a `HARD MODE` pill appears under the board. |
| 6 | Type `crane`, Enter. | `A` and `N` come back yellow. |
| 7 | Type `pedal` (ignores the `N` hint), Enter. | Row shakes, red toast **Guess must contain N**; the guess is not consumed. |
| 8 | Delete it and continue with guesses that honour every hint until `ZONAL` is found. | Every accepted guess reuses the revealed letters; final row goes green. |
| 9 | Open the Statistics modal (bar-chart icon). | 2 played, 100 % win, current streak 2, max streak 2, distribution updated. |
| 10 | Click **Share**, then paste into any text field. | Toast **Copied results to clipboard**; the pasted text is `Wordle Seeded #43 N/6` followed by the 🟩🟨⬛ grid of the game. |

## Project layout

```
src/
  App.tsx              URL/seed sync, keyboard listener, modals, share
  hooks/useGame.ts     game state machine, flip timing, stats persistence
  lib/words.ts         bundled dictionaries, answerForSeed, seed parsing
  lib/evaluate.ts      guess scoring, keyboard states, hard-mode rules
  lib/share.ts         emoji grid + clipboard
  lib/stats.ts         localStorage stats + hard-mode preference
  components/          Board, Keyboard, StatsModal, HelpModal, SeedDialog, Toast, Modal
  data/answers.json    2,315 answers
  data/allowed.json    10,657 extra valid guesses
  assets/wordle-emoji.ttf  🟩🟨⬛ subset of Noto Color Emoji (OFL)
```
