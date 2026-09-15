import type {CSSProperties, ReactNode} from 'react';
import {AbsoluteFill, Sequence, useCurrentFrame, useVideoConfig} from 'remotion';
import {
  SourceImage, SourceVideo, contain, easeInOut, makeTimeline, mix, progress,
  type ImageSelection, type SceneTiming, type VideoSelection,
} from '../../shared';
import type {DiptychConfig, Pairing} from './config';

const rule = (config: DiptychConfig): string => `1px solid ${config.brand.colors.ink}30`;
const animate = (frame: number, from: number, duration: number): number =>
  easeInOut(progress(frame, from, duration));

const Label = ({children, config, style}: {
  children: ReactNode; config: DiptychConfig; style?: CSSProperties;
}) => <div style={{
  fontSize: config.brand.typography.bodySize * 0.67,
  lineHeight: config.brand.typography.bodyLineHeight * 0.893,
  letterSpacing: config.brand.typography.bodyTracking,
  ...style,
}}>{children}</div>;

const Logo = ({config, width = 174}: {config: DiptychConfig; width?: number}) =>
  <SourceImage {...config.media.logo} width={width} height={width * 0.344} />;

const Frame = ({config, caption, index, note, children}: {
  config: DiptychConfig; caption: string; index: string; note: string; children: ReactNode;
}) => {
  const {width, height} = useVideoConfig();
  const {margin, captionHeight, grid} = config.layout;
  return <>
    <div style={{position: 'absolute', top: 44, left: margin, width: width - margin * 2 - 205}}>
      <div style={{
        fontSize: config.brand.typography.headingSize * 0.62,
        lineHeight: config.brand.typography.headingLineHeight * 1.08,
        letterSpacing: config.brand.typography.headingTracking,
      }}>{caption}</div>
    </div>
    <div style={{position: 'absolute', top: 48, right: margin}}><Logo config={config} /></div>
    <div style={{
      position: 'absolute', left: margin, right: margin, top: margin + captionHeight,
      bottom: margin + grid.footerHeight,
    }}>{children}</div>
    <div style={{
      position: 'absolute', left: margin, right: margin, top: height - margin - 16,
      display: 'flex', alignItems: 'center', justifyContent: 'space-between',
    }}>
      <Label config={config}>{index} / {config.copy.featureName}</Label>
      <Label config={config} style={{color: config.brand.colors.secondaryInk}}>{note}</Label>
    </div>
  </>;
};

const Panel = ({config, label, width, height, children}: {
  config: DiptychConfig; label: string; width: number; height: number; children: ReactNode;
}) => <div style={{width, height, position: 'relative'}}>
  <Label config={config} style={{
    height: config.layout.grid.panelLabelHeight, display: 'flex', alignItems: 'flex-start',
  }}>{label}</Label>
  <div style={{
    position: 'absolute', top: config.layout.grid.panelLabelHeight,
    bottom: 0, width, background: config.brand.colors.mediaMat, overflow: 'hidden',
    display: 'flex', alignItems: 'center', justifyContent: 'center',
  }}>{children}</div>
</div>;

const ImagePair = ({config, media, pair, duration}: {
  config: DiptychConfig; media: ImageSelection; pair: Pairing; duration: number;
}) => {
  const frame = useCurrentFrame();
  const {width, height} = useVideoConfig();
  const {margin, gutter, padding, captionHeight, grid} = config.layout;
  const w = width - margin * 2;
  const h = height - margin * 2 - captionHeight - grid.footerHeight;
  const imageH = h - grid.panelLabelHeight - padding * 2;
  const movement = Math.min(config.motion.dividerFrames, duration * 0.07);
  const active = animate(frame, duration * config.motion.activeAt, movement);
  const balanced = animate(frame, duration * config.motion.balancedAt, movement);
  const unified = animate(frame, duration * config.motion.unifyAt, movement);
  const ratio = mix(mix(pair.balancedRatio, pair.activeRatio, active), pair.balancedRatio, balanced);
  const leftW = (w - gutter) * ratio;
  const rightW = w - gutter - leftW;
  return <>
    <div style={{display: 'flex', gap: gutter, opacity: 1 - unified}}>
      <Panel config={config} label={pair.leftLabel} width={leftW} height={h}>
        <SourceImage {...media} framing={{...media.framing, crop: pair.leftCrop}}
          width={leftW - padding * 2} height={imageH} />
      </Panel>
      <Panel config={config} label={pair.rightLabel} width={rightW} height={h}>
        <SourceImage {...media}
          framing={pair.rightCrop ? {...media.framing, crop: pair.rightCrop} : media.framing}
          width={rightW - padding * 2} height={imageH} />
      </Panel>
    </div>
    <div style={{
      position: 'absolute', top: grid.panelLabelHeight, bottom: 0,
      left: leftW + gutter / 2, width: config.motion.dividerWidth,
      background: config.brand.colors.ink, opacity: 1 - unified,
    }} />
    <div style={{position: 'absolute', inset: 0, opacity: unified}}>
      <Panel config={config} label={`${config.labels.source} / ${pair.note}`} width={w} height={h}>
        <SourceImage {...media} width={w - padding * 2} height={imageH} />
      </Panel>
    </div>
  </>;
};

