import React from "react";
import { interpolate, useCurrentFrame } from "remotion";
import { color, font, layout, radius, shadow, sizes, tracking, weight } from "../theme";
import { enter, lifetime } from "./anim";

const MicIcon: React.FC = () => (
  <svg width={16} height={16} viewBox="0 0 16 16" fill="none" stroke={color.gray500} strokeWidth={1.4}>
    <rect x="5.5" y="1.5" width="5" height="8" rx="2.5" />
    <path d="M3 7.5a5 5 0 0 0 10 0M8 12.5V15" strokeLinecap="round" />
  </svg>
);

const KeyboardIcon: React.FC = () => (
  <svg width={16} height={16} viewBox="0 0 16 16" fill="none" stroke={color.gray500} strokeWidth={1.4}>
    <rect x="1.5" y="3.5" width="13" height="9" rx="1.5" />
    <path d="M4 6.5h1M7.5 6.5h1M11 6.5h1M4 9.5h8" strokeLinecap="round" />
  </svg>
);

/**
 * The developer's intent, rendered as a prompt card in the left panel.
 * `typed` reveals characters over `typeDuration`; `spoken` fades in whole with a mic label.
 */
export const PromptCard: React.FC<{
  text: string;
  variant: "typed" | "spoken";
  at: number;
  typeDuration?: number;
  until?: number;
}> = ({ text, variant, at, typeDuration = 60, until }) => {
  const frame = useCurrentFrame();
  const p = enter(frame, at, 20);
  const opacity = lifetime(frame, at, until, 20);

  const typing = variant === "typed";
  const typeStart = at + 8;
  const shown = typing
    ? Math.floor(interpolate(frame, [typeStart, typeStart + typeDuration], [0, text.length], {
        extrapolateLeft: "clamp",
        extrapolateRight: "clamp",
      }))
    : text.length;
  const done = shown >= text.length;
  const caretOn = !done || Math.floor((frame - typeStart) / 16) % 2 === 0;
  const visible = typing ? text.slice(0, shown) : text;
  const spokenOpacity = typing ? 1 : enter(frame, at + 10, 24);

  return (
    <div
      style={{
        position: "absolute",
        left: layout.left.x,
        top: layout.contentTop,
        width: layout.left.w,
        opacity,
        transform: `translateY(${(1 - p) * 16}px)`,
        background: color.white,
        border: `1px solid ${color.border}`,
        borderRadius: radius.lg,
        boxShadow: shadow.card,
        padding: "22px 26px 24px",
        boxSizing: "border-box",
      }}
    >
      <div
        style={{
          display: "flex",
          alignItems: "center",
          gap: 8,
          fontFamily: font.mono,
          fontSize: sizes.label,
          fontWeight: weight.medium,
          letterSpacing: tracking.caps,
          textTransform: "uppercase",
          color: color.gray500,
          marginBottom: 14,
        }}
      >
        {typing ? <KeyboardIcon /> : <MicIcon />}
        {typing ? "Typed" : "Spoken"}
      </div>
      <div
        style={{
          fontFamily: font.sans,
          fontSize: sizes.body,
          fontWeight: weight.regular,
          letterSpacing: tracking.body,
          lineHeight: 1.4,
          color: color.ink,
          minHeight: sizes.body * 1.4 * 2,
          opacity: spokenOpacity,
        }}
      >
        {visible}
        {typing ? (
          <span
            style={{
              display: "inline-block",
              width: 2,
              height: sizes.body * 1.05,
              background: color.accent,
              marginLeft: 2,
              verticalAlign: "text-bottom",
              opacity: caretOn ? 1 : 0,
            }}
          />
        ) : null}
      </div>
    </div>
  );
};
