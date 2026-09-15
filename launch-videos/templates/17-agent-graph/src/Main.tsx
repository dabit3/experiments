import React from "react";
import { AbsoluteFill, Img, staticFile } from "remotion";
import { Heading, Label, Seq, useEnterExit } from "./components";
import { FeatureScene, FeatureStep } from "./FeatureScene";
import { Graph } from "./Graph";
import { SCENES, Scene } from "./scenes";
import { MARGIN, color, font, type, useFrame } from "./theme";

const Hook: React.FC<{ scene: Scene }> = ({ scene }) => (
  <AbsoluteFill style={{ alignItems: "center", justifyContent: "center", gap: 36 }}>
    <Label from={scene.from + 4} to={scene.to} align="center">
      Devin · macOS · native iOS
    </Label>
    <Heading from={scene.from + 10} to={scene.to} size={type.sizes1080p.hero} align="center">
      Devin now runs on Mac.
    </Heading>
  </AbsoluteFill>
);

const Context: React.FC<{ scene: Scene }> = ({ scene }) => {
  const mid = scene.from + Math.round(scene.dur / 2);
  return (
    <AbsoluteFill style={{ justifyContent: "center", paddingLeft: MARGIN, paddingRight: MARGIN }}>
      <div style={{ position: "absolute", left: MARGIN, top: 380 }}>
        <Label from={scene.from + 2} to={scene.to}>
          Before
        </Label>
      </div>
      <div style={{ position: "absolute", left: MARGIN, top: 440, right: MARGIN }}>
        <Heading from={scene.from + 8} to={mid} maxWidth={1500}>
          {"iOS teams QA'd the app by hand,\nor waited 20+ minutes for CI."}
        </Heading>
      </div>
      <div style={{ position: "absolute", left: MARGIN, top: 440, right: MARGIN }}>
        <Heading from={mid + 4} to={scene.to} maxWidth={1500}>
          {"No coding agent could build, run\nand tap through an iPhone app."}
        </Heading>
      </div>
    </AbsoluteFill>
  );
};

const Plan: React.FC<{ scene: Scene }> = ({ scene }) => (
  <AbsoluteFill>
    <div style={{ position: "absolute", left: MARGIN, top: 150, display: "flex", flexDirection: "column", gap: 24 }}>
      <Label from={scene.from + 6} to={scene.to + 6}>
        Agent plan · 7 steps
      </Label>
      <Heading from={scene.from + 12} to={scene.to + 6} size={type.sizes1080p.h3}>
        Devin plans the work, then runs it in a Mac VM.
      </Heading>
    </div>
  </AbsoluteFill>
);

const Outcome: React.FC<{ scene: Scene }> = ({ scene }) => {
  const mid = scene.from + Math.round(scene.dur / 2);
  return (
    <AbsoluteFill>
      <div style={{ position: "absolute", left: MARGIN, right: MARGIN, top: 200, textAlign: "center" }}>
        <Label from={scene.from + 12} to={scene.to} align="center">
          Result
        </Label>
      </div>
      <div style={{ position: "absolute", left: MARGIN, right: MARGIN, top: 262, display: "flex", justifyContent: "center" }}>
        <Heading from={scene.from + 18} to={mid} align="center">
          Minutes, not 20+ minute CI round-trips.
        </Heading>
      </div>
      <div style={{ position: "absolute", left: MARGIN, right: MARGIN, top: 262, display: "flex", justifyContent: "center" }}>
        <Heading from={mid + 4} to={scene.to} align="center">
          The only coding agent with a Mac cloud agent.
        </Heading>
      </div>
    </AbsoluteFill>
  );
};

const End: React.FC<{ scene: Scene }> = ({ scene }) => {
  const frame = useFrame();
  const lockup = useEnterExit(scene.from + 4, scene.to + 30, 26);
  const line = useEnterExit(scene.from + 16, scene.to + 30, 24);
  return (
    <AbsoluteFill style={{ alignItems: "center", justifyContent: "center", gap: 40 }}>
      <Img
        src={staticFile("brand/devin-lockup-horizontal-white.png")}
        style={{ width: 520, opacity: lockup.opacity, transform: `translateY(${lockup.rise}px)` }}
      />
      <div
        style={{
          fontFamily: font.sans,
          fontWeight: 400,
          fontSize: type.sizes1080p.body,
          letterSpacing: type.tracking.body,
          color: color.gray300,
          opacity: line.opacity,
          transform: `translateY(${line.rise}px)`,
        }}
      >
        Build, run and test iOS apps in the cloud.
      </div>
      <div
        style={{
          fontFamily: font.mono,
          fontWeight: 500,
          fontSize: type.sizes1080p.label,
          letterSpacing: type.tracking.caps,
          color: color.gray500,
          opacity: frame > scene.from + 28 ? line.opacity : 0,
        }}
      >
        devin.ai
      </div>
    </AbsoluteFill>
  );
};

