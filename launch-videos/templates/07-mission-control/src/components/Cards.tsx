import React from "react";
import { Img, staticFile } from "remotion";
import type { Brand, Content } from "../schema";
import { MonoLabel } from "./Panel";

/** Headline with the accent phrase set in `brand.accent`. */
export const Headline: React.FC<{
  brand: Brand;
  content: Content;
  size: number;
  align: "left" | "center";
}> = ({ brand, content, size, align }) => {
  const { headline, headlineAccent } = content;
  const idx = headlineAccent ? headline.indexOf(headlineAccent) : -1;
  const parts =
    idx >= 0 && headlineAccent
      ? [
          headline.slice(0, idx),
          headlineAccent,
          headline.slice(idx + headlineAccent.length),
        ]
      : [headline, "", ""];
  return (
    <div
      style={{
        fontFamily: brand.fontFamily,
        fontSize: size,
        lineHeight: 1.02,
        letterSpacing: -size * 0.038,
        fontWeight: 500,
        color: brand.white,
        textAlign: align,
      }}
    >
      {parts[0]}
      <span style={{ color: brand.accent }}>{parts[1]}</span>
      {parts[2]}
    </div>
  );
};

type TitleProps = {
  brand: Brand;
  content: Content;
  width: number;
  height: number;
  /** Entrance progress of eyebrow / headline / subhead (0..1 each). */
  steps: [number, number, number];
};

/** Opening card shown on the primary display before footage arrives. */
export const TitleCard: React.FC<TitleProps> = ({ brand, content, width, height, steps }) => {
  const pad = 56;
  const rise = (p: number) => `translateY(${(1 - p) * 14}px)`;
  return (
    <div
      style={{
        position: "absolute",
        inset: 0,
        width,
        height,
        padding: pad,
        display: "flex",
        flexDirection: "column",
        justifyContent: "flex-end",
        gap: 24,
        boxSizing: "border-box",
      }}
    >
      <div style={{ opacity: steps[0], transform: rise(steps[0]) }}>
        <MonoLabel brand={brand} color={brand.accent} size={18}>
          {content.eyebrow}
        </MonoLabel>
      </div>
      <div style={{ opacity: steps[1], transform: rise(steps[1]), maxWidth: width - pad * 2 }}>
        <Headline brand={brand} content={content} size={100} align="left" />
      </div>
      <div
        style={{
          opacity: steps[2],
          transform: rise(steps[2]),
          fontFamily: brand.fontFamily,
          fontSize: 34,
          lineHeight: "46px",
          letterSpacing: -0.5,
          color: brand.inkMuted,
          maxWidth: Math.min(1000, width - pad * 2),
        }}
      >
        {content.subhead}
      </div>
    </div>
  );
};

type HeroProps = {
  brand: Brand;
  content: Content;
  width: number;
  height: number;
  steps: [number, number, number, number];
};

/** Closing lockup: logo, headline, CTA, outro line. */
export const HeroCard: React.FC<HeroProps> = ({ brand, content, width, height, steps }) => {
  const rise = (p: number) => `translateY(${(1 - p) * 14}px)`;
  const logoH = 64;
  return (
    <div
      style={{
        position: "absolute",
        inset: 0,
        width,
        height,
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        gap: 32,
        boxSizing: "border-box",
        padding: 80,
      }}
    >
      <div style={{ opacity: steps[0], transform: rise(steps[0]) }}>
        <Img
          src={staticFile(brand.logoDark)}
          style={{ height: logoH, width: (logoH * 2984) / 1024, display: "block" }}
        />
      </div>
      <div style={{ opacity: steps[1], transform: rise(steps[1]), maxWidth: 1400 }}>
        <Headline brand={brand} content={content} size={108} align="center" />
      </div>
      <div
        style={{
          opacity: steps[2],
          transform: rise(steps[2]),
          display: "flex",
          alignItems: "center",
          gap: 20,
          marginTop: 8,
        }}
      >
        <div
          style={{
            height: 64,
            padding: "0 28px",
            borderRadius: 2,
            background: brand.white,
            color: brand.ink,
            fontFamily: brand.fontFamily,
            fontSize: 26,
            fontWeight: 500,
            letterSpacing: -0.2,
            display: "flex",
            alignItems: "center",
          }}
        >
          {content.cta.label}
        </div>
        <span
          style={{
            fontFamily: brand.monoFontFamily,
            fontSize: 22,
            color: brand.inkMuted,
          }}
        >
          {content.cta.url}
        </span>
      </div>
      <div
        style={{
          opacity: steps[3],
          transform: rise(steps[3]),
          fontFamily: brand.fontFamily,
          fontSize: 30,
          letterSpacing: -0.4,
          color: brand.inkMuted,
        }}
      >
        {content.outroLine}
      </div>
    </div>
  );
};
