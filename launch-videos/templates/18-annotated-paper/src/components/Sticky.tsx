import React from "react";
import { useProgress } from "../anim";
import { color, ease, font, sec, shadow } from "../theme";

type StickyProps = {
  x: number;
  y: number;
  at: number;
  rotate?: number;
  width?: number;
  children: React.ReactNode;
};

/** Small square note in the reviewer's hand. Fade + settle, ease-out. */
export const Sticky: React.FC<StickyProps> = ({ x, y, at, rotate = -2, width = 190, children }) => {
  const t = useProgress(at, sec(0.45), ease.out);
  return (
    <div
      style={{
        position: "absolute",
        left: x,
        top: y,
        width,
        minHeight: width * 0.62,
        padding: "16px 18px",
        boxSizing: "border-box",
        backgroundColor: color.accentSoft,
        boxShadow: shadow.card,
        transform: `rotate(${rotate}deg) scale(${0.94 + 0.06 * t})`,
        transformOrigin: "50% 0%",
        opacity: t,
        fontFamily: font.hand,
        fontWeight: 500,
        fontSize: 30,
        lineHeight: 1.1,
        color: color.ink,
        display: "flex",
        alignItems: "center",
      }}
    >
      <span>{children}</span>
    </div>
  );
};

/** Free-standing handwritten label (no note behind it). */
export const HandLabel: React.FC<{
  x: number;
  y: number;
  at: number;
  rotate?: number;
  size?: number;
  children: React.ReactNode;
}> = ({ x, y, at, rotate = -3, size = 30, children }) => {
  const t = useProgress(at, sec(0.4), ease.out);
  return (
    <div
      style={{
        position: "absolute",
        left: x,
        top: y,
        transform: `rotate(${rotate}deg)`,
        opacity: t,
        fontFamily: font.hand,
        fontWeight: 600,
        fontSize: size,
        lineHeight: 1,
        color: color.accent,
        whiteSpace: "nowrap",
      }}
    >
      {children}
    </div>
  );
};
