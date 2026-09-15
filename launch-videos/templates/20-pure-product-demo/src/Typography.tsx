import React from "react";
import { Easing, interpolate, useCurrentFrame } from "remotion";
import type { Brand } from "./schema";

// brief/brand.md site scale, enlarged ~1.35x for video legibility at 1920px.
export const type = {
  display: { fontSize: 120, lineHeight: "124px", letterSpacing: -4.5, fontWeight: 500 },
  h2: { fontSize: 104, lineHeight: "116px", letterSpacing: -3.8, fontWeight: 500 },
  h5: { fontSize: 38, lineHeight: "52px", letterSpacing: -0.6, fontWeight: 400 },
  body: { fontSize: 28, lineHeight: "38px", letterSpacing: -0.5, fontWeight: 400 },
  label: { fontSize: 24, lineHeight: "32px", letterSpacing: -0.3, fontWeight: 400 },
  eyebrow: {
    fontSize: 22,
    lineHeight: "30px",
    letterSpacing: 0.6,
    fontWeight: 500,
    textTransform: "uppercase" as const,
  },
};

// Ease-out cubic entrance, 300-500ms, no overshoot.
export const useEnter = (delay = 0, duration = 12) => {
  const frame = useCurrentFrame();
  const t = interpolate(frame, [delay, delay + duration], [0, 1], {
    easing: Easing.out(Easing.cubic),
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  return { opacity: t, transform: `translateY(${(1 - t) * 10}px)` };
};

// Headline with a single accent-colored substring (e.g. "Devin now runs in a Mac VM").
export const AccentText: React.FC<{ text: string; accent: string; brand: Brand }> = ({
  text,
  accent,
  brand,
}) => {
  const i = accent ? text.indexOf(accent) : -1;
  if (i < 0) {
    return <>{text}</>;
  }
  return (
    <>
      {text.slice(0, i)}
      <span style={{ color: brand.accent }}>{accent}</span>
      {text.slice(i + accent.length)}
    </>
  );
};
