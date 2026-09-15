import {useMemo, type CSSProperties, type ReactNode} from 'react';
import {AbsoluteFill, Sequence, useCurrentFrame, useVideoConfig} from 'remotion';
import {
  SourceImage, SourceVideo, easeInOut, makeTimeline, mix, progress, rectangleReveal,
  type SceneId, type SceneTiming,
} from '../../shared';
import type {SwissConfig} from './config';

type Props = {config: SwissConfig};
type ProductSceneId = Exclude<SceneId, 'opening' | 'closing'>;

export const revealAmount = (frame: number, requestedFrames: number, sceneFrames: number) =>
  easeInOut(progress(frame, 0, Math.min(requestedFrames, Math.max(0, sceneFrames - 1))));

export const iphoneSplitFrame = (sceneFrames: number, ratio: number) =>
  Math.min(Math.max(1, Math.round(sceneFrames * ratio)), Math.max(1, sceneFrames - 1));

const labelStyle = (config: SwissConfig): CSSProperties => ({
  fontSize: config.brand.typography.bodySize * 0.52,
  letterSpacing: config.brand.typography.bodyTracking,
  lineHeight: 1.25,
});

const TypeMask = ({children, amount, travel, style}: {
  children: ReactNode; amount: number; travel: number; style?: CSSProperties;
}) => <div style={{overflow: 'hidden', ...style}}>
  <div style={{
    clipPath: rectangleReveal(amount, 'y'),
    transform: `translateY(${(1 - amount) * travel}px)`,
  }}>{children}</div>
</div>;

const Rule = ({color, ...style}: CSSProperties & {color: string}) =>
  <div style={{position: 'absolute', backgroundColor: color, ...style}} />;

const PageGrid = ({config, children}: Props & {children: ReactNode}) => {
  const {margin, gutter, grid} = config.layout;
  const {height} = useVideoConfig();
  const left = margin + grid.railWidth + gutter;
  const hairline = {color: config.brand.colors.ink, opacity: 0.24};
  return <AbsoluteFill>
    <div style={{position: 'absolute', left: margin - 8, top: margin - 9}}>
      <SourceImage {...config.media.logo} width={164} height={56} />
    </div>
    <Rule {...hairline} left={margin} right={margin}
      top={margin + grid.headerHeight - 34} height={grid.ruleWidth} />
    <Rule {...hairline} left={left - gutter / 2}
      top={margin + grid.headerHeight - 34} bottom={margin} width={grid.ruleWidth} />
    <Rule {...hairline} left={margin} right={margin} bottom={margin}
      height={grid.ruleWidth} />
    <div style={{
      position: 'absolute', left, top: height - margin + 11,
      ...labelStyle(config), fontSize: 18, color: config.brand.colors.secondaryInk,
    }}>{config.editorial.montageLabel}</div>
    <div style={{
      position: 'absolute', left: margin, top: height - margin + 11,
      ...labelStyle(config), fontSize: 18,
    }}>16:9</div>
    {children}
  </AbsoluteFill>;
};

const Opening = ({config, duration}: Props & {duration: number}) => {
  const frame = useCurrentFrame();
  const {width} = useVideoConfig();
  const {margin, grid, gutter} = config.layout;
  const left = margin + grid.railWidth + gutter;
  const amount = revealAmount(frame + 4, config.motion.typeRevealFrames, duration);
  const panel = revealAmount(frame, config.motion.panelRevealFrames, duration);
  const {typography, colors, spacing} = config.brand;
  const headingSize = typography.headingSize * Math.min(1, 28 / config.copy.opening.length);
  return <PageGrid config={config}>
    <div style={{
      position: 'absolute', left: margin, top: grid.titleTop + 7,
      fontSize: 104, lineHeight: 1, letterSpacing: typography.headingTracking,
    }}>{config.editorial.openingRail}</div>
    <TypeMask amount={amount} travel={config.motion.typeTravel} style={{
      position: 'absolute', left, top: grid.titleTop,
      width: Math.min(grid.titleWidth, width - left - margin),
      fontSize: headingSize, lineHeight: typography.headingLineHeight,
      letterSpacing: typography.headingTracking,
    }}>{config.copy.opening}</TypeMask>
    <div style={{
      position: 'absolute', left, top: 724, width: 880,
      fontSize: typography.bodySize, lineHeight: typography.bodyLineHeight,
      letterSpacing: typography.bodyTracking,
    }}>{config.copy.benefit}</div>
    <Rule color={colors.ink} left={left} top={900 + spacing.titleGap / 2}
      height={12} width={mix(grid.railWidth, width - left - margin, panel)} />
  </PageGrid>;
};

