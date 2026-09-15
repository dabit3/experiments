import {useMemo, type CSSProperties, type ReactNode} from 'react';
import {AbsoluteFill, Sequence, useCurrentFrame, useVideoConfig} from 'remotion';
import {
  SourceImage, SourceVideo, easeInOut, makeTimeline, mix, progress,
  type ImageSelection, type SceneId, type SceneTiming,
} from '../../shared';
import type {KineticConfig} from './config';
import {boundedFrames, fitPhrase, iphoneCut, type PhraseLayout} from './phrase';

type Props = {config: KineticConfig};
type DemoId = Exclude<SceneId, 'opening' | 'closing'>;

const usePhrase = (
  text: string, width: number, maxSize: number, minSize: number,
  maxLines: number, config: KineticConfig,
): PhraseLayout => {
  const {fontFamily, headingTracking} = config.brand.typography;
  return useMemo(() => {
    const context = document.createElement('canvas').getContext('2d');
    if (!context) throw new Error('Canvas text metrics are unavailable');
    const tracking = headingTracking.endsWith('em') ? Number.parseFloat(headingTracking) : 0;
    return fitPhrase(text, width, maxSize, minSize, maxLines, (value, size) => {
      context.font = `400 ${size}px "${fontFamily}"`;
      return context.measureText(value).width + Math.max(0, value.length - 1) * tracking * size;
    });
  }, [text, width, maxSize, minSize, maxLines, fontFamily, headingTracking]);
};

const Text = ({
  layout, config, style,
}: Props & {layout: PhraseLayout; style?: CSSProperties}) =>
  <div style={{
    fontSize: layout.fontSize,
    lineHeight: config.brand.typography.headingLineHeight,
    letterSpacing: config.brand.typography.headingTracking,
    fontWeight: 400,
    ...style,
  }}>
    {layout.lines.map((line, index) => <div key={index} style={{whiteSpace: 'pre'}}>{line}</div>)}
  </div>;

export const Transition = ({
  children, amount, travel,
}: {children: ReactNode; amount: number; travel: number}) =>
  <div style={{overflow: 'hidden', paddingBottom: 8}}>
    <div style={{transform: `translateY(${(1 - amount) * travel}px)`}}>{children}</div>
  </div>;

const Logo = ({config, width = 190}: Props & {width?: number}) =>
  <SourceImage {...config.media.logo} width={width} height={width / 2.914} />;

const Eyebrow = ({config, left, right}: Props & {left: string; right: string}) =>
  <div style={{
    position: 'absolute', left: config.layout.margin, right: config.layout.margin,
    top: 22, height: config.layout.grid.labelHeight,
    display: 'flex', alignItems: 'center', justifyContent: 'space-between',
    fontSize: config.typography.labelSize,
    color: config.brand.colors.secondaryInk,
    letterSpacing: config.brand.typography.bodyTracking,
  }}>
    <span>{left}</span><span>{right}</span>
  </div>;

export const Title = ({config, duration}: Props & {duration: number}) => {
  const frame = useCurrentFrame();
  const {width, height} = useVideoConfig();
  const {margin, gutter} = config.layout;
  const titleWidth = Math.min(width - 2 * margin, config.layout.grid.titleWidth);
  const title = usePhrase(config.copy.opening, titleWidth, config.typography.titleSize,
    config.typography.titleMinSize, config.typography.titleMaxLines, config);
  const benefit = usePhrase(config.copy.benefit, width - 2 * margin,
    config.brand.typography.bodySize + 8, 28, 2, config);
  const entrance = easeInOut(progress(frame + 8, 0,
    boundedFrames(config.motion.titleRevealFrames, duration)));
  const lift = easeInOut(progress(frame, duration - boundedFrames(config.motion.phraseDockFrames, duration),
    boundedFrames(config.motion.phraseDockFrames, duration)));
  const titleHeight = title.lines.length * title.fontSize * config.brand.typography.headingLineHeight;
  const titleTop = Math.max(200, (height - titleHeight) / 2 - 36);
  return <AbsoluteFill>
    <div style={{position: 'absolute', left: margin, top: 52}}><Logo config={config} width={220} /></div>
    <div style={{
      position: 'absolute', right: margin, top: 73,
      fontSize: config.typography.labelSize,
      color: config.brand.colors.secondaryInk,
    }}>{config.copy.featureName}</div>
    <div style={{
      position: 'absolute', left: margin, top: titleTop - lift * config.motion.titleLift,
      width: titleWidth,
    }}>
      <Transition amount={entrance} travel={config.motion.titleTravel}>
        <Text layout={title} config={config} />
      </Transition>
    </div>
    <div style={{
      position: 'absolute', left: margin, top: height - 220,
      width: mix(title.width, width - margin * 2, lift),
      height: config.motion.ruleThickness, background: config.brand.colors.ink,
    }} />
    <div style={{position: 'absolute', left: margin, top: height - 180, right: margin}}>
      <Text layout={benefit} config={config} />
      <div style={{
        marginTop: gutter, fontSize: config.typography.labelSize,
        color: config.brand.colors.secondaryInk,
      }}>Simulator workflows · separate session examples</div>
    </div>
  </AbsoluteFill>;
};

