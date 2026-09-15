import React from "react";
import { AbsoluteFill, useCurrentFrame } from "remotion";
import type { LaunchProps } from "../schema";
import { Caret } from "../components/Caret";
import { TypedText } from "../components/TypedText";
import { Header } from "../components/Header";
import { progress, typedLength, typingFrames, easeOut } from "../motion";

type Props = { props: LaunchProps; durationInFrames: number };

/**
 * Three lines typed one after another on paper: eyebrow (mono), headline
 * (display), subhead. The caret moves down with each completed line and
 * settles, blinking, after the subhead.
 */
export const Open: React.FC<Props> = ({ props, durationInFrames }) => {
  const frame = useCurrentFrame();
  const { brand, content, cursor, layout, timing } = props;

  const eyebrowStart = 10;
  const eyebrowDone = eyebrowStart + typingFrames(content.eyebrow, cursor.charsPerFrame);
  const headlineStart = eyebrowDone + 10;
  const headlineDone = headlineStart + typingFrames(content.headline, cursor.charsPerFrame);
  const subheadStart = headlineDone + 10;
  const subheadSpeed = cursor.charsPerFrame * 2.5;
  const subheadDone = subheadStart + typingFrames(content.subhead, subheadSpeed);

  const eyebrowChars = typedLength(content.eyebrow, frame - eyebrowStart, cursor.charsPerFrame);
  const headlineChars = typedLength(content.headline, frame - headlineStart, cursor.charsPerFrame);
  const subheadChars = typedLength(content.subhead, frame - subheadStart, subheadSpeed);

  const activeLine =
    frame < headlineStart ? "eyebrow" : frame < subheadStart ? "headline" : "subhead";
  const blinking =
    (activeLine === "eyebrow" && (frame < eyebrowStart || frame >= eyebrowDone)) ||
    (activeLine === "headline" && frame >= headlineDone) ||
    (activeLine === "subhead" && frame >= subheadDone);

  const exit = 1 - progress(frame, durationInFrames - timing.exitFade, timing.exitFade, easeOut);

  const displaySize = 88;
  const subSize = 30;

  return (
    <AbsoluteFill style={{ backgroundColor: brand.paper, opacity: exit }}>
      <Header brand={brand} left={content.featureName} safeMargin={layout.safeMargin} />
      <div
        style={{
          position: "absolute",
          left: layout.safeMargin,
          right: layout.safeMargin,
          top: "50%",
          transform: "translateY(-52%)",
          color: brand.ink,
        }}
      >
        <div
          style={{
            fontFamily: brand.monoFontFamily,
            fontSize: 20,
            lineHeight: "28px",
            letterSpacing: 0.4,
            textTransform: "uppercase",
            color: brand.inkMuted,
            minHeight: 28,
            opacity: frame >= eyebrowStart ? 1 : 0,
          }}
        >
          <TypedText text={content.eyebrow} visibleChars={eyebrowChars} brand={brand} />
          {activeLine === "eyebrow" ? (
            <Caret brand={brand} cursor={cursor} fontSize={20} blinking={blinking} />
          ) : null}
        </div>
        <div
          style={{
            marginTop: 28,
            fontFamily: brand.fontFamily,
            fontWeight: 500,
            fontSize: displaySize,
            lineHeight: `${displaySize}px`,
            letterSpacing: -3.3,
            minHeight: displaySize,
            opacity: frame >= headlineStart ? 1 : 0,
          }}
        >
          <TypedText
            text={content.headline}
            visibleChars={headlineChars}
            accentWord={content.headlineAccentWord}
            brand={brand}
          />
          {activeLine === "headline" ? (
            <Caret brand={brand} cursor={cursor} fontSize={displaySize * 0.8} blinking={blinking} />
          ) : null}
        </div>
        <div
          style={{
            marginTop: 40,
            maxWidth: 1180,
            fontFamily: brand.fontFamily,
            fontWeight: 400,
            fontSize: subSize,
            lineHeight: `${subSize * 1.4}px`,
            letterSpacing: -0.4,
            color: brand.inkMuted,
            minHeight: subSize * 1.4 * 2,
            opacity: frame >= subheadStart ? 1 : 0,
          }}
        >
          <TypedText text={content.subhead} visibleChars={subheadChars} brand={brand} />
          {activeLine === "subhead" ? (
            <Caret brand={brand} cursor={cursor} fontSize={subSize} blinking={blinking} />
          ) : null}
        </div>
      </div>
    </AbsoluteFill>
  );
};
