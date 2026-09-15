import type {CSSProperties, ReactNode} from 'react';
import {AbsoluteFill, Sequence, useCurrentFrame, useVideoConfig} from 'remotion';
import {
  SourceImage, SourceVideo, easeInOut, makeTimeline, mix, progress, sceneIds,
  type SceneTiming, type TemplateProps,
} from '../../shared';
import type {StoryboardConfig} from './config';

type Props = TemplateProps<StoryboardConfig>;
type Rect = {left: number; top: number; width: number; height: number};

const reveal = (value: number, reverse: boolean) =>
  `inset(0 ${reverse ? 0 : (1 - value) * 100}% 0 ${reverse ? (1 - value) * 100 : 0}%)`;

const boundedMotion = (requested: number, duration: number) =>
  Math.max(0, Math.min(requested, Math.floor(duration / 4)));

const textStyle = (config: StoryboardConfig, size: number): CSSProperties => ({
  fontSize: size,
  lineHeight: config.brand.typography.headingLineHeight,
  letterSpacing: config.brand.typography.headingTracking,
  fontWeight: 400,
});

const Index = ({children, config, style}: Props & {
  children: ReactNode; style?: CSSProperties;
}) => <div style={{
  fontFamily: config.brand.typography.monoFamily, fontSize: 20,
  lineHeight: 1.25, letterSpacing: '-0.02em', ...style,
}}>{children}</div>;

const Panel = ({rect, config, children, style}: Props & {
  rect: Rect; children: ReactNode; style?: CSSProperties;
}) => <div style={{
  position: 'absolute', ...rect, boxSizing: 'border-box', overflow: 'hidden',
  border: `${config.layout.grid.borderWidth}px solid ${config.brand.colors.ink}`,
  backgroundColor: config.brand.colors.white, ...style,
}}>{children}</div>;

const Header = ({config, scene}: Props & {scene: SceneTiming}) => {
  const {width} = useVideoConfig();
  const {margin, grid} = config.layout;
  const note = scene.id === 'iphone' || scene.id === 'ipad'
    ? config.storyboard.stillLabel
    : scene.id === 'agent' || scene.id === 'webQa'
      ? config.storyboard.recordingLabel : config.copy.featureName;
  return <div style={{
    position: 'absolute', top: 24, left: margin, width: width - margin * 2,
    display: 'flex', alignItems: 'center', justifyContent: 'space-between',
  }}>
    <SourceImage {...config.media.logo} width={grid.logoWidth} height={42} />
    <Index config={config} style={{color: config.brand.colors.secondaryInk}}>
      {note}
    </Index>
    <Index config={config}>{config.storyboard.edition}</Index>
  </div>;
};

const Footer = ({config, scene}: Props & {scene: SceneTiming}) => {
  const {width, height} = useVideoConfig();
  const active = sceneIds.indexOf(scene.id);
  const {margin, captionHeight, gutter} = config.layout;
  const reverse = config.storyboard.readingOrder === 'right-to-left';
  const isOpening = scene.id === 'opening';
  const caption = isOpening ? config.copy.featureName : config.copy[scene.id];
  return <div style={{
    position: 'absolute', left: margin, right: margin, top: height - captionHeight,
  }}>
    <div style={{display: 'flex', gap: 34, alignItems: 'baseline'}}>
      <span style={textStyle(config, 52)}>{String(active + 1).padStart(2, '0')}</span>
      <span style={{
        ...textStyle(config, config.brand.typography.bodySize * 1.25),
        maxWidth: width - margin * 2 - 130,
      }}>{caption}</span>
    </div>
    <div style={{
      marginTop: 25, display: 'flex', flexDirection: reverse ? 'row-reverse' : 'row',
      gap: gutter / 2, alignItems: 'center',
    }}>
      {sceneIds.map((id, index) => <div key={id} style={{
        width: index === active ? 144 : 36, height: 6,
        backgroundColor: index <= active ? config.brand.colors.ink : config.brand.colors.mediaMat,
      }} />)}
      <Index config={config} style={{
        marginLeft: reverse ? 0 : 'auto', marginRight: reverse ? 'auto' : 0,
        fontSize: 18, color: config.brand.colors.secondaryInk,
      }}>{config.storyboard.montageLabel}</Index>
    </div>
  </div>;
};

