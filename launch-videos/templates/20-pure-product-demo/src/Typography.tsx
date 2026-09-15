import React from "react";
import { Easing, interpolate, useCurrentFrame } from "remotion";
import type { Brand } from "./schema";

// Site scale x1.27 for 1920px (brief/brand.md).
export const type = {
  display: { fontSize: 89, lineHeight: "89px", letterSpacing: -3.4, fontWeight: 500 },
  h2: { fontSize: 81, lineHeight: "94px", letterSpacing: -3, fontWeight: 500 },
  h5: { fontSize: 27, lineHeight: "41px", letterSpacing: -0.4, fontWeight: 400 },
  body: { fontSize: 20, lineHeight: "28px", letterSpacing: -0.4, fontWeight: 400 },
  label: { fontSize: 18, lineHeight: "25px", letterSpacing: -0.2, fontWeight: 400 },
  eyebrow: {
    fontSize: 14.4,
    lineHeight: "22px",
    letterSpacing: 0.36,
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
