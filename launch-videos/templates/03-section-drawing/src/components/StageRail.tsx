import React from "react";
import type { Brand, Content } from "../schema";
import { CONTENT, MARGIN, OVERVIEW_GAP_OPEN, overviewBoxes, RAIL_HEIGHT } from "../layout";
import { Mono } from "./Text";

/**
 * Thin rail along the top of stage scenes: the five stage labels on one hairline,
 * aligned to the overview diagram's columns, with the current stage underlined in accent.
 */
export const StageRail: React.FC<{
  brand: Brand;
  content: Content;
  current: number;
  opacity: number;
}> = ({ brand, content, current, opacity }) => {
  if (opacity <= 0) {
    return null;
  }
  const boxes = overviewBoxes(content.stages.length, OVERVIEW_GAP_OPEN);
  const baseline = MARGIN + RAIL_HEIGHT;
  return (
    <div style={{ position: "absolute", left: 0, top: 0, opacity }}>
      <div
        style={{
          position: "absolute",
          left: CONTENT.x,
          top: baseline,
          width: CONTENT.w,
          height: 1,
          background: brand.line,
        }}
      />
      {content.stages.map((stage, i) => {
        const box = boxes[i];
        const isCurrent = i === current;
        const done = i < current;
        return (
          <div key={stage.id} style={{ position: "absolute", left: box.x, top: MARGIN + 6, width: box.w }}>
            <div style={{ display: "flex", alignItems: "baseline", gap: 10 }}>
              <Mono brand={brand} size={15} color={isCurrent ? brand.accent : brand.inkSubtle}>
                {String(i + 1).padStart(2, "0")}
              </Mono>
              <div
                style={{
                  fontFamily: brand.fontFamily,
                  fontSize: 24,
                  lineHeight: "30px",
                  letterSpacing: -0.3,
                  fontWeight: isCurrent ? 500 : 400,
                  color: isCurrent ? brand.ink : done ? brand.inkMuted : brand.inkSubtle,
                }}
              >
                {stage.label}
              </div>
            </div>
            {isCurrent ? (
              <div
                style={{
                  position: "absolute",
                  left: 0,
                  top: baseline - (MARGIN + 6) - 1,
                  width: box.w,
                  height: 2,
                  background: brand.accent,
                }}
              />
            ) : null}
          </div>
        );
      })}
    </div>
  );
};
