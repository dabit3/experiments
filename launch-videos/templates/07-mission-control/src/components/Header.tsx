import React from "react";
import { Img, staticFile } from "remotion";
import type { Rect } from "../layout";
import type { Brand, Content } from "../schema";
import { MonoLabel } from "./Panel";

type Props = {
  rect: Rect;
  brand: Brand;
  content: Content;
  /** Id of the highlighted stage; undefined = none yet. */
  stage?: string;
  opacity: number;
};

export const Header: React.FC<Props> = ({ rect, brand, content, stage, opacity }) => {
  const stageIndex = content.stages.findIndex((s) => s.id === stage);
  const logoH = 36;

  return (
    <div
      style={{
        position: "absolute",
        left: rect.x,
        top: rect.y,
        width: rect.w,
        height: rect.h,
        display: "flex",
        alignItems: "center",
        justifyContent: "space-between",
        opacity,
      }}
    >
      <div style={{ display: "flex", alignItems: "center", gap: 24 }}>
        <Img
          src={staticFile(brand.logoDark)}
          style={{ height: logoH, width: (logoH * 2984) / 1024, display: "block" }}
        />
        <div style={{ width: 1, height: 28, background: brand.consoleLine }} />
        <span
          style={{
            fontFamily: brand.fontFamily,
            fontSize: 26,
            fontWeight: 500,
            letterSpacing: -0.2,
            color: brand.white,
          }}
        >
          {content.featureName}
        </span>
      </div>

      <div style={{ display: "flex", alignItems: "center", gap: 16 }}>
        {content.stages.map((s, i) => {
          const done = stageIndex >= 0 && i < stageIndex;
          const current = i === stageIndex;
          const color = current ? brand.white : done ? brand.inkMuted : brand.inkSubtle;
          return (
            <React.Fragment key={s.id}>
              {i > 0 ? (
                <div style={{ width: 20, height: 1, background: brand.consoleLine }} />
              ) : null}
              <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                <div
                  style={{
                    width: 8,
                    height: 8,
                    borderRadius: 4,
                    background: current ? brand.accent : done ? brand.inkMuted : "transparent",
                    boxShadow: current || done ? "none" : `0 0 0 1px ${brand.inkSubtle}`,
                  }}
                />
                <MonoLabel brand={brand} color={color} size={16}>
                  {s.label}
                </MonoLabel>
              </div>
            </React.Fragment>
          );
        })}
      </div>
    </div>
  );
};
