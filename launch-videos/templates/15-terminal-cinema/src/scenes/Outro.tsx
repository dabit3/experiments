import React from "react";
import { AbsoluteFill, Img, staticFile, useCurrentFrame } from "remotion";
import type { LaunchProps } from "../schema";
import { Caret } from "../components/Caret";
import { TypedText } from "../components/TypedText";
import { progress, typedLength, typingFrames, easeOut } from "../motion";

type Props = { props: LaunchProps };

/**
 * Minimal close: lockup, the outro line typed once, then the CTA button
 * and URL with the caret resting after the address.
 */
export const Outro: React.FC<Props> = ({ props }) => {
  const frame = useCurrentFrame();
  const { brand, content, cursor, layout } = props;

  const logoIn = progress(frame, 0, 14, easeOut);
  const lineStart = 10;
  const lineDone = lineStart + typingFrames(content.outroLine, cursor.charsPerFrame * 1.5);
  const lineChars = typedLength(content.outroLine, frame - lineStart, cursor.charsPerFrame * 1.5);
  const ctaIn = progress(frame, lineDone + 6, 14, easeOut);

  return (
    <AbsoluteFill style={{ backgroundColor: brand.paper }}>
      <div
        style={{
          position: "absolute",
          left: layout.safeMargin,
          right: layout.safeMargin,
          top: "50%",
          transform: "translateY(-50%)",
          color: brand.ink,
        }}
      >
        <Img
          src={staticFile(brand.logoLight)}
          style={{
            height: 56,
            display: "block",
            opacity: logoIn,
            transform: `translateY(${(1 - logoIn) * 8}px)`,
          }}
        />
        <div
          style={{
            marginTop: 48,
            fontFamily: brand.fontFamily,
            fontWeight: 500,
            fontSize: 48,
            lineHeight: "56px",
            letterSpacing: -1.6,
            minHeight: 56,
            opacity: frame >= lineStart ? 1 : 0,
          }}
        >
          <TypedText text={content.outroLine} visibleChars={lineChars} brand={brand} />
          {frame < lineDone + 6 ? (
            <Caret brand={brand} cursor={cursor} fontSize={42} blinking={false} />
          ) : null}
        </div>
        <div
          style={{
            marginTop: 40,
            display: "flex",
            alignItems: "center",
            gap: 24,
            opacity: ctaIn,
            transform: `translateY(${(1 - ctaIn) * 8}px)`,
          }}
        >
          <div
            style={{
              backgroundColor: brand.ink,
              color: brand.white,
              fontFamily: brand.fontFamily,
              fontWeight: 500,
              fontSize: 22,
              lineHeight: "26px",
              letterSpacing: -0.3,
              padding: "10px 18px",
              borderRadius: 2,
            }}
          >
            {content.cta.label}
          </div>
          <div
            style={{
              fontFamily: brand.monoFontFamily,
              fontSize: 22,
              lineHeight: "26px",
              color: brand.inkMuted,
              display: "flex",
              alignItems: "center",
            }}
          >
            {content.cta.url}
            <Caret brand={brand} cursor={cursor} fontSize={22} blinking />
          </div>
        </div>
      </div>
    </AbsoluteFill>
  );
};
