import React from "react";
import { AbsoluteFill, Sequence, useCurrentFrame, useVideoConfig } from "remotion";
import type { DemoScene, LaunchProps } from "../schema";
import { Caret } from "../components/Caret";
import { TypedText } from "../components/TypedText";
import { Header } from "../components/Header";
import { Media, fitMedia } from "../components/Media";
import { progress, typedLength, typingFrames, easeOut, easeInOut } from "../motion";

type Props = {
  props: LaunchProps;
  scene: DemoScene;
  index: number;
  count: number;
};

/**
 * One demonstration beat:
 *   1. the caption is typed as a large statement on empty paper
 *   2. the finished line settles into a small section label
 *   3. a baseline extends from the label's left edge across the frame
 *   4. the baseline expands into the product frame and the footage plays
 */
export const Demo: React.FC<Props> = ({ props, scene, index, count }) => {
  const frame = useCurrentFrame();
  const { width, height } = useVideoConfig();
  const { brand, content, cursor, layout, timing } = props;
  const slot = props.media[scene.media];
  const caption = content.captions[scene.captionIndex] ?? "";

  const safe = layout.safeMargin;
  const labelH = Math.round(layout.labelSize * 1.4);
  const gap = 28;
  const top = scene.captionPlacement === "top";
  const labelY = top ? safe : height - safe - labelH;
  const frameTop = top ? safe + labelH + gap : safe;
  const frameBottom = top ? height - safe : height - safe - labelH - gap;
  const boxW = width - safe * 2;
  const boxH = frameBottom - frameTop;
  const fit = slot ? fitMedia(slot, boxW, boxH) : { w: boxW, h: boxH };
  const mediaLeft = safe + (boxW - fit.w) / 2;
  const mediaTop = top ? frameTop : frameBottom - fit.h;
  const ruleY = top ? frameTop : frameBottom;

  const typeDone = typingFrames(caption, cursor.charsPerFrame);
  const settleStart = typeDone + timing.holdAfterType;
  const ruleStart = settleStart + timing.settle;
  const expandStart = ruleStart + timing.rule;

  const chars = typedLength(caption, frame, cursor.charsPerFrame);
  const settle = progress(frame, settleStart, timing.settle);
  const rule = progress(frame, ruleStart, timing.rule, easeOut);
  const expand = progress(frame, expandStart, timing.expand, easeInOut);
  const exit = 1 - progress(frame, scene.durationInFrames - timing.exitFade, timing.exitFade, easeOut);

  const ruleLeft = safe + (mediaLeft - safe) * expand;
  const ruleWidth = boxW * rule - (boxW - fit.w) * expand;
  const ruleOpacity = 1 - progress(frame, expandStart + timing.expand * 0.6, timing.expand * 0.4);

  const clip = top
    ? `inset(0 0 ${(1 - expand) * 100}% 0)`
    : `inset(${(1 - expand) * 100}% 0 0 0)`;

  const stage = String(index + 1).padStart(2, "0");
  const badge = slot?.playbackRate && slot.playbackRate > 1 ? content.speedBadge : null;

  return (
    <AbsoluteFill style={{ backgroundColor: brand.paper, opacity: exit }}>
      <Header
        brand={brand}
        left={content.featureName}
        right={`${scene.label}  ${stage}/${String(count).padStart(2, "0")}`}
        safeMargin={safe}
      />

      {/* Large typed statement */}
      <div
        style={{
          position: "absolute",
          left: safe,
          maxWidth: width - safe * 2 - 200,
          top: height / 2,
          transform: `translateY(calc(-50% - ${settle * 120}px))`,
          opacity: 1 - settle,
          fontFamily: brand.fontFamily,
          fontWeight: 500,
          fontSize: layout.statementSize,
          lineHeight: `${layout.statementSize * 1.15}px`,
          letterSpacing: -layout.statementSize * 0.03,
          color: brand.ink,
        }}
      >
        <TypedText text={caption} visibleChars={chars} brand={brand} />
        {settle < 1 ? (
          <Caret
            brand={brand}
            cursor={cursor}
            fontSize={layout.statementSize * 0.85}
            blinking={frame >= typeDone}
          />
        ) : null}
      </div>

      {/* Settled section label */}
      <div
        style={{
          position: "absolute",
          left: safe,
          right: safe,
          top: labelY + (1 - settle) * 12,
          height: labelH,
          display: "flex",
          alignItems: "center",
          opacity: settle,
          fontFamily: brand.fontFamily,
          fontWeight: 500,
          fontSize: layout.labelSize,
          lineHeight: `${labelH}px`,
          letterSpacing: -layout.labelSize * 0.015,
          color: brand.ink,
          whiteSpace: "nowrap",
          overflow: "hidden",
        }}
      >
        {caption}
      </div>

      {/* Baseline that becomes the product frame */}
      <div
        style={{
          position: "absolute",
          left: ruleLeft,
          top: ruleY - 1,
          width: Math.max(0, ruleWidth),
          height: 2,
          backgroundColor: brand.accent,
          opacity: ruleOpacity,
        }}
      />

      {slot ? (
        <div
          style={{
            position: "absolute",
            left: mediaLeft,
            top: mediaTop,
            width: fit.w,
            height: fit.h,
            clipPath: clip,
            opacity: frame >= expandStart ? 1 : 0,
          }}
        >
          <Sequence from={expandStart} layout="none">
            <Media slot={slot} fit={fit} brand={brand} radius={layout.frameRadius} />
          </Sequence>
          {badge ? (
            <div
              style={{
                position: "absolute",
                top: 16,
                right: 16,
                padding: "4px 10px",
                borderRadius: 8,
                backgroundColor: brand.ink,
                color: brand.white,
                fontFamily: brand.monoFontFamily,
                fontSize: 16,
                lineHeight: "20px",
                opacity: expand,
              }}
            >
              {badge}
            </div>
          ) : null}
        </div>
      ) : null}
    </AbsoluteFill>
  );
};
