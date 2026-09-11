# Discovery sweep 05 — after manual web↔iOS UI pass fixes

Source: testing-agent manual web↔iOS pass on the design-pass-2 build (6600c92) plus
automated run `evidence/tests/e2e-20260910-080805` (web + iOS, digest 5B0FF7B1, 2331 snapshots each).

Findings fixed at this revision (all `lastfort/client`):
- Hotbar: key 1 now selects the pickaxe (inventory 0), keys 2–6 the five item slots; HUD
  renders Q build-tool + 1 pickaxe + 2–6 items (previously keys were off by one, 6 was a no-op).
- Spectator overlay: shows `ELIMINATED · SQUAD STILL IN` until a placement exists (was `#0`).
- Results ribbon: dark foreground in both themes, deeper teal XP in light mode (contrast).
- Storm slab: short labels (`SHRINKS IN`, `SHRINKING`, `IN STORM`, `BUS LEAVES`, `FINAL RING`)
  and stacked value on compact HUDs so the label is never ellipsized.

Not changed (recorded, not a defect vs. reference): desktop hotbar sits lower-right with
materials above it and vitals lower-left, matching the publicly documented reference layout.

No new inaccessible requirements discovered. Android runtime frontier unchanged (no nested
virtualization on this host). The web+iOS+macOS run `e2e-20260910-071751` predates these
UI-only fixes; macOS was not re-run after them.
