import type {CSSProperties} from 'react';
import {AbsoluteFill, Sequence, useCurrentFrame, useVideoConfig} from 'remotion';
import {
  assets, easeInOut, makeTimeline, mediaGeometry, mix, progress,
  SourceImage, SourceVideo,
  type ImageSelection, type SceneTiming, type TemplateProps,
} from '../../shared';
import type {Annotation, SectionConfig, StageId} from './config';

const mono = (config: SectionConfig): CSSProperties => ({
  fontFamily: config.brand.typography.monoFamily,
  fontSize: config.drawing.indexSize,
  lineHeight: 1.2,
  letterSpacing: '0.01em',
});

const DraftGrid = ({config, opacity}: {config: SectionConfig; opacity: number}) =>
  <AbsoluteFill style={{
    opacity: opacity * config.drawing.gridOpacity,
    backgroundImage: `linear-gradient(${config.brand.colors.ink} 1px, transparent 1px), linear-gradient(90deg, ${config.brand.colors.ink} 1px, transparent 1px)`,
    backgroundSize: `${config.drawing.gridSpacing}px ${config.drawing.gridSpacing}px`,
    pointerEvents: 'none',
  }} />;

const Datum = ({config, top, opacity = 1}: {config: SectionConfig; top: number; opacity?: number}) =>
  <svg width={1920} height={30} style={{position: 'absolute', left: 0, top, opacity}}>
    <path d="M 28 15 H 1892 M 60 5 V 25 M 1860 5 V 25" fill="none"
      stroke={config.brand.colors.ink} strokeWidth={config.drawing.lineWidth} />
    <path d="M 48 23 L 72 7 M 1848 23 L 1872 7" stroke={config.brand.colors.ink}
      strokeWidth={config.drawing.lineWidth * 2} />
  </svg>;

const Stages = ({config, active, top, compact = false, resolve = 0}: {
  config: SectionConfig; active?: StageId; top: number; compact?: boolean; resolve?: number;
}) => {
  const {margin, gutter} = config.layout;
  const width = 1920 - margin * 2;
  const cell = width / config.stages.length;
  return <div style={{position: 'absolute', left: margin, top, width}}>
    <svg width={width} height={48} style={{position: 'absolute', overflow: 'visible'}}>
      {config.connections.map((connection, i) => {
        const start = config.stages.findIndex((stage) => stage.id === connection.from);
        const end = config.stages.findIndex((stage) => stage.id === connection.to);
        if (start < 0 || end < 0) return null;
        return <path key={i} d={`M ${start * cell + 16} 0 H ${end * cell + 16}`}
          fill="none" stroke={config.brand.colors.ink}
          strokeOpacity={compact ? 0.15 : mix(0.2, 0.7, resolve)}
          strokeWidth={config.drawing.lineWidth} />;
      })}
    </svg>
    {config.stages.map((stage, index) => <div key={stage.id} style={{
      position: 'absolute', top: 0, left: index * cell, width: cell - gutter,
      color: config.brand.colors.ink,
      transform: `translateY(${compact ? 0 : (1 - resolve) * (index % 2) * 14}px)`,
    }}>
      <div style={{
        position: 'absolute', left: 0, top: -4, width: 8, height: 8,
        background: stage.id === active || resolve > 0.95 ? config.brand.colors.ink : config.brand.colors.canvas,
        border: `1px solid ${config.brand.colors.ink}`,
      }} />
      <div style={{
        ...mono(config), paddingTop: compact ? 12 : 22,
        opacity: !active || stage.id === active ? 1 : 0.46,
        fontSize: compact ? config.drawing.indexSize - 2 : config.drawing.indexSize + 2,
      }}>{String(index + 1).padStart(2, '0')} / {stage.label}</div>
    </div>)}
  </div>;
};

const Leader = ({config, annotation, selection, width, height, opacity}: {
  config: SectionConfig; annotation: Annotation; selection: ImageSelection;
  width: number; height: number; opacity: number;
}) => {
  const geometry = mediaGeometry(assets[selection.asset], {width, height}, selection.framing);
  const scale = geometry.mediaWidth / assets[selection.asset].width;
  const x = geometry.cropLeft + geometry.mediaLeft + annotation.x * scale;
  const y = geometry.cropTop + geometry.mediaTop + annotation.y * scale;
  if (!annotation.enabled || x < 0 || x > width || y < 0 || y > height) return null;
  const startY = annotation.edge === 'top' ? -15 : height + 15;
  return <svg width={width} height={height} style={{
    position: 'absolute', inset: 0, overflow: 'visible', opacity, pointerEvents: 'none',
  }}>
    <text x={x - 48} y={startY + (annotation.edge === 'top' ? -8 : 16)} textAnchor="end"
      fontFamily={config.brand.typography.monoFamily}
      fontSize={16} fill={config.brand.colors.ink}>{annotation.label}</text>
    <path d={`M ${x - 42} ${startY} H ${x} V ${y}`}
      stroke={config.brand.colors.ink} fill="none" strokeWidth={config.drawing.lineWidth} />
    <circle cx={x} cy={y} r={4} fill={config.brand.colors.canvas}
      stroke={config.brand.colors.ink} strokeWidth={config.drawing.lineWidth} />
  </svg>;
};

