import type {CSSProperties, ReactNode} from 'react';
import {AbsoluteFill, Sequence, useCurrentFrame, useVideoConfig} from 'remotion';
import {
  assets, easeInOut, makeTimeline, mediaGeometry, mix, progress, SourceImage, SourceVideo,
  type ImageSelection, type SceneTiming, type VideoSelection,
} from '../../shared';
import type {FocusKey, OpticalConfig} from './config';

type SourceSelection = ImageSelection | VideoSelection;
type Box = {x: number; y: number; width: number; height: number};
const position = (box: Box): CSSProperties => ({
  position: 'absolute', left: box.x, top: box.y, width: box.width, height: box.height,
});

const Media = ({selection, box, duration, config}: {
  selection: SourceSelection; box: Box; duration: number; config: OpticalConfig;
}) => 'sourceStartSeconds' in selection
  ? <SourceVideo {...selection} width={box.width} height={box.height}
      durationInFrames={duration} labelStyle={{
        fontFamily: config.brand.typography.fontFamily,
        backgroundColor: config.brand.colors.ink, color: config.brand.colors.white,
        fontSize: config.layout.grid.annotationSize,
      }} />
  : <SourceImage {...selection} width={box.width} height={box.height} />;

const Index = ({children, style, config}: {
  children: ReactNode; style?: CSSProperties; config: OpticalConfig;
}) => <div style={{
  fontFamily: config.brand.typography.monoFamily,
  fontSize: config.layout.grid.indexSize,
  letterSpacing: '0.025em', lineHeight: 1.3,
  color: config.brand.colors.secondaryInk, ...style,
}}>{children}</div>;

const Header = ({config, number}: {config: OpticalConfig; number: string}) => {
  const {margin, grid} = config.layout;
  return <>
    <div style={{position: 'absolute', left: margin, top: 45}}>
      <SourceImage {...config.media.logo} width={grid.logoWidth} height={56} />
    </div>
    <Index config={config} style={{position: 'absolute', right: margin, top: 60}}>
      {number} / {config.labels.direction}
    </Index>
    <div style={{
      position: 'absolute', left: margin, right: margin, top: 121,
      borderTop: `1px solid ${config.brand.colors.ink}`, opacity: 0.22,
    }} />
  </>;
};

const Footer = ({config}: {config: OpticalConfig}) => <div style={{
  position: 'absolute', left: config.layout.margin, right: config.layout.margin,
  bottom: 30, borderTop: `1px solid ${config.brand.colors.mediaMat}`,
  paddingTop: 16, display: 'flex', justifyContent: 'space-between',
  fontSize: 21, color: config.brand.colors.secondaryInk,
}}>
  <span>{config.labels.montage}</span><span>{config.copy.featureName}</span>
</div>;

const Caption = ({config, children}: {config: OpticalConfig; children: string}) =>
  <div style={{
    position: 'absolute', left: config.layout.margin, right: config.layout.margin,
    top: config.layout.captionHeight, fontSize: config.layout.grid.captionSize,
    lineHeight: config.brand.typography.headingLineHeight,
    letterSpacing: config.brand.typography.headingTracking,
  }}>{children}</div>;

