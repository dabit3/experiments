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

This app exists to show Devin playing a real-time game in a real browser. The
recording below is Devin driving the page with keyboard input while reading the
canvas and telemetry to plan each move.

Scenario performed:

1. Open the app, pick a difficulty and press **Space** to start.
2. Play with the arrow keys, reading the board after each batch of moves to
   route the snake to the apple, until the score reaches at least 8 without dying.
3. Press **P**, assert the "Paused" overlay, press **P** again to resume.
4. Deliberately steer into a wall, assert the "Game Over" overlay with the final
   score and the updated high score.
5. Press **Space** to restart and eat at least two more apples.

<!-- SHOWCASE_MEDIA -->