const Cover = ({config, closing, duration}: {
  config: SectionConfig; closing: boolean; duration: number;
}) => {
  const frame = useCurrentFrame();
  const {margin, gutter} = config.layout;
  const open = easeInOut(progress(frame, 0, Math.min(28, duration * 0.22)));
  const settle = easeInOut(progress(frame, duration * config.motion.introResolveFraction, duration * 0.2));
  const planeSelections: {selection: ImageSelection; stage: StageId}[] = closing
    ? [
      {selection: config.media.environment, stage: 'environment'},
      {selection: config.media.iphone[1], stage: 'iphone'},
      {selection: config.media.ipad, stage: 'ipad'},
    ]
    : [
      {selection: config.media.ipad, stage: 'ipad'},
      {selection: config.media.iphone[0], stage: 'iphone'},
      {selection: config.media.environment, stage: 'environment'},
    ];
  const typography = config.brand.typography;
  return <AbsoluteFill>
    <DraftGrid config={config} opacity={closing ? 1 - settle * 0.6 : 1} />
    <Datum config={config} top={98} />
    <div style={{position: 'absolute', left: margin, top: 43, ...mono(config)}}>
      {config.drawing.title}
    </div>
    <div style={{position: 'absolute', right: margin, top: 39}}>
      <SourceImage {...config.media.logo} width={156} height={46} />
    </div>
    <div style={{position: 'absolute', left: margin, top: 174, width: 850}}>
      <div style={{...mono(config), marginBottom: 42}}>
        {closing ? config.drawing.closingLabel : config.copy.featureName}
      </div>
      <div style={{
        fontSize: closing ? typography.headingSize * 0.79 : typography.headingSize,
        lineHeight: typography.headingLineHeight,
        letterSpacing: typography.headingTracking,
        maxWidth: closing ? 800 : 760,
      }}>{closing ? config.copy.closing : config.copy.opening}</div>
      <div style={{
        marginTop: typography.bodySize + config.brand.spacing.titleGap,
        fontSize: typography.bodySize,
        lineHeight: typography.bodyLineHeight,
        maxWidth: 750,
      }}>{closing ? config.copy.cta : config.copy.benefit}</div>
      {closing ? <div style={{
        marginTop: 40, display: 'inline-block',
        padding: '14px 20px', background: config.brand.colors.ink,
        color: config.brand.colors.white, fontSize: 28,
      }}>{config.copy.url}</div> : null}
    </div>
    <div style={{position: 'absolute', left: 1010, top: 218, width: 770, height: 530}}>
      <div style={{position: 'absolute', left: 0, right: 0, top: 568, ...mono(config), fontSize: 16}}>
        {closing ? 'A—A / ASSEMBLED VIEWS' : 'A—A / EXPLODED VIEWS'}
      </div>
      {planeSelections.map(({selection, stage}, index) => {
        const offset = (2 - index) * config.motion.planeSeparation * open * (1 - settle * 0.65);
        const x = offset;
        const y = -offset * 0.65 + index * 46;
        return <div key={index} style={{
          position: 'absolute', left: x, top: y + (1 - open) * config.motion.planeTravel,
          background: config.brand.colors.canvas,
          width: 730, height: 408,
          border: `${config.drawing.lineWidth}px solid ${config.brand.colors.ink}`,
          padding: config.layout.padding,
          boxSizing: 'border-box',
        }}>
          <SourceImage {...selection} width={730 - config.layout.padding * 2}
            height={408 - config.layout.padding * 2} />
          <div style={{position: 'absolute', left: -gutter, top: 0, ...mono(config), fontSize: 14}}>
            {String(config.stages.findIndex((item) => item.id === stage) + 1).padStart(2, '0')}
          </div>
        </div>;
      })}
    </div>
    <div style={{position: 'absolute', left: margin, bottom: 214, ...mono(config), fontSize: 18}}>
      {config.drawing.montageLabel}
    </div>
    <Datum config={config} top={890} />
    <Stages config={config} top={936} resolve={closing ? settle : open} />
  </AbsoluteFill>;
};

