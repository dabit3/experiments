import {useMemo, type CSSProperties, type ReactNode} from 'react';
import {AbsoluteFill, Sequence, useCurrentFrame, useVideoConfig} from 'remotion';
import {
  SourceImage, SourceVideo, easeInOut, makeTimeline, progress,
  type ImageSelection, type SceneId, type SceneTiming,
} from '../../shared';
import type {EditorialConfig} from './config';

type Box = {x: number; y: number; width: number; height: number};
type Props = {config: EditorialConfig};

const boxStyle = ({x, y, width, height}: Box): CSSProperties => ({
  position: 'absolute', left: x, top: y, width, height,
});

const fittedSize = (text: string, box: Box, desired: number, config: EditorialConfig): number => {
  const context = document.createElement('canvas').getContext('2d');
  if (!context) throw new Error('Canvas text measurement is required for editorial copy fitting');
  const type = config.brand.typography;
  const fits = (size: number) => {
    context.font = `400 ${size}px "${type.fontFamily}"`;
    const tracking = parseFloat(type.headingTracking) * (type.headingTracking.endsWith('em') ? size : 1);
    const measure = (value: string) => context.measureText(value).width + Math.max(0, value.length - 1) * tracking;
    let lines = 0;
    for (const paragraph of text.split('\n')) {
      let line = '';
      lines++;
      for (const word of paragraph.split(/\s+/)) {
        if (measure(word) > box.width) return false;
        const candidate = line ? `${line} ${word}` : word;
        if (line && measure(candidate) > box.width) {
          lines++;
          line = word;
        } else {
          line = candidate;
        }
      }
    }
    return lines * size * type.headingLineHeight <= box.height;
  };
  if (fits(desired)) return desired;
  let low = 1;
  let high = desired;
  for (let i = 0; i < 14; i++) {
    const mid = (low + high) / 2;
    if (fits(mid)) low = mid;
    else high = mid;
  }
  return Math.floor(low * 10) / 10;
};

const Copy = ({
  config: c, text, box, size, secondary = false, style,
}: Props & {
  text: string; box: Box; size: number; secondary?: boolean; style?: CSSProperties;
}) => {
  const scale = c.brand.typography.headingSize / 96;
  const desired = size * scale;
  const fontSize = useMemo(() => fittedSize(text, box, desired, c), [text, box, desired, c]);
  return <div style={{
    ...boxStyle(box),
    fontSize, fontWeight: 400,
    lineHeight: c.brand.typography.headingLineHeight,
    letterSpacing: c.brand.typography.headingTracking,
    color: secondary ? c.brand.colors.secondaryInk : c.brand.colors.ink,
    whiteSpace: 'pre-line',
    overflowWrap: 'break-word',
    ...style,
  }}>{text}</div>;
};

const Small = ({config: c, children, style}: Props & {children: ReactNode; style?: CSSProperties}) =>
  <div style={{
    fontSize: c.brand.typography.bodySize * 2 / 3,
    lineHeight: c.brand.typography.bodyLineHeight,
    letterSpacing: c.brand.typography.bodyTracking,
    color: c.brand.colors.secondaryInk,
    ...style,
  }}>{children}</div>;

const Reveal = ({
  config: c, frame, delay = 0, children, box, duration,
}: Props & {frame: number; delay?: number; children: ReactNode; box: Box; duration: number}) => {
  const amount = easeInOut(progress(frame, delay, Math.min(c.motion.revealFrames, duration / 5)));
  const hidden = (1 - amount) * 100;
  return <div style={{
    ...boxStyle(box),
    clipPath: c.motion.revealDirection === 'left'
      ? `inset(0 ${hidden}% 0 0)` : `inset(0 0 0 ${hidden}%)`,
  }}>{children}</div>;
};

const ImagePlate = ({
  config: c, selection, width, height, pad = true,
}: Props & {selection: ImageSelection; width: number; height: number; pad?: boolean}) => {
  const p = pad ? c.layout.padding : 0;
  return <div style={{width, height, padding: p, boxSizing: 'border-box', background: c.brand.colors.mediaMat}}>
    <SourceImage {...selection} width={width - p * 2} height={height - p * 2} />
  </div>;
};

const Masthead = ({config: c, frame, page}: Props & {frame: number; page: string}) => {
  const m = c.layout.margin;
  return <>
    <div style={{position: 'absolute', left: m, top: 40}}>
      <SourceImage {...c.media.logo} width={c.editorial.logoWidth} height={54} />
    </div>
    <Small config={c} style={{position: 'absolute', right: m, top: 54}}>{c.editorial.edition}</Small>
    <div style={{
      position: 'absolute', left: m, right: m, top: 116, height: 1,
      background: c.brand.colors.ink,
      transformOrigin: 'left',
      transform: `scaleX(${easeInOut(progress(frame, 0, c.motion.ruleFrames))})`,
    }} />
    <Small config={c} style={{position: 'absolute', left: m, bottom: 29}}>
      {c.editorial.montageNote}
    </Small>
    <Small config={c} style={{position: 'absolute', right: m, bottom: 29}}>{page} / 07</Small>
  </>;
};

