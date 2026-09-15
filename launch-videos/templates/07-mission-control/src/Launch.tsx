import React, { useMemo } from "react";
import { AbsoluteFill, Sequence, useCurrentFrame, useVideoConfig } from "remotion";
import { Bays, BAY_HEADER } from "./components/Bays";
import { CaptionBar } from "./components/CaptionBar";
import { HeroCard, TitleCard } from "./components/Cards";
import { Header } from "./components/Header";
import { Media } from "./components/Media";
import { MonoLabel, Panel } from "./components/Panel";
import { loadFonts } from "./fonts";
import { computeGeometry, lerpRect, type Rect } from "./layout";
import { enter, leave, move } from "./motion";
import type { BayStatus, LaunchProps, Scene } from "./schema";

loadFonts();

type TimedScene = { scene: Scene; start: number; end: number; index: number };

export const timeScenes = (scenes: Scene[]): TimedScene[] => {
  let cursor = 0;
  return scenes.map((scene, index) => {
    const start = cursor;
    cursor += scene.durationInFrames;
    return { scene, start, end: cursor, index };
  });
};

export const totalDuration = (scenes: Scene[]) =>
  scenes.reduce((sum, s) => sum + s.durationInFrames, 0);

const PRIMARY_HEADER = BAY_HEADER;

export const Launch: React.FC<LaunchProps> = (props) => {
  const { brand, content, media, bays, statusLabels, layout, scenes } = props;
  const frame = useCurrentFrame();
  const { width, height } = useVideoConfig();

  const geometry = useMemo(
    () => computeGeometry(layout, width, height, bays.length),
    [layout, width, height, bays.length],
  );
  const timed = useMemo(() => timeScenes(scenes), [scenes]);

  const current =
    timed.find((t) => frame >= t.start && frame < t.end) ?? timed[timed.length - 1];
  if (!current) return null;
  const local = frame - current.start;
  const scene = current.scene;
  const isHero = scene.primary === "hero";
  const T = layout.transitionFrames;

  // Closing consolidation: bays + caption leave, primary grows into the hero view.
  const consolidate = isHero ? move(local, 0, layout.consolidateFrames) : 0;
  const primaryRect: Rect = lerpRect(geometry.primary, geometry.primaryExpanded, consolidate);
  const sideOpacity = isHero ? leave(local, 0, Math.round(layout.consolidateFrames * 0.6)) : 1;

  // Opening entrances.
  const headerIn = enter(frame, 0, 12);
  const primaryIn = enter(frame, 0, 14);
  const bayEntrances = bays.map((_, i) => enter(frame, 8 + i * 6, 14));

  // Bay statuses follow the active bay: earlier bays are held, the active one is live.
  const activeIndex = scene.activeBay ? bays.findIndex((b) => b.id === scene.activeBay) : -1;
  const statuses: BayStatus[] = bays.map((_, i) => {
    if (activeIndex < 0) return isHero ? "held" : "standby";
    if (i < activeIndex) return "held";
    if (i === activeIndex) return "live";
    return "standby";
  });

  // Caption: last cue whose offset has passed.
  const cue = [...scene.captions].filter((c) => c.at <= local).pop();
  const captionText = cue ? content.captions[cue.caption] : undefined;
  const captionProgress = cue ? enter(local, cue.at, 12) : 0;
  const useCase = scene.useCase === undefined ? undefined : content.useCases[scene.useCase];

  const mediaW = primaryRect.w;
  const mediaH = primaryRect.h - PRIMARY_HEADER;
  const inspecting =
    activeIndex >= 0 ? bays[activeIndex]?.label : isHero ? undefined : content.eyebrow;

  return (
    <AbsoluteFill style={{ background: brand.black }}>
      <Header
        rect={geometry.header}
        brand={brand}
        content={content}
        stage={scene.stage}
        opacity={headerIn}
      />

      <Panel rect={primaryRect} brand={brand} radius={layout.panelRadius} opacity={primaryIn}>
        <div
          style={{
            position: "absolute",
            left: 0,
            top: 0,
            right: 0,
            height: PRIMARY_HEADER,
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
            padding: "0 16px",
            borderBottom: `1px solid ${brand.consoleLine}`,
            zIndex: 2,
          }}
        >
          <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
            <MonoLabel brand={brand} color={brand.inkMuted} size={12}>
              00
            </MonoLabel>
            <MonoLabel brand={brand} color={brand.white} size={12}>
              Primary display
            </MonoLabel>
          </div>
          <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
            {scene.speedBadge ? (
              <div
                style={{
                  height: 22,
                  padding: "0 10px",
                  borderRadius: 8,
                  boxShadow: `inset 0 0 0 1px ${brand.consoleLine}`,
                  display: "flex",
                  alignItems: "center",
                }}
              >
                <MonoLabel brand={brand} color={brand.white} size={11}>
                  {content.speedBadge}
                </MonoLabel>
              </div>
            ) : null}
            {inspecting ? (
              <MonoLabel brand={brand} color={brand.inkMuted} size={12}>
                {inspecting}
              </MonoLabel>
            ) : null}
          </div>
        </div>

        <div
          style={{
            position: "absolute",
            left: 0,
            top: PRIMARY_HEADER,
            width: mediaW,
            height: mediaH,
            overflow: "hidden",
            background: brand.black,
          }}
        >
          {timed.map(({ scene: s, start, index }) => {
            // Each scene's primary content overlaps the next by T frames so the newcomer
            // can fade in on top (ease-in-out crossfade, no cut).
            const fadeIn = index === 0 ? 1 : move(frame, start, T);
            const from = start;
            const duration = s.durationInFrames + T;
            const slot = media[s.primary];
            return (
              <Sequence key={s.id} from={from} durationInFrames={duration} layout="none">
                <div style={{ position: "absolute", inset: 0, opacity: fadeIn }}>
                  {s.primary === "title" ? (
                    <TitleCard
                      brand={brand}
                      content={content}
                      width={mediaW}
                      height={mediaH}
                      steps={[enter(frame, 18, 14), enter(frame, 26, 16), enter(frame, 38, 16)]}
                    />
                  ) : s.primary === "hero" ? (
                    <>
                      <div
                        style={{ position: "absolute", inset: 0, background: brand.blackRaised }}
                      />
                      <HeroCard
                        brand={brand}
                        content={content}
                        width={mediaW}
                        height={mediaH}
                        steps={[
                          enter(frame - start, layout.consolidateFrames - 6, 14),
                          enter(frame - start, layout.consolidateFrames + 2, 16),
                          enter(frame - start, layout.consolidateFrames + 14, 16),
                          enter(frame - start, layout.consolidateFrames + 24, 16),
                        ]}
                      />
                    </>
                  ) : slot ? (
                    <Media
                      slot={slot}
                      width={mediaW}
                      height={mediaH}
                      fit="contain"
                      background={brand.black}
                    />
                  ) : null}
                </div>
              </Sequence>
            );
          })}
        </div>
      </Panel>

      <Bays
        bays={bays}
        rects={geometry.bays}
        statuses={statuses}
        media={media}
        brand={brand}
        statusLabels={statusLabels}
        radius={layout.panelRadius}
        opacity={sideOpacity}
        entrances={bayEntrances}
      />

      <CaptionBar
        rect={geometry.caption}
        brand={brand}
        useCase={useCase}
        caption={captionText}
        progress={captionProgress}
        opacity={sideOpacity}
      />
    </AbsoluteFill>
  );
};
