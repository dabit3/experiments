import React from "react";
import { Sequence, useCurrentFrame, useVideoConfig } from "remotion";
import type { Brand, Content, Layout, LaunchProps, Scene } from "../schema";
import { progress, resolveAt } from "../score";
import { MediaView } from "./MediaView";

type Props = {
  scene: Scene;
  stageNumber: number;
  brand: Brand;
  content: Content;
  layout: Layout;
  media: LaunchProps["media"];
  exitFrames: number;
};

const MEDIA_FADE = 12;

/**
 * One workflow stage: the large product view on the left, its caption and the log of
 * footage events on the right. Cues can swap the media slot and/or the caption.
 */
export const Stage: React.FC<Props> = ({
  scene,
  stageNumber,
  brand,
  content,
  layout,
  media,
  exitFrames,
}) => {
  const frame = useCurrentFrame();
  const { width } = useVideoConfig();
  const cues = scene.cues ?? [];

  // Every distinct media segment: the arrival slot plus one per cue that swaps media.
  const segments: { from: number; slot: string }[] = [];
  if (scene.mediaSlot) segments.push({ from: 0, slot: scene.mediaSlot });
  cues.forEach((c) => {
    if (c.mediaSlot) segments.push({ from: c.at, slot: c.mediaSlot });
  });

  const captionIndex = resolveAt(scene, "captionIndex", frame);
  const caption = captionIndex === undefined ? "" : (content.captions[captionIndex] ?? "");
  const captionChangedAt = cues
    .filter((c) => c.captionIndex !== undefined && frame >= c.at)
    .reduce((acc, c) => Math.max(acc, c.at), 0);
  const captionIn = progress(frame, captionChangedAt, 14);

  const enter = progress(frame, 0, 16);
  const exit = 1 - progress(frame, scene.durationInFrames - exitFrames, exitFrames);

  const captionX = layout.margin + layout.mediaWidth + layout.captionGap;
  const captionW = width - layout.margin - captionX;
  const label = content.stages[scene.track ?? 0] ?? "";

  return (
    <div style={{ position: "absolute", inset: 0, opacity: exit }}>
      <div
        style={{
          position: "absolute",
          left: layout.margin,
          top: layout.mediaTop,
          width: layout.mediaWidth,
          height: layout.mediaHeight,
        }}
      >
        {segments.map((seg, i) => {
          const slot = media[seg.slot];
          if (!slot) return null;
          const next = segments[i + 1];
          const duration = (next ? next.from : scene.durationInFrames) - seg.from + MEDIA_FADE;
          return (
            <Sequence
              key={`${seg.slot}-${seg.from}`}
              from={seg.from}
              durationInFrames={duration}
              layout="none"
            >
              <MediaSegment
                fadeIn={i === 0 ? 16 : MEDIA_FADE}
                fadeOutAt={next ? next.from - seg.from : undefined}
              >
                <MediaView
                  slot={slot}
                  brand={brand}
                  areaWidth={layout.mediaWidth}
                  areaHeight={layout.mediaHeight}
                  speedBadge={content.speedBadge}
                  monoFontFamily={brand.monoFontFamily}
                />
              </MediaSegment>
            </Sequence>
          );
        })}
      </div>

      <div
        style={{
          position: "absolute",
          left: captionX,
          top: layout.mediaTop,
          width: captionW,
          height: layout.mediaHeight,
          opacity: enter,
          transform: `translateY(${(1 - enter) * 10}px)`,
        }}
      >
        <div
          style={{
            fontFamily: brand.monoFontFamily,
            fontSize: 14,
            lineHeight: "20px",
            letterSpacing: 0.4,
            textTransform: "uppercase",
            color: brand.inkMuted,
          }}
        >
          <span style={{ color: brand.accent }}>{String(stageNumber).padStart(2, "0")}</span>
          {"  ·  "}
          {label}
        </div>
        <div
          style={{
            marginTop: 20,
            fontFamily: brand.fontFamily,
            fontWeight: 500,
            fontSize: 34,
            lineHeight: "42px",
            letterSpacing: -0.6,
            color: brand.ink,
            opacity: captionIn,
            transform: `translateY(${(1 - captionIn) * 8}px)`,
          }}
        >
          {caption}
        </div>

        <div
          style={{
            position: "absolute",
            left: 0,
            bottom: 0,
            width: "100%",
            borderTop: `1px solid ${brand.line}`,
            paddingTop: 16,
          }}
        >
          {cues.map((cue) => {
            const fired = frame >= cue.at;
            const cueIn = progress(frame, cue.at, 12);
            return (
              <div
                key={cue.label}
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: 12,
                  height: 28,
                  fontFamily: brand.monoFontFamily,
                  fontSize: 15,
                  lineHeight: "20px",
                  color: fired ? brand.ink : brand.inkSubtle,
                }}
              >
                <span
                  style={{
                    width: 8,
                    height: 8,
                    borderRadius: 1,
                    boxSizing: "border-box",
                    border: `1px solid ${fired ? brand.accent : brand.inkSubtle}`,
                    background: fired ? brand.accent : "transparent",
                    transform: `scale(${fired ? 1 + (1 - cueIn) * 0.6 : 1})`,
                  }}
                />
                {cue.label}
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
};

const MediaSegment: React.FC<{
  fadeIn: number;
  fadeOutAt?: number;
  children: React.ReactNode;
}> = ({ fadeIn, fadeOutAt, children }) => {
  const frame = useCurrentFrame();
  const inP = progress(frame, 0, fadeIn);
  const outP = fadeOutAt === undefined ? 0 : progress(frame, fadeOutAt, MEDIA_FADE);
  return (
    <div
      style={{
        position: "absolute",
        inset: 0,
        opacity: inP * (1 - outP),
        transform: `translateY(${(1 - inP) * 12}px)`,
      }}
    >
      {children}
    </div>
  );
};