const BUILD: FeatureStep[] = [
  {
    index: 0,
    shot: { file: "screens/devin-web-13.png", origin: "50% 70%" },
    headline: "Devin clones the repo and reads the brief.",
    log: "git clone dabit3/experiments · main",
  },
  {
    index: 1,
    shot: { file: "screens/devin-desktop-5.png", origin: "50% 25%", position: "50% 14%", scale: 1.08 },
    headline: "It builds the app in Xcode, inside the session.",
    log: "xcodebuild build → BUILD SUCCEEDED",
  },
];

const SIMULATOR: FeatureStep[] = [
  {
    index: 2,
    shot: { file: "screens/devin-web-11.png", origin: "32% 45%" },
    headline: "It boots a live iPhone Simulator you can watch.",
    log: "simctl boot 'iPhone 17 Pro' · iOS 26.5",
  },
  {
    index: 3,
    shot: { file: "screens/devin-web-10.png", origin: "32% 50%" },
    headline: "It taps and types like a person, and reproduces the bug.",
    log: "stream reply test → 3 FAILED",
  },
];

const FIX: FeatureStep[] = [
  {
    index: 4,
    shot: { file: "screens/devin-desktop-7.png", origin: "55% 25%", position: "50% 14%", scale: 1.08 },
    headline: "It fixes the code and rebuilds.",
    log: "fix @MainActor → BUILD SUCCEEDED",
  },
  {
    index: 5,
    shot: { file: "screens/devin-desktop-9.png", origin: "30% 45%", position: "50% 25%" },
    headline: "Then re-runs the UI tests in the Simulator.",
    log: "xcodebuild test → 5 passed, 0 failed",
  },
];

const PR: FeatureStep[] = [
  {
    index: 6,
    shot: { file: "screens/devin-web-9.png", origin: "70% 30%" },
    headline: "It opens a PR with the Simulator recording attached.",
    log: "gh pr create → #161 · Ready to merge",
  },
];

export const Main: React.FC = () => {
  return (
    <AbsoluteFill style={{ background: color.darkBg, color: color.white }}>
      <Seq from={SCENES.hook.from} dur={SCENES.hook.dur} name="Hook">
        <Hook scene={SCENES.hook} />
      </Seq>
      <Seq from={SCENES.context.from} dur={SCENES.context.dur} name="Context">
        <Context scene={SCENES.context} />
      </Seq>

      <Seq from={SCENES.plan.from} dur={SCENES.end.from - SCENES.plan.from} name="Graph">
        <Graph />
      </Seq>

      <Seq from={SCENES.plan.from} dur={SCENES.plan.dur + 6} name="Plan">
        <Plan scene={SCENES.plan} />
      </Seq>
      <Seq from={SCENES.build.from} dur={SCENES.build.dur} name="Clone + Build">
        <FeatureScene scene={SCENES.build} steps={BUILD} />
      </Seq>
      <Seq from={SCENES.simulator.from} dur={SCENES.simulator.dur} name="Simulator">
        <FeatureScene scene={SCENES.simulator} steps={SIMULATOR} />
      </Seq>
      <Seq from={SCENES.fix.from} dur={SCENES.fix.dur} name="Fix + Tests">
        <FeatureScene scene={SCENES.fix} steps={FIX} />
      </Seq>
      <Seq from={SCENES.pr.from} dur={SCENES.pr.dur} name="Open PR">
        <FeatureScene scene={SCENES.pr} steps={PR} />
      </Seq>
      <Seq from={SCENES.outcome.from} dur={SCENES.outcome.dur} name="Outcome">
        <Outcome scene={SCENES.outcome} />
      </Seq>
      <Seq from={SCENES.end.from} dur={SCENES.end.dur} name="End card">
        <End scene={SCENES.end} />
      </Seq>
    </AbsoluteFill>
  );
};
