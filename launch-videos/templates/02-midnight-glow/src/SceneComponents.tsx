import React from "react";
import { AbsoluteFill, Img, interpolate, staticFile, useCurrentFrame } from "remotion";
import {
  Backdrop,
  Cursor,
  Headline,
  Label,
  Pill,
  SceneFade,
  ScreenFrame,
  enter,
} from "./components";
import { MONO, SANS } from "./fonts";
import { color, easeOut, hairline, sec } from "./tokens";

/* Shared geometry for the four feature scenes: the screenshot frame sits
   below the headline and bleeds off the bottom edge (Linear-style). */
const FRAME = { x: 210, y: 320, width: 1500 };
const LABEL_Y = 104;
const HEAD_Y = 138;
const HEAD_SIZE = 48;

/* Intrinsic aspect ratios (w/h) of the screenshots we use. */
const ASPECT = {
  web4: 2988 / 1622,
  web9: 2988 / 1628,
  web10: 2990 / 1624,
  web11: 2986 / 1630,
  web13: 2982 / 1620,
  web17: 2978 / 1620,
  web19: 2982 / 1626,
};

/* Convert a fractional (u, v) position inside a screenshot to frame px. */
const at = (u: number, v: number, aspect: number) => ({
  x: Math.round(u * FRAME.width),
  y: Math.round((v * FRAME.width) / aspect),
});

/* ------------------------------------------------------------------ */
/* 1. Hook                                                             */
/* ------------------------------------------------------------------ */

export const Hook: React.FC = () => {
  const frame = useCurrentFrame();
  const glow = interpolate(frame, [0, sec(1.6)], [0.2, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeOut,
  });
  return (
    <SceneFade inDur={sec(0.2)}>
      <Backdrop glowY={560} glowSize={1700} glowOpacity={glow} />
      <Label x={0} y={392} width={1920} align="center" start={sec(0.1)} color={color.gray400}>
        Devin · macOS
      </Label>
      <Headline
        size={112}
        x={0}
        y={448}
        width={1920}
        align="center"
        start={sec(0.35)}
        glow={1.2}
      >
        Devin now runs on Mac.
      </Headline>
    </SceneFade>
  );
};

/* ------------------------------------------------------------------ */
/* 2. Problem / context                                                */
/* ------------------------------------------------------------------ */

export const Context: React.FC = () => {
  const frame = useCurrentFrame();
  const rule = enter(frame, sec(0.3), sec(1.0));
  return (
    <SceneFade>
      <Backdrop glowX={520} glowY={520} glowSize={1500} glowOpacity={0.7} />
      <Label x={120} y={300} start={sec(0.2)}>
        Before
      </Label>
      <div
        style={{
          position: "absolute",
          left: 120,
          top: 346,
          height: 1,
          width: 1680 * rule,
          background: hairline,
        }}
      />
      <Headline size={64} x={120} y={392} width={1500} start={sec(0.5)} holdUntil={sec(3.0)}>
        iOS teams QA'd by hand,{"\n"}or waited 20+ minutes on CI.
      </Headline>
      <Headline size={64} x={120} y={392} width={1500} start={sec(3.05)}>
        No coding agent could build, run{"\n"}and tap through an iPhone app.
      </Headline>
      <Label x={120} y={640} start={sec(3.4)} color={color.gray500}>
        Until now
      </Label>
    </SceneFade>
  );
};

/* ------------------------------------------------------------------ */
/* 3. Feature — pick macOS, build & run                                */
/* ------------------------------------------------------------------ */

