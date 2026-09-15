import React from "react";
import { AbsoluteFill, Sequence, staticFile, useCurrentFrame } from "remotion";
import { Cta } from "./Cta";
import { Exhibit } from "./Exhibit";
import { TitleWall } from "./TitleWall";
import { WIDTH } from "./defaults";
import { nbInternationalFontFace } from "./fonts";
import { enter, move } from "./motion";
import type { LaunchProps, Scene } from "./schema";

type Placed = {
  scene: Scene;
  start: number;
  end: number;
  /** Position along the gallery wall (undefined for the CTA, which is a cut). */
  wallIndex?: number;
};

export const placeScenes = (scenes: Scene[]): Placed[] => {
  let cursor = 0;
  let wall = 0;
  return scenes.map((scene) => {
    const placed: Placed = {
      scene,
      start: cursor,
      end: cursor + scene.durationInFrames,
      wallIndex: scene.kind === "cta" ? undefined : wall,
    };
    if (scene.kind !== "cta") wall += 1;
    cursor += scene.durationInFrames;
    return placed;
  });
};

export const totalDuration = (scenes: Scene[]) =>
  scenes.reduce((sum, s) => sum + s.durationInFrames, 0);

/**
 * The gallery is one long wall. Every non-CTA scene hangs at wallIndex * WIDTH and a
 * single camera translates laterally between them (ease-in-out, gallery.panFrames).
 * The CTA is a deliberate cut: it fades in over the final display.
 */
export const Launch: React.FC<LaunchProps> = ({ brand, content, media, gallery, scenes }) => {
  const frame = useCurrentFrame();
  const placed = placeScenes(scenes);
  const wallScenes = placed.filter((p) => p.wallIndex !== undefined);
  const exhibitCount = wallScenes.filter(
    (p) => p.scene.kind === "exhibit" && !p.scene.isResult,
  ).length;

  // Camera: which wall scene are we on, and are we panning to the next one?
  let cameraX = 0;
  for (let i = 0; i < wallScenes.length; i++) {
    const p = wallScenes[i];
    const next = wallScenes[i + 1];
    const isLast = i === wallScenes.length - 1;
    if (frame >= p.start && (frame < p.end || isLast)) {
      const idx = p.wallIndex ?? 0;
      if (next && next.start === p.end) {
        cameraX = move(frame, p.end - gallery.panFrames, gallery.panFrames, idx * WIDTH, (idx + 1) * WIDTH);
      } else {
        cameraX = idx * WIDTH;
      }
      break;
    }
  }

  const fontFace = nbInternationalFontFace(staticFile);

  let exhibitOrdinal = 0;

  return (
    <AbsoluteFill style={{ backgroundColor: brand.paper }}>
      <style>{fontFace}</style>
      <AbsoluteFill style={{ transform: `translateX(${-cameraX}px)` }}>
        {wallScenes.map((p) => {
          const idx = p.wallIndex ?? 0;
          const lead = idx === 0 ? 0 : gallery.panFrames;
          const localFrame = frame - p.start;
          let wayfinding = "";
          if (p.scene.kind === "exhibit") {
            if (p.scene.isResult) {
              wayfinding = content.stages[p.scene.stageIndex] ?? "";
            } else {
              exhibitOrdinal += 1;
              wayfinding = `${exhibitOrdinal} / ${exhibitCount}`;
            }
          }
          return (
            <Sequence
              key={p.scene.id}
              from={p.start - lead}
              durationInFrames={p.scene.durationInFrames + lead}
              layout="none"
            >
              <AbsoluteFill style={{ left: idx * WIDTH, width: WIDTH }}>
                {p.scene.kind === "title" ? (
                  <TitleWall brand={brand} content={content} gallery={gallery} localFrame={localFrame} />
                ) : p.scene.kind === "exhibit" ? (
                  <Exhibit
                    scene={p.scene}
                    brand={brand}
                    content={content}
                    gallery={gallery}
                    media={media}
                    localFrame={localFrame}
                    lead={lead}
                    wayfinding={wayfinding}
                  />
                ) : null}
              </AbsoluteFill>
            </Sequence>
          );
        })}
      </AbsoluteFill>
      {placed
        .filter((p) => p.scene.kind === "cta")
        .map((p) => (
          <Sequence key={p.scene.id} from={p.start} durationInFrames={p.scene.durationInFrames} layout="none">
            <AbsoluteFill style={{ opacity: enter(frame, p.start, gallery.cutFrames) }}>
              <Cta brand={brand} content={content} localFrame={frame - p.start} />
            </AbsoluteFill>
          </Sequence>
        ))}
    </AbsoluteFill>
  );
};
