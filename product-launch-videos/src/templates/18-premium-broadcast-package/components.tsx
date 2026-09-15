import type {CSSProperties, ReactNode} from 'react';
import {AbsoluteFill, useCurrentFrame, useVideoConfig} from 'remotion';
import {
  easeInOut, progress, rectangleReveal, SourceImage,
  type ImageSelection, type SceneId,
} from '../../shared';
import type {BroadcastConfig} from './config';

type Props = {config: BroadcastConfig};
export type ProductScene = Exclude<SceneId, 'opening' | 'closing'>;

const headingStyle = (config: BroadcastConfig): CSSProperties => ({
  fontSize: config.brand.typography.headingSize,
  lineHeight: config.brand.typography.headingLineHeight,
  letterSpacing: config.brand.typography.headingTracking,
  fontWeight: 400,
});

export const productBounds = (config: BroadcastConfig, width: number, height: number) => ({
  left: config.layout.margin,
  top: config.layout.grid.mediaTop,
  width: width - 2 * config.layout.margin,
  height: height - config.layout.grid.mediaTop - config.layout.margin -
    config.layout.captionHeight - config.layout.gutter,
});

export const ChapterMarker = ({config, scene, note}: Props & {scene: SceneId; note?: string}) => {
  const chapter = config.broadcast.chapters[scene];
  return <div style={{
    position: 'absolute', left: config.layout.margin, right: config.layout.margin,
    top: 22, height: config.layout.grid.headerHeight,
    display: 'flex', alignItems: 'center', justifyContent: 'space-between',
    fontSize: config.broadcast.markerSize,
  }}>
    <div style={{display: 'flex', alignItems: 'center', gap: 18}}>
      <span style={{width: 12, height: 12, background: 'currentColor'}} />
      <span>{config.copy.featureName}</span>
      <span style={{opacity: 0.35}}>/</span>
      <span>{chapter.label}</span>
    </div>
    <div style={{color: config.brand.colors.secondaryInk}}>{note ?? config.broadcast.montageLabel}</div>
  </div>;
};

export const Transition = ({config, frame, duration, children}: Props & {
  frame: number; duration: number; children: ReactNode;
}) => {
  const amount = easeInOut(progress(frame, 0, Math.min(config.motion.wipeFrames, duration / 5)));
  return <div style={{width: '100%', height: '100%', position: 'relative'}}>
    {children}
    {amount < 1 ? <div style={{
      position: 'absolute', inset: 0,
      background: config.brand.colors.mediaMat,
      clipPath: `inset(0 0 0 ${amount * 100}%)`,
      borderLeft: `3px solid ${config.brand.colors.ink}`,
      pointerEvents: 'none',
    }} /> : null}
  </div>;
};

export const LowerThird = ({config, scene, duration}: Props & {
  scene: ProductScene; duration: number;
}) => {
  const frame = useCurrentFrame();
  const {height} = useVideoConfig();
  const {margin, captionHeight, gutter} = config.layout;
  const enter = easeInOut(progress(frame, 0, Math.min(config.motion.stingFrames, duration / 5)));
  return <div style={{
    position: 'absolute', left: margin, right: margin,
    top: height - margin - captionHeight, height: captionHeight,
    borderTop: `2px solid ${config.brand.colors.ink}`,
    display: 'flex', alignItems: 'center', gap: gutter, overflow: 'hidden',
  }}>
    <div style={{
      width: 116, height: 104, flexShrink: 0,
      background: config.brand.colors.ink, color: config.brand.colors.white,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      fontSize: 50, transform: `translateY(${(1 - enter) * config.motion.panelTravel}px)`,
    }}>{config.broadcast.chapters[scene].number}</div>
    <div style={{
      fontSize: config.broadcast.captionSize, lineHeight: 1.12, flex: 1,
      letterSpacing: config.brand.typography.headingTracking,
    }}>{config.copy[scene]}</div>
    <div style={{
      width: 76, height: 76, flexShrink: 0, border: '1px solid currentColor',
      display: 'grid', placeItems: 'center', fontSize: 45,
    }}>↗</div>
  </div>;
};

export const Demonstration = ({config, scene, duration, children, note}: Props & {
  scene: ProductScene; duration: number; children: ReactNode; note?: string;
}) => {
  const {width, height} = useVideoConfig();
  const box = productBounds(config, width, height);
  return <>
    <ChapterMarker config={config} scene={scene} note={note} />
    <div style={{
      position: 'absolute', ...box, overflow: 'hidden',
      background: config.brand.colors.mediaMat,
    }}>{children}</div>
    <LowerThird config={config} scene={scene} duration={duration} />
  </>;
};

