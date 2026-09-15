import React from "react";
import type { Brand, Rect, Scene } from "../schema";
import { CONTENT_BOTTOM, CONTENT_H, CONTENT_TOP, MARGIN, WIDTH } from "../defaults";

/**
 * Explanatory text lives in the margins: under the active panel in the bottom
 * margin, or in the free right-hand margin next to a tall panel. Never over UI.
 */
export const Caption: React.FC<{
  brand: Brand;
  text: string;
  number: number;
  placement: Scene["captionPlacement"];
  anchor: Rect;
  progress: number;
  speedBadge: string | null;
}> = ({ brand, text, number, placement, anchor, progress, speedBadge }) => {
  const rise = (1 - progress) * 8;
  const index = (
    <span
      style={{
        fontFamily: brand.monoFontFamily,
        fontSize: 15,
        letterSpacing: 0.4,
        color: brand.accent,
        fontWeight: 500,
      }}
    >
      {String(number).padStart(2, "0")}
    </span>
  );
  const badge = speedBadge ? (
    <span
      style={{
        fontFamily: brand.monoFontFamily,
        fontSize: 13,
        lineHeight: "20px",
        padding: "0 8px",
        borderRadius: 8,
        border: `1px solid ${brand.line}`,
        color: brand.inkMuted,
        marginLeft: 12,
      }}
    >
      {speedBadge}
    </span>
  ) : null;

  if (placement === "beside") {
    const left = anchor.x + anchor.w + 48;
    return (
      <div
        style={{
          position: "absolute",
          left,
          width: WIDTH - MARGIN - left,
          top: CONTENT_TOP,
          height: CONTENT_H,
          display: "flex",
          flexDirection: "column",
          justifyContent: "center",
          gap: 16,
          opacity: progress,
          transform: `translateY(${rise}px)`,
        }}
      >
        <div style={{ display: "flex", alignItems: "center" }}>
          {index}
          {badge}
        </div>
        <div
          style={{
            fontFamily: brand.fontFamily,
            fontSize: 34,
            lineHeight: "42px",
            letterSpacing: -0.6,
            color: brand.ink,
            maxWidth: 620,
          }}
        >
          {text}
        </div>
      </div>
    );
  }

  const left = Math.max(MARGIN, anchor.x);
  return (
    <div
      style={{
        position: "absolute",
        left,
        width: Math.min(1120, WIDTH - MARGIN - left),
        top: CONTENT_BOTTOM + 34,
        display: "flex",
        alignItems: "baseline",
        gap: 18,
        opacity: progress,
        transform: `translateY(${rise}px)`,
      }}
    >
      <div style={{ display: "flex", alignItems: "center", flexShrink: 0 }}>
        {index}
        {badge}
      </div>
      <div
        style={{
          fontFamily: brand.fontFamily,
          fontSize: 28,
          lineHeight: "36px",
          letterSpacing: -0.4,
          color: brand.ink,
        }}
      >
        {text}
      </div>
    </div>
  );
};
