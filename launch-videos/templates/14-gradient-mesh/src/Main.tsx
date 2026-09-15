import React from "react";
import { AbsoluteFill, Sequence } from "remotion";
import { Mesh } from "./Mesh";
import { sceneAt } from "./scenes";
import { Context } from "./scenes/Context";
import { EndCard } from "./scenes/EndCard";
import { Feature } from "./scenes/Feature";
import { Hook } from "./scenes/Hook";
import { Outcome } from "./scenes/Outcome";
import { sec } from "./tokens";

const Scene: React.FC<{ id: Parameters<typeof sceneAt>[0]; children: React.ReactNode }> = ({ id, children }) => {
  const s = sceneAt(id);
  return (
    <Sequence name={id} from={s.from} durationInFrames={s.durationInFrames}>
      {children}
    </Sequence>
  );
};

export const Main: React.FC = () => (
  <AbsoluteFill>
    <Mesh />

    <Scene id="hook">
      <Hook />
    </Scene>

    <Scene id="context">
      <Context />
    </Scene>

    <Scene id="featureRun">
      <Feature
        index="01"
        label="Build and run"
        lines={[
          { text: "Choose macOS.", at: sec(0.2) },
          { text: "Devin builds and runs the app in the Simulator.", at: sec(2.9) },
        ]}
        shots={[
          { src: "devin-web-1", at: 0, origin: [0.25, 0.6] },
          { src: "devin-web-4", at: sec(1.5), origin: [0.25, 0.6] },
          { src: "devin-desktop-9", at: sec(3.4), origin: [0.5, 0.02] },
        ]}
        cursor={[
          { at: sec(0.3), x: 0.42, y: 0.8 },
          { at: sec(1.1), x: 0.255, y: 0.605, click: true },
          { at: sec(1.6), x: 0.255, y: 0.605 },
          { at: sec(2.3), x: 0.27, y: 0.735, click: true },
          { at: sec(3.0), x: 0.27, y: 0.735 },
          { at: sec(3.6), x: 0.62, y: 1.3 },
        ]}
        zoom={[1, 1.05]}
      />
    </Scene>

    <Scene id="featureLive">
      <Feature
        index="02"
        label="Live Simulator"
        lines={[
          { text: "A live iPhone Simulator, inside the session.", at: sec(0.2) },
          { text: "Devin taps, types and scrolls. You can too.", at: sec(3.6) },
        ]}
        shots={[
          { src: "devin-web-11", at: 0, origin: [0.33, 0.5] },
          { src: "devin-web-10", at: sec(2.6), origin: [0.33, 0.5] },
        ]}
        zoom={[1, 1.1]}
      />
    </Scene>

    <Scene id="featureFix">
      <Feature
        index="03"
        label="Fix and ship"
        lines={[
          { text: "Devin reproduces the bug and fixes it.", at: sec(0.2) },
          { text: "Re-runs the UI tests. Opens the PR.", at: sec(3.8) },
        ]}
        shots={[
          { src: "devin-web-14", at: 0, origin: [0.32, 0.5] },
          { src: "devin-web-9", at: sec(3.0), origin: [0.78, 0.35] },
        ]}
        zoom={[1, 1.07]}
      />
    </Scene>

    <Scene id="featureMatrix">
      <Feature
        index="04"
        label="Every screen"
        lines={[
          { text: "iPhone and iPad. Dark mode. Every orientation.", at: sec(0.2) },
          { text: "Compared pixel for pixel.", at: sec(4.0) },
        ]}
        shots={[
          { src: "devin-web-19", at: 0, origin: [0.33, 0.5] },
          { src: "devin-web-17", at: sec(3.2), origin: [0.4, 0] },
        ]}
        zoom={[1.01, 1.07]}
      />
    </Scene>

    <Scene id="outcome">
      <Outcome />
    </Scene>

    <Scene id="endCard">
      <EndCard />
    </Scene>
  </AbsoluteFill>
);