export const FeatureMacOS: React.FC = () => {
  const swap = sec(3.9);
  const picker = at(0.27, 0.73, ASPECT.web4); // "macOS ✓" row in the platform menu
  const plan = at(0.325, 0.765, ASPECT.web13); // "Executing actions" row
  return (
    <SceneFade>
      <Backdrop glowX={700} glowY={760} glowSize={1600} />
      <Label x={120} y={LABEL_Y} start={0}>
        01 — Build & run
      </Label>
      <Headline size={HEAD_SIZE} x={120} y={HEAD_Y} start={sec(0.15)}>
        Pick macOS. Devin builds and runs{"\n"}the app in the iOS Simulator.
      </Headline>

      <ScreenFrame
        src="screens/devin-web-4.png"
        {...FRAME}
        aspect={ASPECT.web4}
        start={sec(0.4)}
        kenBurns={{ scale: [1.1, 1.16], y: [-40, -60], origin: "38% 68%" }}
      >
        <Pill
          label="macOS · hosted VM"
          anchor={{ x: picker.x + 60, y: picker.y }}
          pill={{ x: picker.x + 330, y: picker.y - 24 }}
          from="right"
          start={sec(1.4)}
          end={swap - sec(0.2)}
          tone="accent"
        />
        <Cursor
          path={[
            { x: 520, y: 420, at: sec(0.9) },
            { x: picker.x + 20, y: picker.y + 2, at: sec(2.2) },
            { x: picker.x + 20, y: picker.y + 2, at: sec(3.4) },
          ]}
          clicks={[sec(2.4)]}
        />
      </ScreenFrame>

      <ScreenFrame
        src="screens/devin-web-13.png"
        {...FRAME}
        aspect={ASPECT.web13}
        start={swap}
        rise={0}
        enterDur={sec(0.8)}
        kenBurns={{ scale: [1.04, 1.1], origin: "35% 80%", start: swap }}
      >
        <Pill
          label="Rebuild · rerun all tests"
          anchor={{ x: plan.x + 50, y: plan.y }}
          pill={{ x: plan.x + 300, y: plan.y - 6 }}
          from="right"
          start={swap + sec(1.0)}
          tone="success"
        />
      </ScreenFrame>
    </SceneFade>
  );
};

/* ------------------------------------------------------------------ */
/* 4. Feature — live Simulator                                         */
/* ------------------------------------------------------------------ */

export const FeatureSimulator: React.FC = () => {
  const swap = sec(3.2);
  const send = at(0.4, 0.81, ASPECT.web10); // send button on the phone
  const passed = at(0.66, 0.115, ASPECT.web10); // "12 passed" in the header
  const phone = at(0.32, 0.4, ASPECT.web11); // phone screen
  return (
    <SceneFade>
      <Backdrop glowX={760} glowY={780} glowSize={1600} />
      <Label x={120} y={LABEL_Y} start={0}>
        02 — Live Simulator
      </Label>
      <Headline size={HEAD_SIZE} x={120} y={HEAD_Y} start={sec(0.15)}>
        A live iPhone Simulator in the session.{"\n"}Devin taps, types and scrolls like a person.
      </Headline>

      <ScreenFrame
        src="screens/devin-web-11.png"
        {...FRAME}
        aspect={ASPECT.web11}
        start={sec(0.4)}
        kenBurns={{ scale: [1, 1.05], origin: "35% 55%" }}
      >
        <Pill
          label="You can watch — and tap too"
          anchor={{ x: phone.x, y: phone.y }}
          pill={{ x: phone.x - 200, y: phone.y - 16 }}
          from="left"
          start={sec(1.2)}
          end={swap - sec(0.2)}
        />
      </ScreenFrame>

      <ScreenFrame
        src="screens/devin-web-10.png"
        {...FRAME}
        aspect={ASPECT.web10}
        start={swap}
        rise={0}
        enterDur={sec(0.8)}
        kenBurns={{ scale: [1.05, 1.08], origin: "35% 55%", start: swap }}
      >
        <Pill
          label="12 passed"
          anchor={{ x: passed.x - 8, y: passed.y + 4 }}
          pill={{ x: passed.x + 200, y: passed.y - 78 }}
          from="right"
          start={swap + sec(1.3)}
          tone="success"
        />
        <Cursor
          path={[
            { x: 700, y: 430, at: swap + sec(0.2) },
            { x: send.x, y: send.y, at: swap + sec(1.4) },
            { x: send.x, y: send.y, at: swap + sec(2.2) },
            { x: 560, y: 300, at: swap + sec(3.6) },
          ]}
          clicks={[swap + sec(1.55)]}
        />
      </ScreenFrame>
    </SceneFade>
  );
};