const Inspection = ({config, selection, focusKey, duration}: {
  config: OpticalConfig; selection: SourceSelection; focusKey: FocusKey; duration: number;
}) => {
  const frame = useCurrentFrame();
  const {fps, width} = useVideoConfig();
  const {margin, gutter, padding, grid} = config.layout;
  const {crop, annotation, sourceNote} = config.focus[focusKey];
  const source = assets[selection.asset];
  const motion = config.motion;
  const revealFrames = Math.max(1, Math.min(motion.revealFrames, duration * 0.16));
  const hold = Math.min(motion.contextHoldSeconds * fps, duration * 0.2);
  const returnFrames = Math.min(motion.returnSeconds * fps, duration * 0.2);
  const observation = easeInOut(progress(frame, hold, revealFrames)) *
    (1 - easeInOut(progress(frame, duration - returnFrames, revealFrames)));
  const detailVisibility = easeInOut(progress(frame, hold + revealFrames, revealFrames)) *
    (1 - easeInOut(progress(frame, duration - returnFrames - revealFrames, revealFrames)));
  const full: Box = {
    x: margin, y: grid.mediaTop, width: width - 2 * margin, height: grid.mediaHeight,
  };
  const contextX = margin + grid.inspectionWidth + gutter;
  const context: Box = {
    x: mix(full.x, contextX, observation), y: full.y,
    width: mix(full.width, width - margin - contextX, observation), height: full.height,
  };
  const webQa = selection.asset === 'devin-testing-2.mp4';
  const contextGeometry = mediaGeometry(source, {
    width: context.width, height: context.height - (webQa ? 48 : 0),
  }, selection.framing);
  const mainCrop = selection.framing.crop ?? {x: 0, y: 0, width: source.width, height: source.height};
  if (crop.x < mainCrop.x || crop.y < mainCrop.y ||
    crop.x + crop.width > mainCrop.x + mainCrop.width ||
    crop.y + crop.height > mainCrop.y + mainCrop.height) {
    throw new Error(`Inspection region ${focusKey} must remain inside the context source crop`);
  }
  const sourceScale = contextGeometry.mediaWidth / source.width;
  const focusBox: Box = {
    x: context.x + contextGeometry.cropLeft + (crop.x - mainCrop.x) * sourceScale,
    y: context.y + contextGeometry.cropTop + (crop.y - mainCrop.y) * sourceScale,
    width: crop.width * sourceScale, height: crop.height * sourceScale,
  };
  const detailScale = Math.min(1, Math.max(0.1, motion.maxSourceScale),
    grid.inspectionWidth / crop.width, grid.inspectionHeight / crop.height);
  const detail: Box = {
    x: margin, y: grid.inspectionTop,
    width: crop.width * detailScale, height: crop.height * detailScale + (webQa ? 48 : 0),
  };
  const detailSelection = {
    ...selection, framing: {fit: 'contain' as const, anchorX: 0.5, anchorY: 0.5, crop},
  };
  const color = config.brand.colors.ink;
  const elbowX = contextX - gutter / 2;
  const lineY = focusBox.y + focusBox.height / 2;
  const detailY = detail.y + (detail.height - (webQa ? 48 : 0)) / 2;
  return <>
    <div style={position(context)}>
      <Media selection={selection} box={context} duration={duration} config={config} />
    </div>
    <Index config={config} style={{
      position: 'absolute', left: context.x, top: grid.mediaTop - 34,
    }}>{config.labels.fullView}</Index>
    <svg width={width} height={1080} style={{
      position: 'absolute', inset: 0, opacity: detailVisibility, pointerEvents: 'none',
    }}>
      <path d={`M ${detail.x + detail.width + padding / 2} ${detailY}
        H ${elbowX} V ${lineY} H ${focusBox.x - padding / 2}`}
        fill="none" stroke={color} strokeWidth={1}
        opacity={motion.connectorOpacity} />
      <rect x={focusBox.x - 5} y={focusBox.y - 5}
        width={focusBox.width + 10} height={focusBox.height + 10}
        fill="none" stroke={config.brand.colors.white} strokeWidth={motion.outlineWidth + 2} />
      <rect x={focusBox.x - 5} y={focusBox.y - 5}
        width={focusBox.width + 10} height={focusBox.height + 10}
        fill="none" stroke={color} strokeWidth={motion.outlineWidth} />
    </svg>
    <div style={{opacity: detailVisibility}}>
      <Index config={config} style={{
        position: 'absolute', left: detail.x, top: detail.y - 38,
      }}>{config.labels.inspection}</Index>
      <div style={{
        ...position(detail), backgroundColor: config.brand.colors.white,
        outline: `${motion.outlineWidth}px solid ${color}`,
        outlineOffset: 8,
      }}>
        <div style={{clipPath: `inset(0 ${(1 - detailVisibility) * 100}% 0 0)`}}>
          <Media selection={detailSelection} box={detail} duration={duration} config={config} />
        </div>
      </div>
      <div style={{
        position: 'absolute', left: margin, top: grid.annotationTop,
        width: grid.inspectionWidth, fontSize: grid.annotationSize,
        letterSpacing: config.brand.typography.bodyTracking,
        lineHeight: config.brand.typography.bodyLineHeight,
      }}>
        <div style={{borderTop: `1px solid ${color}`, width: 48, marginBottom: 18}} />
        <div>{annotation}</div>
        <div style={{color: config.brand.colors.secondaryInk, marginTop: 8}}>{sourceNote}</div>
      </div>
    </div>
  </>;
};

