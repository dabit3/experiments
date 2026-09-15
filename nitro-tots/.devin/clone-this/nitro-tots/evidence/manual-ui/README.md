# Manual UI verification (testing agent, release web + native macOS)

Second pass after the fixes for: fixed Grand Prix rival roster + cumulative standings,
time-trial timing excluding the countdown, title-screen "Rejoin your match" banner,
and touch HUD spacing (speedo/minimap above the on-screen controls).

| File | What it shows |
|---|---|
| cup_race1..4_results.png, cup_final_standings.png | Offline Sugar Cup: same 7 rivals every race; cumulative points + placement history after each race; final 57/46/39/36/33/29/28/20 |
| title_rejoin_banner.png, resumed_live_race.png, room_before/after_resume.json | Refresh mid online race -> banner -> same player id/slot resumed, no duplicate seat |
| title_no_banner_after_match.png | Banner cleared after match over / leave |
| web_online_final.png, macos_online_final.png | Web + native macOS agree on final order, points and hash d6bf2f06 |
| touch_hud_400px.png, touch_hud_wide.png | Speedo + minimap visible above the touch controls at 400px and wide |
| time_trial_hud_vs_results_pre_fix.png | HISTORICAL (pre-fix build): residual 1-tick HUD/results difference (1:21.13 vs 1:21.10). Not passing evidence. |
| time_trial_hud_vs_results_fixed.png | PASS on the final build: HUD clock frozen at the racer finish tick (app/lib/game/hud.dart); HUD and results both show 1:24.16 |
| manual-ui-reverification.mp4 | Screen recording of the pass (time-trial section predates the clock fix; the fixed re-check is the PNG above) |
