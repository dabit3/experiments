# Reference study — 13 September 2026

Reference: **Mobile Suit Gundam: Extreme Vs.**, with the accessible official
Maxiboost ON arcade instructions used for this implementation.

## Sources actually read and images inspected

- https://en.bandainamcoent.eu/gundam/mobile-suit-gundam-extreme-vs-maxiboost
  Official product description confirms 2-versus-2, mobile suit abilities and
  three EX burst systems.
- https://gundam-vs.jp/extreme/acmb-on/sp/about/howto/
- https://gundam-vs.jp/extreme/acmb-on/sp/assets/images/about/img_howto_system03.png
  Inspected the full HUD screenshot: rear third-person suit, distant red circular
  reticle, stacked cyan/red team bars at upper left, timer and radar upper right,
  large white HP lower left, boost at bottom center, ammunition at right.
- https://gundam-vs.jp/extreme/acmb-on/sp/assets/images/about/img_howto_system02.png
  Inspected both action screenshots: articulated white/blue/red angular armor,
  dark exposed joints, pointed shoulders, backpack, long feet, green/yellow
  step trail and blue-white tapered boost exhaust. Boost dash cancels actions;
  step cancels melee.
- https://gundam-vs.jp/extreme/acmb-on/sp/about/rule/
  Official text gives each side 6000 team cost, lost on suit destruction.
- https://www.dualshockers.com/mobile-suit-gundam-extreme-maxiboost-beginner-tips-tricks/
  Secondary source describes landing to recover boost, movement discipline,
  lock warnings, rainbow steps and 1500/2000/2500/3000 cost roles.

Source images are retained privately in the ignored research evidence directory;
they are not distributed as app assets.

## Translation into Orbital Versus

Native iPhone landscape, SceneKit 3D. Rear chase camera; original cobalt/ivory
**Aster-02** and vermilion/ivory **Vesper-02** mecha with faceted armor, fins,
rifle, shield, articulated limbs, saber and exhaust. An orbital launch complex
supplies the futuristic arena requested by the assignment. Large team cost bars,
radar, lock range colors, HP, boost, ammo and overdrive retain the reference's
information hierarchy. Guest pilots occupy opposing teams with an explicitly
labeled AI wingman each.

Observed mechanics: boost dash, step, ranged/melee, lock markers, team cost,
landing recharge and burst. Our exact speeds, damage, combo timing, map, soundtrack,
unit designs, touchscreen controls, 90-second timeout tiebreak and one combined
overdrive are authored adaptations, not measured reference values.

## Acceptance inventory

| ID | Journey / behavior | Evidence required |
| --- | --- | --- |
| NET-01 | Two distinct native peers join one room, ready, countdown | Real sockets, both device displays |
| MOVE-01 | Joystick, boost/flight, gravity, landing recharge, dodge | Manual path plus server assertions |
| COMBAT-01 | Lock, beam travel/hit, saber lunge/combo, shield | Match footage and damage telemetry |
| COST-01 | Death subtracts cost, respawn, finite common winner | Server tests and common result screen |
| FLOW-01 | Both vote rematch; reconnect preserves identity | Protocol tests and device test |
| ART-01 | Articulated original 3D suits, exhaust, beams, HUD | Full match screenshot/footage |
| AUDIO-01 | Original synthesis ambience and action feedback | Generated bundled audio/native playback |

## Evidence boundary

No executable arcade/console reference, source code, original assets or matched
capture device is available. Pixel parity, exact hitboxes, roster breadth and
private behavior are unverified. The clone-this research/inventory/evidence loop
is applied; its zero-pixel gate cannot pass and is not claimed. User-authorized
visual approximation and required commits take precedence over the skill's strict
parity/no-commit defaults. This is a substantial original playable adaptation.
