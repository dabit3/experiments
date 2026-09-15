import React from "react";
import { AbsoluteFill, interpolate, useCurrentFrame } from "remotion";
import type { LaunchProps, StationScene as StationSceneProps } from "../schema";
import { RouteMap } from "../components/RouteMap";
import { MediaFrame } from "../components/MediaFrame";
import { RouteIndicator } from "../components/RouteIndicator";
import { TopBar, Wipe } from "../components/Chrome";
import { STAGE, TYPE, easeInOut, fitToStage, lerpRect, ramp, routeXs, stationIndex } from "../geometry";

type Props = { props: LaunchProps; scene: StationSceneProps };

export const StationScene: React.FC<Props> = ({ props, scene }) => {
  const frame = useCurrentFrame();
  const { brand, route, timing, media, content } = props;
  const k = stationIndex(route, scene.station);
  const station = route.stations[k - 1];
  const slot = media[scene.media];
  if (!slot) {
    throw new Error(`Unknown media slot "${scene.media}"`);
  }
  const D = scene.durationInFrames;
  const { arrive, expand, collapse } = timing;

  // A: the line finishes into the marker.
  const progress = k - 0.15 + 0.15 * ramp(frame, 0, arrive, easeInOut);
  // B / D: the recording expands from the marker, later returns to it.
  const tExpand = ramp(frame, arrive, expand, easeInOut);
  const tCollapse = ramp(frame, D - collapse, collapse, easeInOut);
  const openness = frame < D - collapse ? tExpand : 1 - tCollapse;

  const xs = routeXs(route);
  const r = route.markerRadius;
  const markerRect = { x: xs[k] - r, y: route.y - r, w: 2 * r, h: 2 * r };
  const target = fitToStage(slot);
  const rect = lerpRect(markerRect, target, openness);

  const mapOpacity = interpolate(openness, [0, 0.7], [1, 0], { extrapolateRight: "clamp" });
  const uiOpacity = interpolate(openness, [0.75, 1], [0, 1], { extrapolateLeft: "clamp" });
  const pulseT = ramp(frame, arrive - 2, 22);

  return (
    <AbsoluteFill style={{ background: brand.paper }}>
      <TopBar brand={brand} content={content} opacity={mapOpacity} />
      <RouteMap
        brand={brand}
        route={route}
        progress={progress}
        opacity={mapOpacity}
        pulse={pulseT > 0 && pulseT < 1 ? { station: k, t: pulseT } : undefined}
      />

      {/* Station header: number, name, and the small route indicator */}
      <div style={{ position: "absolute", left: STAGE.x, right: STAGE.x, top: 62, height: 52, opacity: uiOpacity }}>
        <div style={{ display: "flex", alignItems: "center", gap: 16, position: "absolute", left: 0, top: 0, height: 52 }}>
          <div
            style={{
              width: 44,
              height: 44,
              borderRadius: 9999,
              background: brand.accent,
              color: brand.white,
              fontFamily: brand.monoFontFamily,
              fontSize: TYPE.label.size,
              fontWeight: 500,
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
            }}
          >
            {String(k).padStart(2, "0")}
          </div>
          <div
            style={{
              fontFamily: brand.fontFamily,
              fontSize: TYPE.h3.size,
              letterSpacing: TYPE.h3.tracking,
              fontWeight: 500,
              color: brand.ink,
            }}
          >
            {station.name}
          </div>
        </div>
        <div style={{ position: "absolute", right: 0, top: 0, height: 52, display: "flex", alignItems: "center" }}>
          <RouteIndicator brand={brand} route={route} current={k} />
        </div>
      </div>

      {openness > 0 ? (
        <MediaFrame
          brand={brand}
          slot={slot}
          target={target}
          rect={rect}
          speedBadge={scene.speedBadge ? content.speedBadge : undefined}
        />
      ) : null}

      {/* Captions: what changes at this station */}
      <div style={{ position: "absolute", left: STAGE.x, right: STAGE.x, top: STAGE.y + STAGE.h + 26, height: 44, opacity: uiOpacity }}>
        {scene.captions.map((c, i) => {
          const next = scene.captions[i + 1];
          const end = next ? next.atFrame : Number.POSITIVE_INFINITY;
          if (frame < c.atFrame || frame >= end) {
            return null;
          }
          const tIn = ramp(frame, c.atFrame, timing.captionWipe);
          const fadeOut = next ? interpolate(frame, [end - 8, end], [1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" }) : 1;
          return (
            <Wipe key={c.text} t={tIn} style={{ position: "absolute", left: 0, top: 0, opacity: fadeOut }}>
              <div
                style={{
                  fontFamily: brand.fontFamily,
                  fontSize: 30,
                  lineHeight: 1.35,
                  letterSpacing: -0.45,
                  color: brand.ink,
                  whiteSpace: "nowrap",
                }}
              >
                {c.text}
              </div>
            </Wipe>
          );
        })}
      </div>
    </AbsoluteFill>
  );
};
