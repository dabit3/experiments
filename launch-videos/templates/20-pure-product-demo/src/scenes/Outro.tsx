import React from "react";
import { AbsoluteFill, Img, staticFile } from "remotion";
import type { Brand, Content, Layout } from "../schema";
import { type, useEnter } from "../Typography";

type Props = { brand: Brand; content: Content; layout: Layout };

// Minimal closing CTA on paper: outro line, one button, the URL, the lockup.
export const Outro: React.FC<Props> = ({ brand, content, layout }) => {
  const line = useEnter(0);
  const cta = useEnter(6);
  const logo = useEnter(10);

  return (
    <AbsoluteFill
      style={{
        backgroundColor: brand.paper,
        fontFamily: brand.fontFamily,
        color: brand.ink,
        alignItems: "center",
        justifyContent: "center",
      }}
    >
      <div style={{ textAlign: "center", maxWidth: 1600, padding: `0 ${layout.marginX}px` }}>
        <div style={{ ...type.h2, ...line, textWrap: "balance" }}>{content.outroLine}</div>
        <div
          style={{
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            gap: 20,
            marginTop: 48,
            ...cta,
          }}
        >
          <div
            style={{
              backgroundColor: brand.ink,
              color: brand.white,
              borderRadius: 2,
              height: 42,
              padding: "0 16px",
              display: "flex",
              alignItems: "center",
              ...type.body,
              fontWeight: 500,
            }}
          >
            {content.cta.label}
          </div>
          <div
            style={{
              fontFamily: brand.monoFontFamily,
              fontSize: 18,
              lineHeight: "24px",
              color: brand.inkMuted,
            }}
          >
            {content.cta.url}
          </div>
        </div>
      </div>
      <div
        style={{
          position: "absolute",
          bottom: layout.marginBottom,
          left: "50%",
          transform: "translateX(-50%)",
        }}
      >
        <Img src={staticFile(brand.logoLight)} style={{ height: 36, display: "block", ...logo }} />
      </div>
    </AbsoluteFill>
  );
};
