import React from "react";
import { useProgress } from "../anim";
import { color, ease, font, radius, sec, shadow, type } from "../theme";

type PaperProps = {
  x: number;
  y: number;
  width: number;
  rotate?: number;
  /** Frame (relative to scene) at which the sheet lands. */
  enterAt?: number;
  caption?: string;
  captionRight?: string;
  padding?: number;
  children: React.ReactNode;
};

/** A printed sheet: white stock, soft shadow, slight rotation, mono figure caption. */
export const Paper: React.FC<PaperProps> = ({
  x,
  y,
  width,
  rotate = 0,
  enterAt = 0,
  caption,
  captionRight,
  padding = 28,
  children,
}) => {
  const t = useProgress(enterAt, sec(0.7), ease.out);
  return (
    <div
      style={{
        position: "absolute",
        left: x,
        top: y,
        width,
        padding,
        boxSizing: "border-box",
        backgroundColor: color.white,
        borderRadius: radius.button,
        boxShadow: shadow.soft,
        transform: `translateY(${(1 - t) * 28}px) rotate(${rotate}deg)`,
        transformOrigin: "50% 50%",
        opacity: t,
      }}
    >
      {children}
      {caption ? (
        <div
          style={{
            display: "flex",
            justifyContent: "space-between",
            marginTop: 18,
            fontFamily: font.mono,
            fontSize: 16,
            letterSpacing: type.tracking.caps,
            textTransform: "uppercase",
            color: color.gray500,
            lineHeight: 1,
          }}
        >
          <span>{caption}</span>
          {captionRight ? <span>{captionRight}</span> : null}
        </div>
      ) : null}
    </div>
  );
};
