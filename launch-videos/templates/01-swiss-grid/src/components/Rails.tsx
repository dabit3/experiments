import { Img, staticFile } from "remotion";
import { HEIGHT, WIDTH } from "../defaults";
import type { Brand, Content, Grid } from "../schema";

type RailProps = {
  brand: Brand;
  grid: Grid;
  content: Content;
  sceneIndex: number;
  sceneCount: number;
  /** Index into content.stages that is currently active, if any. */
  stage?: number;
  dark?: boolean;
};

const pad = (n: number) => String(n).padStart(2, "0");

/**
 * Persistent top and bottom rails. Top: lockup and a mono scene counter.
 * Bottom: the workflow stages as a progress indicator; the active stage takes
 * the accent color.
 */
export const Rails = ({ brand, grid, content, sceneIndex, sceneCount, stage, dark }: RailProps) => {
  const fg = dark ? brand.white : brand.ink;
  const muted = dark ? brand.inkSubtle : brand.inkMuted;
  const line = dark ? brand.blackRaised : brand.line;
  const innerWidth = WIDTH - grid.margin * 2;
  const mono = {
    fontFamily: brand.monoFontFamily,
    fontSize: 14,
    letterSpacing: "0.04em",
    textTransform: "uppercase" as const,
    lineHeight: `${grid.railHeight}px`,
  };
  return (
    <>
      <div
        style={{
          position: "absolute",
          left: grid.margin,
          top: grid.margin,
          width: innerWidth,
          height: grid.railHeight,
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          borderBottom: `1px solid ${line}`,
          color: fg,
        }}
      >
        <Img
          src={staticFile(dark ? brand.logoDark : brand.logoLight)}
          style={{ height: 22, display: "block" }}
        />
        <div style={{ ...mono, color: muted }}>
          {content.featureName}
          <span style={{ color: fg, marginLeft: 32 }}>
            {pad(sceneIndex + 1)} / {pad(sceneCount)}
          </span>
        </div>
      </div>
      <div
        style={{
          position: "absolute",
          left: grid.margin,
          top: HEIGHT - grid.margin - grid.railHeight,
          width: innerWidth,
          height: grid.railHeight,
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          borderTop: `1px solid ${line}`,
          ...mono,
          color: muted,
        }}
      >
        <div style={{ display: "flex", gap: 32 }}>
          {content.stages.map((label, i) => {
            const active = stage === i;
            return (
              <span
                key={label}
                style={{
                  color: active ? brand.accent : muted,
                  position: "relative",
                }}
              >
                {pad(i + 1)}&nbsp;&nbsp;{label}
                {active ? (
                  <span
                    style={{
                      position: "absolute",
                      left: 0,
                      right: 0,
                      top: -1,
                      height: 2,
                      background: brand.accent,
                    }}
                  />
                ) : null}
              </span>
            );
          })}
        </div>
        <div>{content.cta.url}</div>
      </div>
    </>
  );
};
