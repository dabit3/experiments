# Escape Room: six chained puzzles in one page

A single-page point-and-click escape room set in a Victorian study after dark.
The whole scene is CSS + inline SVG; there is no backend, no network call at
runtime and no external asset (fonts are bundled from `@fontsource`). Six
puzzles unlock strictly in order, and every answer is somewhere in the room —
you just have to notice the affordance that exposes it. A **Casebook** panel on
the right tracks the timer, the six objectives, a running journal, the three
hints, Reset, and the items found so far.

| # | Puzzle | Hidden affordance |
|---|--------|-------------------|
| 1 | **Brass lockbox** — four colour dials | Read the four stripes of the painting top-to-bottom (amber, teal, crimson, violet). |
| 2 | **Desk lamp + typewriter** — a 3-letter word | The lamp blinks Morse (`− − −  · − −  · − · ·` → **OWL**); the lamp's inspect view records the blinks on a paper-tape strip and the wall chart decodes them. |
| 3 | **Corkboard note** — safe combination | The card is written in "lemon ink": the text only appears after hovering it for half a second. |
| 4 | **Rug → key → drawer** | Drag the rug aside to reveal a brass key, then drag the key onto the locked desk drawer. |
| 5 | **Embroidered sampler** — Caesar cipher | The drawer holds a shift dial; turn it to shift 7 to read `THE LETTER ON THE DESK NUMBERS THE BOOKS`. |
| 6 | **Bookshelf** — click order | Roman numerals are tucked into the margins of a long, *scrollable* letter (I Cartography, II Poetry, III Astronomy, IV Alchemy, V Botany). |

When the shelf accepts the order, the bolt on the door draws back. Clicking the
door swings it open and the escape overlay shows the final time; the Casebook
timer starts when you "Step inside" and stops when the door opens.

There is a subtle **Hint** button (three hints, one per press, keyed to the
current puzzle) and a **Reset** button that restores the room and the clock.
Everything is deterministic: same colours, same Morse word, same code, same
shift, same book order on every run.

## Run it

```sh
cd escape-room
npm install
npm run dev      # http://localhost:5173
npm run lint
npm run build
```

Vite + React 19 + TypeScript (strict). `npm run lint` (oxlint) and
`npm run build` (`tsc -b && vite build`) must both pass cleanly.

## Computer-use skill showcased

**Discovering hidden UI affordances: hover-reveal, timing, drag, decoding,
scrolling.** Nothing in the room is labelled with its answer. The agent has to
open inspect views, watch a lamp blink and time the pulses, hover an element
long enough for a transition to run, perform real pointer drags (with pointer
capture) between two elements, decode a substitution cipher with an in-app
dial, and scroll a panel to find content that is off-screen.

## Browser test scenario

Start `npm run dev`, open the app in a maximised Chrome window with screen
recording on, then:

1. Click **Step inside**. *Expected:* overlay closes, the Casebook timer starts at 00:00 and objective 1 "The lockbox" is marked **Now**.
2. Click the painting, read the four bands, close it. Click the brass lockbox on the desk and turn the dials to **amber · teal · crimson · violet**, then **Turn the latch**. *Expected:* lockbox opens, the lamp lights and starts blinking, objective 2 becomes current, the bulb appears under "Found in the room".
3. Click the lamp to open its inspect view and watch a full cycle (~35 s) build up on the tape strip; open the Morse chart on the wall to decode `−−− ·−− ·−··` → **OWL**. Click the typewriter, type `OWL`, press Enter. *Expected:* the typed page mentions lemon ink; objective 3 current.
4. Move the mouse over the card on the corkboard and hold still. *Expected:* after ~0.5 s the card warms and reads "The safe answers to 4 · 1 · 9." Moving away blanks it again.
5. Click the wall safe, set the wheels to **4 1 9**, **Turn the handle**. *Expected:* the safe swings open showing a crowbar; the journal says the rug will move now.
6. Press on the rug and drag it aside. *Expected:* a brass key is revealed on the floorboards.
7. Drag the key onto the desk drawer (it pulses gold as the drop target). *Expected:* the drawer opens showing a brass dial; objective 5 current.
8. Click the sampler and press **+** until the dial reads **shift 7**. *Expected:* the decoded line reads `THE LETTER ON THE DESK NUMBERS THE BOOKS`; objective 6 current.
9. Click the letter on the desk and scroll through it, noting the numerals in the margins.
10. Click the books in order **Cartography, Poetry, Astronomy, Alchemy, Botany**. *Expected:* each book slides out; on the fifth the door's bolt draws back and the Casebook reads "The door is unbolted".
11. Click the door. *Expected:* the door swings open, the timer stops, and an overlay shows "You escaped the study" with the final time and hints used.

Use at most one hint during the run. Reset should return the room to its
starting state at any point.

## Recording

Recording (Devin solving the room end-to-end in Chrome, 0 hints, escape time
06:18; the test script is composed to the right of the browser and lights up
as each puzzle is reached):
https://app.devin.ai/attachments/821c80b5-4ac9-4c82-b43e-7ac91eebe779/escape-room-showcase.mp4
