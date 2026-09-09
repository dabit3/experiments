# Mission Control: coordinate a launch across three browser windows

A rocket launch console split across **three browser windows**. The Main window
owns the launch checklist and opens two popup consoles with `window.open` — a
**Propulsion** console and a **Guidance** console — each a separate route in the
same Vite app. All three windows stay in sync over a `BroadcastChannel`, and the
seven-step launch sequence deliberately interleaves actions across the windows
in a fixed order, so completing it means constantly switching to the right
window.

**Recording:** https://app.devin.ai/attachments/2f168eaa-cfad-40d0-b774-a83232d104c5/mission-control-windows.mp4

## What's in the box

| Route         | Window                | Role                                                                |
| ------------- | --------------------- | ------------------------------------------------------------------- |
| `/`           | Main (mission authority) | Checklist, live gauge, countdown, LAUNCH, lift-off animation, console dock |
| `/propulsion` | Propulsion popup      | ARM FUEL switch, hold-to-PRESSURISE button, "Propulsion GO" report   |
| `/guidance`   | Guidance popup        | Target-orbit entry form (must match Main's flight plan), "Guidance GO" |

- **Single authority.** Main holds the only reducer. Popups are thin clients:
  they post `command` messages on the channel and render whatever `state` Main
  broadcasts back. Popups announce themselves with `hello`, Main answers with a
  full state snapshot, and a `bye` on unload flips the console's lamp to
  offline in Main.
- **Deterministic mission.** The target orbit is derived from the mission seed
  (`ARTEMIS-7` by default, override with `/?seed=…`) through a small FNV-1a
  hash, so a replay always shows the same numbers. The default seed yields
  **414 km × 45.0°**.
- **Status log in every window.** Every event is appended to a shared log that
  all three windows render.
- **Popup-blocked fallback.** If `window.open` returns `null`, the console card
  in Main turns into an "Open in tab" link; the channel works identically
  across tabs.
- **No backend, no network.** Everything is bundled; the only cross-window
  transport is `BroadcastChannel`.

## Run it

```sh
cd mission-control-windows
npm install
npm run dev        # http://localhost:5173
npm run lint       # oxlint
npm run build      # strict tsc + vite build
```

Open `http://localhost:5173/` and use the two **Open … console** buttons in
the Consoles dock. The popups are sized so both fit stacked down the right
edge of the screen next to the Main window.

## Computer-use skill showcased

**Multi-window management** — opening popups, focusing the right window at the
right moment, and reasoning about cross-window state that is synchronised via
`BroadcastChannel`. Several steps can only be completed with information that
is displayed in a *different* window (the flight plan is shown in Main but
must be typed into Guidance), and one step requires holding a mouse button in
a popup while the result is only visible in Main.

## Browser test scenario

Preconditions: dev server running, Chrome maximised, start at
`http://localhost:5173/`.

| #  | Window     | Action                                                                     | Expected result                                                                                                                           |
| -- | ---------- | -------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| 1  | Main       | Click **Open Propulsion console**, then **Open Guidance console**           | Two popup windows open on `/propulsion` and `/guidance`; both show **LINKED TO MAIN**; both console cards in Main turn **LINKED**; the log records the openings in all three windows |
| 2  | Propulsion | Click **ARM FUEL**                                                          | Button becomes **ARMED** and collapses; Main's checklist advances to step 2 *Confirm fuel armed*; log: `Fuel system ARMED…` everywhere     |
| 3  | Main       | Click **CONFIRM FUEL ARMED**                                                | Checklist step 3 *Lock target orbit* is active; the **Flight plan · target orbit** panel shows `414 km × 45.0°` (only in Main); Guidance's orbit form unlocks |
| 4  | Guidance   | Type `414` in Altitude, `45` in Inclination, press Enter / **LOCK TARGET ORBIT** | Orbit card collapses to **LOCKED · 414 km × 45.0°**; Main advances to step 4 *Pressurise tanks* and shows the tank-pressure gauge at 0 %. (A wrong value is rejected with a shake and increments the attempt counter.) |
| 5  | Propulsion | Press and **hold** the round **PRESSURISE** button for 3 s                  | Ring fills in the popup while Main's gauge needle sweeps live; at 100 % the lamp reads **NOMINAL**, the rocket's engine lights, Main advances to step 5 *Countdown*. Releasing early stops the fill |
| 6  | Main       | Click **START COUNTDOWN** and do **not** press **ABORT** in any window      | `3 → 2 → 1` shown in Main and, compact, as an overlay in both popups with a live red ABORT button; after T-0 Main holds at step 6 *Ready check* |
| 7  | Propulsion | Click **REPORT PROPULSION GO**                                              | Propulsion lamp **GO**; Main's ready board lights *Propulsion GO*; LAUNCH still disabled                                                   |
| 8  | Guidance   | Click **REPORT GUIDANCE GO**                                                | Guidance lamp **GO**; Main's ready board lights both; **LAUNCH** becomes enabled and glows                                                 |
| 9  | Main       | Click **LAUNCH**                                                            | Rocket lifts off the pad with flame and smoke; the stage reads **LIFT-OFF** with climbing altitude/velocity; phase pill reads **IN FLIGHT**; both popups show a synced **LAUNCHED** overlay with the same telemetry; log: `LIFT-OFF. Kestrel IV has cleared the tower.` in all windows |

Negative checks worth doing: pressing **ABORT** during the countdown puts all
three windows into an **ABORTED** state; **Reset** in Main returns everything
(including the popups) to step 1.
