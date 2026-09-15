import type {CSSProperties, ReactNode} from 'react';
import {AbsoluteFill, Sequence, useCurrentFrame, useVideoConfig} from 'remotion';
import {
  SourceImage, SourceVideo, easeInOut, makeTimeline, progress,
  type ImageSelection, type SceneTiming,
} from '../../shared';
import type {PaperConfig} from './config';

type Box = {x: number; y: number; width: number; height: number};
const boxStyle = (box: Box): CSSProperties => ({
  position: 'absolute', left: box.x, top: box.y, width: box.width, height: box.height,
});

const Paper = ({
  config, box, children, style, layers = config.paper.layers,
}: {
  config: PaperConfig; box: Box; children?: ReactNode; style?: CSSProperties; layers?: number;
}) => {
  const {colors} = config.brand;
  return <div style={{...boxStyle(box), ...style}}>
    {Array.from({length: Math.max(0, Math.round(layers) - 1)}, (_, index) => {
      const depth = Math.round(layers) - 1 - index;
      return <AbsoluteFill key={depth} style={{
        transform: `translate(${depth * config.paper.layerOffsetX}px, ${depth * config.paper.layerOffsetY}px)`,
        background: depth % 2 ? colors.canvas : colors.mediaMat,
        border: '1px solid rgba(25,25,25,0.06)',
        boxShadow: `0 3px 3px rgba(25,25,25,${config.paper.shadowStrength * 0.22})`,
      }} />;
    })}
    <AbsoluteFill style={{
      background: colors.canvas,
      boxShadow: `0 12px 28px rgba(25,25,25,${config.paper.shadowStrength}), 0 1px 2px rgba(25,25,25,0.06)`,
    }}>
      <AbsoluteFill style={{
        opacity: config.paper.textureOpacity,
        backgroundImage: 'repeating-linear-gradient(0deg, transparent 0px, transparent 3px, #191919 3px, transparent 4px)',
        pointerEvents: 'none',
      }} />
      {children}
    </AbsoluteFill>
  </div>;
};

const Fold = ({config, height, lift = 0}: {config: PaperConfig; height: number; lift?: number}) =>
  <div style={{
    position: 'absolute', right: -config.paper.foldWidth + 1, top: 0,
    width: config.paper.foldWidth, height,
    transformOrigin: 'left center',
    transform: `perspective(900px) rotateY(${-lift * config.motion.foldAngle}deg)`,
    background: `linear-gradient(90deg, ${config.brand.colors.mediaMat}, ${config.brand.colors.canvas} 42%, ${config.brand.colors.white})`,
    borderLeft: '1px solid rgba(25,25,25,0.1)',
    boxShadow: `${8 + lift * config.motion.dividerLift}px ${4 + lift * 8}px ${12 + lift * 12}px rgba(25,25,25,${config.paper.shadowStrength})`,
  }} />;

const Sleeve = ({
  config, width, height, amount, axis,
}: {config: PaperConfig; width: number; height: number; amount: number; axis: 'x' | 'y'}) => {
  if (amount >= 1) return null;
  const sign = config.motion.sleeveDirection === 'left' ? -1 : 1;
  const travel = axis === 'x' ? width + 2 * config.paper.foldWidth : height + 40;
  return <div style={{
    position: 'absolute', inset: 0, zIndex: 3,
    transform: axis === 'x' ? `translateX(${sign * amount * travel}px)` : `translateY(${-amount * travel}px)`,
    background: config.brand.colors.canvas,
    boxShadow: `12px 14px ${24 + Math.sin(amount * Math.PI) * 20}px rgba(25,25,25,${config.paper.shadowStrength})`,
  }}>
    <div style={{
      position: 'absolute', top: 0, bottom: 0, right: 110,
      borderLeft: '1px solid rgba(25,25,25,0.1)',
      borderRight: '1px solid rgba(255,255,255,0.8)',
    }} />
    <Fold config={config} height={height} lift={Math.sin(amount * Math.PI)} />
  </div>;
};

const getLayout = (config: PaperConfig) => {
  const {margin, padding, captionHeight, grid} = config.layout;
  const captionY = 1080 - margin - captionHeight;
  const stage: Box = {
    x: margin, y: grid.mediaTop, width: 1920 - margin * 2 - config.paper.foldWidth,
    height: captionY - grid.captionGap - grid.mediaTop,
  };
  return {
    stage,
    media: {x: padding, y: padding, width: stage.width - 2 * padding, height: stage.height - 2 * padding},
    caption: {x: margin, y: captionY, width: stage.width, height: captionHeight},
  };
};

