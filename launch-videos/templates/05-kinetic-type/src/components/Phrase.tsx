import React from "react";
import { mix } from "../motion";
import { LINE_HEIGHT } from "../layout";

export type PhrasePose = { x: number; y: number; scale: number };

/**
 * A complete phrase treated as one graphic object. It is laid out once at the
 * caption width and moved between poses with translate + scale only, so line
 * breaks never change while it travels from title to caption.
 */
export const Phrase: React.FC<{
  text: string;
  width: number;
  fontSize: number;
  fontFamily: string;
  color: string;
  from: PhrasePose;
  to: PhrasePose;
  /** 0 = `from`, 1 = `to` */
  progress: number;
  opacity?: number;
  offsetY?: number;
  weight?: 400 | 500;
  align?: "left" | "center";
}> = ({
  text,
  width,
  fontSize,
  fontFamily,
  color,
  from,
  to,
  progress,
  opacity = 1,
  offsetY = 0,
  weight = 500,
  align = "left",
}) => {
  const x = mix(from.x, to.x, progress);
  const y = mix(from.y, to.y, progress) + offsetY;
  const scale = mix(from.scale, to.scale, progress);
  return (
    <div
      style={{
        position: "absolute",
        left: 0,
        top: 0,
        width,
        transform: `translate(${x}px, ${y}px) scale(${scale})`,
        transformOrigin: "top left",
        fontFamily,
        fontSize,
        fontWeight: weight,
        lineHeight: LINE_HEIGHT,
        letterSpacing: "-0.03em",
        color,
        opacity,
        textAlign: align,
        textWrap: "balance",
      }}
    >
      {text}
    </div>
  );
};
