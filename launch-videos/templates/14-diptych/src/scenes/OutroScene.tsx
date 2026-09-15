import React from "react";
import { useCurrentFrame } from "remotion";
import type { LaunchProps } from "../schema";
import { HEIGHT, WIDTH } from "../geometry";
import { enter } from "../motion";
import { Backdrop, TopBar, type } from "../components/Chrome";

export const OutroScene: React.FC<{ props: LaunchProps }> = ({ props }) => {
  const frame = useCurrentFrame();
  const { brand, layout, content } = props;
  const a = enter(frame, 0, layout.enterDuration);
  const b = enter(frame, 10, layout.enterDuration);

  return (
    <>
      <Backdrop color={brand.black} />
      <TopBar
        brand={brand}
        layout={layout}
        featureName={content.featureName}
        opacity={a}
        dark
      />
      <div
        style={{
          position: "absolute",
          left: layout.margin,
          width: WIDTH - layout.margin * 2,
          top: HEIGHT / 2 - 110,
          fontFamily: brand.fontFamily,
          color: brand.white,
        }}
      >
        <div
          style={{
            ...type.h2,
            opacity: a,
            transform: `translateY(${(1 - a) * 16}px)`,
          }}
        >
          {content.outroLine}
        </div>
        <div
          style={{
            marginTop: 40,
            display: "flex",
            alignItems: "center",
            gap: 24,
            opacity: b,
            transform: `translateY(${(1 - b) * 12}px)`,
          }}
        >
          <div
            style={{
              backgroundColor: brand.white,
              color: brand.ink,
              borderRadius: 2,
              height: 42,
              padding: "0 16px",
              display: "flex",
              alignItems: "center",
              fontSize: 20,
              letterSpacing: "-0.3px",
              fontWeight: 500,
            }}
          >
            {content.cta.label}
          </div>
          <div
            style={{
              fontFamily: brand.monoFontFamily,
              fontSize: 20,
              color: brand.inkSubtle,
            }}
          >
            {content.cta.url}
          </div>
        </div>
      </div>
    </>
  );
};
