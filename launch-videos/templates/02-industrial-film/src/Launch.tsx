import React from "react";
import { AbsoluteFill, Easing, Sequence, interpolate, staticFile, useCurrentFrame } from "remotion";
import type { LaunchProps, Scene } from "./schema";
import { FRAME_HEIGHT, FRAME_WIDTH } from "./defaults";
import { nbInternationalFontFace } from "./fonts";
import { Studio } from "./components/Studio";
import { Plane, lerpView, planeRect, type PlaneMotion } from "./components/Plane";
import { CaptionBlock, CtaBlock, Logo, SAFE, SpeedBadge, TitleBlock } from "./components/Text";

const easeOut = Easing.bezier(0.33, 1, 0.68, 1);
const easeIn = Easing.bezier(0.32, 0, 0.67, 0);
const easeInOut = Easing.bezier(0.65, 0, 0.35, 1);

const cameraEasing = {
  linear: Easing.linear,
  out: easeOut,
  inOut: easeInOut,
};

const FilmScene: React.FC<{
  props: LaunchProps;
  scene: Scene;
  total: number;
}> = ({ props, scene, total }) => {
  const frame = useCurrentFrame();
  const { brand, content, lighting, transitionFrames, tiltDegrees } = props;

  const lead = scene.transitionIn === "none" ? 0 : transitionFrames;
  const enter =
    lead > 0
      ? interpolate(frame, [0, lead], [0, 1], {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
          easing: easeOut,
        })
      : 1;
  const exit =
    scene.transitionOut === "none"
      ? 0
      : interpolate(frame, [total - transitionFrames, total], [0, 1], {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
          easing: easeIn,
        });

  const tiltIn = scene.transitionIn === "tilt" ? tiltDegrees : 0;
  const tiltOut = scene.transitionOut === "tilt" ? tiltDegrees : 0;
  const motion: PlaneMotion = {
    opacity: enter * (1 - exit),
    rotateY: tiltIn * (1 - enter) - tiltOut * exit,
    translateX: 48 * (1 - enter) * (tiltIn ? 1 : 0) - 32 * exit * (tiltOut ? 1 : 0),
  };

  const slot = scene.media ? props.media[scene.media] : undefined;
  const cameraEnd = Math.max(1, total - (scene.camera?.settleFrames ?? 0));
  const cameraT = interpolate(frame, [0, cameraEnd], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: scene.camera ? cameraEasing[scene.camera.easing] : Easing.linear,
  });
  const view = scene.camera ? lerpView(scene.camera.from, scene.camera.to, cameraT) : null;

  const textStart = lead + scene.titleDelay;
  const textIn = interpolate(frame, [textStart, textStart + 18], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeOut,
  });
  const textOpacity = textIn * (1 - exit);
  const textRise = (1 - textIn) * 14;

  const captionText = scene.caption === null ? null : content.captions[scene.caption] ?? null;
  const stageText = scene.stage === null ? null : content.stages[scene.stage] ?? null;
  const stageLabel =
    stageText === null
      ? null
      : `${String((scene.stage ?? 0) + 1).padStart(2, "0")} — ${stageText}`;

  const columnWidth = scene.captionWidth * FRAME_WIDTH;
  const rect = slot && view ? planeRect(slot, view) : null;

  const columnStyle: React.CSSProperties = (() => {
    switch (scene.captionPlacement) {
      case "right":
        return { left: FRAME_WIDTH - SAFE - columnWidth, top: 0, height: FRAME_HEIGHT, justifyContent: "center" };
      case "below":
        return {
          left: rect ? rect.left : SAFE,
          top: rect ? rect.top + rect.height + 40 : FRAME_HEIGHT / 2,
          justifyContent: "flex-start",
        };
      case "above":
        return {
          left: rect ? rect.left : SAFE,
          top: 0,
          height: rect ? rect.top - 40 : FRAME_HEIGHT / 2,
          justifyContent: "flex-end",
        };
      case "left":
      default:
        return { left: SAFE, top: 0, height: FRAME_HEIGHT, justifyContent: "center" };
    }
  })();

  const body = (() => {
    if (scene.kind === "cta") {
      return <CtaBlock brand={brand} content={content} />;
    }
    if (scene.showTitle) {
      return <TitleBlock brand={brand} content={content} />;
    }
    if (captionText) {
      return <CaptionBlock brand={brand} eyebrow={stageLabel} text={captionText} />;
    }
    return null;
  })();

  const sped = slot?.kind === "video" && (slot.playbackRate ?? 1) > 1;

  return (
    <AbsoluteFill>
      {slot && view ? (
        <Plane slot={slot} view={view} motion={motion} brand={brand} lighting={lighting} />
      ) : null}
      {sped && rect ? (
        <SpeedBadge
          brand={brand}
          label={content.speedBadge}
          left={rect.left + rect.width - 56}
          top={rect.top + 16}
        />
      ) : null}
      {scene.showLogo ? <Logo brand={brand} opacity={textOpacity} /> : null}
      {body ? (
        <div
          style={{
            position: "absolute",
            display: "flex",
            flexDirection: "column",
            width: columnWidth,
            opacity: textOpacity,
            transform: `translateY(${textRise}px)`,
            ...columnStyle,
          }}
        >
          {body}
        </div>
      ) : null}
    </AbsoluteFill>
  );
};

export const Launch: React.FC<LaunchProps> = (props) => {
  const { brand, lighting, scenes } = props;

  let cursor = 0;
  const placed = scenes.map((scene) => {
    const start = cursor;
    cursor += scene.durationInFrames;
    return { scene, start };
  });

  return (
    <AbsoluteFill style={{ fontFamily: brand.fontFamily, color: brand.ink }}>
      {brand.useLicensedFont ? <style>{nbInternationalFontFace(staticFile)}</style> : null}
      <Studio brand={brand} lighting={lighting} />
      {placed.map(({ scene, start }) => {
        const total = scene.durationInFrames;
        return (
          <Sequence key={scene.id} from={start} durationInFrames={total} layout="none">
            <FilmScene props={props} scene={scene} total={total} />
          </Sequence>
        );
      })}
    </AbsoluteFill>
  );
};
