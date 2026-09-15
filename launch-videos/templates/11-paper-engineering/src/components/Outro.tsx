import React from "react";
import type { Brand, Content, Layout, MediaSlot, Surface } from "../schema";
import {
  easeInOut,
  easeOut,
  fitPlate,
  lerpBox,
  mediaAspect,
  progress,
  HEIGHT,
  type Box,
} from "../lib";
import { Plate } from "./Plate";

type Props = {
  frame: number;
  fromBox: Box;
  stage: Box;
  slot: MediaSlot;
  brand: Brand;
  content: Content;
  layout: Layout;
  surface: Surface;
  moveFrames: number;
};

/**
 * The layers resolve into one clean composition: the real result stays on its plate
 * at the right, the outro line and CTA sit on the paper at the left.
 */
export const Outro: React.FC<Props> = ({
  frame,
  fromBox,
  stage,
  slot,
  brand,
  content,
  layout,
  surface,
  moveFrames,
}) => {
  const move = progress(frame, 0, moveFrames, easeInOut);
  const full: Box = {
    x: stage.x,
    y: stage.y,
    w: stage.w,
    h: HEIGHT - layout.margin - stage.y,
  };
  const column: Box = {
    x: full.x + full.w - layout.outroPlateWidth,
    y: full.y,
    w: layout.outroPlateWidth,
    h: full.h,
  };
  const toBox = fitPlate(mediaAspect(slot), layout.platePadding, column);
  const box = lerpBox(fromBox, toBox, move);

  const textW = column.x - full.x - 72;
  const enter = (delay: number) => progress(frame, delay, delay + 16, easeOut);
  const rise = (p: number): React.CSSProperties => ({
    opacity: p,
    transform: `translateY(${(1 - p) * 14}px)`,
  });
  const d0 = Math.round(moveFrames * 0.5);

  return (
    <>
      <div
        style={{
          position: "absolute",
          left: full.x,
          top: full.y,
          width: textW,
          height: full.h,
          display: "flex",
          flexDirection: "column",
          justifyContent: "center",
          fontFamily: brand.fontFamily,
          color: brand.ink,
        }}
      >
        <div
          style={{
            ...rise(enter(d0)),
            fontSize: 15,
            lineHeight: "22px",
            letterSpacing: 0.4,
            textTransform: "uppercase",
            fontWeight: 500,
            color: brand.inkMuted,
            marginBottom: 24,
          }}
        >
          {content.featureName}
        </div>
        <h2
          style={{
            ...rise(enter(d0 + 4)),
            margin: 0,
            fontSize: 64,
            lineHeight: "72px",
            letterSpacing: -2.34,
            fontWeight: 500,
          }}
        >
          {content.outroLine}
        </h2>
        <div
          style={{
            ...rise(enter(d0 + 10)),
            marginTop: 40,
            display: "flex",
            alignItems: "center",
            gap: 20,
          }}
        >
          <span
            style={{
              background: brand.ink,
              color: brand.white,
              borderRadius: 2,
              height: 52,
              padding: "0 22px",
              display: "inline-flex",
              alignItems: "center",
              fontSize: 20,
              letterSpacing: -0.2,
              fontWeight: 500,
            }}
          >
            {content.cta.label}
          </span>
          <span
            style={{
              fontFamily: brand.monoFontFamily,
              fontSize: 18,
              color: brand.inkMuted,
            }}
          >
            {content.cta.url}
          </span>
        </div>
      </div>
      <Plate
        box={box}
        slot={slot}
        brand={brand}
        layout={layout}
        surface={surface}
        elevation={1 + 1.2 * Math.sin(Math.PI * move)}
      />
    </>
  );
};
