import React from 'react';
import {useCurrentFrame} from 'remotion';
import type {DemoScene, LaunchProps, OutroScene, ResultScene} from '../schema';
import type {Rect, SceneGeometry} from '../geometry';
import {findSlot} from '../geometry';
import {easeInOut, easeOut, enterStyle} from '../motion';
import {AccentText, Eyebrow} from './Label';
import {Media} from './Media';

type OverlayProps = {
  props: LaunchProps;
  geo: SceneGeometry;
  /** Frames the product frame takes to settle at the start of this scene (0 for the first scene). */
  lead: number;
  durationInFrames: number;
};

/** Visibility envelope: enter after the frame settles, leave before the next boundary. */
const useEnvelope = (lead: number, durationInFrames: number, entrance: number, half: number) => {
  const frame = useCurrentFrame();
  const settled = frame - lead;
  const enter = easeOut(settled, 0, entrance);
  const exitStart = durationInFrames - half - entrance;
  const exit = easeInOut(frame, exitStart, entrance);
  return {settled, enter, visible: enter * (1 - exit), exit};
};

const rectStyle = (r: Rect): React.CSSProperties => ({
  position: 'absolute',
  left: r.x,
  top: r.y,
  width: r.w,
  height: r.h,
});

export const OpenOverlay: React.FC<OverlayProps> = ({props, geo, durationInFrames}) => {
  const {brand, content, motion} = props;
  const half = motion.transitionFrames / 2;
  const env = useEnvelope(10, durationInFrames, motion.entranceFrames, half);
  const dir = -motion.slideDistance;
  const text = geo.text as Rect;
  const eyebrowT = easeOut(env.settled, 0, motion.entranceFrames);
  const headT = easeOut(env.settled, motion.stagger, motion.entranceFrames);
  const subT = easeOut(env.settled, motion.stagger * 2, motion.entranceFrames);
  return (
    <div
      style={{
        ...rectStyle(text),
        display: 'flex',
        flexDirection: 'column',
        justifyContent: 'center',
        gap: 28,
        opacity: 1 - env.exit,
        transform: `translateX(${-env.exit * motion.slideDistance}px)`,
      }}
    >
      <Eyebrow brand={brand} color={brand.accent} style={enterStyle(eyebrowT, dir, 'x')}>
        {content.eyebrow}
      </Eyebrow>
      <div
        style={{
          fontFamily: brand.fontFamily,
          fontSize: 80,
          lineHeight: '86px',
          letterSpacing: -2.4,
          fontWeight: 500,
          color: brand.ink,
          ...enterStyle(headT, dir, 'x'),
        }}
      >
        <AccentText text={content.headline} accent={content.headlineAccent} accentColor={brand.accent} />
      </div>
      <div
        style={{
          fontFamily: brand.fontFamily,
          fontSize: 28,
          lineHeight: '40px',
          letterSpacing: -0.3,
          color: brand.inkMuted,
          maxWidth: 700,
          ...enterStyle(subT, dir, 'x'),
        }}
      >
        {content.subhead}
      </div>
    </div>
  );
};

export const DemoOverlay: React.FC<OverlayProps & {scene: DemoScene}> = ({
  props,
  geo,
  lead,
  durationInFrames,
  scene,
}) => {
  const {brand, content, motion, shapes, layout} = props;
  const half = motion.transitionFrames / 2;
  const env = useEnvelope(lead, durationInFrames, motion.entranceFrames, half);
  const caption = content.captions[scene.caption] ?? '';
  const stageLabel = content.stages[scene.stage] ?? '';
  const planeOnLeft = scene.composition !== 'media-left';
  const dir = planeOnLeft ? -motion.slideDistance : motion.slideDistance;
  const slide = (1 - env.enter) * dir + env.exit * dir;
  const captionT = easeOut(env.settled, motion.stagger, motion.entranceFrames);

  if (geo.plane === null && geo.text) {
    // media-wide: single caption line under the frame.
    return (
      <div
        style={{
          ...rectStyle(geo.text),
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          opacity: env.visible,
          transform: `translateY(${(1 - env.enter) * 16}px)`,
        }}
      >
        <CaptionLine brand={brand} caption={caption} label={scene.label ?? ''} />
      </div>
    );
  }
  if (geo.plane === null) {
    return null;
  }

  return (
    <>
      <div
        style={{
          ...rectStyle(geo.plane),
          background: shapes.plane.fill,
          borderRadius: layout.radius,
          padding: shapes.plane.padding,
          boxSizing: 'border-box',
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'space-between',
          opacity: env.visible,
          transform: `translateX(${slide}px)`,
        }}
      >
        <div style={{display: 'flex', flexDirection: 'column', gap: 10}}>
          <Eyebrow brand={brand} color={shapes.plane.textMuted}>
            {String(scene.stage + 1).padStart(2, '0')} · {stageLabel}
          </Eyebrow>
          <div
            style={{
              fontFamily: brand.fontFamily,
              fontSize: 20,
              lineHeight: '28px',
              letterSpacing: -0.2,
              color: shapes.plane.textMuted,
            }}
          >
            {scene.label}
          </div>
        </div>
        <div
          style={{
            fontFamily: brand.fontFamily,
            fontSize: shapes.plane.captionSize,
            lineHeight: `${Math.round(shapes.plane.captionSize * 1.3)}px`,
            letterSpacing: -0.6,
            fontWeight: 500,
            color: shapes.plane.text,
            ...enterStyle(captionT, 18, 'y'),
          }}
        >
          {caption}
        </div>
      </div>
      {geo.frames.slice(1).map((r, i) => {
        const name = scene.media[i + 1];
        const slot = findSlot(props.media, name);
        if (!slot) {
          return null;
        }
        const t = easeOut(env.settled, motion.stagger * (i + 1), motion.entranceFrames);
        return (
          <div
            key={name}
            style={{
              ...rectStyle(r),
              overflow: 'hidden',
              borderRadius: layout.radius,
              background: brand.paper,
              boxShadow: `0 0 0 ${shapes.frame.borderWidth}px ${shapes.frame.border}`,
              opacity: t * (1 - env.exit),
              transform: `translateX(${(1 - t) * motion.slideDistance + env.exit * motion.slideDistance}px)`,
            }}
          >
            <Media slot={slot} rest={r} />
          </div>
        );
      })}
    </>
  );
};

