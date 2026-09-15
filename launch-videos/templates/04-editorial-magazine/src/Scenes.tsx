import React from "react";
import { AbsoluteFill } from "remotion";
import { Media } from "./Media";
import type { LaunchProps, MediaSlot, Scene } from "./schema";
import {
  Body,
  Button,
  CaptionHeading,
  Enter,
  Eyebrow,
  Folio,
  Headline,
  MarginWord,
  Reveal,
  Rule,
  SpeedBadge,
  type Theme,
} from "./Typo";

export const FRAME_W = 1920;
export const FRAME_H = 1080;
const CONTENT_TOP = 150;
const CONTENT_BOTTOM = 940;

type SceneProps = {
  scene: Scene;
  props: LaunchProps;
  page: number;
  total: number;
};

const themeOf = (props: LaunchProps): Theme => ({
  brand: props.brand,
  tokens: props.layoutTokens,
  type: props.type,
});

const slotOf = (props: LaunchProps, key: string | undefined): MediaSlot => {
  const slot = key ? props.media[key] : undefined;
  if (!slot) {
    throw new Error(`Scene references unknown media slot "${key}"`);
  }
  return slot;
};

const cropAspect = (slot: MediaSlot): number => {
  const c = slot.crop ?? { x: 0, y: 0, w: 1, h: 1 };
  return (slot.aspect * c.w) / c.h;
};

/** Fit a box of the slot's crop aspect inside maxW x maxH. */
const fitBox = (slot: MediaSlot, maxW: number, maxH: number) => {
  const a = cropAspect(slot);
  let w = maxW;
  let h = w / a;
  if (h > maxH) {
    h = maxH;
    w = h * a;
  }
  return { w: Math.round(w), h: Math.round(h) };
};

/** Shrink an oversized word so it fits the column it was given. */
const marginWordSize = (word: string, maxWidth: number, base: number) =>
  Math.min(base, Math.floor(maxWidth / (0.56 * word.length)));

const Page: React.FC<{
  theme: Theme;
  dark: boolean;
  page: number;
  total: number;
  running: string;
  children: React.ReactNode;
}> = ({ theme, dark, page, total, running, children }) => (
  <AbsoluteFill style={{ background: dark ? theme.brand.black : theme.brand.paper }}>
    {children}
    {theme.tokens.showFolio ? (
      <Folio theme={theme} page={page} total={total} left={running} dark={dark} />
    ) : null}
  </AbsoluteFill>
);

const Explanation: React.FC<{
  theme: Theme;
  kicker?: string;
  caption?: string;
  width: number;
  dark: boolean;
  headingSize?: number;
}> = ({ theme, kicker, caption, width, dark, headingSize }) => {
  const { textEnterFrames } = theme.tokens;
  return (
    <div style={{ width, display: "flex", flexDirection: "column", gap: 20 }}>
      {kicker ? (
        <Enter frames={textEnterFrames}>
          <Eyebrow theme={theme} color={dark ? theme.brand.inkSubtle : undefined}>
            {kicker}
          </Eyebrow>
        </Enter>
      ) : null}
      <Enter frames={textEnterFrames} delay={3}>
        <Rule theme={theme} width={48} accent />
      </Enter>
      {caption ? (
        <Enter frames={textEnterFrames} delay={5}>
          <CaptionHeading
            theme={theme}
            size={headingSize}
            color={dark ? theme.brand.white : undefined}
          >
            {caption}
          </CaptionHeading>
        </Enter>
      ) : null}
    </div>
  );
};

/* ------------------------------------------------------------------ cover */

