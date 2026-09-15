import type {CSSProperties, ReactNode} from 'react';
import {AbsoluteFill, Sequence, useCurrentFrame, useVideoConfig} from 'remotion';
import {
  assets, easeInOut, makeTimeline, progress, SourceImage, SourceVideo,
  type ImageSelection, type SceneTiming, type VideoSelection,
} from '../../shared';
import type {NoirConfig} from './config';
import {boundedTransition, openingAmount, shutterClip, splitStillFrames} from './motion';

type Props = {config: NoirConfig};
type ProductScene = Exclude<SceneTiming['id'], 'opening' | 'closing'>;

const headline = (config: NoirConfig): CSSProperties => ({
  fontWeight: 400,
  fontSize: config.brand.typography.headingSize,
  lineHeight: config.brand.typography.headingLineHeight,
  letterSpacing: config.brand.typography.headingTracking,
});

const ExteriorLight = ({
  config, width, height, amount,
}: Props & {width: number; height: number; amount: number}) => {
  const {lightingEnabled, edgeLightLength, edgeLightOpacity, edgeLightTravel} = config.motion;
  if (!lightingEnabled) return null;
  const offset = config.layout.padding;
  const top = Math.min(height - edgeLightLength, 70 + amount * edgeLightTravel);
  return <>
    <div style={{
      position: 'absolute', inset: -offset,
      border: `1px solid ${config.brand.colors.white}`,
      opacity: 0.1, pointerEvents: 'none',
    }} />
    <div style={{
      position: 'absolute', left: -offset - 1, top,
      width: 2, height: edgeLightLength,
      background: config.brand.colors.white, opacity: edgeLightOpacity,
    }} />
    <div style={{
      position: 'absolute', left: width - edgeLightLength, top: -offset - 1,
      height: 2, width: edgeLightLength,
      background: config.brand.colors.white, opacity: edgeLightOpacity,
    }} />
  </>;
};

const Aperture = ({
  config, width, height, amount, children,
}: Props & {width: number; height: number; amount: number; children: ReactNode}) =>
  <div style={{width, height, position: 'relative'}}>
    <ExteriorLight {...{config, width, height, amount}} />
    <div style={{
      width, height,
      clipPath: shutterClip(amount, width, height, config.motion),
    }}>
      {children}
    </div>
  </div>;

const Pane = ({
  config, selection, duration, amount = 1,
}: Props & {
  selection: ImageSelection | VideoSelection;
  duration?: number;
  amount?: number;
}) => {
  const {width, height} = useVideoConfig();
  const {margin, captionHeight, gutter} = config.layout;
  const top = margin + captionHeight;
  const maxHeight = height - top - margin - gutter / 2;
  const maxWidth = width - margin * 2;
  const source = selection.framing.crop ?? assets[selection.asset];
  const isVideo = 'sourceStartSeconds' in selection;
  const labelHeight = selection.asset === 'devin-testing-2.mp4' ? 44 : 0;
  const paneWidth = Math.min(maxWidth, (maxHeight - labelHeight) * source.width / source.height);
  const paneHeight = paneWidth * source.height / source.width + labelHeight;
  return <div style={{
    position: 'absolute', left: (width - paneWidth) / 2,
    top: top + (maxHeight - paneHeight) / 2,
  }}>
    <Aperture {...{config, amount}} width={paneWidth} height={paneHeight}>
      {isVideo ? <SourceVideo
        {...selection}
        width={paneWidth} height={paneHeight} durationInFrames={duration ?? 1}
        labelHeight={labelHeight}
        labelStyle={{
          backgroundColor: config.brand.colors.ink,
          color: config.brand.colors.white,
          fontFamily: config.brand.typography.fontFamily,
          fontSize: 26, padding: 0,
          letterSpacing: config.brand.typography.bodyTracking,
        }}
      /> : <SourceImage {...selection} width={paneWidth} height={paneHeight} />}
    </Aperture>
  </div>;
};

const Header = ({
  config, caption, index,
}: Props & {caption: string; index: string}) => {
  const {margin, grid} = config.layout;
  return <>
    <div style={{
      position: 'absolute', left: margin, right: margin + 220, top: margin - 15,
      fontSize: grid.captionSize, lineHeight: 1.2,
      letterSpacing: config.brand.typography.headingTracking,
    }}>{caption}</div>
    <div style={{
      position: 'absolute', right: margin, top: margin - 7,
      display: 'flex', alignItems: 'center', gap: 22,
      fontSize: grid.footerSize,
    }}>
      <span style={{opacity: 0.55}}>{config.copy.featureName}</span>
      <span style={{fontFamily: config.brand.typography.monoFamily}}>{index}</span>
    </div>
  </>;
};

const Footnote = ({config, text}: Props & {text: string}) =>
  <div style={{
    position: 'absolute', left: config.layout.margin, right: config.layout.margin,
    bottom: 20, display: 'flex', justifyContent: 'space-between',
    fontSize: config.layout.grid.footerSize, color: config.brand.colors.white,
  }}>
    <span style={{opacity: 0.65}}>{config.labels.montage}</span>
    <span style={{opacity: 0.65}}>{text}</span>
  </div>;

