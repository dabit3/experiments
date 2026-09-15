import React from "react";
import { AbsoluteFill, Img, Sequence, staticFile, useCurrentFrame, useVideoConfig } from "remotion";
import { ensureFonts } from "./fonts";
import { resolveLens, stageRectFor } from "./geometry";
import { CaptionBlock, MarginChrome, TitleBlock, textStyles } from "./Margin";
import { easeOut, linear, presence } from "./motion";
import type { Inspection, LaunchProps, MediaSlot, Scene } from "./schema";
import { Stage } from "./Stage";

ensureFonts();

const sceneStarts = (scenes: Scene[]) => {
  let acc = 0;
  return scenes.map((s) => {
    const start = acc;
    acc += s.durationInFrames;
    return start;
  });
};

export const totalDuration = (scenes: Scene[]) =>
  scenes.reduce((sum, s) => sum + s.durationInFrames, 0);

const LicensedFontFace: React.FC = () => (
  <style>{`
    @font-face { font-family: "NB International Pro"; font-weight: 400; font-display: swap;
      src: url("${staticFile("fonts/NBInternationalPro-Regular.woff2")}") format("woff2"); }
    @font-face { font-family: "NB International Pro"; font-weight: 500; font-display: swap;
      src: url("${staticFile("fonts/NBInternationalPro-Medium.woff2")}") format("woff2"); }
  `}</style>
);

const Outro: React.FC<{ props: LaunchProps; frame: number }> = ({ props, frame }) => {
  const { brand, content } = props;
  const a = easeOut(frame, 0, 15);
  const b = easeOut(frame, 8, 15);
  const c = easeOut(frame, 16, 15);
  return (
    <AbsoluteFill
      style={{
        background: brand.paper,
        alignItems: "center",
        justifyContent: "center",
        flexDirection: "column",
        gap: 40,
      }}
    >
      <Img
        src={staticFile(brand.logoLight)}
        style={{ height: 48, opacity: a, transform: `translateY(${(1 - a) * 12}px)` }}
      />
      <div
        style={{
          ...textStyles.headline(brand),
          textAlign: "center",
          maxWidth: 1100,
          opacity: b,
          transform: `translateY(${(1 - b) * 12}px)`,
        }}
      >
        {content.outroLine}
      </div>
      <div
        style={{
          display: "flex",
          alignItems: "center",
          gap: 20,
          opacity: c,
          transform: `translateY(${(1 - c) * 12}px)`,
        }}
      >
        <div
          style={{
            background: brand.ink,
            color: brand.white,
            fontFamily: brand.fontFamily,
            fontSize: 20,
            lineHeight: "42px",
            height: 42,
            padding: "0 16px",
            borderRadius: 2,
            fontWeight: 500,
          }}
        >
          {content.cta.label}
        </div>
        <div style={{ ...textStyles.mono(brand), fontSize: 18, color: brand.inkMuted }}>
          {content.cta.url}
        </div>
      </div>
    </AbsoluteFill>
  );
};

const OutroAt: React.FC<{ props: LaunchProps }> = ({ props }) => {
  const frame = useCurrentFrame();
  return <Outro props={props} frame={frame} />;
};

const resolveMagnification = (
  inspection: Inspection,
  slot: MediaSlot,
  w: number,
  h: number,
) => resolveLens(inspection, slot, { x: 0, y: 0, w, h }).magnification;

export const Launch: React.FC<LaunchProps> = (props) => {
  const { brand, content, media, scenes, layout } = props;
  const frame = useCurrentFrame();
  const { width, height } = useVideoConfig();

  const starts = sceneStarts(scenes);
  const column = {
    x: layout.safeMargin,
    y: layout.safeMargin + 80,
    w: layout.marginWidth,
    h: height - 2 * (layout.safeMargin + 80),
  };
  const stageX = layout.safeMargin + layout.marginWidth + layout.gap;
  const stageW = width - stageX - layout.safeMargin;
  const inspectScenes = scenes.filter((s) => s.kind === "inspect");
  const xf = layout.crossfadeFrames;

  const lastFootage = scenes.reduce(
    (idx, s, i) => (s.kind === "outro" ? idx : i),
    0,
  );
  const chromeEnd = starts[lastFootage] + scenes[lastFootage].durationInFrames;
  const chromeOpacity = presence(frame, 0, chromeEnd, 12, xf);

  return (
    <AbsoluteFill style={{ background: brand.paper }}>
      <LicensedFontFace />

      {scenes.map((scene, i) => {
        const start = starts[i];
        if (scene.kind === "outro") {
          return (
            <Sequence key={scene.id} from={start} durationInFrames={scene.durationInFrames}>
              <OutroAt props={props} />
            </Sequence>
          );
        }

        const slot = scene.media ? media[scene.media] : undefined;
        if (!slot) {
          return null;
        }
        const stage = stageRectFor(slot, stageX, stageW, height);
        // Each footage scene stays mounted `xf` frames into the next one so the next
        // media can dissolve in on top of it.
        const isLast = i === lastFootage;
        const dur = scene.durationInFrames + (isLast ? 0 : xf);
        const local = frame - start;
        const fadeIn = i === 0 ? easeOut(local, 0, 12) : linear(local, 0, xf);
        const fadeOut = isLast ? 1 - linear(local, scene.durationInFrames - xf, xf) : 1;
        const opacity = Math.min(fadeIn, fadeOut);
        const rise = (1 - easeOut(local, 0, 15)) * 10;

        const captionVisible = presence(local, 6, scene.durationInFrames, 12, xf);
        const inspection = scene.inspection;
        const labelVisible = inspection
          ? presence(local, inspection.openAt + 4, inspection.closeAt ?? scene.durationInFrames - 10, 12, 10)
          : 0;

        return (
          <Sequence key={scene.id} from={start} durationInFrames={dur} layout="none">
            <div style={{ position: "absolute", inset: 0, opacity }}>
              <Stage
                slot={slot}
                stage={stage}
                inspection={inspection}
                frame={local}
                sceneDuration={scene.durationInFrames}
                brand={brand}
                layout={layout}
              />
            </div>
            {scene.kind === "title" ? (
              <TitleBlock
                content={content}
                brand={brand}
                column={column}
                opacity={captionVisible}
                rise={rise}
              />
            ) : (
              <CaptionBlock
                index={inspectScenes.indexOf(scene)}
                total={inspectScenes.length}
                caption={content.captions[scene.captionIndex ?? 0] ?? ""}
                label={inspection?.label}
                magnification={
                  inspection ? resolveMagnification(inspection, slot, stage.w, stage.h) : undefined
                }
                brand={brand}
                layout={layout}
                column={column}
                captionOpacity={captionVisible}
                labelOpacity={labelVisible}
                rise={rise}
              />
            )}
          </Sequence>
        );
      })}

      <MarginChrome
        brand={brand}
        content={content}
        column={column}
        logoSrc={staticFile(brand.logoLight)}
        safeMargin={layout.safeMargin}
        opacity={chromeOpacity}
      />
    </AbsoluteFill>
  );
};