export const Caption = ({
  config, text, amount, isVideo, headerBottom,
}: Props & {text: string; amount: number; isVideo: boolean; headerBottom: number}) => {
  const {width} = useVideoConfig();
  const available = width - 2 * config.layout.margin;
  const large = usePhrase(text, available - config.motion.phraseTravel,
    config.typography.phraseSize, config.typography.captionMinSize, 1, config);
  const small = usePhrase(text, available, config.typography.captionSize,
    config.typography.captionMinSize, 1, config);
  const size = mix(isVideo ? Math.min(large.fontSize, small.fontSize * 1.18) : large.fontSize,
    small.fontSize, amount);
  const fontHeight = size * config.brand.typography.headingLineHeight;
  return <>
    <div style={{
      position: 'absolute', left: config.layout.margin, right: config.layout.margin,
      top: 62, height: headerBottom - 70, overflow: 'hidden',
    }}>
      <Text layout={{...small, fontSize: size}} config={config} style={{
        position: 'absolute',
        top: Math.max(0, (headerBottom - 70 - fontHeight) / 2),
        transform: `translateX(${(1 - amount) * config.motion.phraseTravel}px)`,
      }} />
    </div>
    <div style={{
      position: 'absolute', left: config.layout.margin, top: headerBottom,
      width: mix(Math.min(available, large.width), available, amount),
      height: config.motion.ruleThickness, background: config.brand.colors.ink,
    }} />
  </>;
};

const Still = ({
  config, selection, width, height,
}: Props & {selection: ImageSelection; width: number; height: number}) =>
  <SourceImage {...selection} width={width} height={height}
    style={{backgroundColor: config.brand.colors.mediaMat}} />;

export const Demo = ({
  config, scene,
}: Props & {scene: SceneTiming & {id: DemoId}}) => {
  const frame = useCurrentFrame();
  const {width, height} = useVideoConfig();
  const {margin, padding, gutter, captionHeight} = config.layout;
  const isVideo = scene.id === 'agent' || scene.id === 'webQa';
  const amount = easeInOut(progress(frame, 0, boundedFrames(config.motion.phraseDockFrames, scene.durationInFrames)));
  const dockHeight = captionHeight + config.layout.grid.labelHeight;
  const headerBottom = isVideo ? dockHeight : mix(config.layout.grid.launchHeaderHeight, dockHeight, amount);
  const mediaTop = headerBottom + gutter / 2;
  const mediaWidth = width - 2 * margin - 2 * padding;
  const mediaHeight = height - mediaTop - margin - 2 * padding;
  const cut = iphoneCut(scene.durationInFrames, config.motion.iphoneSplit);
  const iphoneIndex = frame < cut ? 0 : 1;
  const label = scene.id === 'iphone' ? config.labels.iphone[iphoneIndex] : config.labels[scene.id];
  const index = ['environment', 'agent', 'iphone', 'webQa', 'ipad'].indexOf(scene.id) + 1;
  let source: ReactNode;
  if (scene.id === 'agent' || scene.id === 'webQa') {
    source = <SourceVideo {...config.media[scene.id]} width={mediaWidth} height={mediaHeight}
      durationInFrames={scene.durationInFrames}
      labelStyle={{fontSize: 28, backgroundColor: config.brand.colors.ink,
        color: config.brand.colors.white, fontFamily: config.brand.typography.fontFamily}} />;
  } else {
    const selection = scene.id === 'iphone' ? config.media.iphone[iphoneIndex] : config.media[scene.id];
    source = <Still selection={selection} width={mediaWidth} height={mediaHeight} config={config} />;
  }
  return <AbsoluteFill>
    <Eyebrow config={config} left={`${config.copy.featureName} / ${String(index).padStart(2, '0')}`}
      right={label} />
    <Caption config={config} text={config.copy[scene.id]} amount={amount}
      isVideo={isVideo} headerBottom={headerBottom} />
    <div style={{
      position: 'absolute', left: margin, top: mediaTop,
      padding, backgroundColor: config.brand.colors.mediaMat,
      width: width - margin * 2, height: height - mediaTop - margin,
      boxSizing: 'border-box',
    }}>{source}</div>
  </AbsoluteFill>;
};