const QuietTitle = ({
  config, title, supporting, closing = false,
}: Props & {title: string; supporting?: string; closing?: boolean}) => {
  const frame = useCurrentFrame();
  const {durationInFrames} = useVideoConfig();
  const {margin, grid} = config.layout;
  const enter = openingAmount(frame + 1, boundedTransition(config.motion.titleFadeFrames, durationInFrames));
  const line = easeInOut(progress(frame, 4, config.motion.shutterFrames * 2));
  return <AbsoluteFill>
    <div style={{position: 'absolute', left: margin, top: margin - 8}}>
      <SourceImage {...config.media.logo} width={grid.logoWidth} height={grid.logoWidth * 1024 / 2984} />
    </div>
    <div style={{
      position: 'absolute', right: margin, top: margin + 12,
      fontSize: 26, opacity: 0.65,
    }}>{config.copy.featureName}</div>
    <div style={{
      position: 'absolute', top: grid.titleTop, left: grid.titleLeft,
      width: grid.titleWidth, opacity: enter,
    }}>
      <div style={headline(config)}>{title}</div>
      {supporting ? <div style={{
        marginTop: config.brand.spacing.titleGap,
        maxWidth: grid.benefitWidth,
        fontSize: config.brand.typography.bodySize,
        lineHeight: config.brand.typography.bodyLineHeight,
        opacity: 0.78,
      }}>{supporting}</div> : null}
    </div>
    <div style={{
      position: 'absolute', left: grid.titleLeft, right: grid.titleLeft,
      top: grid.titleLineY, height: 1, background: config.brand.colors.white,
      opacity: 0.25, transform: `scaleX(${line})`, transformOrigin: 'left',
    }} />
    <div style={{
      position: 'absolute', left: grid.titleLeft, top: grid.titleLineY + 35,
      fontSize: 30, opacity: enter,
    }}>{closing ? config.copy.url : config.labels.montage}</div>
  </AbsoluteFill>;
};

const Still = ({
  config, selection, duration, exit = false,
}: Props & {selection: ImageSelection; duration: number; exit?: boolean}) => {
  const frame = useCurrentFrame();
  const entering = openingAmount(frame, boundedTransition(config.motion.shutterFrames, duration));
  const exitFrames = boundedTransition(config.motion.stillExitFrames, duration);
  const leaving = exit && exitFrames > 0
    ? 1 - openingAmount(frame - (duration - exitFrames - 1), exitFrames)
    : 1;
  return <Pane config={config} selection={selection} amount={Math.min(entering, leaving)} />;
};

const Demonstration = ({
  config, scene,
}: Props & {scene: SceneTiming & {id: ProductScene}}) => {
  const frame = useCurrentFrame();
  const index = {environment: '01', agent: '02', iphone: '03', webQa: '04', ipad: '05'}[scene.id];
  const caption = config.copy[scene.id];
  const intertitle = scene.id === 'iphone'
    ? boundedTransition(config.motion.intertitleFrames, scene.durationInFrames) : 0;
  const split = splitStillFrames(scene.durationInFrames - intertitle, config.motion.iphoneSplit);
  const video = scene.id === 'agent' || scene.id === 'webQa';
  const secondary = video ? config.labels.recording
    : scene.id === 'environment' ? '' : config.labels.still;
  if (frame < intertitle) {
    return <QuietTitle config={config} title={caption} />;
  }
  return <AbsoluteFill>
    <Header config={config} caption={caption} index={index} />
    {scene.id === 'agent' || scene.id === 'webQa' ?
      <Pane config={config} selection={config.media[scene.id]} duration={scene.durationInFrames} /> : null}
    {scene.id === 'environment' || scene.id === 'ipad' ?
      <Still config={config} selection={config.media[scene.id]} duration={scene.durationInFrames} /> : null}
    {scene.id === 'iphone' ? <>
      <Sequence from={intertitle} durationInFrames={split}>
        <Still config={config} selection={config.media.iphone[0]} duration={split} exit />
      </Sequence>
      <Sequence from={intertitle + split} durationInFrames={scene.durationInFrames - intertitle - split}>
        <Still
          config={config} selection={config.media.iphone[1]}
          duration={scene.durationInFrames - intertitle - split}
        />
      </Sequence>
    </> : null}
    <Footnote config={config} text={secondary} />
  </AbsoluteFill>;
};

const Closing = ({config, scene}: Props & {scene: SceneTiming}) => {
  const frame = useCurrentFrame();
  const resultHold = Math.min(config.motion.resultHoldFrames, Math.floor(scene.durationInFrames / 4));
  const shutter = boundedTransition(config.motion.shutterFrames, scene.durationInFrames) / 2;
  const ctaStart = Math.min(scene.durationInFrames - 1, Math.ceil(resultHold + shutter));
  return frame < ctaStart ? <AbsoluteFill>
    <Header config={config} caption={config.copy.closing} index="06" />
    <Pane config={config} selection={config.media.ipad}
      amount={1 - openingAmount(frame - resultHold, shutter)} />
    <Footnote config={config} text={config.labels.still} />
  </AbsoluteFill> : <Sequence from={ctaStart}>
    <QuietTitle config={config} title={config.copy.cta} supporting={config.copy.closing} closing />
  </Sequence>;
};

export const Template = ({config}: Props) => {
  const {fps} = useVideoConfig();
  return <AbsoluteFill style={{
    backgroundColor: config.brand.colors.ink, color: config.brand.colors.white,
    fontFamily: config.brand.typography.fontFamily,
    fontWeight: 400, letterSpacing: config.brand.typography.bodyTracking,
  }}>
    {makeTimeline(config.durations, fps).map((scene) =>
      <Sequence key={scene.id} from={scene.from} durationInFrames={scene.durationInFrames}>
        {scene.id === 'opening' ?
          <QuietTitle config={config} title={config.copy.opening} supporting={config.copy.benefit} /> :
          scene.id === 'closing' ? <Closing config={config} scene={scene} /> :
          <Demonstration config={config} scene={{...scene, id: scene.id}} />}
      </Sequence>,
    )}
  </AbsoluteFill>;
};