const Opening = ({config, scene, board}: Props & {scene: SceneTiming; board: Rect}) => {
  const frame = useCurrentFrame();
  const {colors, typography, spacing} = config.brand;
  const {gutter} = config.layout;
  const reverse = config.storyboard.readingOrder === 'right-to-left';
  const total = config.storyboard.introFractions.reduce((sum, value) => sum + value, 0);
  const widths = config.storyboard.introFractions.map((value) => (board.width - gutter * 2) * value / total);
  const stagger = Math.min(config.motion.introStaggerFrames, scene.durationInFrames / 10);
  const labels = config.storyboard.introLabels;
  return <>
    {widths.map((panelWidth, i) => {
      const preceding = widths.slice(0, i).reduce((sum, value) => sum + value, 0) + gutter * i;
      const opening = easeInOut(progress(frame, stagger * i, boundedMotion(16, scene.durationInFrames)));
      const dark = i === 1;
      return <Panel key={i} config={config} rect={{
        left: board.left + (reverse ? board.width - preceding - panelWidth : preceding),
        top: board.top, width: panelWidth, height: board.height,
      }} style={{
        clipPath: reveal(i === 0 ? 1 : opening, reverse),
        color: dark ? colors.white : colors.ink,
        backgroundColor: dark ? colors.ink : colors.canvas,
        padding: spacing.padding,
      }}>
        <Index config={config}>01.{['a', 'b', 'c'][i]} / {labels[i]}</Index>
        {i === 0 ? <>
          <div style={{position: 'absolute', top: '39%', left: spacing.padding}}>
            <SourceImage {...config.media.logo}
              width={panelWidth - spacing.padding * 2} height={100} />
          </div>
          <div style={{
            position: 'absolute', bottom: 36, ...textStyle(config, typography.headingSize * 1.65),
          }}>01</div>
        </> : i === 1 ? <div style={{
          position: 'absolute', top: '31%', left: 48, right: 48,
          ...textStyle(config, typography.headingSize * 1.42),
          lineHeight: typography.headingLineHeight * 1.03,
        }}>{config.copy.opening}</div> : <div style={{
          position: 'absolute', top: '35%', left: spacing.padding, right: spacing.padding,
          ...textStyle(config, typography.bodySize * 1.32),
          lineHeight: typography.headingLineHeight * 1.13,
        }}>{config.copy.benefit}</div>}
      </Panel>;
    })}
  </>;
};

const StillPair = ({config, duration, width, height}: Props & {
  duration: number; width: number; height: number;
}) => {
  const frame = useCurrentFrame();
  const split = Math.min(duration - 1, Math.max(1, Math.round(duration * config.motion.iphoneSplit)));
  const boundary = easeInOut(progress(
    frame, split, boundedMotion(config.motion.stillBoundaryFrames, duration - split),
  ));
  const reverse = config.storyboard.readingOrder === 'right-to-left';
  if (frame < split || boundary === 0) {
    return <SourceImage {...config.media.iphone[0]} width={width} height={height} />;
  }
  if (boundary === 1) {
    return <SourceImage {...config.media.iphone[1]} width={width} height={height} />;
  }
  const gutter = config.layout.gutter * Math.sin(Math.PI * boundary);
  const previousWidth = (width - gutter) * (1 - boundary);
  const nextWidth = (width - gutter) * boundary;
  return <div style={{position: 'relative', width, height}}>
    <div style={{
      position: 'absolute', top: 0, left: reverse ? nextWidth + gutter : 0,
    }}>
      <SourceImage {...config.media.iphone[0]} width={previousWidth} height={height} />
    </div>
    <div style={{
      position: 'absolute', top: 0, left: reverse ? 0 : previousWidth + gutter,
    }}>
      <SourceImage {...config.media.iphone[1]} width={nextWidth} height={height} />
    </div>
    <div style={{
      position: 'absolute', top: 0, height, width: gutter,
      left: reverse ? nextWidth : previousWidth,
      backgroundColor: config.brand.colors.canvas,
    }} />
  </div>;
};

const Media = ({config, scene, width, height}: Props & {
  scene: SceneTiming; width: number; height: number;
}) => {
  if (scene.id === 'agent' || scene.id === 'webQa') {
    return <SourceVideo {...config.media[scene.id]} width={width} height={height}
      durationInFrames={scene.durationInFrames}
      labelStyle={{
        backgroundColor: config.brand.colors.ink, color: config.brand.colors.white,
        fontFamily: config.brand.typography.fontFamily, fontSize: 27,
      }} />;
  }
  if (scene.id === 'iphone') {
    return <StillPair config={config} duration={scene.durationInFrames} width={width} height={height} />;
  }
  const selection = scene.id === 'environment' ? config.media.environment : config.media.ipad;
  return <SourceImage {...selection} width={width} height={height} />;
};