const Cover: React.FC<SceneProps> = ({ scene, props, page, total }) => {
  const theme = themeOf(props);
  const { margin, textEnterFrames, revealFrames } = theme.tokens;
  const slot = slotOf(props, scene.media[0]);
  const { content } = props;

  const mediaW = 880;
  const mediaH = 728;
  const mediaX = scene.bleed ? FRAME_W - mediaW : FRAME_W - margin - mediaW;
  const mediaY = 176;

  return (
    <Page theme={theme} dark={scene.dark} page={page} total={total} running={content.issueLabel}>
      <div
        style={{
          position: "absolute",
          left: margin,
          top: mediaY,
          width: mediaX - margin - 72,
          height: mediaH,
          display: "flex",
          flexDirection: "column",
          justifyContent: "space-between",
        }}
      >
        <Enter frames={textEnterFrames}>
          <Eyebrow theme={theme}>
            {content.eyebrow} · {content.featureName}
          </Eyebrow>
        </Enter>
        <Enter frames={textEnterFrames} delay={4}>
          <Headline
            theme={theme}
            text={content.headline}
            accentWord={content.accentWord}
            size={theme.type.display}
            maxWidth={820}
          />
        </Enter>
        <Enter frames={textEnterFrames} delay={10}>
          <Body theme={theme} maxWidth={560}>
            {content.subhead}
          </Body>
        </Enter>
      </div>
      <Reveal
        frames={revealFrames}
        enabled={scene.reveal === "wipe"}
        style={{ position: "absolute", left: mediaX, top: mediaY }}
      >
        <Media
          slot={slot}
          width={mediaW}
          height={mediaH}
          brand={theme.brand}
          tokens={theme.tokens}
          framed={!scene.bleed}
          style={
            scene.bleed
              ? { border: `1px solid ${theme.brand.line}`, borderRight: "none" }
              : undefined
          }
        />
      </Reveal>
    </Page>
  );
};

/* ----------------------------------------------------------------- spread */

const Spread: React.FC<SceneProps> = ({ scene, props, page, total }) => {
  const theme = themeOf(props);
  const { margin, textEnterFrames, revealFrames } = theme.tokens;
  const slot = slotOf(props, scene.media[0]);
  const caption = scene.captionIndex === undefined ? undefined : props.content.captions[scene.captionIndex];

  const mediaW = Math.round((scene.mediaWidth ?? 0.6) * FRAME_W);
  const mediaH = CONTENT_BOTTOM - CONTENT_TOP;
  const right = scene.mediaSide === "right";
  const mediaX = right
    ? scene.bleed
      ? FRAME_W - mediaW
      : FRAME_W - margin - mediaW
    : scene.bleed
      ? 0
      : margin;

  const colGap = 72;
  const colX = right ? margin : mediaX + mediaW + colGap;
  const colW = right ? mediaX - colGap - margin : FRAME_W - margin - colX;

  const bleedBorder: React.CSSProperties | undefined = scene.bleed
    ? {
        border: `1px solid ${theme.brand.line}`,
        ...(right ? { borderRight: "none" } : { borderLeft: "none" }),
      }
    : undefined;

  const wordSize = scene.marginWord
    ? marginWordSize(scene.marginWord, colW, theme.type.marginWord)
    : 0;

  return (
    <Page theme={theme} dark={scene.dark} page={page} total={total} running={props.content.issueLabel}>
      <Reveal
        frames={revealFrames}
        enabled={scene.reveal === "wipe"}
        style={{ position: "absolute", left: mediaX, top: CONTENT_TOP }}
      >
        <Media
          slot={slot}
          width={mediaW}
          height={mediaH}
          brand={theme.brand}
          tokens={theme.tokens}
          framed={!scene.bleed}
          style={bleedBorder}
        />
        {slot.kind === "video" && (slot.playbackRate ?? 1) > 1 ? (
          <SpeedBadge theme={theme} label={props.content.speedBadge} />
        ) : null}
      </Reveal>
      {scene.marginWord ? (
        <Enter frames={textEnterFrames} delay={2} style={{ position: "absolute", left: colX, top: CONTENT_TOP - 4 }}>
          <MarginWord
            theme={theme}
            word={scene.marginWord}
            color={scene.dark ? theme.brand.white : undefined}
            style={{ position: "relative", fontSize: wordSize, letterSpacing: -0.05 * wordSize }}
          />
        </Enter>
      ) : null}
      <div style={{ position: "absolute", left: colX, bottom: FRAME_H - CONTENT_BOTTOM, width: colW }}>
        <Explanation theme={theme} kicker={scene.kicker} caption={caption} width={Math.min(colW, 560)} dark={scene.dark} />
      </div>
    </Page>
  );
};

