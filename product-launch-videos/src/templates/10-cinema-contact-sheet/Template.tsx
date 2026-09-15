import type {CSSProperties} from 'react';
import {AbsoluteFill, Freeze, Sequence, useCurrentFrame, useVideoConfig} from 'remotion';
import {SourceImage, SourceVideo, easeInOut, mix, progress} from '../../shared';
import type {CinemaConfig} from './config';
import {createEdit, frozenFrame, type Shot} from './timing';

type Rect = {x: number; y: number; width: number; height: number};

const blendRect = (a: Rect, b: Rect, amount: number): Rect => ({
  x: mix(a.x, b.x, amount), y: mix(a.y, b.y, amount),
  width: mix(a.width, b.width, amount), height: mix(a.height, b.height, amount),
});

const positions = (config: CinemaConfig, width: number, height: number) => {
  const {margin, gutter, captionHeight, grid} = config.layout;
  const tileWidth = (width - margin * 2 - gutter * 2) / 3;
  return {
    hero: {x: margin, y: grid.heroTop, width: width - margin * 2,
      height: height - captionHeight - grid.heroTop - 26},
    ending: {x: margin + 190, y: grid.closingHeroTop, width: width - margin * 2 - 380,
      height: grid.closingHeroHeight},
    tile: (index: number): Rect => ({
      x: margin + (index % 3) * (tileWidth + gutter),
      y: grid.top + Math.floor(index / 3) * (grid.tileHeight + grid.rowGap),
      width: tileWidth, height: grid.tileHeight,
    }),
  };
};

const Media = ({shot, width, height, config, frame, live = false}: {
  shot: Shot; width: number; height: number; config: CinemaConfig; frame: number; live?: boolean;
}) => {
  if (shot.kind === 'still') return <SourceImage {...shot.media} width={width} height={height} />;
  const video = <SourceVideo
    {...shot.media} width={width} height={height} durationInFrames={shot.durationInFrames}
    labelHeight={42}
    labelStyle={{
      backgroundColor: config.brand.colors.ink, color: config.brand.colors.white,
      fontFamily: config.brand.typography.fontFamily,
      fontSize: width < 700 ? 19 : 27,
    }}
  />;
  return live
    ? <Sequence from={shot.from} durationInFrames={shot.durationInFrames} layout="none">{video}</Sequence>
    : <Freeze frame={frozenFrame(shot, frame >= shot.from + shot.durationInFrames)}>{video}</Freeze>;
};

const Plate = ({shot, rect, config, frame, live = false, selected = false}: {
  shot: Shot; rect: Rect; config: CinemaConfig; frame: number; live?: boolean; selected?: boolean;
}) => {
  const padding = config.layout.padding;
  return <div style={{
    position: 'absolute', left: rect.x, top: rect.y,
    width: rect.width, height: rect.height,
    padding, boxSizing: 'border-box', backgroundColor: config.brand.colors.ink,
    outline: selected ? `${config.motion.selectionStroke}px solid ${config.brand.colors.ink}` : undefined,
    outlineOffset: 7,
  }}>
    <div style={{backgroundColor: config.brand.colors.mediaMat}}>
      <Media shot={shot} width={rect.width - padding * 2} height={rect.height - padding * 2}
        config={config} frame={frame} live={live} />
    </div>
  </div>;
};

