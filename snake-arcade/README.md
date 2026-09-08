# Snake Arcade

A retro, CRT-styled Snake game built with Vite + React + TypeScript. The 20x20
board is rendered on a `<canvas>`; you steer with the arrow keys or WASD, start
and restart with Space, and pause with P. Score and a localStorage-backed high
score sit above the board, the snake speeds up 10% every 5 apples, and a
"telemetry" side panel exposes the live game state (head, heading, apple, speed).
Three difficulties (Chill 4 cells/s, Normal 6, Fast 9) can be picked on the start
screen with the mouse or keys 1/2/3.

## Run it

```sh
cd snake-arcade
npm install
npm run dev
```

Then open the URL Vite prints (http://localhost:5173 by default).

Other scripts: `npm run build` (type-check + production build), `npm run lint`.

## Project layout

```
src/
  game/engine.ts        pure game logic: reducer, collision, apple spawning, speed-ups
  game/useSnakeGame.ts  keyboard handling + fixed-rate game loop
  game/types.ts         shared types
  components/           GameCanvas (canvas renderer), Overlay (start/pause/over), Telemetry
```

## Computer-use showcase

This app exists to show Devin playing a real-time game in a real browser. Devin
drove a maximized Chrome window with genuine keyboard input only (no game-state
injection), steering **live while the snake was moving** — reading the canvas and
telemetry panel every tick and sending the next arrow key, with zero pauses on
the way to score 8.

**Recording (real time, unedited, 2:02):**
[snake-showcase-live-realtime-annotated.mp4](https://app.devin.ai/attachments/58777683-824f-4fa6-bc97-75f45089fd2e/snake-showcase-live-realtime-annotated.mp4)

![Devin steering the snake toward the apple in real time](docs/showcase/gameplay.webp)

### Scenario Devin performed

1. **Start** — Loaded http://localhost:5173, confirmed the start screen ("Press
   Space to start", "Devin's turn" badge, score 0 / high score 0), pressed `1`
   to select Chill (4 cells/s) and `Space` to start. Telemetry read *Playing*,
   length 3.
2. **Play to 8 apples, live** — Ran a tight read-then-steer loop against the
   moving game: each tick, read head / heading / apple / length from the
   telemetry panel, pick the next non-reversing turn toward the apple that
   avoids the body and walls, and press that arrow key. No `P` presses at all.
   Reached score 3, score 5 (speed ticked up from 4.0 to 4.4 cells/s) and score
   8 with length 11 in 27 seconds, never dying.
3. **Pause / resume** — Only after score 8: pressed `P`, asserted the *Paused*
   overlay and that the head froze; pressed `P` again ~1 s later and asserted
   status back to *Playing*.
4. **Wall crash** — Steered left into the x = 0 wall on purpose. Asserted the
   *Game Over* overlay, final score 8 matching the HUD, the "New high score!"
   badge, and the HUD high score updated from 0 to 8.
5. **Restart** — Pressed `Space`; asserted score 0, length 3, status *Playing*
   and high score still 8. Ate two more apples live (score 2, length 5) in 14
   seconds, again without pausing.

### Screenshots

| Start screen | Score 3 |
|---|---|
| ![Start screen with difficulty picker](docs/showcase/01-start-screen.png) | ![Mid-game at score 3](docs/showcase/02-score3.png) |

| Score 5, speed-up to 4.4 cells/s | Score 8, length 11 |
|---|---|
| ![Score 5 with speed increase](docs/showcase/03-score5-speedup.png) | ![Score 8 with an 11-cell snake](docs/showcase/04-score8.png) |

| Brief pause after score 8 | Game over with new high score |
|---|---|
| ![Paused overlay](docs/showcase/05-paused.png) | ![Game over, final score 8, new high score](docs/showcase/06-game-over-high-score.png) |

| Restarted run, 2 more apples |
|---|
| ![Restarted run at score 2 with high score 8 retained](docs/showcase/07-restart-score2.png) |

### Bonus: 2-minute high-score run

Devin then played one continuous two-minute run on Chill with the same live
controller — no pauses, no deaths, real keyboard input — and reached **score 38**
(length 41, speed ramped from 4.0 to 7.8 cells/s) before deliberately crashing
after the clock ran out to bank the new record.

**Recording (real time, unedited, 2:26):**
[snake-highscore-realtime-annotated.mp4](https://app.devin.ai/attachments/d66bd4c1-8e8c-4d08-b2db-64acf9518dd3/snake-highscore-realtime-annotated.mp4)

| Score 20 | Score 35 | Final: 38, new high score |
|---|---|---|
| ![Score 20 mid-run](docs/showcase/highscore-run0-score020.png) | ![Score 35 mid-run](docs/showcase/highscore-run0-score035.png) | ![Game over at 38 with new high score](docs/showcase/highscore-99-final-game-over.png) |
