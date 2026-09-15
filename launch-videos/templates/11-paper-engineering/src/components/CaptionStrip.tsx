import React from "react";
import type { Brand, Content, Layout, Surface } from "../schema";
import { easeInOut, progress, softShadow, type Box } from "../lib";

export type CaptionState = {
  /** Text currently on the strip (undefined before the first caption). */
  text?: string;
  /** Ordinal (1-based) of the caption among those shown, for the index label. */
  ordinal: number;
  total: number;
  /** Frame at which `text` replaced `previous`. */
  changedAt: number;
  previous?: string;
  previousOrdinal: number;
  stage?: string;
  badge?: string;
  /** 0..1 progress through the demonstrations, for the accent line. */
  progress: number;
};

type Props = {
  frame: number;
  box: Box;
  brand: Brand;
  content: Content;
  layout: Layout;
  surface: Surface;
  state: CaptionState;
  slideFrames: number;
  /** 0..1, slides the strip down and away in the final composition. */
  dismiss: number;
};

const pad2 = (n: number) => String(n).padStart(2, "0");

/** A separate matte strip below the stage. Text is always left-aligned here. */
export const CaptionStrip: React.FC<Props> = ({
  frame,
  box,
  brand,
  content,
  layout,
  surface,
  state,
  slideFrames,
  dismiss,
}) => {
  const t = progress(frame, state.changedAt, state.changedAt + slideFrames, easeInOut);
  const padX = layout.platePadding + 16;

  const line = (text: string | undefined, ordinal: number, offset: number, opacity: number) =>
    text ? (
      <div
        style={{
          position: "absolute",
          left: padX,
          right: 320,
          top: 0,
          height: box.h,
          display: "flex",
          alignItems: "center",
          gap: 24,
          transform: `translateY(${offset}px)`,
          opacity,
        }}
      >
        <span
          style={{
            fontFamily: brand.monoFontFamily,
            fontSize: 16,
            letterSpacing: 0.28,
            color: brand.inkSubtle,
            width: 72,
            flexShrink: 0,
          }}
        >
          {pad2(ordinal)} / {pad2(state.total)}
        </span>
        <span
          style={{
            fontFamily: brand.fontFamily,
            fontSize: 28,
            lineHeight: "36px",
            letterSpacing: -0.42,
            fontWeight: 500,
            color: brand.ink,
            whiteSpace: "nowrap",
          }}
        >
          {text}
        </span>
      </div>
    ) : null;

  const idle = state.text ? null : (
    <div
      style={{
        position: "absolute",
        left: padX,
        top: 0,
        height: box.h,
        display: "flex",
        alignItems: "center",
        gap: 24,
        opacity: 1 - t,
        transform: `translateY(${-t * box.h}px)`,
      }}
    >
      <span
        style={{
          fontFamily: brand.monoFontFamily,
          fontSize: 16,
          letterSpacing: 0.28,
          color: brand.inkSubtle,
        }}
      >
        {content.eyebrow.toUpperCase()}
      </span>
      <span
        style={{
          fontFamily: brand.fontFamily,
          fontSize: 28,
          lineHeight: "36px",
          letterSpacing: -0.42,
          fontWeight: 500,
          color: brand.ink,
        }}
      >
        {content.featureName}
      </span>
    </div>
  );

  return (
    <div
      style={{
        position: "absolute",
        left: box.x,
        top: box.y,
        width: box.w,
        height: box.h,
        background: brand.surfaceAlt,
        borderRadius: 12,
        boxShadow: softShadow(surface, brand),
        overflow: "hidden",
        transform: `translateY(${dismiss * (box.h + layout.margin + 40)}px)`,
      }}
    >
      {idle}
      {line(state.previous, state.previousOrdinal, -t * box.h * 0.5, 1 - t)}
      {line(state.text, state.ordinal, (1 - t) * box.h * 0.5, t)}

      <div
        style={{
          position: "absolute",
          right: padX,
          top: 0,
          height: box.h,
          display: "flex",
          alignItems: "center",
          gap: 16,
          fontFamily: brand.monoFontFamily,
          fontSize: 16,
          letterSpacing: 0.28,
          textTransform: "uppercase",
          color: brand.inkMuted,
        }}
      >
        {state.badge ? (
          <span
            style={{
              color: brand.ink,
              border: `1px solid ${brand.line}`,
              borderRadius: 8,
              padding: "2px 8px",
            }}
          >
            {state.badge}
          </span>
        ) : null}
        {state.stage ? <span>{state.stage}</span> : null}
      </div>

      <div
        style={{
          position: "absolute",
          left: 0,
          bottom: 0,
          height: 2,
          width: `${state.progress * 100}%`,
          background: brand.accent,
        }}
      />
    </div>
  );
};