const VideoPair = ({config, media, duration, webQa}: {
  config: DiptychConfig; media: VideoSelection; duration: number; webQa: boolean;
}) => {
  const frame = useCurrentFrame();
  const {width, height} = useVideoConfig();
  const {margin, gutter, captionHeight, grid, padding} = config.layout;
  const w = width - margin * 2;
  const h = height - margin * 2 - captionHeight - grid.footerHeight;
  const railW = (w - gutter) * config.motion.videoRailRatio;
  const videoW = w - railW - gutter;
  const reveal = animate(frame, 0, config.motion.shutterFrames);
  return <div style={{display: 'flex', gap: gutter, height: h}}>
    <div style={{width: railW, paddingTop: grid.panelLabelHeight, position: 'relative'}}>
      <div style={{height: 2, width: mix(0, railW - 32, reveal), background: config.brand.colors.ink}} />
      <div style={{
        paddingTop: 28, fontSize: config.brand.typography.bodySize * 1.15,
        lineHeight: config.brand.typography.headingLineHeight * 1.05,
        letterSpacing: config.brand.typography.headingTracking,
      }}>{webQa ? config.labels.qaAction : config.labels.agentAction}</div>
      <div style={{height: 52, width: 2, background: config.brand.colors.ink, margin: '26px 0'}} />
      <div style={{fontSize: config.brand.typography.bodySize * 1.15,
        lineHeight: config.brand.typography.headingLineHeight * 1.05}}>
        {webQa ? config.labels.qaObservation : config.labels.agentObservation}
      </div>
      <Label config={config} style={{position: 'absolute', bottom: 24, width: railW - 20}}>
        {config.labels.playback}
      </Label>
    </div>
    <Panel config={config} label={webQa ? config.labels.qaPair : config.labels.agentPair}
      width={videoW} height={h}>
      <SourceVideo {...media} width={videoW - padding * 2}
        height={h - grid.panelLabelHeight - padding * 2} durationInFrames={duration}
        labelStyle={{fontFamily: config.brand.typography.fontFamily, fontSize: 28}} />
    </Panel>
    <div style={{
      position: 'absolute', left: railW + gutter / 2, top: grid.panelLabelHeight,
      bottom: 0, width: config.motion.dividerWidth, background: config.brand.colors.ink,
    }} />
  </div>;
};

const Opening = ({config}: {config: DiptychConfig}) => {
  const frame = useCurrentFrame();
  const {width, height} = useVideoConfig();
  const {margin, gutter} = config.layout;
  const divider = width * config.motion.openingSplit;
  const open = animate(frame, 4, config.motion.dividerFrames * 2);
  return <>
    <div style={{position: 'absolute', left: margin, top: margin}}><Logo config={config} width={270} /></div>
    <Label config={config} style={{position: 'absolute', right: margin, top: margin + 16}}>{config.labels.edition}</Label>
    <div style={{
      position: 'absolute', left: divider, top: margin + 172, bottom: margin + 72,
      width: config.motion.dividerWidth, background: config.brand.colors.ink,
      transform: `scaleY(${open})`, transformOrigin: 'center',
    }} />
    <div style={{
      position: 'absolute', left: margin, top: height * 0.35,
      width: divider - margin - gutter * 3,
      fontSize: config.brand.typography.headingSize * 1.45,
      lineHeight: config.brand.typography.headingLineHeight,
      letterSpacing: config.brand.typography.headingTracking,
      clipPath: `inset(0 ${100 * (1 - open)}% 0 0)`,
    }}>{config.copy.opening}</div>
    <div style={{
      position: 'absolute', left: divider + gutter * 3, right: margin,
      top: height * 0.36, opacity: open,
    }}>
      <Label config={config} style={{marginBottom: config.brand.spacing.titleGap}}>{config.copy.featureName}</Label>
      <div style={{
        fontSize: config.brand.typography.headingSize * 0.69,
        lineHeight: config.brand.typography.headingLineHeight * 1.08,
        letterSpacing: config.brand.typography.headingTracking,
      }}>{config.copy.benefit}</div>
    </div>
    <Label config={config} style={{position: 'absolute', bottom: margin, left: margin}}>
      {config.labels.montage}
    </Label>
  </>;
};