const CaptionLine: React.FC<{
  brand: LaunchProps['brand'];
  caption: string;
  label: string;
}> = ({brand, caption, label}) => (
  <>
    <div
      style={{
        fontFamily: brand.fontFamily,
        fontSize: 26,
        lineHeight: '34px',
        letterSpacing: -0.4,
        fontWeight: 500,
        color: brand.ink,
      }}
    >
      {caption}
    </div>
    <Eyebrow brand={brand} color={brand.accent}>
      {label}
    </Eyebrow>
  </>
);

export const ResultOverlay: React.FC<OverlayProps & {scene: ResultScene}> = ({
  props,
  geo,
  lead,
  durationInFrames,
  scene,
}) => {
  const {brand, content, motion} = props;
  const half = motion.transitionFrames / 2;
  const env = useEnvelope(lead + 6, durationInFrames, motion.entranceFrames, half);
  const text = geo.text as Rect;
  return (
    <div
      style={{
        ...rectStyle(text),
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        opacity: env.visible,
        transform: `translateY(${(1 - env.enter) * 16}px)`,
      }}
    >
      <CaptionLine brand={brand} caption={content.captions[scene.caption] ?? ''} label={scene.label ?? ''} />
    </div>
  );
};

export const OutroOverlay: React.FC<OverlayProps & {scene: OutroScene}> = ({
  props,
  geo,
  lead,
  durationInFrames,
}) => {
  const {brand, content, motion} = props;
  const frame = useCurrentFrame();
  const settled = frame - lead;
  const text = geo.text as Rect;
  const dir = motion.slideDistance;
  const t0 = easeOut(settled, 0, motion.entranceFrames);
  const t1 = easeOut(settled, motion.stagger, motion.entranceFrames);
  const t2 = easeOut(settled, motion.stagger * 2, motion.entranceFrames);
  const fade = 1 - easeInOut(frame, durationInFrames - 14, 14);
  return (
    <div
      style={{
        ...rectStyle(text),
        display: 'flex',
        flexDirection: 'column',
        justifyContent: 'space-between',
        padding: '8px 0',
        boxSizing: 'border-box',
        opacity: fade,
      }}
    >
      <div style={{display: 'flex', flexDirection: 'column', gap: 24}}>
        <Eyebrow brand={brand} color={brand.accent} style={enterStyle(t0, dir, 'x')}>
          {content.featureName}
        </Eyebrow>
        <div
          style={{
            fontFamily: brand.fontFamily,
            fontSize: 64,
            lineHeight: '72px',
            letterSpacing: -1.8,
            fontWeight: 500,
            color: brand.ink,
            ...enterStyle(t1, dir, 'x'),
          }}
        >
          {content.outroLine}
        </div>
      </div>
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          gap: 28,
          ...enterStyle(t2, dir, 'x'),
        }}
      >
        <div
          style={{
            height: 56,
            padding: '0 28px',
            display: 'flex',
            alignItems: 'center',
            borderRadius: 2,
            background: brand.ink,
            color: brand.white,
            fontFamily: brand.fontFamily,
            fontSize: 22,
            fontWeight: 500,
            letterSpacing: -0.3,
          }}
        >
          {content.cta.label}
        </div>
        <div
          style={{
            fontFamily: brand.monoFontFamily,
            fontSize: 20,
            color: brand.inkMuted,
          }}
        >
          {content.cta.url}
        </div>
      </div>
    </div>
  );
};
