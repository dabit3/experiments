import React from "react";
import { AbsoluteFill, Img, staticFile } from "remotion";
import type { Brand, Content, Layout } from "../schema";
import { AccentText, type, useEnter } from "../Typography";

type Props = { brand: Brand; content: Content; layout: Layout };

// Opening feature statement: eyebrow, headline, subhead. Left-aligned on paper, then a
// hard cut straight into the product.
export const Statement: React.FC<Props> = ({ brand, content, layout }) => {
  const eyebrow = useEnter(0);
  const headline = useEnter(3);
  const subhead = useEnter(7);
  const logo = useEnter(0);

  return (
    <AbsoluteFill style={{ backgroundColor: brand.paper, fontFamily: brand.fontFamily }}>
      <Img
        src={staticFile(brand.logoLight)}
        style={{
          position: "absolute",
          left: layout.marginX,
          top: layout.marginTop,
          height: 72,
          ...logo,
        }}
      />
      <div
        style={{
          position: "absolute",
          left: layout.marginX,
          right: layout.marginX,
          top: "50%",
          transform: "translateY(-50%)",
          color: brand.ink,
        }}
      >
        <div
          style={{
            ...type.eyebrow,
            color: brand.inkMuted,
            marginBottom: 32,
            display: "flex",
            alignItems: "center",
            gap: 14,
            ...eyebrow,
          }}
        >
          <span
            style={{
              width: 12,
              height: 12,
              borderRadius: 9999,
              backgroundColor: brand.accent,
              display: "inline-block",
            }}
          />
          {content.eyebrow} · {content.featureName}
        </div>
        <div style={{ ...type.display, maxWidth: 1700, ...headline }}>
          <AccentText text={content.headline} accent={content.headlineAccent} brand={brand} />
        </div>
        <div style={{ ...type.h5, color: brand.inkMuted, maxWidth: 1500, marginTop: 36, ...subhead }}>
          {content.subhead}
        </div>
      </div>
    </AbsoluteFill>
  );
};