export const EndCard = ({config, duration}: Props & {duration: number}) => {
  const frame = useCurrentFrame();
  const {width, height} = useVideoConfig();
  const {margin, gutter, grid} = config.layout;
  const available = width - 2 * margin;
  const title = usePhrase(config.copy.featureName, available, config.typography.titleSize,
    config.typography.titleMinSize, 2, config);
  const pricing = usePhrase(config.copy.closing, available, config.typography.captionSize,
    config.typography.captionMinSize, 2, config);
  const cta = usePhrase(config.copy.cta, available - 180, config.typography.captionSize,
    config.typography.captionMinSize, 2, config);
  const url = usePhrase(config.copy.url, available - 80, config.brand.typography.bodySize, 24, 1, config);
  const reveal = easeInOut(progress(frame + 5, 0, boundedFrames(config.motion.endCardRevealFrames, duration)));
  const titleHeight = title.lines.length * title.fontSize * config.brand.typography.headingLineHeight;
  const pricingHeight = pricing.lines.length * pricing.fontSize * config.brand.typography.headingLineHeight;
  const cardHeight = Math.max(grid.endCardHeight, 80 + gutter +
    (cta.lines.length * cta.fontSize + url.fontSize) * config.brand.typography.headingLineHeight);
  const titleTop = Math.max(160, Math.min(450 - titleHeight / 2,
    height - margin - cardHeight - titleHeight - pricingHeight - gutter * 3 - config.brand.spacing.titleGap));
  return <AbsoluteFill>
    <div style={{position: 'absolute', top: 52, left: margin}}><Logo config={config} width={220} /></div>
    <div style={{position: 'absolute', left: margin, top: titleTop, width: available}}>
      <Transition amount={reveal} travel={config.motion.titleTravel}>
        <Text config={config} layout={title} />
      </Transition>
      <div style={{
        marginTop: config.brand.spacing.titleGap + gutter,
        transform: `translateX(${(1 - reveal) * config.motion.titleLift}px)`,
      }}><Text config={config} layout={pricing} /></div>
    </div>
    <div style={{
      position: 'absolute', left: margin, right: margin, bottom: margin,
      height: cardHeight, backgroundColor: config.brand.colors.ink,
      color: config.brand.colors.white, padding: 40, boxSizing: 'border-box',
      clipPath: `inset(0 ${(1 - reveal) * 12}% 0 0)`,
    }}>
      <Text config={config} layout={cta} />
      <div style={{marginTop: gutter}}><Text config={config} layout={url} /></div>
      <span style={{position: 'absolute', right: 40, top: 44, fontSize: 60}}>↗</span>
    </div>
  </AbsoluteFill>;
};

export const Template = ({config}: Props) => {
  const {fps} = useVideoConfig();
  const timeline = makeTimeline(config.durations, fps);
  return <AbsoluteFill style={{
    backgroundColor: config.brand.colors.canvas, color: config.brand.colors.ink,
    fontFamily: config.brand.typography.fontFamily, fontWeight: 400,
  }}>
    {timeline.map((scene) => <Sequence key={scene.id} from={scene.from}
      durationInFrames={scene.durationInFrames}>
      {scene.id === 'opening' ? <Title config={config} duration={scene.durationInFrames} /> :
        scene.id === 'closing' ? <EndCard config={config} duration={scene.durationInFrames} /> :
          <Demo config={config} scene={{...scene, id: scene.id}} />}
    </Sequence>)}
  </AbsoluteFill>;
};
