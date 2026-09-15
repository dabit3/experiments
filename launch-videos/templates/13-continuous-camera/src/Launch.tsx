import React from "react";
import { AbsoluteFill, Sequence, staticFile, useCurrentFrame } from "remotion";
import "./fonts";
import type { LaunchProps } from "./schema";
import { buildTimeline, cameraAt, routeProgress } from "./timeline";
import { CtaCell, MediaCell, OpeningCell } from "./Stations";
import { Route } from "./Route";
import { VIEW_H, VIEW_W } from "./type";

// Optional licensed brand font, served from assets/fonts/ when brand.licensedFontFiles is set.
const fontFace = (files: { regular: string; medium: string }) => `
@font-face { font-family: "NB International Pro"; font-weight: 400; src: url("${staticFile(files.regular)}") format("woff2"); }
@font-face { font-family: "NB International Pro"; font-weight: 500; src: url("${staticFile(files.medium)}") format("woff2"); }
`;

const DotGrid: React.FC<{ spacing: number; color: string; camX: number; camY: number; zoom: number }> = ({
  spacing,
  color,
  camX,
  camY,
  zoom,
}) => {
  if (spacing <= 0) return null;
  const s = spacing * zoom;
  // Screen-space pattern shifted so the dots stay pinned to canvas coordinates.
  const ox = ((VIEW_W / 2 - camX * zoom) % s + s) % s;
  const oy = ((VIEW_H / 2 - camY * zoom) % s + s) % s;
  return (
    <svg width={VIEW_W} height={VIEW_H} style={{ position: "absolute", left: 0, top: 0 }}>
      <defs>
        <pattern id="dots" width={s} height={s} patternUnits="userSpaceOnUse" x={ox} y={oy}>
          <circle cx={0} cy={0} r={1.5} fill={color} />
        </pattern>
      </defs>
      <rect width={VIEW_W} height={VIEW_H} fill="url(#dots)" />
    </svg>
  );
};

export const Launch: React.FC<LaunchProps> = (props) => {
  const { brand, content, media, scenes, camera } = props;
  const frame = useCurrentFrame();
  const timeline = buildTimeline(scenes);
  const cam = cameraAt(frame, timeline, camera);
  const progress = routeProgress(frame, timeline, camera);
  const activeIndex = timeline.reduce((acc, t) => (frame >= t.arrive ? t.index : acc), 0);

  return (
    <AbsoluteFill style={{ background: brand.paper, overflow: "hidden" }}>
      {brand.licensedFontFiles ? <style>{fontFace(brand.licensedFontFiles)}</style> : null}
      <DotGrid spacing={camera.gridSpacing} color={brand.line} camX={cam.x} camY={cam.y} zoom={cam.zoom} />
      <div
        style={{
          position: "absolute",
          left: 0,
          top: 0,
          transformOrigin: "0 0",
          transform: `translate(${VIEW_W / 2 - cam.x * cam.zoom}px, ${VIEW_H / 2 - cam.y * cam.zoom}px) scale(${cam.zoom})`,
        }}
      >
        <Route timeline={timeline} camera={camera} brand={brand} progress={progress} activeIndex={activeIndex} />
        {timeline.map((t, i) => {
          // Mount each station only while it can be on screen: from the start of
          // the travel into it until the camera has arrived at the next one.
          const next = timeline[i + 1];
          const from = t.travelStart;
          const to = next ? next.arrive : t.leave;
          const cell =
            t.station.kind === "opening" ? (
              <OpeningCell station={t.station} timing={t} frame={frame} brand={brand} content={content} />
            ) : t.station.kind === "cta" ? (
              <CtaCell station={t.station} timing={t} frame={frame} brand={brand} content={content} />
            ) : (
              <MediaCell
                station={t.station}
                timing={t}
                frame={frame}
                brand={brand}
                content={content}
                media={media}
              />
            );
          return (
            <Sequence key={t.station.id} from={from} durationInFrames={Math.max(1, to - from)} layout="none">
              {cell}
            </Sequence>
          );
        })}
      </div>
    </AbsoluteFill>
  );
};