const Closing = ({config, duration}: {config: DiptychConfig; duration: number}) => {
  const frame = useCurrentFrame();
  const {width, height} = useVideoConfig();
  const {margin, gutter} = config.layout;
  const cta = animate(frame, duration * config.motion.closingCtaAt, config.motion.dividerFrames);
  const divider = width * config.motion.openingSplit;
  return <>
    <div style={{position: 'absolute', inset: 0, opacity: 1 - cta, background: config.brand.colors.white}}>
      <SourceImage {...config.media.ipad} framing={contain} width={width} height={height} />
    </div>
    <AbsoluteFill style={{
      background: config.brand.colors.canvas,
      clipPath: `inset(0 ${100 * (1 - cta)}% 0 0)`,
    }}>
      <div style={{position: 'absolute', left: margin, top: margin}}><Logo config={config} width={270} /></div>
      <Label config={config} style={{position: 'absolute', right: margin, top: margin + 16}}>{config.labels.next}</Label>
      <div style={{
        position: 'absolute', left: margin, top: height * 0.36,
        width: divider - margin - gutter * 3,
        fontSize: config.brand.typography.headingSize,
        lineHeight: config.brand.typography.headingLineHeight * 1.04,
        letterSpacing: config.brand.typography.headingTracking,
      }}>{config.copy.closing}</div>
      <div style={{
        position: 'absolute', left: divider, top: 242, bottom: 152,
        width: config.motion.dividerWidth, background: config.brand.colors.ink,
      }} />
      <div style={{position: 'absolute', top: height * 0.37, left: divider + gutter * 3, right: margin}}>
        <div style={{fontSize: config.brand.typography.headingSize * 0.68,
          lineHeight: config.brand.typography.headingLineHeight * 1.05,
          letterSpacing: config.brand.typography.headingTracking}}>{config.copy.cta}</div>
        <div style={{
          marginTop: 48, padding: '18px 22px', background: config.brand.colors.ink,
          color: config.brand.colors.white, fontSize: config.brand.typography.bodySize,
          borderRadius: 2, display: 'inline-block',
        }}>{config.copy.url}</div>
      </div>
      <div style={{position: 'absolute', bottom: margin, left: margin, right: margin, borderTop: rule(config), paddingTop: 24}}>
        <Label config={config}>{config.copy.featureName}</Label>
      </div>
    </AbsoluteFill>
  </>;
};

const ProductScene = ({config, scene}: {config: DiptychConfig; scene: SceneTiming}) => {
  const split = Math.max(1, Math.min(scene.durationInFrames - 1,
    Math.round(scene.durationInFrames * config.motion.iphoneSwitchAt)));
  switch (scene.id) {
    case 'environment':
      return <Frame config={config} caption={config.copy.environment} index="01" note={config.pairings.environment.note}>
        <ImagePair config={config} media={config.media.environment} pair={config.pairings.environment} duration={scene.durationInFrames} />
      </Frame>;
    case 'agent':
      return <Frame config={config} caption={config.copy.agent} index="02" note={config.labels.playback}>
        <VideoPair config={config} media={config.media.agent} duration={scene.durationInFrames} webQa={false} />
      </Frame>;
    case 'iphone':
      return <Frame config={config} caption={config.copy.iphone} index="03" note={config.labels.iphoneNote}>
        <Sequence durationInFrames={split} layout="none">
          <ImagePair config={config} media={config.media.iphone[0]} pair={config.pairings.iphone[0]} duration={split} />
        </Sequence>
        <Sequence from={split} durationInFrames={scene.durationInFrames - split} layout="none">
          <ImagePair config={config} media={config.media.iphone[1]} pair={config.pairings.iphone[1]} duration={scene.durationInFrames - split} />
        </Sequence>
      </Frame>;
    case 'webQa':
      return <Frame config={config} caption={config.copy.webQa} index="04" note={config.labels.qaNote}>
        <VideoPair config={config} media={config.media.webQa} duration={scene.durationInFrames} webQa />
      </Frame>;
    case 'ipad':
      return <Frame config={config} caption={config.copy.ipad} index="05" note={config.pairings.ipad.note}>
        <ImagePair config={config} media={config.media.ipad} pair={config.pairings.ipad} duration={scene.durationInFrames} />
      </Frame>;
    case 'opening':
      return <Opening config={config} />;
    case 'closing':
      return <Closing config={config} duration={scene.durationInFrames} />;
  }
};

export const Template = ({config}: {config: DiptychConfig}) => {
  const {fps} = useVideoConfig();
  if (Math.round(config.durations.iphone * fps) < 2) {
    throw new Error('The iPhone scene needs at least two frames for its two source stills.');
  }
  const {activeAt, balancedAt, unifyAt} = config.motion;
  if (!(0 <= activeAt && activeAt < balancedAt && balancedAt < unifyAt && unifyAt < 1)) {
    throw new Error('Still synchronization cues must satisfy 0 <= activeAt < balancedAt < unifyAt < 1.');
  }
  return <AbsoluteFill style={{
    background: config.brand.colors.canvas, color: config.brand.colors.ink,
    fontFamily: config.brand.typography.fontFamily, fontWeight: 400,
    WebkitFontSmoothing: 'antialiased',
  }}>
    {makeTimeline(config.durations, fps).map((scene) =>
      <Sequence key={scene.id} from={scene.from} durationInFrames={scene.durationInFrames}>
        <ProductScene config={config} scene={scene} />
      </Sequence>)}
  </AbsoluteFill>;
};