const Caption = ({
  config, index, text, label,
}: {config: PaperConfig; index: number; text: string; label: string}) => {
  const {caption} = getLayout(config);
  const indexWidth = config.layout.grid.captionIndexWidth;
  return <Paper config={config} box={caption} layers={2}>
    <div style={{
      position: 'absolute', left: 0, top: 0, bottom: 0, width: indexWidth,
      background: config.brand.colors.ink, color: config.brand.colors.white,
      display: 'flex', justifyContent: 'center', alignItems: 'center',
      fontFamily: config.brand.typography.monoFamily, fontSize: 26,
    }}>{String(index).padStart(2, '0')}</div>
    <div style={{
      position: 'absolute', left: indexWidth + config.layout.gutter, top: 18,
      width: caption.width - indexWidth - config.layout.gutter * 2,
    }}>
      <div style={{
        fontSize: config.paper.captionSize, lineHeight: 1.1,
        letterSpacing: config.brand.typography.bodyTracking,
      }}>{text}</div>
      <div style={{
        fontSize: config.paper.labelSize, marginTop: 12,
        color: config.brand.colors.secondaryInk,
      }}>{label}</div>
    </div>
  </Paper>;
};

const ProductScene = ({config, timing}: {config: PaperConfig; timing: SceneTiming}) => {
  const frame = useCurrentFrame();
  const {stage, media} = getLayout(config);
  const {id, durationInFrames} = timing;
  const split = Math.max(1, Math.min(durationInFrames - 1, Math.round(durationInFrames * config.motion.iphoneSplit)));
  const isSecond = id === 'iphone' && frame >= split;
  const video = id === 'agent' ? config.media.agent : id === 'webQa' ? config.media.webQa : null;
  const image: ImageSelection = id === 'environment' ? config.media.environment :
    id === 'ipad' ? config.media.ipad : config.media.iphone[isSecond ? 1 : 0];
  const localReveal = isSecond ? frame - split : frame;
  const revealFrames = Math.min(config.motion.sleeveFrames, durationInFrames / 4);
  const reveal = easeInOut(progress(localReveal, 0, revealFrames));
  const lift = Math.sin(easeInOut(progress(frame, 0, revealFrames)) * Math.PI);
  const label = id === 'iphone'
    ? config.paper.labels[isSecond ? 'iphoneSecond' : 'iphoneFirst']
    : config.paper.labels[id];
  const sceneIndex = {opening: 1, environment: 2, agent: 3, iphone: 4, webQa: 5, ipad: 6, closing: 7}[id];
  return <AbsoluteFill>
    <Paper config={config} box={stage}>
      <div style={{...boxStyle(media), background: config.brand.colors.white}}>
        {video ? <SourceVideo
          {...video} width={media.width} height={media.height}
          durationInFrames={durationInFrames}
          labelStyle={{background: config.brand.colors.ink, color: config.brand.colors.white}}
        /> : <SourceImage {...image} width={media.width} height={media.height} />}
      </div>
      <Fold config={config} height={stage.height} lift={lift} />
      {!video && id !== 'environment' ? <div style={{
        position: 'absolute', inset: 0, overflow: 'hidden', pointerEvents: 'none',
      }}>
        <Sleeve config={config} width={stage.width} height={stage.height} amount={reveal}
          axis={id === 'ipad' ? 'y' : 'x'} />
      </div> : null}
      {video ? <div style={{
        position: 'absolute', left: 0, top: 0, width: config.layout.padding, height: stage.height,
        background: config.brand.colors.canvas,
        transform: `translateX(${-lift * config.motion.dividerLift}px)`,
        boxShadow: `-4px 4px 12px rgba(25,25,25,${config.paper.shadowStrength * lift})`,
      }} /> : null}
    </Paper>
    <Caption config={config} index={sceneIndex} text={config.copy[id]} label={label} />
  </AbsoluteFill>;
};

const Opening = ({config, durationInFrames}: {config: PaperConfig; durationInFrames: number}) => {
  const frame = useCurrentFrame();
  const revealFrames = Math.min(config.motion.titleRevealFrames, durationInFrames / 3);
  const reveal = easeInOut(progress(frame, durationInFrames - revealFrames, revealFrames));
  const {margin} = config.layout;
  const width = 1920 - margin * 2 - config.paper.foldWidth;
  return <AbsoluteFill>
    <ProductScene config={config} timing={{id: 'environment', from: 0, durationInFrames}} />
    <Paper config={config} box={{x: margin, y: margin, width, height: 1080 - margin * 2}}
      style={{transform: `translateX(${-reveal * 2100}px)`}}>
      <div style={{position: 'absolute', left: 76, top: 64}}>
        <SourceImage {...config.media.logo} width={242} height={98} />
      </div>
      <div style={{
        position: 'absolute', left: 76, top: 272, width: config.paper.titleWidth,
        fontSize: config.brand.typography.headingSize,
        lineHeight: config.brand.typography.headingLineHeight,
        letterSpacing: config.brand.typography.headingTracking,
      }}>{config.copy.opening}</div>
      <div style={{
        position: 'absolute', left: 80, bottom: 136, width: config.paper.titleWidth * 0.7,
        fontSize: config.brand.typography.bodySize,
        lineHeight: config.brand.typography.bodyLineHeight,
        letterSpacing: config.brand.typography.bodyTracking,
      }}>{config.copy.benefit}</div>
      <div style={{
        position: 'absolute', left: 80, bottom: 48, fontSize: config.paper.labelSize,
        color: config.brand.colors.secondaryInk,
      }}>{config.paper.labels.opening}</div>
      <div style={{
        position: 'absolute', left: width - 344, top: 0, bottom: 0, width: 344,
        borderLeft: '1px solid rgba(25,25,25,0.09)',
        background: `linear-gradient(90deg, ${config.brand.colors.mediaMat}, ${config.brand.colors.canvas} 12%)`,
      }}>
        <div style={{
          position: 'absolute', left: 40, top: 68, fontSize: config.paper.labelSize,
        }}>{config.copy.featureName}</div>
        <div style={{
          position: 'absolute', left: 0, right: 0, bottom: 86, height: 162,
          background: config.brand.colors.white,
          boxShadow: `0 12px 18px rgba(25,25,25,${config.paper.shadowStrength})`,
          display: 'flex', alignItems: 'center', paddingLeft: 40,
          fontSize: 28, fontFamily: config.brand.typography.monoFamily,
        }}>01 / 07</div>
      </div>
      <Fold config={config} height={1080 - margin * 2} lift={Math.sin(reveal * Math.PI)} />
    </Paper>
  </AbsoluteFill>;
};

