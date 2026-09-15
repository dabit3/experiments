import React from "react";
import { AbsoluteFill, Freeze, useCurrentFrame, useVideoConfig } from "remotion";
import type { Brand, Content, LayoutSettings, Lighting, Mask, MediaSlot, ProductScene } from "../schema";
import { Media, mediaAspect } from "../components/Media";
import { Shutter } from "../components/Shutter";
import { RimLight } from "../components/Stage";
import { enter, exit, move } from "../motion";

type Box = { left: number; top: number; width: number; height: number };

const fullBox = (aspect: number, layout: LayoutSettings, frameWidth: number): Box => {
  const width = layout.mediaWidth;
  const height = Math.round(width / aspect);
  return { left: Math.round((frameWidth - width) / 2), top: layout.mediaTop, width, height };
};

const splitBox = (aspect: number, layout: LayoutSettings, frameWidth: number, frameHeight: number): Box => {
  const height = frameHeight - layout.mediaTop * 2;
  const width = Math.round(height * aspect);
  const columnRight = frameWidth / 2;
  const left = Math.round(layout.safeMargin + (columnRight - layout.safeMargin - width) / 2);
  return { left, top: layout.mediaTop, width, height };
};

const Caption: React.FC<{
  brand: Brand;
  lighting: Lighting;
  text: string;
  index?: string;
  size: number;
  progress: number;
  align: "left" | "column";
}> = ({ brand, lighting, text, index, size, progress, align }) => {
  const lineHeight = Math.round(size * 1.28);
  return (
    <div
      style={{
        display: "flex",
        flexDirection: align === "column" ? "column" : "row",
        alignItems: align === "column" ? "flex-start" : "baseline",
        gap: align === "column" ? 20 : 24,
        opacity: progress,
        transform: `translateY(${(1 - progress) * 10}px)`,
        color: brand.white,
      }}
    >
      {lighting.keyLine ? (
        <div
          style={{
            width: align === "column" ? 48 : 1,
            height: align === "column" ? 1 : lineHeight - 8,
            alignSelf: align === "column" ? "flex-start" : "center",
            background: brand.accent,
            flexShrink: 0,
          }}
        />
      ) : null}
      {index ? (
        <div
          style={{
            fontFamily: brand.monoFontFamily,
            fontSize: Math.round(size * 0.5),
            lineHeight: `${lineHeight}px`,
            letterSpacing: 1.2,
            color: brand.inkSubtle,
            flexShrink: 0,
          }}
        >
          {index}
        </div>
      ) : null}
      <div
        style={{
          fontSize: size,
          lineHeight: `${lineHeight}px`,
          letterSpacing: -size * 0.02,
          fontWeight: 400,
        }}
      >
        {text}
      </div>
    </div>
  );
};

/** Large product view: shutter reveal, full hold while the footage plays, caption below or beside. */
export const Product: React.FC<{
  scene: ProductScene;
  slot: MediaSlot;
  brand: Brand;
  content: Content;
  layout: LayoutSettings;
  lighting: Lighting;
  defaultMask: Mask;
}> = ({ scene, slot, brand, content, layout, lighting, defaultMask }) => {
  const frame = useCurrentFrame();
  const { width: frameWidth, height: frameHeight } = useVideoConfig();
  const mask = scene.mask ?? defaultMask;
  const aspect = mediaAspect(slot);
  const box =
    scene.layout === "split"
      ? splitBox(aspect, layout, frameWidth, frameHeight)
      : fullBox(aspect, layout, frameWidth);

  const revealDone = mask.kind === "none" ? 0 : mask.delayInFrames + mask.durationInFrames;
  const reveal = mask.kind === "none" ? 1 : move(frame, mask.delayInFrames, mask.durationInFrames);
  const captionIn = enter(frame, revealDone + 2, 12);
  const out = exit(frame, scene.durationInFrames, 8);
  const freezeAt = scene.durationInFrames - scene.holdOutFrames;

  const media = (
    <div style={{ borderRadius: layout.radius, overflow: "hidden", width: box.width, height: box.height }}>
      <Media slot={slot} width={box.width} height={box.height} />
    </div>
  );

  return (
    <AbsoluteFill style={{ opacity: out }}>
      <RimLight
        lighting={lighting}
        left={box.left}
        top={box.top}
        width={box.width}
        height={box.height}
        radius={layout.radius}
        opacity={reveal}
      />
      <div style={{ position: "absolute", left: box.left, top: box.top }}>
        <Shutter frame={frame} mask={mask} brand={brand} width={box.width} height={box.height}>
          {scene.holdOutFrames > 0 ? (
            <Freeze frame={freezeAt} active={frame >= freezeAt}>
              {media}
            </Freeze>
          ) : (
            media
          )}
        </Shutter>
      </div>
      {scene.speedBadge ? (
        <div
          style={{
            position: "absolute",
            left: box.left + box.width - 16,
            top: box.top + 16,
            transform: "translateX(-100%)",
            fontFamily: brand.monoFontFamily,
            fontSize: 14,
            lineHeight: "20px",
            padding: "4px 10px",
            borderRadius: 8,
            background: brand.blackRaised,
            color: brand.white,
            border: `1px solid ${brand.blackRaisedAlt}`,
            opacity: reveal,
          }}
        >
          {content.speedBadge}
        </div>
      ) : null}
      {scene.layout === "split" ? (
        <div
          style={{
            position: "absolute",
            left: frameWidth / 2 + 40,
            right: layout.safeMargin,
            top: 0,
            bottom: 0,
            display: "flex",
            flexDirection: "column",
            justifyContent: "center",
          }}
        >
          <Caption
            brand={brand}
            lighting={lighting}
            text={scene.caption}
            index={scene.captionIndex}
            size={Math.round(layout.captionSize * 1.4)}
            progress={captionIn}
            align="column"
          />
        </div>
      ) : (
        <div
          style={{
            position: "absolute",
            left: box.left,
            right: box.left,
            top: box.top + box.height + 30,
          }}
        >
          <Caption
            brand={brand}
            lighting={lighting}
            text={scene.caption}
            index={scene.captionIndex}
            size={layout.captionSize}
            progress={captionIn}
            align="left"
          />
        </div>
      )}
    </AbsoluteFill>
  );
};