const Demonstration = ({config, scene, board}: Props & {scene: SceneTiming; board: Rect}) => {
  const frame = useCurrentFrame();
  const {gutter, padding, grid} = config.layout;
  const {colors} = config.brand;
  const activeIndex = sceneIds.indexOf(scene.id);
  const previousId = sceneIds[Math.max(0, activeIndex - 1)];
  const reverse = config.storyboard.readingOrder === 'right-to-left';
  const arrangement = config.storyboard.arrangements[scene.id];
  const video = scene.id === 'agent' || scene.id === 'webQa';
  const entryFraction = video ? config.motion.videoEntryFraction : config.motion.stillEntryFraction;
  const t = easeInOut(progress(frame, 0, boundedMotion(config.motion.gutterFrames, scene.durationInFrames)));
  const quiet: Rect = {...board};
  const active: Rect = {...board};
  if (arrangement === 'side') {
    quiet.width = mix(board.width * (1 - entryFraction), grid.contextWidth, t);
    active.width = board.width - quiet.width - gutter;
    active.left = board.left + (reverse ? 0 : quiet.width + gutter);
    quiet.left = reverse ? active.left + active.width + gutter : board.left;
  } else if (arrangement === 'stack') {
    quiet.height = mix(board.height * (1 - entryFraction), grid.contextHeight, t);
    active.top += quiet.height + gutter;
    active.height -= quiet.height + gutter;
  }
  const compact = arrangement === 'stack';
  return <>
    {arrangement !== 'full' ? <Panel config={config} rect={quiet} style={{
      backgroundColor: colors.ink, color: colors.white, border: 0,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
    }}>
      <Index config={config} style={{
        whiteSpace: 'nowrap', opacity: config.motion.contextOpacity,
        transform: compact ? 'none' : 'rotate(-90deg)',
        fontSize: compact ? 19 : 24,
      }}>
        {String(activeIndex).padStart(2, '0')} / {config.storyboard.chapterNames[previousId]}
      </Index>
    </Panel> : null}
    <Panel config={config} rect={active} style={{backgroundColor: colors.mediaMat}}>
      <div style={{position: 'absolute', top: padding, left: padding}}>
        <Media config={config} scene={scene}
          width={active.width - padding * 2} height={active.height - padding * 2} />
      </div>
    </Panel>
  </>;
};

const Closing = ({config, scene, board}: Props & {scene: SceneTiming; board: Rect}) => {
  const frame = useCurrentFrame();
  const {colors, typography} = config.brand;
  const start = Math.round(scene.durationInFrames * config.motion.closingResultFraction);
  const t = easeInOut(progress(
    frame, start, boundedMotion(config.motion.closingBoundaryFrames, scene.durationInFrames - start),
  ));
  const reverse = config.storyboard.readingOrder === 'right-to-left';
  const {padding, gutter} = config.layout;
  return <>
    <Panel config={config} rect={board} style={{backgroundColor: colors.mediaMat}}>
      <div style={{position: 'absolute', top: padding, left: padding}}>
        <SourceImage {...config.media.ipad}
          width={board.width - padding * 2} height={board.height - padding * 2} />
      </div>
    </Panel>
    {frame >= start ? <Panel config={config} rect={board} style={{
      backgroundColor: colors.ink, color: colors.white, clipPath: reveal(t, reverse),
    }}>
      <div style={{position: 'absolute', top: 62, left: 64}}>
        <SourceImage {...config.storyboard.closingLogo} width={240} height={76} />
      </div>
      <div style={{
        position: 'absolute', top: '34%', left: 64, right: 120,
        ...textStyle(config, typography.headingSize * 1.32),
        lineHeight: typography.headingLineHeight * 1.06,
        maxWidth: 1320,
      }}>{config.copy.cta}</div>
      <div style={{
        position: 'absolute', bottom: 66, left: 64, right: 64,
        display: 'flex', justifyContent: 'space-between', alignItems: 'baseline',
      }}>
        <span style={{fontSize: typography.bodySize * 1.18}}>{config.copy.url}</span>
        <Index config={config}>07 / {config.storyboard.chapterNames.closing}</Index>
      </div>
    </Panel> : null}
    {t > 0 && t < 1 ? <div style={{
      position: 'absolute', top: board.top, height: board.height, width: gutter,
      left: board.left + (reverse ? 1 - t : t) * board.width - gutter / 2,
      backgroundColor: colors.canvas,
    }} /> : null}
  </>;
};

const StoryScene = ({config, scene}: Props & {scene: SceneTiming}) => {
  const {width, height} = useVideoConfig();
  const {margin, grid, captionHeight, gutter} = config.layout;
  const board: Rect = {
    left: margin, top: grid.top, width: width - margin * 2,
    height: height - captionHeight - gutter - grid.top,
  };
  return <>
    <Header config={config} scene={scene} />
    {scene.id === 'opening' ? <Opening config={config} scene={scene} board={board} />
      : scene.id === 'closing' ? <Closing config={config} scene={scene} board={board} />
        : <Demonstration config={config} scene={scene} board={board} />}
    <Footer config={config} scene={scene} />
  </>;
};

export const Template = ({config}: Props) => {
  const {fps} = useVideoConfig();
  return <AbsoluteFill style={{
    backgroundColor: config.brand.colors.canvas, color: config.brand.colors.ink,
    fontFamily: config.brand.typography.fontFamily,
    fontSize: config.brand.typography.bodySize,
    lineHeight: config.brand.typography.bodyLineHeight,
    letterSpacing: config.brand.typography.bodyTracking,
  }}>
    {makeTimeline(config.durations, fps).map((scene) => <Sequence key={scene.id}
      from={scene.from} durationInFrames={scene.durationInFrames}>
      <StoryScene config={config} scene={scene} />
    </Sequence>)}
  </AbsoluteFill>;
};
