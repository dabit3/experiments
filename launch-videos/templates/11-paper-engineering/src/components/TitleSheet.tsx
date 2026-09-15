import React from "react";
import type { Brand, Content, Layout, Surface, TitleScene } from "../schema";
import { easeInOut, easeOut, plateShadow, progress, type Box } from "../lib";

type Props = {
  scene: TitleScene;
  frame: number;
  box: Box;
  brand: Brand;
  content: Content;
  layout: Layout;
  surface: Surface;
  exitFrames: number;
};

const splitHeadline = (headline: string, accentWord?: string) => {
  if (!accentWord) return { before: headline, accent: "", after: "" };
  const i = headline.indexOf(accentWord);
  if (i < 0) return { before: headline, accent: "", after: "" };
  return {
    before: headline.slice(0, i),
    accent: accentWord,
    after: headline.slice(i + accentWord.length),
  };
};

/** The title layer: a matte sheet over the product that slides away to reveal it. */
export const TitleSheet: React.FC<Props> = ({
  scene,
  frame,
  box,
  brand,
  content,
  layout,
  surface,
  exitFrames,
}) => {
  const exitStart = scene.durationInFrames - exitFrames;
  const exit = progress(frame, exitStart, scene.durationInFrames, easeInOut);
  if (exit >= 1) return null;

  const travel = 1.0 * (scene.exit === "up" ? box.h + box.y + 160 : box.w + box.x + 160);
  const transform =
    scene.exit === "left"
      ? `translateX(${-travel * exit}px)`
      : scene.exit === "right"
        ? `translateX(${travel * exit}px)`
        : `translateY(${-travel * exit}px)`;
  const elevation = 1 + 2.2 * Math.sin(Math.PI * exit);

  // Text enters in sequence with a short ease-out.
  const enter = (delay: number) => progress(frame, delay, delay + 14, easeOut);
  const rise = (p: number): React.CSSProperties => ({
    opacity: p,
    transform: `translateY(${(1 - p) * 16}px)`,
  });

  const { before, accent, after } = splitHeadline(content.headline, content.accentWord);
  const pad = layout.margin;

  return (
    <div
      style={{
        position: "absolute",
        left: box.x,
        top: box.y,
        width: box.w,
        height: box.h,
        background: brand.surfaceAlt,
        borderRadius: layout.plateRadius,
        boxShadow: plateShadow(surface, elevation),
        transform,
        fontFamily: brand.fontFamily,
        color: brand.ink,
      }}
    >
      <div
        style={{
          position: "absolute",
          left: pad,
          right: pad,
          top: 0,
          bottom: 0,
          display: "flex",
          flexDirection: "column",
          justifyContent: "center",
        }}
      >
        <div
          style={{
            ...rise(enter(0)),
            display: "flex",
            alignItems: "center",
            gap: 12,
            marginBottom: 28,
          }}
        >
          <span
            style={{
              fontSize: 15,
              lineHeight: "22px",
              letterSpacing: 0.4,
              textTransform: "uppercase",
              fontWeight: 500,
              color: brand.white,
              background: brand.ink,
              borderRadius: 8,
              padding: "2px 10px",
            }}
          >
            {content.eyebrow}
          </span>
          <span
            style={{
              fontSize: 15,
              lineHeight: "22px",
              letterSpacing: 0.4,
              textTransform: "uppercase",
              fontWeight: 500,
              color: brand.inkMuted,
            }}
          >
            {content.featureName}
          </span>
        </div>
        <h1
          style={{
            ...rise(enter(4)),
            margin: 0,
            fontSize: 96,
            lineHeight: "100px",
            letterSpacing: -3.6,
            fontWeight: 500,
            maxWidth: 1240,
          }}
        >
          {before}
          {accent ? <span style={{ color: brand.accent }}>{accent}</span> : null}
          {after}
        </h1>
        <p
          style={{
            ...rise(enter(9)),
            margin: 0,
            marginTop: 28,
            fontSize: 30,
            lineHeight: "42px",
            letterSpacing: -0.4,
            fontWeight: 400,
            color: brand.inkMuted,
            maxWidth: 1040,
          }}
        >
          {content.subhead}
        </p>
      </div>
    </div>
  );
};
