import React from "react";
import { AbsoluteFill, Sequence, useCurrentFrame } from "remotion";
import type {
  BeatScene,
  Brand,
  Content,
  MediaSlot,
  Timing,
  Typography,
} from "../schema";
import { beatGeometry, mediaAspect } from "../layout";
import { enter, leave, mix, move } from "../motion";
import { Phrase } from "../components/Phrase";
import { Demo, Frame } from "../components/Demo";
import { Label } from "../components/Label";

/**
 * One demonstration beat.
 *
 *  1. A hairline frame with the exact geometry of the upcoming footage fades in
 *     and the caption phrase stands inside it, large.
 *  2. The phrase travels to the margin and shrinks into a caption (one object,
 *     translate + scale, no reflow) while the footage rises into the frame.
 *  3. Typography goes quiet; the product holds. Several media slots dissolve
 *     in sequence, each held >= 2.5s.
 *  4. Everything lifts out; the next beat's phrase rises in from below.
 */
export const Beat: React.FC<{
  scene: BeatScene;
  brand: Brand;
  content: Content;
  media: Record<string, MediaSlot>;
  timing: Timing;
  typography: Typography;
}> = ({ scene, brand, content, media, timing, typography }) => {
  const frame = useCurrentFrame();
  const text = content.captions[scene.captionIndex] ?? "";
  const slots = scene.media
    .map((name) => media[name])
    .filter((m): m is MediaSlot => m !== undefined);
  const first = slots[0];
  if (!first) {
    return null;
  }

  const geo = beatGeometry(scene.layout, mediaAspect(first), text, typography);
  const { fit } = geo;

  const enterDur = 16;
  const morphStart = enterDur + timing.phraseHoldFrames;
  const mediaStart = morphStart + Math.round(timing.morphFrames * 0.6);
  const exitStart = scene.durationInFrames - timing.exitFrames;

  const phraseIn = enter(frame, 0, enterDur);
  const morph = move(frame, morphStart, timing.morphFrames);
  const frameIn = enter(frame, 0, enterDur + 6);
  const out = leave(frame, exitStart, timing.exitFrames);
  const lift = mix(0, -24, 1 - out);

  // Hairline frame fades once the footage has fully arrived (footage has its own border).
  const frameOpacity =
    frameIn * (1 - enter(frame, mediaStart + timing.mediaInFrames - 4, 8));

  const mediaVisibleFrames = exitStart - mediaStart;
  const perMedia = mediaVisibleFrames / slots.length;

  return (
    <AbsoluteFill style={{ backgroundColor: brand.paper }}>
      <AbsoluteFill style={{ opacity: out, transform: `translateY(${lift}px)` }}>
        <Frame rect={geo.media} brand={brand} radius={typography.frameRadius} opacity={frameOpacity} />

        {slots.map((slot, i) => {
          const start = mediaStart + Math.round(i * perMedia);
          const fadeIn =
            i === 0
              ? enter(frame, start, timing.mediaInFrames)
              : enter(frame, start, timing.dissolveFrames);
          const rise = i === 0 ? mix(20, 0, fadeIn) : 0;
          return (
            <Sequence key={slot.src + i} from={start} layout="none">
              <Demo
                media={slot}
                rect={geo.media}
                brand={brand}
                radius={typography.frameRadius}
                opacity={fadeIn}
                offsetY={rise}
                speedBadge={content.speedBadge}
                monoFontFamily={brand.monoFontFamily}
              />
            </Sequence>
          );
        })}

        {scene.index ? (
          <Label
            text={scene.index}
            x={geo.index.x}
            y={geo.index.y}
            color={brand.accent}
            fontFamily={brand.monoFontFamily}
            opacity={morph}
          />
        ) : null}

        <Phrase
          text={text}
          width={fit.width}
          fontSize={fit.captionSize}
          fontFamily={brand.fontFamily}
          color={brand.ink}
          from={{ x: geo.phrase.x, y: geo.phrase.y, scale: fit.scale }}
          to={{ x: geo.caption.x, y: geo.caption.y, scale: 1 }}
          progress={morph}
          opacity={phraseIn}
          offsetY={mix(28, 0, phraseIn)}
        />
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