/* ------------------------------------------------------------------ */
/* 5. Feature — reproduce, fix, test, PR                               */
/* ------------------------------------------------------------------ */

export const FeatureFixPR: React.FC = () => {
  const play = at(0.17, 0.45, ASPECT.web9); // play button on the Simulator recording
  const ready = at(0.635, 0.385, ASPECT.web9); // end of "Ready to merge"
  return (
    <SceneFade>
      <Backdrop glowX={1100} glowY={760} glowSize={1600} />
      <Label x={120} y={LABEL_Y} start={0}>
        03 — Fix & ship
      </Label>
      <Headline size={HEAD_SIZE} x={120} y={HEAD_Y} start={sec(0.15)}>
        Reproduce the bug. Fix it.{"\n"}Re-run the UI tests. Open the PR.
      </Headline>

      <ScreenFrame
        src="screens/devin-web-9.png"
        {...FRAME}
        aspect={ASPECT.web9}
        start={sec(0.4)}
        kenBurns={{ scale: [1.0, 1.08], x: [0, -60], origin: "60% 40%" }}
      >
        <Pill
          label="Simulator run · 12 passed"
          anchor={{ x: play.x, y: play.y }}
          pill={{ x: play.x + 250, y: play.y - 40 }}
          from="right"
          start={sec(1.3)}
          end={sec(4.0)}
        />
        <Pill
          label="Ready to merge"
          anchor={{ x: ready.x, y: ready.y }}
          pill={{ x: ready.x + 170, y: ready.y - 68 }}
          from="right"
          start={sec(3.9)}
          tone="success"
        />
      </ScreenFrame>
    </SceneFade>
  );
};

/* ------------------------------------------------------------------ */
/* 6. Feature — device matrix                                          */
/* ------------------------------------------------------------------ */

export const FeatureMatrix: React.FC = () => {
  const swap = sec(4.2);
  const darkTile = at(0.49, 0.83, ASPECT.web17); // right edge of "Dark settings" tile
  const ipad = at(0.09, 0.5, ASPECT.web19); // left bezel of the iPad
  return (
    <SceneFade>
      <Backdrop glowX={960} glowY={800} glowSize={1600} />
      <Label x={120} y={LABEL_Y} start={0}>
        04 — Every screen
      </Label>
      <Headline size={HEAD_SIZE} x={120} y={HEAD_Y} start={sec(0.15)}>
        iPhone and iPad, dark mode, every orientation.{"\n"}Compared pixel for pixel.
      </Headline>

      <ScreenFrame
        src="screens/devin-web-17.png"
        {...FRAME}
        aspect={ASPECT.web17}
        start={sec(0.4)}
        kenBurns={{ scale: [1.04, 1.12], y: [0, -90], origin: "50% 50%", dur: swap + sec(0.6) }}
      >
        <Pill
          label="Dark mode · 6 screens"
          anchor={{ x: darkTile.x, y: darkTile.y }}
          pill={{ x: darkTile.x + 270, y: darkTile.y - 40 }}
          from="right"
          start={sec(2.0)}
          end={swap - sec(0.2)}
        />
      </ScreenFrame>

      <ScreenFrame
        src="screens/devin-web-19.png"
        {...FRAME}
        aspect={ASPECT.web19}
        start={swap}
        rise={0}
        enterDur={sec(0.8)}
        kenBurns={{ scale: [1.0, 1.04], x: [0, 30], origin: "50% 45%", start: swap }}
      >
        <Pill
          label="iPad Pro 13″"
          anchor={{ x: ipad.x, y: ipad.y }}
          pill={{ x: ipad.x - 90, y: ipad.y - 30 }}
          from="left"
          start={swap + sec(1.0)}
          tone="accent"
        />
      </ScreenFrame>
    </SceneFade>
  );
};

