# Reference research — 13 September 2026

Reference: **jubeat (2008–)**, KONAMI. New app: **Prism Sixteen**.

## Sources actually read

- [2008 AOU photographs and gameplay description, GIGAZINE](https://gigazine.net/gsc_news/en/20080215_jubeat/)
- [Cabinet / panel photograph](https://i.gzn.jp/img/2008/02/15/jubeat/P1000206_m.jpg)
- [Tutorial / illuminated square photograph](https://i.gzn.jp/img/2008/02/15/jubeat/P1000208_m.jpg)
- [Tutorial HUD photograph](https://i.gzn.jp/img/2008/02/15/jubeat/P1000209_m.jpg)
- [KONAMI official Ave. how-to / Q&A](https://p.eagate.573.jp/game/jubeat/ave/howto/qa.html)
- [Official music-bar screenshot](https://eacache.s.konaminet.jp/game/jubeat/ave/images/howto/qa/qa_musicbar_01.png)
- [RemyWiki: gameplay, multiplayer, scoring](https://remywiki.com/What_is_jubeat)

The photographs and music-bar screenshot were downloaded to the ignored local
research run and visually inspected before implementation. They are research
evidence only, not redistributed or used as game textures.

## Observed in images

The original cabinet has sixteen physical transparent square panels in a 4×4
matrix, with a separate upper information area. Dark framing, fine pale square
outlines, blue technical lines and bright cyan/green markers create a luminous
glass appearance. The tutorial photograph shows an expanding layered square.
The official later-version screenshot places large square sleeve art on the left,
condensed song/level information on the right and a note-density histogram below.

## Documented behavior

Markers animate within individual cells; there is no falling-note highway.
Players tap at each marker's hot point. Simultaneous panels and three difficulties
are central to the game. Network players perform the same song. Official
documentation describes shutters opening with good play and closing with misses;
the community scoring documentation specifies 900,000 judgment points plus up to
100,000 shutter bonus. The music bar represents upcoming note density.

## Authored interpretation and boundaries

Prism Sixteen uses a portrait iPhone, a dark glossy 4×4 frame, cyan/pink concentric
square markers that converge on a fixed hot-point outline, square original cover
art, a density bar, local audio, three hand-patterned difficulties, a shutter gauge
and linked two-player HUD. The numerical timing windows (45/90/140 ms), original
music, note charts, guest room protocol, clean typography and geometric cover
art are authored choices, not measurements of the proprietary game.

Two original tracks are generated from explicit musical phrases and deterministic
DSP. Refraction's cover was generated for this project; Afterglow's hue variation
is a native rendering of that same original artwork. All art appears inside the
game. No ROMs, ripped tracks, proprietary fonts, or extracted assets are included.

The accessible arcade cannot be executed here, so direct interaction traces,
frame-matched screenshot diffs and literal pixel parity are unavailable. The
clone-this research/evidence procedure was consulted, but its strict zero-pixel
completion gate is **not passed or claimed**. The user's explicit approximation
permission and required PR delivery supersede those incompatible gates.

## Acceptance inventory

| ID | Behavior | Evidence method |
|---|---|---|
| P01 | Sixteen independent panels and simultaneous chords | Native multi-touch and driver paths; live recording |
| P02 | Markers follow the locally scheduled song clock | Common server epoch; audio scheduling logs; both displays |
| P03 | Timing judgments, combo, misses, shutter, million-point score | Server boundary tests and complete match |
| P04 | Selection, difficulty, cover and density preview | Native UI interaction |
| P05 | Guest create/join, both ready, live rival score, same outcome | Two real WebSocket connections and simulator recording |
| P06 | Result / rematch / reconnect | Protocol tests and native rematch |
| P07 | Original audible tracks with authored patterns | Generated PCM validation and recorded gameplay |
| P08 | Manual panel input and clear automation labeling | Native tap path plus visible driver status |
