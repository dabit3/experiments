import React from "react";
import { AbsoluteFill, useCurrentFrame } from "remotion";
import type { Brand, LayoutSettings, TitleScene } from "../schema";
import { enter, exit } from "../motion";

/** Short, quiet title card between product views. */
export const Title: React.FC<{
  scene: TitleScene;
  brand: Brand;
  layout: LayoutSettings;
}> = ({ scene, brand, layout }) => {
  const frame = useCurrentFrame();
  const out = exit(frame, scene.durationInFrames, 8);
  const lineIn = enter(frame, 0, 14);
  const textIn = enter(frame, 6, 12);

  return (
    <AbsoluteFill style={{ opacity: out }}>
      <div
        style={{
          position: "absolute",
          left: layout.safeMargin,
          right: layout.safeMargin,
          top: 0,
          bottom: 0,
          display: "flex",
          flexDirection: "column",
          justifyContent: "center",
          alignItems: "center",
          color: brand.white,
          textAlign: "center",
        }}
      >
        <div
          style={{
            width: 48 * lineIn,
            height: 1,
            background: brand.accent,
            marginBottom: 32,
          }}
        />
        {scene.index ? (
          <div
            style={{
              fontFamily: brand.monoFontFamily,
              fontSize: 14,
              lineHeight: "20px",
              letterSpacing: 1.4,
              color: brand.inkSubtle,
              marginBottom: 16,
              opacity: textIn,
            }}
          >
            {scene.index}
          </div>
        ) : null}
        <div
          style={{
            fontSize: 64,
            lineHeight: "74px",
            letterSpacing: -2.3,
            fontWeight: 500,
            opacity: textIn,
            transform: `translateY(${(1 - textIn) * 10}px)`,
          }}
        >
          {scene.text}
        </div>
      </div>
    </AbsoluteFill>
  );
};
