import React from "react";
import { Img, staticFile } from "remotion";
import type { Brand, Content } from "../schema";
import { MARGIN, WIDTH } from "../defaults";

/** Logo top-left, workflow stage tracker top-right, both in the top margin. */
export const Header: React.FC<{
  brand: Brand;
  content: Content;
  stage: number | null;
  opacity: number;
}> = ({ brand, content, stage, opacity }) => {
  return (
    <div
      style={{
        position: "absolute",
        left: MARGIN,
        right: MARGIN,
        top: 60,
        height: 40,
        display: "flex",
        alignItems: "center",
        justifyContent: "space-between",
        opacity,
      }}
    >
      <Img
        src={staticFile(brand.logoLight)}
        style={{ height: 40, width: "auto", display: "block" }}
      />
      <div
        style={{
          display: "flex",
          alignItems: "center",
          gap: 28,
          fontFamily: brand.fontFamily,
          fontSize: 14,
          lineHeight: "20px",
          letterSpacing: 0.4,
          textTransform: "uppercase",
          fontWeight: 500,
          maxWidth: WIDTH * 0.6,
        }}
      >
        {content.stages.map((label, i) => {
          const isActive = stage === i;
          const isDone = stage !== null && i < stage;
          return (
            <div
              key={label}
              style={{
                display: "flex",
                alignItems: "center",
                gap: 8,
                color: isActive
                  ? brand.ink
                  : isDone
                    ? brand.inkMuted
                    : brand.inkSubtle,
              }}
            >
              <div
                style={{
                  width: 6,
                  height: 6,
                  borderRadius: 3,
                  background: isActive
                    ? brand.accent
                    : isDone
                      ? brand.inkMuted
                      : brand.line,
                }}
              />
              {label}
            </div>
          );
        })}
      </div>
    </div>
  );
};