/* ------------------------------------------------------------------- full */

const Full: React.FC<SceneProps> = ({ scene, props, page, total }) => {
  const theme = themeOf(props);
  const { margin, textEnterFrames, revealFrames } = theme.tokens;
  const slot = slotOf(props, scene.media[0]);
  const caption = scene.captionIndex === undefined ? undefined : props.content.captions[scene.captionIndex];

  const maxW = Math.round((scene.mediaWidth ?? 0.72) * FRAME_W);
  const maxH = CONTENT_BOTTOM - CONTENT_TOP + 10;
  const { w: mediaW, h: mediaH } = fitBox(slot, maxW, maxH);
  const right = scene.mediaSide === "right";
  const mediaX = right ? FRAME_W - margin - mediaW : margin;
  const mediaY = CONTENT_TOP - 5;

  const colGap = 64;
  const colX = right ? margin : mediaX + mediaW + colGap;
  const colW = right ? mediaX - colGap - margin : FRAME_W - margin - colX;
  const narrow = colW < 420;
  const wordSize = scene.marginWord
    ? marginWordSize(scene.marginWord, colW, theme.type.marginWord)
    : 0;

  return (
    <Page theme={theme} dark={scene.dark} page={page} total={total} running={props.content.issueLabel}>
      <Reveal
        frames={revealFrames}
        enabled={scene.reveal === "wipe"}
        style={{ position: "absolute", left: mediaX, top: mediaY }}
      >
        <Media slot={slot} width={mediaW} height={mediaH} brand={theme.brand} tokens={theme.tokens} />
        {slot.kind === "video" && (slot.playbackRate ?? 1) > 1 ? (
          <SpeedBadge theme={theme} label={props.content.speedBadge} />
        ) : null}
      </Reveal>
      {scene.marginWord && !narrow ? (
        <Enter frames={textEnterFrames} delay={2} style={{ position: "absolute", left: colX, top: CONTENT_TOP - 4 }}>
          <MarginWord
            theme={theme}
            word={scene.marginWord}
            color={scene.dark ? theme.brand.white : undefined}
            style={{ position: "relative", fontSize: wordSize, letterSpacing: -0.05 * wordSize }}
          />
        </Enter>
      ) : null}
      <div style={{ position: "absolute", left: colX, bottom: FRAME_H - CONTENT_BOTTOM, width: colW }}>
        <Explanation
          theme={theme}
          kicker={scene.kicker}
          caption={caption}
          width={Math.min(colW, 560)}
          dark={scene.dark}
          headingSize={narrow ? Math.round(theme.type.heading * 0.75) : undefined}
        />
      </div>
    </Page>
  );
};

/* ------------------------------------------------------------------ dense */