/* ------------------------------------------------------------------ */
/* 7. Outcome / metrics                                                */
/* ------------------------------------------------------------------ */

const METRICS = [
  { k: "Speed", v: "Minutes, not 20+ minute CI round\u2011trips." },
  { k: "Only", v: "The only coding agent with a Mac cloud agent." },
  { k: "Same", v: "Same security, same price as Linux sessions." },
];

export const Outcome: React.FC = () => {
  const frame = useCurrentFrame();
  const colW = 1680 / 3;
  return (
    <SceneFade>
      <Backdrop glowX={960} glowY={420} glowSize={1700} glowOpacity={0.9} />
      <Label x={0} y={236} width={1920} align="center" start={0}>
        The outcome
      </Label>
      <Headline size={80} x={0} y={286} width={1920} align="center" start={sec(0.2)}>
        Build, run and test iOS apps{"\n"}in the cloud.
      </Headline>
      {METRICS.map((m, i) => {
        const p = enter(frame, sec(1.6 + i * 0.25), sec(0.8));
        return (
          <div
            key={m.k}
            style={{
              position: "absolute",
              left: 120 + i * colW,
              top: 640,
              width: colW - 48,
              opacity: p,
              transform: `translateY(${(1 - p) * 24}px)`,
            }}
          >
            <div style={{ height: 1, background: hairline, marginBottom: 28 }} />
            <div
              style={{
                fontFamily: MONO,
                fontSize: 18,
                fontWeight: 500,
                letterSpacing: "0.04em",
                textTransform: "uppercase",
                color: color.accentSoft,
                textShadow: "0 0 18px rgba(34,0,255,0.6)",
                marginBottom: 20,
              }}
            >
              0{i + 1} — {m.k}
            </div>
            <div
              style={{
                fontFamily: SANS,
                fontSize: 30,
                fontWeight: 400,
                lineHeight: 1.3,
                letterSpacing: "-0.015em",
                color: color.gray300,
              }}
            >
              {m.v}
            </div>
          </div>
        );
      })}
    </SceneFade>
  );
};

/* ------------------------------------------------------------------ */
/* 8. End card                                                         */
/* ------------------------------------------------------------------ */

export const EndCard: React.FC = () => {
  const frame = useCurrentFrame();
  const p = enter(frame, sec(0.2), sec(1.0));
  const glow = interpolate(frame, [0, sec(1.8)], [0.3, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeOut,
  });
  const lockupW = 560;
  const lockupH = Math.round((lockupW * 1024) / 2984);
  return (
    <SceneFade outDur={sec(0.6)}>
      <Backdrop glowY={520} glowSize={1500} glowOpacity={glow} />
      <AbsoluteFill style={{ alignItems: "center", justifyContent: "center" }}>
        <div
          style={{
            opacity: p,
            transform: `translateY(${(1 - p) * 24}px)`,
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            gap: 36,
            marginTop: -40,
          }}
        >
          <Img
            src={staticFile("brand/devin-lockup-horizontal-white.png")}
            style={{ width: lockupW, height: lockupH, filter: "drop-shadow(0 0 36px rgba(34,0,255,0.55))" }}
          />
          <div
            style={{
              fontFamily: SANS,
              fontSize: 32,
              fontWeight: 400,
              letterSpacing: "-0.015em",
              color: color.gray300,
              textAlign: "center",
            }}
          >
            The only coding agent with a Mac cloud agent.
          </div>
        </div>
      </AbsoluteFill>
      <Label x={0} y={900} width={1920} align="center" start={sec(1.2)} color={color.gray500}>
        devin.ai
      </Label>
    </SceneFade>
  );
};
