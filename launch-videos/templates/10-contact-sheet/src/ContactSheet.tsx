import React from "react";
import { AbsoluteFill, Img, interpolate, staticFile } from "remotion";
import type { Brand, Content, LaunchProps, SheetLayout } from "./schema";
import { MediaFrame } from "./MediaFrame";
import { HEIGHT, WIDTH } from "./defaults";
import { cellRect, easeOut, IndexFrame, MARGIN, pad2 } from "./layout";

type Props = {
  brand: Brand;
  content: Content;
  media: LaunchProps["media"];
  sheet: SheetLayout;
  frames: IndexFrame[];
  /** Index frame currently outlined in the accent color, if any. */
  selected: number | null;
  /** Frames with index < viewedUpTo have already been enlarged. */
  viewedUpTo: number;
  /** Hide this cell's thumbnail (the enlarged copy is drawn on top of it). */
  hideIndex?: number | null;
  /** 0..1 staggered entrance of the cells; 1 = fully revealed. */
  reveal?: number;
  opacity?: number;
};

export const Headline: React.FC<{ brand: Brand; content: Content; size: number; lineHeight: number; tracking: number }> = ({
  brand,
  content,
  size,
  lineHeight,
  tracking,
}) => {
  const words = content.headline.split(" ");
  return (
    <div
      style={{
        fontFamily: brand.fontFamily,
        fontWeight: 500,
        fontSize: size,
        lineHeight: `${lineHeight}px`,
        letterSpacing: tracking,
        color: brand.ink,
      }}
    >
      {words.map((w, i) => (
        <React.Fragment key={i}>
          <span style={{ color: w === content.headlineAccentWord ? brand.accent : brand.ink }}>{w}</span>
          {i < words.length - 1 ? " " : null}
        </React.Fragment>
      ))}
    </div>
  );
};

export const ContactSheet: React.FC<Props> = ({
  brand,
  content,
  media,
  sheet,
  frames,
  selected,
  viewedUpTo,
  hideIndex = null,
  reveal = 1,
  opacity = 1,
}) => {
  const count = frames.length;
  const total = pad2(count);

  return (
    <AbsoluteFill style={{ backgroundColor: brand.paper, opacity, fontFamily: brand.fontFamily }}>
      {/* Header */}
      <div style={{ position: "absolute", left: MARGIN, top: MARGIN, width: 1200 }}>
        <div
          style={{
            fontFamily: brand.fontFamily,
            fontWeight: 500,
            fontSize: 14,
            lineHeight: "20px",
            letterSpacing: 0.4,
            textTransform: "uppercase",
            color: brand.inkMuted,
            marginBottom: 20,
          }}
        >
          {content.eyebrow} · {content.featureName}
        </div>
        <Headline brand={brand} content={content} size={70} lineHeight={70} tracking={-2.6} />
        <div
          style={{
            marginTop: 24,
            fontFamily: brand.fontFamily,
            fontWeight: 400,
            fontSize: 22,
            lineHeight: "32px",
            letterSpacing: -0.3,
            color: brand.inkMuted,
            maxWidth: 880,
          }}
        >
          {content.subhead}
        </div>
      </div>

      <Img
        src={staticFile(brand.logoLight)}
        style={{ position: "absolute", right: MARGIN, top: MARGIN - 2, height: 26, width: "auto" }}
      />

      {/* Index frames */}
      {frames.map((f, i) => {
        const rect = cellRect(sheet, count, i);
        const slot = media[f.media];
        const isSelected = selected === i;
        const viewed = i < viewedUpTo;
        const local = interpolate(reveal, [i / count, (i + 1) / count], [0, 1], {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
          easing: easeOut,
        });
        const shift = (1 - local) * 12;
        const numberColor = isSelected ? brand.accent : viewed ? brand.ink : brand.inkSubtle;
        return (
          <div
            key={f.index}
            style={{
              position: "absolute",
              left: rect.x,
              top: rect.y - 30 - shift,
              width: rect.w,
              opacity: local,
            }}
          >
            <div
              style={{
                display: "flex",
                justifyContent: "space-between",
                fontFamily: brand.monoFontFamily,
                fontWeight: 500,
                fontSize: 14,
                lineHeight: "20px",
                color: numberColor,
                marginBottom: 10,
              }}
            >
              <span>{pad2(i + 1)}</span>
              <span style={{ color: brand.inkSubtle, fontWeight: 400 }}>/ {total}</span>
            </div>
            <div style={{ position: "relative", width: rect.w, height: rect.h, opacity: hideIndex === i ? 0 : 1 }}>
              {slot ? (
                <MediaFrame
                  slot={slot}
                  brand={brand}
                  width={rect.w}
                  height={rect.h}
                  radius={8}
                  still={{ frame: slot.thumbFrame ?? slot.startFrom ?? 0 }}
                />
              ) : null}
              <div
                style={{
                  position: "absolute",
                  inset: -3,
                  borderRadius: 11,
                  border: `2px solid ${brand.accent}`,
                  opacity: isSelected ? 1 : 0,
                  pointerEvents: "none",
                }}
              />
            </div>
            <div
              style={{
                marginTop: 12,
                fontFamily: brand.fontFamily,
                fontWeight: 400,
                fontSize: 15,
                lineHeight: "20px",
                letterSpacing: -0.2,
                color: isSelected ? brand.ink : brand.inkMuted,
              }}
            >
              {f.label}
            </div>
          </div>
        );
      })}

      {/* Metadata */}
      <div
        style={{
          position: "absolute",
          left: MARGIN,
          right: MARGIN,
          top: HEIGHT - MARGIN - 20,
          display: "flex",
          justifyContent: "space-between",
          fontFamily: brand.monoFontFamily,
          fontWeight: 400,
          fontSize: 13,
          lineHeight: "20px",
          color: brand.inkSubtle,
          width: WIDTH - 2 * MARGIN,
        }}
      >
        <span>{sheet.metadata}</span>
        <span>{content.cta.url}</span>
      </div>
    </AbsoluteFill>
  );
};
