# experiments

A growing collection of small web apps (35 so far, built in two rounds), each
built and then tested end-to-end in a real browser by Devin. Every app is picked
to stress a different kind of computer use: drag-and-drop, freehand drawing,
keyboard-driven editing, real-time games, file uploads, clipboard and multi-window
coordination, puzzle solving, adversarial UI, WebGL scenes, and more.

Each app lives in its own top-level directory with its own README describing the
app and the browser test scenario. Each row below links to the PR that added the
app and to the recording of Devin running the scenario.

## Round 1: the first ten apps

| Directory | App | Computer-use skill it showcases | PR | Recording |
|-----------|-----|---------------------------------|----|-----------|
| `kanban-board/` | Drag-and-drop Kanban board | Mouse press/drag/release, reordering, multi-column DnD | [#3](https://github.com/dabit3/experiments/pull/3) | [watch](https://app.devin.ai/attachments/895ab452-c188-4f45-8603-79334ee4b3d4/kanban-showcase-edited.mp4) |
| `pixel-painter/` | Canvas drawing app | Precise freehand mouse paths + visual verification (draws a house, writes "DEVIN") | [#1](https://github.com/dabit3/experiments/pull/1) | [watch](https://app.devin.ai/attachments/7025b1bc-f963-487f-9b19-c976f1d1d0ba/pixel-painter-showcase-edited.mp4) |
| `shop-checkout/` | Multi-step e-commerce checkout | Long forms, validation errors, Luhn card check, multi-page state | [#6](https://github.com/dabit3/experiments/pull/6) | [watch](https://app.devin.ai/attachments/c0a70c26-0aad-4173-8002-cfa80760064f/northwind-checkout-showcase-edited.mp4) |
| `mini-sheets/` | Spreadsheet with formulas | Keyboard-only navigation, shortcuts, fill-down, relative copy/paste | [#5](https://github.com/dabit3/experiments/pull/5) | [watch](https://app.devin.ai/attachments/83bc563a-b760-489d-a674-d914d11c3c84/mini-sheets-keyboard-showcase.mp4) |
| `snake-arcade/` | Snake game | Real-time arrow-key control, reading live game state (reaches score 8) | [#2](https://github.com/dabit3/experiments/pull/2) | [watch](https://app.devin.ai/attachments/7617956b-2423-4ce1-9e45-dbb63ec54cd7/snake-arcade-devin-playthrough.mp4) |
| `block-editor/` | Notion-style rich text editor | Text selection, shortcuts, slash commands, block drag, undo/redo | [#9](https://github.com/dabit3/experiments/pull/9) | [watch](https://app.devin.ai/attachments/7d370072-a0da-4384-8874-c706e610d907/block-editor-demo-edited.mp4) |
| `metrics-dashboard/` | Interactive analytics dashboard | Hover tooltips, drag-to-zoom charts, range sliders, filters | [#4](https://github.com/dabit3/experiments/pull/4) | [watch](https://app.devin.ai/attachments/5a28ff3e-411a-498c-aad7-646bbbf1d677/metrics-dashboard-showcase-edited.mp4) |
| `photo-crop/` | Image crop & filter tool | Native file-chooser upload, drag handles, file download round-trip | [#7](https://github.com/dabit3/experiments/pull/7) | [watch](https://app.devin.ai/attachments/663e37e8-c4cb-4f7e-a42a-291a75f7cdc8/photo-crop-showcase-edited.mp4) |
| `week-planner/` | Calendar with drag-to-create events | Drag-to-create, resize, right-click menus, modals | [#10](https://github.com/dabit3/experiments/pull/10) | [watch](https://app.devin.ai/attachments/3c49973b-72c2-4836-8247-1f621460452d/week-planner-showcase-edited.mp4) |
| `realtime-chat/` | WebSocket chat room | Two browser tabs acting as two users in sync | [#8](https://github.com/dabit3/experiments/pull/8) | [watch](https://app.devin.ai/attachments/2c95a9eb-3a7f-447b-8c8d-3aa4fe2bf421/relay-two-users-showcase-edited.mp4) |

## Round 2: 25 more apps

| Directory | App | Computer-use skill it showcases | PR | Recording |
|-----------|-----|---------------------------------|----|-----------|
| `2048-arena/` | 2048 Arena: reach the 512 tile | Long sequences of arrow-key input while continuously re-reading a changing grid | [#13](https://github.com/dabit3/experiments/pull/13) | [watch](https://app.devin.ai/attachments/18d992b6-2c3c-414c-9510-6b450a29c594/2048-arena-showcase-edited.mp4) |
| `airline-booking/` | Airline booking wizard with seat map and boarding pass | Long multi-step form with calendar widgets, autocomplete, a seat map and validation recovery | [#36](https://github.com/dabit3/experiments/pull/36) | [watch](https://app.devin.ai/attachments/f54e05ce-02c6-4e53-959e-16db42cbdabf/airline-booking-showcase.mp4) |
| `battleship-commander/` | Battleship vs a hunt-and-target AI | Turn-based grid clicking with probability reasoning and reading two boards at once | [#22](https://github.com/dabit3/experiments/pull/22) | [watch](https://app.devin.ai/attachments/77f850c4-613b-4ca5-a3fa-ba92a7ff4a24/battleship-commander-showcase-edited.mp4) |
| `beat-lab/` | Beat Lab: a step sequencer and piano roll | Dense grid toggling, slider control, reproducing a pattern from a reference and visual playback verification | [#14](https://github.com/dabit3/experiments/pull/14) | [watch](https://app.devin.ai/attachments/29367945-f5be-4fb6-9073-021d2b3d321f/beat-lab-showcase.mp4) |
| `bug-hunt-store/` | Bug Hunt: a storefront with 8 planted bugs and a scoreboard | Exploratory QA: noticing wrong maths, broken sorting, overlays, off-by-one paging, and reporting them | [#29](https://github.com/dabit3/experiments/pull/29) | [watch](https://app.devin.ai/attachments/a11ae4ce-dea8-4c03-b776-b2da33034f61/bug-hunt-store-showcase.mp4) |
| `chess-arena/` | Chess Arena: checkmate a built-in engine | Long-horizon strategic play; reading a full board state from pixels every move | [#20](https://github.com/dabit3/experiments/pull/20) | [watch](https://app.devin.ai/attachments/94a3bbf8-7d5c-401d-a431-de2ca909a4a9/chess-arena-showcase.mp4) |
| `clipboard-heist/` | Clipboard Heist: a spy mission built on copy and paste | Clipboard operations: select-all, copy, paste, paste-as-plain-text, pasting into the right target | [#23](https://github.com/dabit3/experiments/pull/23) | [watch](https://app.devin.ai/attachments/281d079c-5496-4e13-816c-bcbe5ed32af3/clipboard-heist-showcase.mp4) |
| `configurator-3d/` | 3D Sneaker Configurator (Three.js) | Orbiting a WebGL scene by dragging, selecting 3D parts, and verifying rendered colours | [#35](https://github.com/dabit3/experiments/pull/35) | [watch](https://app.devin.ai/attachments/4ad52f6a-de18-4bbd-a961-9a842d1f49e2/sneaker-showcase-edited.mp4) |
| `dark-pattern-gauntlet/` | Dark Pattern Gauntlet: cancel a subscription through 10 hostile screens | Resilience to adversarial UI: fake close buttons, moving targets, confirmshaming, countdowns, disguised ads | [#27](https://github.com/dabit3/experiments/pull/27) | [watch](https://app.devin.ai/attachments/a04f0ce0-1705-4605-97ac-50e62e4b63d6/dark-pattern-gauntlet-showcase-edited.mp4) |
| `escape-room/` | Escape Room: six chained puzzles in one page | Discovering hidden UI affordances: hover-reveal, timing, drag, decoding, scrolling | [#37](https://github.com/dabit3/experiments/pull/37) | [watch](https://app.devin.ai/attachments/50495ee2-4936-4305-8e50-4be4661507f2/escape-room-showcase.mp4) |
| `flowchart-studio/` | Flowchart Studio: node-and-edge diagramming | Port-to-port edge dragging, marquee selection, panning/zooming an infinite canvas | [#28](https://github.com/dabit3/experiments/pull/28) | [watch](https://app.devin.ai/attachments/a1d05e06-6f21-4110-960c-fc7e7fc42d14/flowchart-ci-full-rerun-edited.mp4) |
| `keyboard-only-gauntlet/` | Keyboard-Only Gauntlet: the mouse is disabled | Accessible keyboard navigation through complex ARIA widgets with no pointer at all | [#30](https://github.com/dabit3/experiments/pull/30) | [watch](https://app.devin.ai/attachments/7d5adc83-9b01-4d7c-b535-bcee98bd7ebd/keyboard-only-gauntlet-showcase.mp4) |
| `minesweeper-lab/` | Minesweeper with seeded boards and right-click flags | Left-click reveal, right-click flag, chord-click, and probabilistic deduction | [#24](https://github.com/dabit3/experiments/pull/24) | [watch](https://app.devin.ai/attachments/ba4a1426-ecdd-4792-b1be-4dbe56d4429b/minesweeper-lab-showcase.mp4) |
| `mission-control-windows/` | Mission Control: coordinate a launch across three browser windows | Multi-window management: popups, focusing the right window, cross-window state via BroadcastChannel | [#32](https://github.com/dabit3/experiments/pull/32) | [watch](https://app.devin.ai/attachments/2f168eaa-cfad-40d0-b774-a83232d104c5/mission-control-windows.mp4) |
| `password-game/` | The Password Game: rules that stack against you | Iterative constraint satisfaction in a single text field with live validation | [#21](https://github.com/dabit3/experiments/pull/21) | [watch](https://app.devin.ai/attachments/1e9a8987-856d-45b9-ad61-49d68b360a42/password-game-showcase-v2-edited.mp4) |
| `pdf-form-signer/` | PDF Form Signer: fill a form, draw a signature, download a real PDF | Form filling, freehand signature drawing on a canvas, file download and verifying the downloaded artefact | [#26](https://github.com/dabit3/experiments/pull/26) | [watch](https://app.devin.ai/attachments/16ddfb12-2535-4ddb-8ec4-42bd51b52672/pdf-form-signer-fixed-showcase-edited.mp4) |
| `physics-rube-goldberg/` | Rube Goldberg Lab: place parts so the ball rings the bell | Drag-placing objects into a physics scene, running a simulation, observing and iterating | [#34](https://github.com/dabit3/experiments/pull/34) | [watch](https://app.devin.ai/attachments/3f08ab62-1468-4b05-b578-8d247b734964/rube-goldberg-showcase-edited.mp4) |
| `prove-youre-a-robot/` | Prove You're a Robot: a reverse-CAPTCHA gauntlet | Pixel-precise mouse manipulation: slider puzzles, rotation, tile selection, jigsaw drag, path tracing | [#31](https://github.com/dabit3/experiments/pull/31) | [watch](https://app.devin.ai/attachments/28591f56-6b0c-44d3-935d-c8855e7908c0/prove-youre-a-robot-showcase-edited.mp4) |
| `restaurant-pos/` | Restaurant POS: floor plan, modifiers, and split bills | Complex stateful workflow with arithmetic that must be verified visually | [#19](https://github.com/dabit3/experiments/pull/19) | [watch](https://app.devin.ai/attachments/3c4476ce-3b5b-4d70-8e8e-4c4e71101d80/restaurant-pos-showcase.mp4) |
| `slide-forge/` | SlideForge: build a deck, present it fullscreen, export a PDF | Rich WYSIWYG editing, drag-to-reorder thumbnails, fullscreen presenting, browser print dialog | [#25](https://github.com/dabit3/experiments/pull/25) | [watch](https://app.devin.ai/attachments/a61b50c3-40bb-40d4-acd8-d88db73355a4/slide-forge-complete-showcase-edited.mp4) |
| `sokoban-depot/` | Sokoban Depot: push crates onto targets | Spatial planning, backtracking with undo, level progression | [#17](https://github.com/dabit3/experiments/pull/17) | [watch](https://app.devin.ai/attachments/065bd180-32b8-4608-865b-c76bca5a86c3/sokoban-depot-showcase.mp4) |
| `sudoku-dojo/` | Sudoku Dojo: solve an 81-cell grid by hand | Sustained deductive puzzle-solving with dozens of precise clicks and digit keys | [#16](https://github.com/dabit3/experiments/pull/16) | [watch](https://app.devin.ai/attachments/acb65f42-601e-49cf-8c39-9deed96098a5/sudoku-dojo-showcase.mp4) |
| `terminal-treasure-hunt/` | Terminal Treasure Hunt: a fake shell with a hidden flag | Typing shell commands into a browser terminal and reading dense text output | [#18](https://github.com/dabit3/experiments/pull/18) | [watch](https://app.devin.ai/attachments/cd65a858-7688-47e7-bfa8-7d5d8b8c3db6/terminal-treasure-hunt-showcase-edited.mp4) |
| `timeline-cutter/` | Timeline Cutter: a video editor timeline with trim, split and ripple | Sub-pixel drag of trim handles, scrubbing a playhead, drag-reorder with snapping | [#33](https://github.com/dabit3/experiments/pull/33) | [watch](https://app.devin.ai/attachments/9ad24747-4ad6-49e3-8e1f-5e90ce7549c7/timeline-cutter-showcase-edited.mp4) |
| `wordle-seeded/` | Wordle with reproducible seeds and a hard mode | Keyboard entry plus multi-step reasoning from colour feedback | [#15](https://github.com/dabit3/experiments/pull/15) | [watch](https://app.devin.ai/attachments/571ff954-facb-4b35-84ef-c35e66fa5093/wordle-seeded-showcase.mp4) |

## Running an app

```sh
cd <directory>
npm install
npm run dev
```
