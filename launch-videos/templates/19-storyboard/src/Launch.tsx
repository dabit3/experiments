import React, { useMemo } from "react";
import { AbsoluteFill, Sequence, interpolate, useCurrentFrame } from "remotion";
import type { LaunchProps, Scene } from "./schema";
import { Panel } from "./components/Panel";
import { Header } from "./components/Header";
import { Caption } from "./components/Caption";
import { Title } from "./components/Title";
import { Outro } from "./components/Outro";
import {
  fadeIn,
  panelRuns,
  panelStateAt,
  sceneAt,
  sceneStarts,
} from "./timeline";
import { loadFonts } from "./fonts";
import { MARGIN } from "./defaults";

loadFonts();

const activePanel = (scene: Scene | undefined) =>
  scene?.panels.find((p) => p.role === "active");

export const Launch: React.FC<LaunchProps> = (props) => {
  const { brand, content, media, scenes, storyboard: sb } = props;
  const frame = useCurrentFrame();

  const starts = useMemo(() => sceneStarts(scenes), [scenes]);
  const runs = useMemo(() => panelRuns(scenes, sb), [scenes, sb]);
  const numberOf = useMemo(() => {
    const m = new Map<string, number>();
    for (const r of runs) m.set(r.slot, r.number);
    return m;
  }, [runs]);

  const { index, scene, local } = sceneAt(scenes, starts, frame);
  const prev = index > 0 ? scenes[index - 1] : undefined;
  const settle = interpolate(local, [0, sb.moveFrames], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  // Header: cross-fade between scenes that show / hide it.
  const headerNow = scene.showHeader ? 1 : 0;
  const headerPrev = prev ? (prev.showHeader ? 1 : 0) : 0;
  const headerOpacity =
    index === 0
      ? fadeIn(local, 0, 20) * headerNow
      : headerPrev + (headerNow - headerPrev) * settle;

  // Captions: the new caption appears once the layout has settled; a changed
  // caption from the previous scene fades out at the scene start.
  const captionChanged = !prev || prev.captionIndex !== scene.captionIndex;
  const curActive = activePanel(scene);
  const prevActive = activePanel(prev);
  const curCaption =
    scene.captionIndex !== null && curActive
      ? {
          text: content.captions[scene.captionIndex] ?? "",
          anchor: curActive.rect,
          number: numberOf.get(curActive.slot) ?? 0,
          placement: scene.captionPlacement,
          badge:
            (media[curActive.slot]?.playbackRate ?? 1) > 1
              ? content.speedBadge
              : null,
          progress: captionChanged
            ? fadeIn(local, sb.moveFrames, sb.captionFadeFrames)
            : 1,
        }
      : null;
  const oldCaption =
    captionChanged &&
    prev &&
    prev.captionIndex !== null &&
    prevActive &&
    local < sb.captionFadeFrames
      ? {
          text: content.captions[prev.captionIndex] ?? "",
          anchor: prevActive.rect,
          number: numberOf.get(prevActive.slot) ?? 0,
          placement: prev.captionPlacement,
          progress: 1 - local / sb.captionFadeFrames,
        }
      : null;

  const titleProgress = scene.kind === "title" ? fadeIn(local, 0, 20) : 1;
  const titleExit =
    scene.kind === "title"
      ? 0
      : prev?.kind === "title"
        ? Math.min(1, local / sb.exitFrames)
        : 1;
  const showTitle = scene.kind === "title" || prev?.kind === "title";

  const panelStates = runs
    .map((run) => ({
      run,
      state: panelStateAt(scenes, starts, run, frame, sb),
    }))
    .filter((p) => p.state !== null)
    .sort((a, b) => (a.state?.activeness ?? 0) - (b.state?.activeness ?? 0));

  return (
    <AbsoluteFill style={{ background: brand.paper }}>
      {showTitle ? (
        <Title
          brand={brand}
          content={content}
          progress={titleProgress}
          exit={titleExit}
        />
      ) : null}
      <Header
        brand={brand}
        content={content}
        stage={scene.stage}
        opacity={headerOpacity}
      />
      {panelStates.map(({ run, state }) => {
        const m = media[run.slot];
        if (!m || !state) return null;
        const chrome = interpolate(state.rect.x, [0, MARGIN * 0.5], [0, 1], {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
        });
        return (
          <Sequence
            key={`${run.slot}-${run.fromScene}`}
            from={run.mountFrame}
            durationInFrames={Math.max(1, run.unmountFrame - run.mountFrame)}
            layout="none"
          >
            <Panel
              media={m}
              state={state}
              number={run.number}
              brand={brand}
              sb={sb}
              chrome={chrome}
            />
          </Sequence>
        );
      })}
      {oldCaption ? (
        <Caption
          brand={brand}
          text={oldCaption.text}
          number={oldCaption.number}
          placement={oldCaption.placement}
          anchor={oldCaption.anchor}
          progress={oldCaption.progress}
          speedBadge={null}
        />
      ) : null}
      {curCaption ? (
        <Caption
          brand={brand}
          text={curCaption.text}
          number={curCaption.number}
          placement={curCaption.placement}
          anchor={curCaption.anchor}
          progress={curCaption.progress}
          speedBadge={curCaption.badge}
        />
      ) : null}
      {scene.kind === "outro" ? (
        <Outro brand={brand} content={content} progress={fadeIn(local, sb.exitFrames + 4, 18)} />
      ) : null}
    </AbsoluteFill>
  );
};