const productOrder: ProductSceneId[] = ['environment', 'agent', 'iphone', 'webQa', 'ipad'];

const ProductScene = ({config, scene}: Props & {scene: SceneTiming & {id: ProductSceneId}}) => {
  const frame = useCurrentFrame();
  const {width, height} = useVideoConfig();
  const {margin, gutter, padding, grid} = config.layout;
  const {typography, colors} = config.brand;
  const left = margin + grid.railWidth + gutter;
  const top = margin + grid.headerHeight;
  const bayWidth = width - left - margin;
  const bayHeight = height - margin - grid.footerHeight - top;
  const imageWidth = bayWidth - padding * 2;
  const imageHeight = bayHeight - padding * 2;
  const isRecording = scene.id === 'agent' || scene.id === 'webQa';
  const panel = isRecording ? 1 : revealAmount(frame, config.motion.panelRevealFrames, scene.durationInFrames);
  const type = isRecording ? 1 : revealAmount(frame + 3, config.motion.typeRevealFrames, scene.durationInFrames);
  const part = frame < iphoneSplitFrame(scene.durationInFrames, config.motion.iphoneSplit) ? 0 : 1;
  const captions: Record<ProductSceneId, string> = {
    environment: config.editorial.environmentLabel,
    agent: config.editorial.agentLabel,
    iphone: config.editorial.iphoneLabels[part],
    webQa: config.editorial.webQaLabel,
    ipad: config.editorial.ipadLabel,
  };
  const media = scene.id === 'agent' || scene.id === 'webQa'
    ? <SourceVideo
      {...config.media[scene.id]} width={imageWidth} height={imageHeight}
      durationInFrames={scene.durationInFrames}
      labelStyle={{
        backgroundColor: colors.ink, color: colors.white,
        fontFamily: typography.fontFamily, fontSize: 26,
      }}
    />
    : <SourceImage
      {...(scene.id === 'iphone' ? config.media.iphone[part] : config.media[scene.id])}
      width={imageWidth} height={imageHeight}
    />;
  const index = productOrder.indexOf(scene.id);
  const captionWidth = grid.railWidth - gutter / 4;
  const caption = config.copy[scene.id];
  const captionSize = useMemo(() => {
    const context = document.createElement('canvas').getContext('2d');
    if (!context) throw new Error('Text measurement requires a canvas context');
    context.font = `${typography.bodySize}px "${typography.fontFamily}"`;
    const widestWord = Math.max(1, ...caption.split(/\s+/).map((word) => context.measureText(word).width));
    return Math.min(typography.bodySize, typography.bodySize * captionWidth / widestWord,
      config.layout.captionHeight / (Math.max(1, Math.ceil(caption.length / 9)) * typography.bodyLineHeight));
  }, [caption, captionWidth, config.layout.captionHeight, typography]);
  return <PageGrid config={config}>
    <div style={{
      position: 'absolute', left: margin, top: top + 8,
      fontSize: typography.headingSize * 0.73, lineHeight: 1,
      letterSpacing: typography.headingTracking,
    }}>{String(index + 1).padStart(2, '0')}</div>
    <TypeMask amount={type} travel={config.motion.typeTravel} style={{
      position: 'absolute', left: margin, top: grid.captionTop,
      width: captionWidth, overflowWrap: 'anywhere',
      fontSize: captionSize, lineHeight: typography.bodyLineHeight,
      letterSpacing: typography.bodyTracking,
    }}>{config.copy[scene.id]}</TypeMask>
    <div style={{
      position: 'absolute', left: margin, bottom: margin + 65,
      width: grid.railWidth - gutter / 4, ...labelStyle(config),
      color: colors.secondaryInk,
    }}>{captions[scene.id]}</div>
    <div style={{
      position: 'absolute', left, top, width: bayWidth, height: bayHeight,
      backgroundColor: colors.mediaMat,
      clipPath: rectangleReveal(mix(config.motion.regionStartWidth, 1, panel)),
    }}>
      <div style={{
        position: 'absolute', left: padding, top: padding,
        transform: `translateX(${(1 - panel) * config.motion.panelTravel}px)`,
      }}>{media}</div>
    </div>
    <Rule color={colors.ink} left={left} top={top - 34} height={4}
      width={bayWidth * (index + 1) / productOrder.length} />
  </PageGrid>;
};