const Index = ({shots, config, frame, active, hidden, opacity = 1}: {
  shots: Shot[]; config: CinemaConfig; frame: number; active: number; hidden?: number; opacity?: number;
}) => {
  const {width, height} = useVideoConfig();
  const geometry = positions(config, width, height);
  return <AbsoluteFill style={{opacity}}>
    {shots.map((shot) => {
      const rect = geometry.tile(shot.index);
      return <div key={shot.index}>
        {hidden !== shot.index ? <Plate shot={shot} rect={rect} config={config} frame={frame}
          selected={active === shot.index} /> : null}
        <div style={{
          position: 'absolute', left: rect.x, top: rect.y + rect.height + 13,
          width: rect.width, display: 'flex', alignItems: 'baseline', gap: 14,
          color: config.brand.colors.ink,
        }}>
          <span style={{fontFamily: config.brand.typography.monoFamily, fontSize: 22}}>
            {String(shot.index + 1).padStart(2, '0')}
          </span>
          <span style={{fontSize: 25, letterSpacing: config.brand.typography.bodyTracking}}>
            {config.archive.labels[shot.index]}
          </span>
          <span style={{
            marginLeft: 'auto', fontFamily: config.brand.typography.monoFamily,
            fontSize: 14, color: config.brand.colors.secondaryInk,
          }}>{config.archive.kinds[shot.index]}</span>
        </div>
      </div>;
    })}
  </AbsoluteFill>;
};

