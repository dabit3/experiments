import React from "react";
import type { Rect } from "../layout";
import type { Brand } from "../schema";
import { MonoLabel } from "./Panel";

type Props = {
  rect: Rect;
  brand: Brand;
  useCase?: string;
  caption?: string;
  /** 0..1 entrance progress of the current caption. */
  progress: number;
  opacity: number;
};

/** Explanatory label in a fixed position under the primary display. */
export const CaptionBar: React.FC<Props> = ({
  rect,
  brand,
  useCase,
  caption,
  progress,
  opacity,
}) => {
  return (
    <div
      style={{
        position: "absolute",
        left: rect.x,
        top: rect.y,
        width: rect.w,
        height: rect.h,
        display: "flex",
        flexDirection: "column",
        justifyContent: "center",
        gap: 14,
        opacity,
      }}
    >
      <div style={{ height: 17, display: "flex", alignItems: "center" }}>
        {useCase ? (
          <MonoLabel brand={brand} color={brand.inkMuted} size={17}>
            {useCase}
          </MonoLabel>
        ) : null}
      </div>
      <div
        style={{
          fontFamily: brand.fontFamily,
          fontSize: 40,
          lineHeight: "50px",
          letterSpacing: -0.7,
          fontWeight: 400,
          color: brand.white,
          opacity: progress,
          transform: `translateY(${(1 - progress) * 10}px)`,
          minHeight: 50,
        }}
      >
        {caption ?? ""}
      </div>
    </div>
  );
};
