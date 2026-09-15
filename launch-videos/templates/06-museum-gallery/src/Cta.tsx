import React from "react";
import { AbsoluteFill, Img, staticFile } from "remotion";
import { enter } from "./motion";
import type { Brand, Content } from "./schema";

type Props = {
  brand: Brand;
  content: Content;
  localFrame: number;
};

/** Minimal closing card on the dark surface: lockup, outro line, one button, the URL. */
export const Cta: React.FC<Props> = ({ brand, content, localFrame }) => {
  const f = Math.max(0, localFrame);
  const a1 = enter(f, 0, 14);
  const a2 = enter(f, 10, 14);
  const a3 = enter(f, 20, 14);
  const rise = (a: number) => `translateY(${(1 - a) * 12}px)`;

  return (
    <AbsoluteFill
      style={{
        backgroundColor: brand.black,
        color: brand.white,
        fontFamily: brand.fontFamily,
        alignItems: "center",
        justifyContent: "center",
      }}
    >
      <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 40 }}>
        <Img
          src={staticFile(brand.logoDark)}
          style={{ height: 40, opacity: a1, transform: rise(a1) }}
        />
        <div
          style={{
            fontSize: 44,
            lineHeight: "52px",
            letterSpacing: -1.4,
            fontWeight: 500,
            textAlign: "center",
            opacity: a2,
            transform: rise(a2),
          }}
        >
          {content.outroLine}
        </div>
        <div
          style={{
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            gap: 20,
            opacity: a3,
            transform: rise(a3),
          }}
        >
          <div
            style={{
              backgroundColor: brand.white,
              color: brand.ink,
              fontSize: 18,
              lineHeight: "22px",
              letterSpacing: -0.3,
              padding: "0 20px",
              height: 44,
              display: "flex",
              alignItems: "center",
              borderRadius: 2,
            }}
          >
            {content.cta.label}
          </div>
          <div
            style={{
              fontFamily: brand.monoFontFamily,
              fontSize: 15,
              lineHeight: "20px",
              color: brand.inkSubtle,
            }}
          >
            {content.cta.url}
          </div>
        </div>
      </div>
    </AbsoluteFill>
  );
};