export const Template = ({config}: {config: CinemaConfig}) => {
  const frame = useCurrentFrame();
  const {fps, width, height} = useVideoConfig();
  const {opening, closing, shots, transitions, requested} = createEdit(config, fps);
  const geometry = positions(config, width, height);
  const {colors, typography} = config.brand;
  const {margin} = config.layout;
  const titleStyle: CSSProperties = {
    fontSize: typography.headingSize, lineHeight: typography.headingLineHeight,
    letterSpacing: typography.headingTracking, fontWeight: 400,
  };
  const bodyStyle: CSSProperties = {
    fontSize: typography.bodySize, lineHeight: typography.bodyLineHeight,
    letterSpacing: typography.bodyTracking,
  };
  const isOpening = frame < opening.durationInFrames;
  const isClosing = frame >= closing.from;
  const transition = transitions.find((item) => item.duration > 0 &&
    frame >= item.from && frame < item.from + item.duration);
  const current = shots.find((shot) => frame >= shot.from && frame < shot.from + shot.durationInFrames) ?? shots[5];
  let active = current.index;
  let floating = current;
  let rect = geometry.hero;
  let indexOpacity = 0;
  let archiveTitleOpacity = 0;
  let live = current.kind === 'video';
  let caption = current.caption;
  let expansion = 1;

  if (isOpening) {
    active = 0;
    floating = shots[0];
    const duration = Math.min(config.motion.openingExpandFrames, opening.durationInFrames * 0.45);
    expansion = easeInOut(progress(frame, opening.durationInFrames - duration, duration));
    rect = blendRect(geometry.tile(0), geometry.hero, expansion);
    indexOpacity = 1 - progress(expansion, 0.65, 0.35);
    archiveTitleOpacity = 1 - progress(expansion, 0, 0.4);
    caption = '';
    live = false;
  } else if (transition) {
    const returnRatio = requested === 0 ? 0 : config.motion.returnFrames / requested;
    const holdRatio = requested === 0 ? 0 : config.motion.indexHoldFrames / requested;
    const t = progress(frame, transition.from, transition.duration);
    const shrinking = t < returnRatio;
    floating = shrinking ? transition.outgoing : transition.incoming;
    active = floating.index;
    expansion = shrinking ? 1 - easeInOut(progress(t, 0, returnRatio))
      : easeInOut(progress(t, returnRatio + holdRatio, 1 - returnRatio - holdRatio));
    rect = blendRect(geometry.tile(active), geometry.hero, expansion);
    indexOpacity = 1 - progress(expansion, 0.65, 0.35);
    archiveTitleOpacity = 1 - progress(expansion, 0.1, 0.4);
    caption = expansion > 0.9 ? floating.caption : '';
    live = false;
  } else if (isClosing) {
    active = 5;
    floating = shots[5];
    const duration = Math.min(requested, Math.floor(closing.durationInFrames * 0.3));
    const t = progress(frame, closing.from, duration);
    const returnRatio = requested === 0 ? 0 : config.motion.returnFrames / requested;
    const holdRatio = requested === 0 ? 0 : config.motion.indexHoldFrames / requested;
    const shrinking = t < returnRatio;
    expansion = shrinking ? 1 - easeInOut(progress(t, 0, returnRatio))
      : easeInOut(progress(t, returnRatio + holdRatio, 1 - returnRatio - holdRatio));
    rect = blendRect(geometry.tile(5), shrinking ? geometry.hero : geometry.ending, expansion);
    indexOpacity = 1 - progress(expansion, 0.65, 0.35);
    archiveTitleOpacity = 1 - progress(expansion, 0.1, 0.4);
    caption = '';
    live = false;
  }

  const closingReady = isClosing && frame >= closing.from +
    Math.min(requested, Math.floor(closing.durationInFrames * 0.3));
  const progressMark = (active + 1) / shots.length;
  return <AbsoluteFill style={{
    backgroundColor: colors.canvas, color: colors.ink,
    fontFamily: typography.fontFamily, fontWeight: 400,
  }}>
    <div style={{
      position: 'absolute', top: 27, left: margin, right: margin,
      height: 49, borderBottom: `1px solid ${colors.ink}`, display: 'flex', alignItems: 'flex-start',
    }}>
      <div style={{width: 129, height: 32}}>
        <SourceImage {...config.media.logo} width={129} height={32} />
      </div>
      <span style={{marginLeft: 36, fontSize: 26, letterSpacing: typography.bodyTracking}}>
        {config.copy.featureName}
      </span>
      <span style={{
        marginLeft: 'auto', fontSize: 19, lineHeight: '32px',
        fontFamily: typography.monoFamily, color: colors.secondaryInk,
      }}>{isOpening ? 'CONTACT SHEET'
          : `${config.archive.kinds[active]}  ·  ${String(active + 1).padStart(2, '0')} / 06`}</span>
    </div>

    <div style={{
      position: 'absolute', left: margin, right: margin, top: 131, opacity: archiveTitleOpacity,
    }}>
      <div style={titleStyle}>{isOpening ? config.copy.opening : config.archive.title}</div>
      <div style={{...bodyStyle, marginTop: config.brand.spacing.titleGap, color: colors.secondaryInk}}>
        {isOpening ? config.copy.benefit : config.archive.context}
      </div>
    </div>

    {indexOpacity > 0 ? <Index shots={shots} config={config} frame={frame} active={active}
      hidden={floating.index} opacity={indexOpacity} /> : null}
    <Plate shot={floating} rect={rect} config={config} frame={frame} live={live}
      selected={indexOpacity > 0.5 && expansion < 0.1} />

    {caption ? <div style={{
      position: 'absolute', bottom: 30, left: margin, right: margin,
      display: 'flex', alignItems: 'center', gap: 32,
    }}>
      <span style={{fontFamily: typography.monoFamily, fontSize: 24, color: colors.secondaryInk}}>
        {String(active + 1).padStart(2, '0')}
      </span>
      <span style={{...bodyStyle, fontSize: typography.bodySize * 1.22, lineHeight: 1.1}}>
        {caption}
      </span>
      <span style={{marginLeft: 'auto', fontSize: 18, color: colors.secondaryInk, whiteSpace: 'nowrap'}}>
        {config.archive.context}
      </span>
    </div> : null}

    {closingReady ? <>
      <div style={{position: 'absolute', left: margin, right: margin, top: 857, ...titleStyle,
        fontSize: typography.headingSize * 0.66}}>
        {config.copy.closing}
      </div>
      <div style={{
        position: 'absolute', left: margin, right: margin, top: 959, display: 'flex',
        alignItems: 'center', justifyContent: 'space-between', borderTop: `1px solid ${colors.ink}`,
        paddingTop: 22,
      }}>
        <span style={{...bodyStyle, fontSize: typography.bodySize * 1.22}}>{config.copy.cta}</span>
        <span style={{fontFamily: typography.monoFamily, fontSize: 28}}>{config.copy.url}</span>
      </div>
    </> : null}
    <div style={{
      position: 'absolute', left: margin, bottom: 0, width: (width - margin * 2) * progressMark,
      height: 4, backgroundColor: colors.ink,
    }} />
  </AbsoluteFill>;
};
