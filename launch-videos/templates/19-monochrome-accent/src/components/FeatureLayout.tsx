import React from "react";
import { AbsoluteFill } from "remotion";
import { MARGIN, Palette, size } from "../theme";
import { Body, Headline, Label } from "./Text";

export type Line = { at: number; until?: number; headline: React.ReactNode; body: React.ReactNode };

/**
 * Feature scene layout. `top`: copy across the top, screenshot below bleeding off the bottom edge.
 * `left`: copy in a left column, screenshot to the right bleeding off the right edge.
 */
export const FeatureLayout: React.FC<{
  palette: Palette;
  variant: "top" | "left";
  label: string;
  lines: Line[];
  screen: React.ReactNode;
}> = ({ palette, variant, label, lines, screen }) => {
  const copy = (
    <>
      <Label palette={palette} at={0}>
        {label}
      </Label>
      <div style={{ position: "relative", marginTop: variant === "top" ? 40 : 48 }}>
        {lines.map((l, i) => (
          <div
            key={i}
            style={{
              position: i === 0 ? "relative" : "absolute",
              top: 0,
              left: 0,
              right: 0,
              display: "flex",
              flexDirection: "column",
              gap: variant === "top" ? 18 : 24,
            }}
          >
            <Headline palette={palette} fontSize={size.h2} at={l.at} until={l.until}>
              {l.headline}
            </Headline>
            <Body palette={palette} at={l.at + 8} until={l.until === undefined ? undefined : l.until + 3}>
              {l.body}
            </Body>
          </div>
        ))}
      </div>
    </>
  );

  if (variant === "top") {
    return (
      <AbsoluteFill style={{ background: palette.bg }}>
        <div style={{ position: "absolute", left: MARGIN, top: MARGIN, width: 1920 - MARGIN * 2 }}>
          {copy}
        </div>
        <div style={{ position: "absolute", left: MARGIN, top: 400 }}>{screen}</div>
      </AbsoluteFill>
    );
  }
  return (
    <AbsoluteFill style={{ background: palette.bg }}>
      <div
        style={{
          position: "absolute",
          left: MARGIN,
          top: 0,
          bottom: 0,
          width: 560,
          display: "flex",
          flexDirection: "column",
          justifyContent: "center",
        }}
      >
        {copy}
      </div>
      <div style={{ position: "absolute", left: 800, top: 160 }}>{screen}</div>
    </AbsoluteFill>
  );
};

export const TOP_SCREEN_WIDTH = 1920 - MARGIN * 2;
export const LEFT_SCREEN_WIDTH = 1400;