const ProductScene = ({config, scene}: {config: OpticalConfig; scene: SceneTiming}) => {
  const split = Math.max(1, Math.min(scene.durationInFrames - 1,
    Math.round(scene.durationInFrames * config.motion.iphoneSplit)));
  const number = String(makeTimeline(config.durations).findIndex((s) => s.id === scene.id) + 1)
    .padStart(2, '0');
  return <AbsoluteFill>
    <Header config={config} number={number} />
    <Caption config={config}>{config.copy[scene.id]}</Caption>
    {scene.id === 'iphone' ? <>
      <Sequence durationInFrames={split}>
        <Inspection config={config} selection={config.media.iphone[0]}
          focusKey="iphoneFirst" duration={split} />
      </Sequence>
      {scene.durationInFrames > 1 ? <Sequence from={split} durationInFrames={scene.durationInFrames - split}>
        <Inspection config={config} selection={config.media.iphone[1]}
          focusKey="iphoneSecond" duration={scene.durationInFrames - split} />
      </Sequence> : null}
    </> : scene.id === 'environment' || scene.id === 'agent' ||
      scene.id === 'webQa' || scene.id === 'ipad'
      ? <Inspection config={config} selection={config.media[scene.id]}
          focusKey={scene.id} duration={scene.durationInFrames} /> : null}
    <Footer config={config} />
  </AbsoluteFill>;
};

const Opening = ({config}: {config: OpticalConfig}) => {
  const frame = useCurrentFrame();
  const {width} = useVideoConfig();
  const {margin, gutter} = config.layout;
  const appearance = easeInOut(progress(frame, 0, config.motion.revealFrames));
  return <AbsoluteFill>
    <Header config={config} number="01" />
    <div style={{
      position: 'absolute', left: margin, top: 242,
      fontSize: config.brand.typography.headingSize * 1.38,
      lineHeight: config.brand.typography.headingLineHeight,
      letterSpacing: config.brand.typography.headingTracking,
      width: 880, zIndex: 1, opacity: mix(0.5, 1, appearance),
    }}>{config.copy.opening}</div>
    <div style={{
      position: 'absolute', left: margin, top: 649, width: 700,
      fontSize: config.brand.typography.bodySize * 1.2,
      lineHeight: 1.2, letterSpacing: config.brand.typography.bodyTracking,
    }}>{config.copy.benefit}</div>
    <div style={{
      position: 'absolute', left: 950 + gutter, right: margin, top: 314,
      height: 460, backgroundColor: config.brand.colors.mediaMat,
      border: `1px solid ${config.brand.colors.mediaMat}`,
    }}>
      <SourceImage {...config.media.environment} width={width - 950 - gutter - margin} height={460} />
    </div>
    <Index config={config} style={{position: 'absolute', left: 950 + gutter, top: 795}}>
      {config.labels.fullView}
    </Index>
    <div style={{
      position: 'absolute', left: margin, bottom: 147, fontSize: 26,
      color: config.brand.colors.secondaryInk,
    }}>{config.labels.openingNote}</div>
    <Footer config={config} />
  </AbsoluteFill>;
};

const Closing = ({config}: {config: OpticalConfig}) => {
  const {width} = useVideoConfig();
  const {margin} = config.layout;
  return <AbsoluteFill>
    <Header config={config} number="07" />
    <Caption config={config}>{config.copy.closing}</Caption>
    <div style={{position: 'absolute', left: margin, top: 250}}>
      <SourceImage {...config.media.ipad} width={width - 2 * margin} height={600} />
    </div>
    <Index config={config} style={{position: 'absolute', left: margin, top: 876}}>
      {config.labels.result}
    </Index>
    <div style={{
      position: 'absolute', left: margin, right: margin, top: 936,
      display: 'flex', justifyContent: 'space-between', alignItems: 'baseline',
    }}>
      <div style={{fontSize: 42, letterSpacing: config.brand.typography.headingTracking}}>
        {config.copy.cta}
      </div>
      <div style={{fontSize: 30}}>{config.copy.url}</div>
    </div>
    <Footer config={config} />
  </AbsoluteFill>;
};

export const Template = ({config}: {config: OpticalConfig}) => {
  const {fps} = useVideoConfig();
  const timeline = makeTimeline(config.durations, fps);
  return <AbsoluteFill style={{
    backgroundColor: config.brand.colors.canvas, color: config.brand.colors.ink,
    fontFamily: config.brand.typography.fontFamily, fontWeight: 400,
  }}>
    {timeline.map((scene) => <Sequence key={scene.id} from={scene.from}
      durationInFrames={scene.durationInFrames}>
      {scene.id === 'opening' ? <Opening config={config} /> :
        scene.id === 'closing' ? <Closing config={config} /> :
          <ProductScene config={config} scene={scene} />}
    </Sequence>)}
  </AbsoluteFill>;
};
