import React from "react";
import { Easing, Img, interpolate, staticFile } from "remotion";
import { MediaFrame, frameSize } from "./MediaFrame";
import type { Brand, Content, LaunchProps, Station } from "./schema";
import type { StationTiming } from "./timeline";
import { SAFE, VIEW_H, VIEW_W, type } from "./type";

const easeOut = Easing.out(Easing.cubic);

/** Entrance for anchored text: 400ms fade + 16px slide, starting on arrival. */
const entrance = (frame: number, arrive: number, delay = 0) => {
  const p = interpolate(frame, [arrive + delay, arrive + delay + 12], [0, 1], {
    easing: easeOut,
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  return { opacity: p, transform: `translateX(${(1 - p) * 16}px)` };
};

const accentHeadline = (headline: string, accent: string, color: string) => {
  const i = accent ? headline.indexOf(accent) : -1;
  if (i < 0) return headline;
  return (
    <>
      {headline.slice(0, i)}
      <span style={{ color }}>{accent}</span>
      {headline.slice(i + accent.length)}
    </>
  );
};

type CellProps = {
  station: Station;
  timing: StationTiming;
  frame: number;
  brand: Brand;
  content: Content;
};

/** Cell origin: a station's centre maps to the centre of a 1920x1080 view. */
const cellOrigin = (s: Station) => ({
  left: s.x - VIEW_W / 2,
  top: s.y - VIEW_H / 2,
});

export const OpeningCell: React.FC<CellProps> = ({
  station,
  timing,
  frame,
  brand,
  content,
}) => {
  const { left, top } = cellOrigin(station);
  const logo = entrance(frame, timing.arrive, 0);
  const eyebrow = entrance(frame, timing.arrive, 6);
  const head = entrance(frame, timing.arrive, 10);
  const sub = entrance(frame, timing.arrive, 18);
  return (
    <div
      style={{
        position: "absolute",
        left,
        top,
        width: VIEW_W,
        height: VIEW_H,
        fontFamily: brand.fontFamily,
        color: brand.ink,
      }}
    >
      <Img
        src={staticFile(brand.logoLight)}
        style={{ position: "absolute", left: SAFE, top: SAFE, height: 44, ...logo }}
      />
      <div
        style={{
          position: "absolute",
          left: SAFE,
          top: 372,
          display: "flex",
          alignItems: "center",
          gap: 12,
          ...eyebrow,
        }}
      >
        <span
          style={{
            ...type.eyebrow,
            padding: "3px 10px",
            borderRadius: 9999,
            border: `1px solid ${brand.line}`,
            background: brand.surfaceAlt,
            color: brand.ink,
          }}
        >
          {content.eyebrow}
        </span>
        <span style={{ ...type.eyebrow, color: brand.inkMuted }}>
          {content.featureName}
        </span>
      </div>
      <div
        style={{
          position: "absolute",
          left: SAFE,
          top: 430,
          width: 1200,
          ...type.display,
          ...head,
        }}
      >
        {accentHeadline(content.headline, content.headlineAccent, brand.accent)}
      </div>
      <div
        style={{
          position: "absolute",
          left: SAFE,
          top: 568,
          width: 900,
          ...type.h5,
          color: brand.inkMuted,
          ...sub,
        }}
      >
        {content.subhead}
      </div>
    </div>
  );
};

export const CtaCell: React.FC<CellProps> = ({
  station,
  timing,
  frame,
  brand,
  content,
}) => {
  const { left, top } = cellOrigin(station);
  const line = entrance(frame, timing.arrive, 0);
  const cta = entrance(frame, timing.arrive, 10);
  const logo = entrance(frame, timing.arrive, 16);
  return (
    <div
      style={{
        position: "absolute",
        left,
        top,
        width: VIEW_W,
        height: VIEW_H,
        fontFamily: brand.fontFamily,
        color: brand.ink,
      }}
    >
      <div
        style={{
          position: "absolute",
          left: SAFE,
          top: 400,
          width: 1300,
          ...type.h2,
          ...line,
        }}
      >
        {content.outroLine}
      </div>
      <div
        style={{
          position: "absolute",
          left: SAFE,
          top: 528,
          display: "flex",
          alignItems: "center",
          gap: 24,
          ...cta,
        }}
      >
        <div
          style={{
            height: 44,
            padding: "0 16px",
            display: "flex",
            alignItems: "center",
            borderRadius: 2,
            background: brand.ink,
            color: brand.white,
            ...type.label,
          }}
        >
          {content.cta.label}
        </div>
        <span
          style={{
            fontFamily: brand.monoFontFamily,
            fontSize: 18,
            color: brand.inkMuted,
          }}
        >
          {content.cta.url}
        </span>
      </div>
      <Img
        src={staticFile(brand.logoLight)}
        style={{
          position: "absolute",
          left: SAFE,
          bottom: SAFE + 60,
          height: 44,
          ...logo,
        }}
      />
    </div>
  );
};

type MediaCellProps = CellProps & { media: LaunchProps["media"] };

/**
 * A media station: a large, front-facing product frame with its caption
 * anchored beside it. Text sits in a 484px column, 64px from the frame.
 */
export const MediaCell: React.FC<MediaCellProps> = ({
  station,
  timing,
  frame,
  brand,
  content,
  media,
}) => {
  const { left, top } = cellOrigin(station);
  const slot = station.mediaSlot ? media[station.mediaSlot] : undefined;
  const slotB = station.mediaSlotB ? media[station.mediaSlotB] : undefined;
  const label = entrance(frame, timing.arrive, 0);
  const caption = entrance(frame, timing.arrive, 6);
  if (!slot) return null;

  const mediaWidth = station.mediaWidth ?? 1180;
  const size = frameSize(slot, mediaWidth);
  const textSide = station.textSide ?? "left";
  const textW = 484;
  const gap = 64;
  // Media region: the space left after the text column and safe margins.
  const regionStart = textSide === "left" ? SAFE + textW + gap : SAFE;
  const regionEnd = textSide === "left" ? VIEW_W - SAFE : VIEW_W - SAFE - textW - gap;
  const mediaLeft = Math.round(regionStart + (regionEnd - regionStart - mediaWidth) / 2);
  const mediaTop = Math.round((VIEW_H - size.height) / 2);
  const textLeft = textSide === "left" ? mediaLeft - gap - textW : mediaLeft + mediaWidth + gap;

  // Second slot dissolves in halfway through the hold (8 frames).
  const mid = timing.arrive + Math.round(station.holdFrames / 2);
  const bOpacity = slotB
    ? interpolate(frame, [mid, mid + 8], [0, 1], {
        extrapolateLeft: "clamp",
        extrapolateRight: "clamp",
      })
    : 0;

  const captionText =
    station.captionIndex !== undefined ? content.captions[station.captionIndex] : undefined;

  return (
    <div
      style={{
        position: "absolute",
        left,
        top,
        width: VIEW_W,
        height: VIEW_H,
        fontFamily: brand.fontFamily,
        color: brand.ink,
      }}
    >
      <div
        style={{
          position: "absolute",
          left: textLeft,
          top: VIEW_H / 2 - 120,
          width: textW,
        }}
      >
        {station.useCaseLabel ? (
          <div style={{ ...type.eyebrow, color: brand.inkMuted, marginBottom: 20, ...label }}>
            {station.useCaseLabel}
          </div>
        ) : null}
        {captionText ? (
          <div style={{ ...type.h3, ...caption }}>{captionText}</div>
        ) : null}
      </div>
      <MediaFrame
        slot={slot}
        width={mediaWidth}
        brand={brand}
        left={mediaLeft}
        top={mediaTop}
        badge={station.showSpeedBadge ? content.speedBadge : undefined}
        monoFontFamily={brand.monoFontFamily}
      />
      {slotB ? (
        <MediaFrame
          slot={slotB}
          width={mediaWidth}
          brand={brand}
          left={mediaLeft}
          top={mediaTop}
          opacity={bOpacity}
          monoFontFamily={brand.monoFontFamily}
        />
      ) : null}
    </div>
  );
};
