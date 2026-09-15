# Nitro Tots — manual design UI pass

Completed the procedure on rebuilt release web and native macOS clients. **One visual defect was found: 400px title tiles truncated three mode names and several hints.** Fixed afterwards in `app/lib/screens/title_screen.dart` (the tile grid now drops to one column below 480 px) and re-verified on the rebuilt web build: `title_phone_400_fixed.png` shows all five labels and hints in full. Layout/behavior review only; no proprietary reference was available for pixel matching.

| Requested check | Result and evidence filenames |
|---|---|
| 1. Desktop/400px title tiles and navigation | **FAIL at 400px, then fixed:** “Grand …”, “Quick …”, and “Time T…” replaced full mode names; several hints also truncated (`title_phone_400_truncated_labels.png`, pre-fix). After the one-column fix and rebuild: `title_phone_400_fixed.png` — full labels and hints. All five tiles navigate to their expected screens. Desktop labels are complete. `title_desktop_1280x800.png`; phone destination PNGs. |
| 2. Garage and cup selection | **PASS:** selectable character/kart grids and preview reflow; phone sections/options remain scroll-reachable. One-lap cup option works. `garage_desktop_selected.png`, `garage_desktop_kart_grid.png`, `garage_phone_400_*.png`, `cup_desktop_one_lap.png`, `cup_phone_400_*.png`. Native title/garage/cup also observed: `native_*.png`. |
| 3. Countdown, HUD, pause | **PASS:** red lamps → green GO; item/lap/clock/place/speed/minimap separated. Center dark-circle pause is legible; paused clock stayed at 0:14.36, then resumed. `countdown_three_lights.png`, `countdown_green_go.png`, `quick_race_hud.png`, `quick_race_paused.png`. Countdown PNGs were captured during the cup. |
| 4. Results table | **PASS:** rank/portrait/name/kart/time/+PTS readable, local row highlighted. 1280×800 shows all eight rows; 1024×700 requires vertical scrolling for rows 7–8, with footer available. Additional 1280×900 wide-row path passed. `quick_results_*.png`. |
| 5. Four-race Sugar Cup | **PASS:** identities/karts stable; each TOTAL is cumulative. Final: Rocco 52, Ozzie 45, Tank 43, Mabel 35, Bea 31, Juno 31, Kiki 31, web design 20. History winners Rocco/Ozzie/Rocco/Tank agree with race tables. `gp_race1_totals.png` through `gp_race4_totals.png`, `gp_final_podium_standings.png`, `gp_final_history.png`. |
| 6. Web + macOS online race | **PASS for final results:** room CQXF; both clients show Waffles 15, Dot 12, Zippy 10, Nova 9, Pudding 8, Biscuit 7, mac qa 6, web design 5; hash `d8aadf4a`. `online_native_roster.png`, `online_*_hud.png`, `online_web_final_results.png`, `online_native_final_results.png`, `online_room_CQXF_final.json`. **Incomplete:** transient per-race time-table parity was not captured before automatic final-podium transition. |
| 7. 400px Touch HUD | **PASS:** speedometer/place and minimap are fully above steering/item/drift controls; top item/clock/pause readable. Touch explicitly selected in Settings. `touch_hud_400x900.png`, `touch_pause_phone_400.png`. |

## Key visual evidence

| 🔴 400px mode-label truncation | 🟢 400px Touch HUD spacing |
|---|---|
| ![Truncated title tile labels](https://app.devin.ai/attachments/a41cd9de-5a00-42ef-b3f9-585780f46700/title_phone_400_truncated_labels.png) | ![HUD above Touch controls](https://app.devin.ai/attachments/353c7c9b-a1b6-48e9-96b5-f0ee6c987ba5/touch_hud_400x900.png) |

## Recording and coverage

- Full-speed raw recording (18m36s, segments concatenated without re-encoding): `manual-ui-2-raw.mp4` in this directory (copy of `/Users/devin/screencasts/nitro-design-ui-2-run/nitro-design-ui-2-run-raw.mp4`); the edited review video cuts from it.
- Automatically time-compressed/annotated preview (1m52s): `/Users/devin/screencasts/nitro-design-ui-2-run/nitro-design-ui-2-run-edited.mp4`.
- Unannotated version of that time-compressed preview: `/Users/devin/screencasts/nitro-design-ui-2-run/nitro-design-ui-2-run-clean.mp4`.
- Annotation timestamps: `/Users/devin/screencasts/nitro-design-ui-2-run/nitro-design-ui-2-run-annotations.json`.
- Original capture segments: `/Users/devin/screencasts/nitro-design-ui-2-run/nitro-design-ui-2-run-raw-000.mkv` through `nitro-design-ui-2-run-raw-009.mkv`.
- Web viewports were verified at 1280×800, 1024×700, 1280×900, and 400×900. Native screenshots include the desktop.
- Offline races were exercised on web; native participated in menu/layout and online checks. Races used one lap and reached results through timeout, not a local completed lap. Vertical item roulette was not triggered.
- No edited review video was assembled manually; the lead will produce that deliverable. No credentials are needed from the user.
- Setup note: an initial short-lived CDP helper lost its viewport override on disconnect. The evidence above was captured after switching to a persistent helper and checking PNG dimensions.