const Closing = ({config, duration}: Props & {duration: number}) => {
  const frame = useCurrentFrame();
  const {width} = useVideoConfig();
  const {margin, gutter, grid} = config.layout;
  const {typography, colors} = config.brand;
  const left = margin + grid.railWidth + gutter;
  const amount = revealAmount(frame + 4, config.motion.typeRevealFrames, duration);
  const panel = revealAmount(frame, config.motion.panelRevealFrames, duration);
  return <PageGrid config={config}>
    <div style={{
      position: 'absolute', left: margin, top: grid.titleTop + 7,
      fontSize: 104, lineHeight: 1, letterSpacing: typography.headingTracking,
    }}>{config.editorial.closingRail}</div>
    <TypeMask amount={amount} travel={config.motion.typeTravel} style={{
      position: 'absolute', left, top: grid.titleTop,
      width: width - left - margin,
      fontSize: typography.headingSize * Math.min(1, 19 / config.copy.featureName.length),
      letterSpacing: typography.headingTracking, lineHeight: typography.headingLineHeight,
    }}>{config.copy.featureName}</TypeMask>
    <div style={{
      position: 'absolute', left, top: 520, width: 1000,
      fontSize: typography.bodySize * 1.2,
      lineHeight: typography.bodyLineHeight, letterSpacing: typography.bodyTracking,
    }}>{config.copy.closing}</div>
    <div style={{
      position: 'absolute', left, top: 744,
      width: width - left - margin, height: 244,
      backgroundColor: colors.ink, color: colors.white,
      clipPath: rectangleReveal(mix(config.motion.regionStartWidth, 1, panel)),
    }}>
      <div style={{
        position: 'absolute', left: gutter, top: 42, right: gutter,
        fontSize: typography.bodySize * Math.min(1.2, 40 / config.copy.cta.length),
        lineHeight: typography.bodyLineHeight, letterSpacing: typography.bodyTracking,
      }}>{config.copy.cta}</div>
      <div style={{
        position: 'absolute', left: gutter, top: 159, ...labelStyle(config), fontSize: 28,
      }}>{config.copy.url}</div>
    </div>
  </PageGrid>;
};

export const Template = ({config}: Props) => {
  const {fps} = useVideoConfig();
  const timeline = makeTimeline(config.durations, fps);
  return <AbsoluteFill style={{
    backgroundColor: config.brand.colors.canvas, color: config.brand.colors.ink,
    fontFamily: config.brand.typography.fontFamily, fontWeight: 400,
  }}>
    {timeline.map((scene) => <Sequence
      key={scene.id} from={scene.from} durationInFrames={scene.durationInFrames}
    >
      {scene.id === 'opening'
        ? <Opening config={config} duration={scene.durationInFrames} />
        : scene.id === 'closing'
          ? <Closing config={config} duration={scene.durationInFrames} />
          : <ProductScene config={config} scene={{...scene, id: scene.id}} />}
    </Sequence>)}
  </AbsoluteFill>;
};
