import React from "react";
import {
  Freeze,
  Img,
  OffthreadVideo,
  staticFile,
  useCurrentFrame,
} from "remotion";
import type { Brand, Media, Storyboard } from "../schema";
import type { PanelState } from "../timeline";

const FULL_CROP = { x: 0, y: 0, w: 1, h: 1 };

/**
 * Pixel-exact crop + cover: the media is scaled so the crop region covers the
 * panel, then offset so the crop's top-left aligns. Nothing is skewed.
 */
const mediaBox = (media: Media, pw: number, ph: number) => {
  const c = media.crop ?? FULL_CROP;
  const cropAspect = (media.aspect * c.w) / c.h;
  const panelAspect = pw / ph;
  let cw: number;
  let ch: number;
  if (cropAspect > panelAspect) {
    ch = ph;
    cw = ph * cropAspect;
  } else {
    cw = pw;
    ch = pw / cropAspect;
  }
  const mw = cw / c.w;
  const mh = ch / c.h;
  return {
    width: mw,
    height: mh,
    left: (pw - cw) / 2 - c.x * mw,
    top: (ph - ch) / 2 - c.y * mh,
  };
};

const MediaContent: React.FC<{ media: Media; pw: number; ph: number }> = ({
  media,
  pw,
  ph,
}) => {
  const local = useCurrentFrame();
  const box = mediaBox(media, pw, ph);
  const style: React.CSSProperties = {
    position: "absolute",
    ...box,
    objectFit: "fill",
  };
  if (media.kind === "image") {
    return <Img src={staticFile(media.src)} style={style} />;
  }
  const rate = media.playbackRate ?? 1;
  const startFrom = media.startFrom ?? 0;
  const lastLocal =
    media.durationInFrames === undefined
      ? Infinity
      : Math.floor((media.durationInFrames - startFrom) / rate) - 1;
  const video = (
    <OffthreadVideo
      src={staticFile(media.src)}
      trimBefore={startFrom}
      playbackRate={rate}
      muted
      style={style}
    />
  );
  if (lastLocal === Infinity) return video;
  return (
    <Freeze frame={lastLocal} active={local >= lastLocal}>
      {video}
    </Freeze>
  );
};

export const Panel: React.FC<{
  media: Media;
  state: PanelState;
  number: number;
  brand: Brand;
  sb: Storyboard;
  /** 1 = normal chrome, 0 = edge-to-edge (no border, radius, label). */
  chrome: number;
}> = ({ media, state, number, brand, sb, chrome }) => {
  const { rect, reveal, presence, activeness } = state;
  const pw = Math.max(1, Math.round(rect.w));
  const ph = Math.max(1, Math.round(rect.h));
  const opacity =
    presence * (sb.contextOpacity + (1 - sb.contextOpacity) * activeness);
  const radius = sb.panelRadius * chrome;
  const revealPx = reveal * pw;
  const edgeOpacity = reveal <= 0 || reveal >= 1 ? 0 : 1 - Math.pow(reveal, 4);
  const showNumber = sb.showPanelNumbers && chrome > 0.01 && rect.y > 24;

  return (
    <div
      style={{
        position: "absolute",
        left: rect.x,
        top: rect.y,
        width: pw,
        height: ph,
        opacity,
      }}
    >
      {showNumber ? (
        <div
          style={{
            position: "absolute",
            left: 0,
            top: -22,
            fontFamily: brand.monoFontFamily,
            fontSize: 12,
            lineHeight: "16px",
            letterSpacing: 0.4,
            color: activeness > 0.5 ? brand.ink : brand.inkSubtle,
            opacity: reveal * chrome,
          }}
        >
          {String(number).padStart(2, "0")}
        </div>
      ) : null}
      <div
        style={{
          position: "absolute",
          inset: 0,
          borderRadius: radius,
          overflow: "hidden",
          background: brand.surface,
          boxShadow:
            chrome > 0.01
              ? `0 0 ${8 * chrome}px rgba(221,221,221,${chrome})`
              : undefined,
          clipPath: `inset(0 ${pw - revealPx}px 0 0 round ${radius}px)`,
        }}
      >
        <MediaContent media={media} pw={pw} ph={ph} />
        <div
          style={{
            position: "absolute",
            inset: 0,
            borderRadius: radius,
            boxShadow: `inset 0 0 0 ${chrome}px ${brand.line}`,
            pointerEvents: "none",
          }}
        />
      </div>
      {/* Moving gutter: the reveal boundary travels across the panel. */}
      <div
        style={{
          position: "absolute",
          top: -sb.gutter / 2,
          bottom: -sb.gutter / 2,
          left: Math.min(pw - 2, revealPx),
          width: 2,
          background: brand.ink,
          opacity: edgeOpacity,
        }}
      />
    </div>
  );
};