const Closing = ({config, durationInFrames}: {config: PaperConfig; durationInFrames: number}) => {
  const frame = useCurrentFrame();
  const {margin, gutter} = config.layout;
  const {colors, typography} = config.brand;
  const imageWidth = config.paper.closingImageWidth;
  const copyX = margin + imageWidth + gutter * 3;
  const copyWidth = 1920 - copyX - margin * 2;
  const reveal = easeInOut(progress(frame, 0, Math.min(config.motion.sleeveFrames, durationInFrames / 4)));
  return <AbsoluteFill>
    <Paper config={config} box={{x: margin, y: margin, width: 1920 - 2 * margin - config.paper.foldWidth, height: 1080 - 2 * margin}}>
      <div style={{position: 'absolute', left: 64, top: 50}}>
        <SourceImage {...config.media.logo} width={228} height={92} />
      </div>
      <div style={{position: 'absolute', right: 70, top: 80, fontSize: config.paper.labelSize}}>
        {config.copy.featureName}
      </div>
    </Paper>
    <Paper config={config} box={{x: margin + 42, y: 320, width: imageWidth, height: imageWidth / 1.83 + 100}} layers={2}>
      <div style={{position: 'absolute', top: 18, left: 18}}>
        <SourceImage {...config.media.iphone[1]} width={imageWidth - 36} height={(imageWidth - 36) / 1.83} />
      </div>
      <div style={{
        position: 'absolute', bottom: 24, left: 26, fontSize: 22,
        color: colors.secondaryInk,
      }}>{config.paper.labels.closing}</div>
    </Paper>
    <div style={{position: 'absolute', left: copyX, top: 294, width: copyWidth}}>
      <div style={{
        fontSize: typography.headingSize * 0.48,
        lineHeight: typography.headingLineHeight * 1.08,
        letterSpacing: typography.headingTracking,
      }}>{config.copy.closing}</div>
      <div style={{height: 1, background: colors.ink, opacity: 0.18, margin: '44px 0'}} />
      <div style={{
        fontSize: typography.bodySize, lineHeight: typography.bodyLineHeight,
        letterSpacing: typography.bodyTracking,
      }}>{config.copy.cta}</div>
      <div style={{fontSize: 28, marginTop: 32, color: colors.secondaryInk}}>{config.copy.url}</div>
    </div>
    <div style={{position: 'absolute', left: margin + 66, bottom: 82, fontSize: 26, fontFamily: typography.monoFamily}}>
      07 / 07
    </div>
    <div style={{position: 'absolute', left: copyX - gutter, top: margin, bottom: margin, width: 1, background: 'rgba(25,25,25,0.07)'}} />
    <div style={{position: 'absolute', inset: margin, overflow: 'hidden', pointerEvents: 'none'}}>
      <Sleeve config={config} width={1920 - margin * 2} height={1080 - margin * 2} amount={reveal} axis="y" />
    </div>
  </AbsoluteFill>;
};

export const Template = ({config}: {config: PaperConfig}) => {
  const {fps} = useVideoConfig();
  const timeline = makeTimeline(config.durations, fps);
  return <AbsoluteFill style={{
    background: config.brand.colors.mediaMat, color: config.brand.colors.ink,
    fontFamily: config.brand.typography.fontFamily, fontWeight: 400,
    overflow: 'hidden',
  }}>
    {timeline.map((timing) => <Sequence key={timing.id} from={timing.from} durationInFrames={timing.durationInFrames}>
      {timing.id === 'opening' ? <Opening config={config} durationInFrames={timing.durationInFrames} /> :
        timing.id === 'closing' ? <Closing config={config} durationInFrames={timing.durationInFrames} /> :
          <ProductScene config={config} timing={timing} />}
    </Sequence>)}
  </AbsoluteFill>;
};