export const Evidence = ({config, media, width, height, frame, duration}: Props & {
  media: ImageSelection; width: number; height: number; frame: number; duration: number;
}) => <Transition config={config} frame={frame} duration={duration}>
  <SourceImage {...media} width={width} height={height} />
</Transition>;

export const Title = ({config, duration}: Props & {duration: number}) => {
  const frame = useCurrentFrame();
  const {width, height} = useVideoConfig();
  const {margin, padding, gutter} = config.layout;
  const panelWidth = width * config.broadcast.titlePanelFraction;
  const panelLeft = width - panelWidth;
  const leftWidth = panelLeft - margin - gutter;
  const enter = easeInOut(progress(frame, 0, Math.min(config.motion.titleRevealFrames, duration / 4)));
  return <AbsoluteFill>
    <div style={{
      position: 'absolute', top: 0, bottom: 0, right: 0, width: panelWidth,
      background: config.brand.colors.ink,
      clipPath: rectangleReveal(enter),
    }} />
    <div style={{position: 'absolute', left: margin, top: 52, fontSize: 25}}>
      {config.copy.featureName}
    </div>
    <div style={{position: 'absolute', left: margin, top: 166}}>
      <SourceImage {...config.media.logo} width={config.broadcast.logoWidth} height={86} />
    </div>
    <div style={{
      position: 'absolute', left: margin, top: 354, width: leftWidth,
      ...headingStyle(config),
    }}>{config.copy.opening}</div>
    <div style={{
      position: 'absolute', left: margin, top: 684, width: leftWidth,
      height: 3, background: config.brand.colors.ink,
      transform: `scaleX(${0.2 + enter * 0.8})`, transformOrigin: 'left',
    }} />
    <div style={{
      position: 'absolute', left: margin, bottom: 124, width: leftWidth,
      fontSize: config.brand.typography.bodySize,
    }}>{config.copy.benefit}</div>
    <div style={{
      position: 'absolute', left: panelLeft + gutter, right: gutter, top: 198,
      color: config.brand.colors.white, fontSize: config.broadcast.markerSize,
      display: 'flex', justifyContent: 'space-between', opacity: enter,
    }}><span>{config.broadcast.titleMediaLabel}</span><span>01</span></div>
    <div style={{
      position: 'absolute', left: panelLeft + gutter, top: 264,
      width: panelWidth - gutter * 2, height: height * 0.5,
      background: config.brand.colors.canvas, padding,
      boxSizing: 'border-box',
      clipPath: rectangleReveal(enter),
    }}>
      <SourceImage {...config.media.environment}
        width={panelWidth - 2 * gutter - 2 * padding} height={height * 0.5 - padding * 2} />
    </div>
    <div style={{
      position: 'absolute', left: panelLeft + gutter, right: gutter, bottom: 124,
      color: config.brand.colors.white, opacity: enter,
      fontSize: config.broadcast.markerSize, borderTop: '1px solid currentColor',
      paddingTop: 22,
    }}>{config.copy.environment}</div>
  </AbsoluteFill>;
};

export const Closing = ({config, duration}: Props & {duration: number}) => {
  const frame = useCurrentFrame();
  const {margin, gutter} = config.layout;
  const enter = easeInOut(progress(frame, 0, Math.min(config.motion.titleRevealFrames, duration / 5)));
  return <AbsoluteFill style={{background: config.brand.colors.ink, color: config.brand.colors.white}}>
    <div style={{
      position: 'absolute', top: 52, left: margin, right: margin,
      display: 'flex', justifyContent: 'space-between', fontSize: 25,
    }}><span>{config.copy.featureName}</span><span>{config.broadcast.chapters.closing.label}</span></div>
    <div style={{position: 'absolute', top: 186, left: margin}}>
      <SourceImage {...config.broadcast.closingLogo} width={config.broadcast.logoWidth} height={86} />
    </div>
    <div style={{
      position: 'absolute', top: 376, left: margin, maxWidth: 1490,
      ...headingStyle(config),
    }}>{config.copy.closing}</div>
    <div style={{
      position: 'absolute', left: margin, right: margin, bottom: 88,
      height: 150, display: 'flex', alignItems: 'center', gap: gutter,
      borderTop: '2px solid currentColor',
    }}>
      <div style={{
        width: 116, height: 104, display: 'grid', placeItems: 'center',
        background: config.brand.colors.white, color: config.brand.colors.ink,
        fontSize: 54, clipPath: rectangleReveal(enter, 'y'),
      }}>↗</div>
      <div style={{fontSize: config.broadcast.captionSize, flex: 1}}>{config.copy.cta}</div>
      <div style={{fontSize: 31}}>{config.copy.url}</div>
    </div>
  </AbsoluteFill>;
};