const Cover = ({config: c, frame, duration}: Props & {frame: number; duration: number}) => {
  const {margin: m, grid: g} = c.layout;
  const image = {x: g.coverMediaX, y: g.coverMediaY, width: 1920 - m - g.coverMediaX, height: g.coverMediaHeight};
  return <>
    <Masthead config={c} frame={frame} page="01" />
    <Copy config={c} text={c.copy.featureName}
      box={{x: m - 5, y: 195, width: g.coverTextWidth, height: 420}}
      size={c.editorial.coverTypeSize} />
    <Copy config={c} text={c.copy.opening}
      box={{x: m, y: 710, width: g.coverTextWidth - 70, height: 165}} size={60} />
    <Reveal config={c} box={image} frame={frame} duration={duration} delay={c.motion.coverRevealDelay}>
      <ImagePlate config={c} selection={{asset: c.media.environment.asset, framing: c.editorial.coverFraming}}
        width={image.width} height={image.height} />
    </Reveal>
    <Small config={c} style={{position: 'absolute', left: image.x, top: 194}}>{c.editorial.coverKicker}</Small>
    <Copy config={c} text={c.copy.benefit}
      box={{x: image.x, y: image.y + image.height + c.brand.spacing.titleGap, width: image.width - 100, height: 148}}
      size={c.brand.typography.bodySize} />
  </>;
};

const Environment = ({config: c, frame, duration}: Props & {frame: number; duration: number}) => {
  const {margin: m, gutter, grid: g} = c.layout;
  const imageX = m + g.environmentRail + gutter;
  const image = {x: imageX, y: g.environmentMediaY, width: 1920 - m - imageX, height: g.environmentMediaHeight};
  return <>
    <Masthead config={c} frame={frame} page="02" />
    <Small config={c} style={{position: 'absolute', left: m, top: 174}}>{c.editorial.environmentKicker}</Small>
    <Copy config={c} text={c.copy.environment}
      box={{x: m, y: 255, width: g.environmentRail, height: 310}} size={c.editorial.sideTypeSize} />
    <Copy config={c} text={c.editorial.environmentWord}
      box={{x: m - 7, y: 737, width: g.environmentRail, height: 186}} size={c.editorial.marginTypeSize} />
    <Reveal config={c} box={image} frame={frame} duration={duration}>
      <ImagePlate config={c} selection={c.media.environment} width={image.width} height={image.height} />
    </Reveal>
    <Small config={c} style={{position: 'absolute', left: imageX, top: image.y - 48}}>
      {c.editorial.environmentNote}
    </Small>
  </>;
};

const Demo = ({config: c, scene, frame}: Props & {scene: SceneTiming; frame: number}) => {
  const isAgent = scene.id === 'agent';
  const isPhone = scene.id === 'iphone';
  const caption = isAgent ? c.copy.agent : isPhone ? c.copy.iphone : c.copy.webQa;
  const m = c.layout.margin;
  const width = 1920 - 2 * m;
  const y = c.layout.captionHeight + 8;
  const height = 1080 - y - 56;
  const firstPhone = frame < Math.round(scene.durationInFrames * c.motion.iphoneSplit);
  const page = isAgent ? '03' : isPhone ? '04' : '05';
  return <>
    <Copy config={c} text={caption}
      box={{x: m, y: 34, width: width - 160, height: c.layout.captionHeight - 56}}
      size={c.editorial.captionTypeSize} />
    <Small config={c} style={{position: 'absolute', right: m, top: 46}}>{page} / 07</Small>
    <div style={{
      position: 'absolute', left: m, right: m, top: c.layout.captionHeight - 10,
      height: 1, background: c.brand.colors.ink,
    }} />
    <div style={{position: 'absolute', left: m, top: y}}>
      {isPhone
        ? <ImagePlate config={c} selection={c.media.iphone[firstPhone ? 0 : 1]}
          width={width} height={height} pad={false} />
        : <SourceVideo {...(isAgent ? c.media.agent : c.media.webQa)}
          width={width} height={height} durationInFrames={scene.durationInFrames}
          labelHeight={44}
          labelStyle={{
            fontFamily: c.brand.typography.fontFamily, fontSize: 26,
            color: c.brand.colors.ink, backgroundColor: c.brand.colors.canvas,
            padding: 0,
          }} />}
    </div>
    <Small config={c} style={{position: 'absolute', left: m, bottom: 15, fontSize: 20}}>
      {isPhone ? c.editorial.iphoneNotes[firstPhone ? 0 : 1] : c.editorial.montageNote}
    </Small>
    <Small config={c} style={{position: 'absolute', right: m, bottom: 15, fontSize: 20}}>
      {c.copy.featureName}
    </Small>
  </>;
};

