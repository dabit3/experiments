import React from "react";
import { useCurrentFrame } from "remotion";
import { color, font, layout, leading, sizes, tracking, weight } from "../theme";
import { enter, lifetime } from "./anim";

export type Line = { text: string; at: number; until?: number; muted?: boolean };

/**
 * Narration lines in the left panel. Each line fades up on `at` and out on `until`.
 * Lines stack vertically in order; a line that has exited collapses so the next moves up.
 */
export const Narration: React.FC<{ lines: Line[]; top?: number; size?: number }> = ({
  lines,
  top = layout.contentTop,
  size = sizes.h3,
}) => {
  const frame = useCurrentFrame();
  return (
    <div
      style={{
        position: "absolute",
        left: layout.left.x,
        top,
        width: layout.left.w,
        display: "flex",
        flexDirection: "column",
        gap: 20,
      }}
    >
      {lines.map((l) => {
        const opacity = lifetime(frame, l.at, l.until, 20, 12);
        const gone = l.until !== undefined && frame >= l.until;
        if (gone) return null;
        const p = enter(frame, l.at, 22);
        return (
          <div
            key={l.text}
            style={{
              fontFamily: font.sans,
              fontSize: size,
              fontWeight: weight.medium,
              letterSpacing: tracking.heading,
              lineHeight: leading.heading,
              color: l.muted ? color.gray500 : color.ink,
              opacity,
              transform: `translateY(${(1 - p) * 14}px)`,
            }}
          >
            {l.text}
          </div>
        );
      })}
    </div>
  );
};