const Product = ({config, scene}: TemplateProps<SectionConfig> & {scene: SceneTiming}) => {
  const frame = useCurrentFrame();
  const id = scene.id as StageId;
  const {margin, padding, captionHeight, grid} = config.layout;
  const mediaWidth = 1920 - margin * 2 - padding * 2;
  const mediaHeight = grid.mediaBottom - grid.mediaTop - padding * 2;
  const revealFrames = Math.min(config.motion.sectionRevealFrames, scene.durationInFrames / 4);
  const reveal = easeInOut(progress(frame, 0, revealFrames));
  const split = Math.max(1, Math.min(scene.durationInFrames - 1,
    Math.round(scene.durationInFrames * config.motion.iphoneSplit)));
  const second = id === 'iphone' && frame >= split;
  const still = id === 'environment' ? config.media.environment
    : id === 'iphone' ? config.media.iphone[second ? 1 : 0]
    : id === 'ipad' ? config.media.ipad : null;
  const localFrame = second ? frame - split : frame;
  const leaderOpacity = progress(localFrame, revealFrames, 8) *
    (1 - progress(localFrame, config.motion.annotationHoldFrames, config.motion.annotationFadeFrames));
  const stillScale = mix(id === 'environment' ? 0.42 : 0.965, 1, reveal);
  const travelX = id === 'environment' ? 938 : config.motion.planeTravel;
  const travelY = id === 'environment' ? 124 : 0;
  const index = config.stages.findIndex((stage) => stage.id === id);
  return <AbsoluteFill>
    <DraftGrid config={config} opacity={1 - reveal} />
    <div style={{position: 'absolute', top: grid.headerY, left: margin, ...mono(config)}}>
      {config.copy.featureName} <span style={{opacity: 0.45}}> / {config.drawing.title}</span>
    </div>
    <div style={{position: 'absolute', top: grid.headerY, right: margin, ...mono(config), fontSize: 17}}>
      {still ? config.drawing.stillLabel : config.drawing.recordLabel}
    </div>
    <div style={{
      position: 'absolute', left: margin, top: grid.mediaTop - captionHeight,
      right: margin, height: captionHeight - 16, display: 'flex', alignItems: 'flex-start', gap: 24,
    }}>
      <div style={{
        ...mono(config), fontSize: 23, marginTop: 8, padding: '4px 9px',
        background: config.brand.colors.ink, color: config.brand.colors.white,
      }}>{String(index + 1).padStart(2, '0')}</div>
      <div style={{
        fontSize: config.brand.typography.headingSize * 0.48,
        letterSpacing: config.brand.typography.headingTracking,
        lineHeight: 1.08,
      }}>{config.copy[id]}</div>
    </div>
    <div style={{
      position: 'absolute', left: margin, top: grid.mediaTop,
      width: mediaWidth + padding * 2, height: mediaHeight + padding * 2,
      background: config.brand.colors.mediaMat,
    }}>
      <div style={{position: 'absolute', left: padding, top: padding,
        transformOrigin: 'top left',
        transform: still ? `translate(${(1 - reveal) * travelX}px, ${(1 - reveal) * travelY}px) scale(${stillScale})` : undefined,
      }}>
        {still ? <SourceImage {...still} width={mediaWidth} height={mediaHeight} /> :
          <SourceVideo {...config.media[id === 'agent' ? 'agent' : 'webQa']}
            width={mediaWidth} height={mediaHeight} durationInFrames={scene.durationInFrames}
            labelStyle={{
              backgroundColor: config.brand.colors.ink, color: config.brand.colors.white,
              fontFamily: config.brand.typography.fontFamily, fontSize: 27,
            }} />}
        {still ? <Leader config={config}
          annotation={config.annotations[second ? 'iphoneSecond' : id]}
          selection={still} width={mediaWidth} height={mediaHeight} opacity={leaderOpacity} /> : null}
      </div>
      <svg width={mediaWidth + padding * 2} height={mediaHeight + padding * 2}
        style={{position: 'absolute', inset: 0, pointerEvents: 'none'}}>
        <path d={`M 0 0 H ${(mediaWidth + padding * 2) * reveal} M ${mediaWidth + padding * 2} ${mediaHeight + padding * 2} H ${(mediaWidth + padding * 2) * (1 - reveal)}`}
          stroke={config.brand.colors.ink} strokeWidth={config.drawing.lineWidth} fill="none" />
      </svg>
    </div>
    <Stages config={config} active={id} top={grid.stageTop} compact />
  </AbsoluteFill>;
};

export const Template = ({config}: TemplateProps<SectionConfig>) => {
  const {fps} = useVideoConfig();
  return <AbsoluteFill style={{
    background: config.brand.colors.canvas,
    color: config.brand.colors.ink,
    fontFamily: config.brand.typography.fontFamily,
    lineHeight: config.brand.typography.bodyLineHeight,
    letterSpacing: config.brand.typography.bodyTracking,
  }}>
    {makeTimeline(config.durations, fps).map((scene) =>
      <Sequence key={scene.id} from={scene.from} durationInFrames={scene.durationInFrames}>
        {scene.id === 'opening' || scene.id === 'closing'
          ? <Cover config={config} closing={scene.id === 'closing'} duration={scene.durationInFrames} />
          : <Product config={config} scene={scene} />}
      </Sequence>)}
  </AbsoluteFill>;
};