const Ipad = ({config: c, frame, duration}: Props & {frame: number; duration: number}) => {
  const {margin: m, gutter, grid: g} = c.layout;
  const image = {x: m, y: g.ipadMediaY, width: 1920 - 2 * m - g.ipadRail - gutter, height: g.ipadMediaHeight};
  const railX = image.x + image.width + gutter;
  return <>
    <Small config={c} style={{position: 'absolute', left: m, top: 38}}>{c.editorial.edition}</Small>
    <Small config={c} style={{position: 'absolute', right: m, top: 38}}>06 / 07</Small>
    <Copy config={c} text={c.editorial.layoutWord}
      box={{x: m - 5, y: 78, width: image.width, height: 146}}
      size={c.editorial.marginTypeSize} />
    <div style={{position: 'absolute', left: railX - gutter / 2, top: image.y, height: image.height, width: 1, background: c.brand.colors.secondaryInk}} />
    <Small config={c} style={{position: 'absolute', left: railX, top: image.y}}>{c.editorial.ipadKicker}</Small>
    <Copy config={c} text={c.copy.ipad}
      box={{x: railX, y: image.y + 87, width: g.ipadRail, height: 340}}
      size={c.editorial.sideTypeSize} />
    <Small config={c} style={{position: 'absolute', left: railX, top: image.y + 563, width: g.ipadRail}}>
      {c.editorial.ipadNote}
    </Small>
    <Reveal config={c} box={image} frame={frame} duration={duration}>
      <ImagePlate config={c} selection={c.media.ipad} width={image.width} height={image.height} pad={false} />
    </Reveal>
    <Small config={c} style={{position: 'absolute', left: m, bottom: 29}}>{c.editorial.montageNote}</Small>
  </>;
};

const Closing = ({config: c, frame, duration}: Props & {frame: number; duration: number}) => {
  const {margin: m, gutter, grid: g} = c.layout;
  const textX = m + g.closingMediaWidth + gutter;
  const textWidth = 1920 - m - textX;
  const image = {x: m, y: g.closingMediaY, width: g.closingMediaWidth, height: g.closingMediaWidth / 1.835};
  return <>
    <Masthead config={c} frame={frame} page="07" />
    <Small config={c} style={{position: 'absolute', left: m, top: g.closingMediaY - 56}}>{c.editorial.ipadNote}</Small>
    <Reveal config={c} box={image} frame={frame} duration={duration}>
      <ImagePlate config={c} selection={c.media.ipad} width={image.width} height={image.height} pad={false} />
    </Reveal>
    <Small config={c} style={{position: 'absolute', left: textX, top: g.closingTextY}}>{c.copy.featureName}</Small>
    <Copy config={c} text={c.copy.closing}
      box={{x: textX, y: g.closingTextY + 76, width: textWidth, height: 318}}
      size={c.editorial.closingTypeSize} />
    <div style={{position: 'absolute', left: textX, top: 683, width: textWidth, height: 1, background: c.brand.colors.ink}} />
    <Copy config={c} text={c.copy.cta}
      box={{x: textX, y: 720, width: textWidth, height: 112}} size={42} />
    <Small config={c} style={{position: 'absolute', left: textX, top: 882, color: c.brand.colors.ink, fontSize: 32}}>
      {c.copy.url}
    </Small>
  </>;
};

const EditorialScene = ({config, scene}: Props & {scene: SceneTiming}) => {
  const frame = useCurrentFrame();
  const common = {config, frame, duration: scene.durationInFrames};
  const compositions: Partial<Record<SceneId, ReactNode>> = {
    opening: <Cover {...common} />,
    environment: <Environment {...common} />,
    ipad: <Ipad {...common} />,
    closing: <Closing {...common} />,
  };
  return <AbsoluteFill>{compositions[scene.id] ?? <Demo config={config} scene={scene} frame={frame} />}</AbsoluteFill>;
};

export const Template = ({config}: Props) => {
  const {fps} = useVideoConfig();
  if (config.motion.iphoneSplit <= 0 || config.motion.iphoneSplit >= 1) {
    throw new Error('motion.iphoneSplit must be between 0 and 1 to show both genuine iPhone stills');
  }
  return <AbsoluteFill style={{
    background: config.brand.colors.canvas, color: config.brand.colors.ink,
    fontFamily: config.brand.typography.fontFamily,
  }}>
    {makeTimeline(config.durations, fps).map((scene) =>
      <Sequence key={scene.id} from={scene.from} durationInFrames={scene.durationInFrames}>
        <EditorialScene config={config} scene={scene} />
      </Sequence>,
    )}
  </AbsoluteFill>;
};
