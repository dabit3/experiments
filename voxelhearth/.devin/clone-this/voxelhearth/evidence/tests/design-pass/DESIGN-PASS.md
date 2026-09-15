# Pixel-GUI design pass (2026-09-10)

Screenshot-driven pass over the web client after moving every screen onto the
integer GUI-pixel grid (`app/lib/ui/pixel.dart`). Produced with

```sh
node test/design-pass.mjs <out> 1280x800   # desktop/
node test/design-pass.mjs <out> 874x402    # phone/  (iPhone 17 landscape logical size)
```

against a `--test-mode` server serving `flutter build web --release`.

Frames per directory: `01-home`, `02-fixture-{home,lobby,results}`,
`03-lobby-live`, `04-game`, `05-game-chat`, `06-inventory`, `07-pause`,
`08-chat`, `09-tab-roster` (PNGs are git-ignored; attached to the PR).

What the pass checked and fixed, in order:

1. GUI scale 2–4 from window size; every panel/slot/button/text baseline on
   whole GUI pixels (no half-pixel blur at any scale).
2. Home: wordmark, dirt/sky backdrop, 200-GUI-px button column, bottom status
   line (version · platform · connection).
3. Lobby: 2-column players / world-rules layout, bevelled list rows, chat box;
   header metadata made flexible and footer buttons wrap on narrow widths.
4. HUD: 182×22 hotbar, 10 hearts + 10 food, XP/score bar, selected-slot frame,
   stack counts right-aligned at (x+17, y+14), roster panel top-right, chat
   bottom-left. Phones: roster top-left, chat feed and debug line beside it
   (clear of the menu buttons and the Place/Jump cluster), whole HUD inset by
   the horizontal safe area so nothing sits under the notch/island (found in
   iOS e2e frames `e2e-20260910-080328`/`-081036`, fixed and re-run).
5. Inventory / crafting / kiln / chest: 176-wide panels, 18×18 slots, result
   arrow, recipe book; result-slot overlap fixed.
6. Pause and options: dimmed backdrop, centred 200-wide buttons, key hints.
7. Results: scoreboard with platform colours; compact columns/labels under
   260 logical px and scroll-only layout under 260 px height (phone landscape).
8. Mobile locked to landscape (Flutter + Info.plist + AndroidManifest) so the
   simulator framebuffer and the app agree on orientation; e2e screenshots are
   rotated upright where a framebuffer is still portrait.

Reference boundary: proportions follow publicly documented genre conventions;
no textures, icons, names, fonts or audio were copied. The original title was
never run.
