import React from "react";
import { interpolate } from "remotion";
import type { Feature, Shot } from "../content";
import { color, easeIn, easeOut, fontSans, FRAME_MARGIN, HEIGHT, radius, shadow, type, WIDTH } from "../tokens";
import { Cursor } from "./Cursor";
import { Screenshot } from "./Screenshot";
import { eyebrowStyle } from "./TileContent";

const XFADE = 16;
const CAPTION_IN = 22;
const CAPTION_OUT = 12;

const cardRect = (layout: Feature["layout"]) =>
  layout === "top"
    ? { x: FRAME_MARGIN, y: 340, w: WIDTH - FRAME_MARGIN * 2, h: HEIGHT - 340 + 80 }
    : { x: 800, y: FRAME_MARGIN, w: WIDTH - 800 + 80, h: HEIGHT - FRAME_MARGIN + 80 };

const shotOpacity = (shot: Shot, next: Shot | undefined, frame: number) => {
  const fadeIn = interpolate(frame, [shot.from, shot.from + XFADE], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  if (!next) return fadeIn;
  // The next shot fades in on top, so this one simply stays until covered.
  return frame < next.from + XFADE ? fadeIn : 0;
};

// Full-frame feature layout, rendered at 1920x1080 and scaled by the parent.
export const Expanded: React.FC<{ feature: Feature; frame: number; holdEnd: number }> = ({
  feature,
  frame,
  holdEnd,
}) => {
  const card = cardRect(feature.layout);
  const textWidth = feature.layout === "top" ? 1400 : 620;
  const activeShots = feature.shots.filter((s) => frame >= s.from);

  return (
    <div style={{ position: "absolute", left: 0, top: 0, width: WIDTH, height: HEIGHT, background: color.paper }}>
      <div
        style={{
          position: "absolute",
          left: FRAME_MARGIN,
          top: feature.layout === "top" ? 104 : FRAME_MARGIN,
          width: textWidth,
        }}
      >
        <div style={{ ...eyebrowStyle, color: color.accent, marginBottom: 28 }}>
          {feature.index} — {feature.label}
        </div>
        <div style={{ position: "relative", height: 260 }}>
          {feature.captions.map((cap, i) => {
            const next = feature.captions[i + 1];
            const end = next ? next.from : holdEnd;
            const inO = interpolate(frame, [cap.from, cap.from + CAPTION_IN], [0, 1], {
              extrapolateLeft: "clamp",
              extrapolateRight: "clamp",
              easing: easeOut,
            });
            const outO = interpolate(frame, [end - CAPTION_OUT, end], [1, 0], {
              extrapolateLeft: "clamp",
              extrapolateRight: "clamp",
              easing: easeIn,
            });
            const rise = (1 - inO) * 18;
            const opacity = Math.min(inO, outO);
            if (opacity <= 0) return null;
            return (
              <div
                key={cap.from}
                style={{ position: "absolute", left: 0, top: 0, width: textWidth, opacity, transform: `translateY(${rise}px)` }}
              >
                <div
                  style={{
                    fontFamily: fontSans,
                    fontSize: type.sizes1080p.h2,
                    fontWeight: 500,
                    letterSpacing: type.tracking.heading,
                    lineHeight: type.leading.heading,
                    color: color.ink,
                  }}
                >
                  {cap.title}
                </div>
                {cap.sub ? (
                  <div
                    style={{
                      marginTop: 16,
                      fontFamily: fontSans,
                      fontSize: type.sizes1080p.body,
                      fontWeight: 400,
                      letterSpacing: type.tracking.body,
                      lineHeight: type.leading.body,
                      color: color.gray500,
                    }}
                  >
                    {cap.sub}
                  </div>
                ) : null}
              </div>
            );
          })}
        </div>
      </div>

      <div
        style={{
          position: "absolute",
          left: card.x,
          top: card.y,
          width: card.w,
          height: card.h,
          borderRadius: radius.md,
          border: `1px solid ${color.border}`,
          boxShadow: shadow.figure,
          background: color.white,
          overflow: "hidden",
        }}
      >
        {activeShots.map((shot, i) => {
          const next = feature.shots[feature.shots.indexOf(shot) + 1];
          const end = next ? next.from + XFADE : holdEnd;
          const t = interpolate(frame, [shot.from, end], [0, 1], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          });
          const zoom = shot.zoom[0] + (shot.zoom[1] - shot.zoom[0]) * t;
          const focus = {
            x: shot.focus[0].x + (shot.focus[1].x - shot.focus[0].x) * t,
            y: shot.focus[0].y + (shot.focus[1].y - shot.focus[0].y) * t,
          };
          return (
            <Screenshot
              key={i}
              screen={shot.screen}
              width={card.w}
              height={card.h}
              zoom={zoom}
              focus={focus}
              opacity={shotOpacity(shot, next, frame)}
            />
          );
        })}
        {feature.cursor ? <Cursor keys={feature.cursor} frame={frame} width={card.w} height={card.h} /> : null}
      </div>
    </div>
  );
};
