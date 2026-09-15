import React from "react";
import { AbsoluteFill, interpolate, Sequence, useCurrentFrame } from "remotion";
import { Grain, Streak } from "./components/FilmLayer";
import { SCENES, SceneId, TOTAL_FRAMES, XFADE } from "./scenes";
import { BuildRun } from "./scenes/BuildRun";
import { ChoosePlatform } from "./scenes/ChoosePlatform";
import { Context } from "./scenes/Context";
import { DeviceMatrix } from "./scenes/DeviceMatrix";
import { EndCard } from "./scenes/EndCard";
import { FixAndPr } from "./scenes/FixAndPr";
import { Hook } from "./scenes/Hook";
import { LiveSimulator } from "./scenes/LiveSimulator";
import { Outcome } from "./scenes/Outcome";
import { BAR_HEIGHT, HEIGHT, PICTURE_HEIGHT, PICTURE_TOP, tokens, WIDTH } from "./tokens";

const COMPONENTS: Record<SceneId, React.FC<{ duration: number }>> = {
  hook: Hook,
  context: Context,
  choosePlatform: ChoosePlatform,
  buildRun: BuildRun,
  liveSimulator: LiveSimulator,
  fixAndPr: FixAndPr,
  deviceMatrix: DeviceMatrix,
  outcome: Outcome,
  endCard: EndCard,
};

/** Dissolve: each scene sits above the previous one and fades in over XFADE frames. */
const Dissolve: React.FC<{ fadeIn: boolean; children: React.ReactNode }> = ({ fadeIn, children }) => {
  const frame = useCurrentFrame();
  const opacity = fadeIn
    ? interpolate(frame, [0, XFADE], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp" })
    : 1;
  return <AbsoluteFill style={{ opacity }}>{children}</AbsoluteFill>;
};

export const Main: React.FC = () => {
  const frame = useCurrentFrame();
  const fadeFromBlack = interpolate(frame, [0, 24], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  return (
    <AbsoluteFill style={{ background: tokens.color.black }}>
      {/* 2.39:1 picture */}
      <div
        style={{
          position: "absolute",
          left: 0,
          top: PICTURE_TOP,
          width: WIDTH,
          height: PICTURE_HEIGHT,
          overflow: "hidden",
          background: tokens.color.darkBg,
          opacity: fadeFromBlack,
        }}
      >
        {SCENES.map((scene, i) => {
          const Comp = COMPONENTS[scene.id];
          return (
            <Sequence key={scene.id} from={scene.from} durationInFrames={scene.duration} layout="none">
              <Dissolve fadeIn={i > 0}>
                <Comp duration={scene.duration} />
              </Dissolve>
            </Sequence>
          );
        })}
        <Streak y={PICTURE_HEIGHT * 0.32} driftFrom={-500} driftTo={700} totalFrames={TOTAL_FRAMES} />
        <Streak
          y={PICTURE_HEIGHT * 0.71}
          driftFrom={1300}
          driftTo={-100}
          totalFrames={TOTAL_FRAMES}
          width={800}
          opacity={0.35}
        />
        <Grain />
      </div>

      {/* Letterbox bars */}
      <div style={{ position: "absolute", left: 0, top: 0, width: WIDTH, height: BAR_HEIGHT, background: tokens.color.black }} />
      <div
        style={{
          position: "absolute",
          left: 0,
          top: PICTURE_TOP + PICTURE_HEIGHT,
          width: WIDTH,
          height: HEIGHT - (PICTURE_TOP + PICTURE_HEIGHT),
          background: tokens.color.black,
        }}
      />
    </AbsoluteFill>
  );
};
