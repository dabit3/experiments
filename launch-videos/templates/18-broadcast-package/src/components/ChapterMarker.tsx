import React from "react";
import type { Brand } from "../schema";
import { type } from "../layout";

type Props = {
  brand: Brand;
  index?: number;
  title: string;
  featureName: string;
  left: number;
  top: number;
  right: number;
};

const pad = (n: number): string => n.toString().padStart(2, "0");

/** Small, stable chapter marker row: "01  Build & test a feature" left, feature name right. */
export const ChapterMarker: React.FC<Props> = ({
  brand,
  index,
  title,
  featureName,
  left,
  top,
  right,
}) => {
  return (
    <div
      style={{
        position: "absolute",
        left,
        right,
        top,
        height: 28,
        display: "flex",
        alignItems: "center",
        justifyContent: "space-between",
        fontFamily: brand.fontFamily,
        color: brand.inkMuted,
        ...type.label,
      }}
    >
      <div style={{ display: "flex", alignItems: "center", gap: 14 }}>
        {index === undefined ? null : (
          <>
            <span
              style={{
                fontFamily: brand.monoFontFamily,
                color: brand.ink,
                fontWeight: 500,
              }}
            >
              {pad(index)}
            </span>
            <span style={{ width: 1, height: 16, background: brand.line }} />
          </>
        )}
        <span>{title}</span>
      </div>
      <span style={{ ...type.eyebrow, fontFamily: brand.fontFamily }}>
        {featureName}
      </span>
    </div>
  );
};