const Dense: React.FC<SceneProps> = ({ scene, props, page, total }) => {
  const theme = themeOf(props);
  const { margin, revealFrames, gutter } = theme.tokens;
  const a = slotOf(props, scene.media[0]);
  const b = slotOf(props, scene.media[1] ?? scene.media[0]);
  const caption = scene.captionIndex === undefined ? undefined : props.content.captions[scene.captionIndex];

  const textW = 520;
  const leftW = 774;
  const rightX = margin + leftW + gutter * 2;
  const rightW = FRAME_W - margin - rightX;

  const boxB = fitBox(b, rightW, CONTENT_BOTTOM - CONTENT_TOP);
  const textBottom = CONTENT_TOP + 190;
  const boxA = fitBox(a, leftW, CONTENT_BOTTOM - textBottom);

  return (
    <Page theme={theme} dark={scene.dark} page={page} total={total} running={props.content.issueLabel}>
      <div style={{ position: "absolute", left: margin, top: CONTENT_TOP }}>
        <Explanation theme={theme} kicker={scene.kicker} caption={caption} width={textW} dark={scene.dark} headingSize={Math.round(theme.type.heading * 0.85)} />
      </div>
      <Reveal
        frames={revealFrames}
        enabled={scene.reveal === "wipe"}
        style={{ position: "absolute", left: margin, top: CONTENT_BOTTOM - boxA.h }}
      >
        <Media slot={a} width={boxA.w} height={boxA.h} brand={theme.brand} tokens={theme.tokens} />
      </Reveal>
      <Reveal
        frames={revealFrames + 6}
        enabled={scene.reveal === "wipe"}
        style={{ position: "absolute", left: FRAME_W - margin - boxB.w, top: CONTENT_TOP }}
      >
        <Media slot={b} width={boxB.w} height={boxB.h} brand={theme.brand} tokens={theme.tokens} />
      </Reveal>
    </Page>
  );
};

/* ---------------------------------------------------------------- closing */

const Closing: React.FC<SceneProps> = ({ scene, props, page, total }) => {
  const theme = themeOf(props);
  const { margin, textEnterFrames, revealFrames } = theme.tokens;
  const slot = slotOf(props, scene.media[0]);
  const { content } = props;
  const dark = scene.dark;

  const box = fitBox(slot, 640, 360);
  const rightX = 1000;
  const rightW = FRAME_W - margin - rightX;

  return (
    <Page theme={theme} dark={dark} page={page} total={total} running={content.issueLabel}>
      <div style={{ position: "absolute", left: margin, top: CONTENT_TOP + 26 }}>
        <Reveal frames={revealFrames} enabled={scene.reveal === "wipe"}>
          <Media
            slot={slot}
            width={box.w}
            height={box.h}
            brand={theme.brand}
            tokens={theme.tokens}
            style={dark ? { border: `1px solid ${theme.brand.blackRaised}`, boxShadow: "none" } : undefined}
          />
        </Reveal>
        <Enter frames={textEnterFrames} delay={4} style={{ marginTop: 28, display: "flex", flexDirection: "column", gap: 14 }}>
          {scene.kicker ? (
            <Eyebrow theme={theme} color={dark ? theme.brand.inkSubtle : undefined}>
              {scene.kicker}
            </Eyebrow>
          ) : null}
          <Rule theme={theme} width={48} accent />
        </Enter>
      </div>
      <div
        style={{
          position: "absolute",
          left: rightX,
          top: CONTENT_TOP + 26,
          width: rightW,
          height: CONTENT_BOTTOM - CONTENT_TOP - 26,
          display: "flex",
          flexDirection: "column",
          justifyContent: "space-between",
        }}
      >
        <Enter frames={textEnterFrames} delay={6}>
          <Headline theme={theme} text={content.outroLine} size={72} color={dark ? theme.brand.white : theme.brand.ink} />
        </Enter>
        <Enter frames={textEnterFrames} delay={14} style={{ display: "flex", flexDirection: "column", gap: 18 }}>
          <div>
            <Button theme={theme} label={content.cta.label} dark={dark} />
          </div>
          <div
            style={{
              fontFamily: theme.brand.monoFontFamily,
              fontSize: theme.type.small,
              color: dark ? theme.brand.inkSubtle : theme.brand.inkMuted,
              letterSpacing: "0.02em",
            }}
          >
            {content.cta.url}
          </div>
        </Enter>
      </div>
    </Page>
  );
};

export const SceneView: React.FC<SceneProps> = (p) => {
  switch (p.scene.layout) {
    case "cover":
      return <Cover {...p} />;
    case "spread":
      return <Spread {...p} />;
    case "full":
      return <Full {...p} />;
    case "dense":
      return <Dense {...p} />;
    case "closing":
      return <Closing {...p} />;
    default: {
      const never: never = p.scene.layout;
      throw new Error(`Unknown layout ${String(never)}`);
    }
  }
};
