# Reference and art direction

## Inspected before implementation

Reference: **The King of Fighters XIII** (2010 arcade / Steam edition). We choose
XIII's 2D presentation consistently rather than mixing XIV's polygonal rendering.

- [Official Steam listing and screenshots](https://store.steampowered.com/app/222940/THE_KING_OF_FIGHTERS_XIII_STEAM_EDITION/)
- [Official English manual](https://www.snk-corp.co.jp/games/webmanual/kof-xiii/THE%20KING%20OF%20FIGHTERS%20STEAM%20EDITION%20Manual_EN.pdf)
- [Controls and attacks](https://dreamcancel.com/wiki/The_King_of_Fighters_XIII/Controls)
- [Movement, hops and jumps](https://dreamcancel.com/wiki/The_King_of_Fighters_XIII/Movement)
- [Gameplay screenshot, urban arena](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/222940/ss_3b8b097bfa608f30831788536738596dd998ec4e.1920x1080.jpg)
- [Gameplay screenshot, power effect](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/222940/ss_a522194226e06093333ce35995e1d9a5920c91ae.1920x1080.jpg)

## Observed

The urban gameplay screenshot shows tall, detailed shaded human sprites with
recognizable costume silhouettes, simultaneous airborne uppercuts, large orange
and violet fire arcs, a lively crowd and illuminated city behind a railing.
The foreground is a reflective gridded platform. Long green health bars sit across
the top with metallic angular framing, portraits at the outside corners and a
central hexagonal clock. Guard gauges sit under health; power stocks and long
segmented meters occupy the bottom corners. Typography is emphatic and italic.
The second screenshot shows a darkened screen and huge luminous special effect.
The manual/listing describes three-person ordered teams, and the control
documentation distinguishes light/strong punch/kick, roll, guard cancel, low/
overhead attacks and four jump types.

## Implemented interpretation

Crown Clash has six original fighters, selected in fighting order, individual
roster health, automatic replacement after KO, retained winner health with a
small recovery, and victory only after all three opposing fighters are eliminated.
Touch inputs expose four attack strengths, crouch/guard, hop/jump, roll, character
special, and a two-stock super. Specials have projectile, rush and anti-air
archetypes. Three power stocks persist across the team; guard pressure causes a
temporary guard break. Normals can cancel into specials and specials into super.
This is an authored combat model, not measured original frame data.

Original generated arena, portraits and sprite poses are used directly in the
game. Sprite animation adds breathing, footwork, anticipations, impacts, airborne
arcs, trails and hit flashes. The generated fighter sheets have four authored
poses per fighter; they do not reproduce XIII's many hand-drawn animation frames.
Audio is locally synthesized original percussion/bass music and action cues.
No extracted game assets, ROMs or proprietary executable are included.

## Evidence limits

Original arcade software was not available. Public screenshots and written
mechanics were accessible; original gameplay could not be exercised or captured
twice. No literal pixel parity, complete roster equivalence, original frame
timing, sound equivalence or rollback-netcode equivalence is claimed.
The clone-this research/evidence workflow is used, but its exact-parity gate
remains unpassed. The user's permitted approximation takes precedence.

## Audit inventory

| Area | Coverage |
| --- | --- |
| Source | Official screenshots + public controls/movement documentation |
| Navigation | Lobby → team selection/order → ready → bout → KO transition → result → rematch |
| Roles | Two guests, distinct IDs, no accounts, no AI opponent |
| States | Invalid room, full room, disconnected pause, reconnect, countdown, timeout, KO, result |
| Responsive | Landscape iPhone; native scalable scene, safe-area controls |
| Data | Authoritative WebSocket snapshots, ordered inputs, resumable room token |
| Assets | Original generated artwork and synthesized audio; sources above |
| Accessibility | Labeled lobby and touch controls; action gameplay remains visual |
| Reliability | Build, Swift format lint, deterministic combat and real socket tests |
| Rebrand | Crown Clash / com.dabit.crownclash; no SNK assets or logos |
