# Keyboard-Only Gauntlet: the mouse is disabled

A six-task accessibility drill built from hand-rolled ARIA widgets. The page disables the mouse completely (`pointer-events: none` on `body`, `cursor: none` everywhere, and any click is intercepted, shows a **Mouse disabled - keyboard only!** toast and increments a *mouse violations* counter). You get through it with the keyboard alone: a progress checklist tracks each widget and the final screen reports total time, per-task time/keystrokes and the violation count.

| # | Widget | ARIA pattern | Goal |
|---|--------|--------------|------|
| 1 | Menubar | `role="menubar"` / `menu` / `menuitem`, roving tabindex | Open **View** and activate **Zen Mode** |
| 2 | Combobox | `role="combobox"` + `listbox`, `aria-autocomplete="list"`, `aria-activedescendant` | Typeahead to **Kazakhstan** |
| 3 | Tab list | `role="tablist"` / `tab` / `tabpanel`, automatic activation | Arrow to the greyed-out **Hidden** tab and claim it |
| 4 | Tree view | `role="tree"` / `treeitem` / `group`, `aria-expanded` | Expand `src › widgets › tree › vault` and select `golden-key.ts` |
| 5 | Modal dialog | `role="dialog"` `aria-modal`, focus trap, `inert` background | Tab to the third button, Enter, then Escape |
| 6 | Slider | `role="slider"` with `aria-valuenow/min/max/text` | Land on exactly **42** and press Enter |

Everything is local and deterministic: no backend, no network calls, bundled data only. Strict TypeScript; `npm run lint` (oxlint) and `npm run build` pass.

## Run it

```bash
cd keyboard-only-gauntlet
npm install
npm run dev      # http://localhost:5173
npm run build    # tsc -b && vite build
npm run lint     # oxlint
```

## Computer-use skill showcased

**Accessible keyboard navigation through complex ARIA widgets with no pointer at all.** The agent cannot click anything; it has to read the widget roles/states and drive each one with the keys the pattern defines (Tab / Shift+Tab, arrows, Home / End / PageUp / PageDown, Enter, Space, Escape and typeahead letters), watching the visible focus ring and `aria-*` state to know where it is.

## Browser test scenario

1. Load the app in a maximised Chrome window. Click anywhere once on purpose.
   **Expected:** the red *Mouse disabled - keyboard only!* toast appears and *Mouse violations* reads 1. Nothing else reacts to the click.
2. Press **Enter** on the focused *Start the gauntlet* button.
   **Expected:** timer starts, violations reset to 0, task 1 (Menubar) is shown and its heading takes focus.
3. **Menubar:** Tab to *File*, → → to *View*, ↓ to open, ↓ to *Zen Mode*, Enter.
   **Expected:** editor switches to Zen Mode, task 1 is ticked, task 2 appears.
4. **Combobox:** Tab into the *Shipping country* input, type `kaz`, ↓, Enter.
   **Expected:** the listbox filters to Kazakhstan, `aria-activedescendant` highlights it, selection completes task 2.
5. **Tab list:** Tab to the tablist, press → five times (or End) to reach the dashed *Hidden* tab, Tab to *Claim the hidden tab*, Enter.
   **Expected:** the hidden panel is revealed and task 3 is ticked.
6. **Tree view:** Tab into the tree, ↓ to `src`, → to expand, → into `widgets`, → expand, → into `menubar`, ↓ ↓ to `tree`, → expand, → into `Tree.tsx`, ↓ to `vault`, → expand, → into `decoy-key.ts`, ↓ to `golden-key.ts`, Enter.
   **Expected:** `golden-key.ts` is selected and marked *target*, task 4 is ticked.
7. **Modal dialog:** Tab to *Open confirmation dialog*, Enter. Tab past the first two buttons to *Arm the trap* (Tab keeps cycling inside the dialog), Enter, then Escape.
   **Expected:** focus never leaves the dialog; the state line flips to *Trap armed*; Escape closes the dialog and completes task 5.
8. **Slider:** Tab to the slider (starts at 17), Home → 0, PageUp × 4 → 40, → → → 42, Enter.
   **Expected:** the readout turns green at 42 and Enter locks it in.
9. **Summary:** the final screen shows **6/6** tasks, total time, per-task times/keystrokes and **0 mouse violations** (*Flawless run.*).

## Recording

- Recording (mp4): https://app.devin.ai/attachments/7d5adc83-9b01-4d7c-b535-bcee98bd7ebd/keyboard-only-gauntlet-showcase.mp4
- Animated preview (webp): https://app.devin.ai/attachments/f22d9dad-d809-40bf-b17c-d68ba9567153/keyboard-only-gauntlet-preview.webp

## Project layout

```
src/
  App.tsx                 phase state machine (intro → running → done), timer, per-task results
  tasks.ts                the six task definitions shown in the checklist
  hooks/useMouseGuard.ts  capture-phase mouse interception, toast + violation counter
  hooks/useKeyLog.ts      recent-keys HUD
  lib/keys.ts             key formatting, typeahead, duration helpers
  components/             Header, Checklist, TaskCard, IntroScreen, SummaryScreen, KeyHud, Toast
  widgets/                MenubarTask, ComboboxTask, TabsTask, TreeTask, DialogTask, SliderTask
```
