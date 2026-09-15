import type {CSSProperties} from 'react';
import {AbsoluteFill, Audio, Sequence, staticFile, useCurrentFrame, useVideoConfig} from 'remotion';
import {
  SourceImage, SourceVideo, easeInOut, makeTimeline, mix, progress,
  type SceneTiming,
} from '../../shared';
import type {MusicalScoreConfig, ProductScene} from './config';

const productOrder: ProductScene[] = ['environment', 'agent', 'iphone', 'webQa', 'ipad'];
const ordinal = (index: number) => String(index + 1).padStart(2, '0');

const Score = ({config, timeline}: {config: MusicalScoreConfig; timeline: SceneTiming[]}) => {
  const frame = useCurrentFrame();
  const {width, fps} = useVideoConfig();
  const {score, layout, brand, motion} = config;
  const active = timeline.find((scene) => frame >= scene.from && frame < scene.from + scene.durationInFrames)!;
  const chapter = productOrder.indexOf(active.id as ProductScene);
  const isClosing = active.id === 'closing';
  const local = frame - active.from;
  const resolve = isClosing ? easeInOut(progress(local, 0, motion.resolveFrames)) : 0;
  const stripWidth = width - layout.margin * 2;
  const graphWidth = stripWidth - score.labelWidth;
  const column = graphWidth / productOrder.length;
  const rowStart = 60;
  const graphBottom = rowStart + score.rowHeight * 2;
  const previousPosition = chapter <= 0 ? 0 : chapter - 1 + 0.5;
  const nextPosition = chapter < 0 ? (isClosing ? 5 : 0) : chapter + 0.5;
  const travel = easeInOut(progress(local, 0, motion.playheadTravelFrames));
  const playhead = isClosing
    ? mix(4.5, 5, resolve) * column
    : mix(previousPosition, nextPosition, travel) * column;
  const entrance = easeInOut(progress(frame, 0, motion.entranceFrames));
  const cue = [...score.cues].reverse().find((item) =>
    item.scene === active.id && local >= Math.round(item.atSeconds * fps));
  const cueAge = cue ? local - Math.round(cue.atSeconds * fps) : -1;
  const accent = cueAge >= 0 ? 1 - progress(cueAge, 0, motion.cueAccentFrames) : 0;
  const mono: CSSProperties = {
    fontFamily: brand.typography.monoFamily,
    fontSize: score.fontSize,
    lineHeight: 1,
  };

  return <div style={{
    position: 'absolute', left: layout.margin, top: layout.grid.scoreTop,
    width: stripWidth, height: 142, color: brand.colors.ink,
  }}>
    <div style={{position: 'absolute', top: 0, left: 0, ...mono, fontSize: score.fontSize - 3}}>
      {score.label}
    </div>
    <div style={{
      position: 'absolute', top: 0, right: 0, ...mono, fontSize: score.fontSize - 3,
      color: brand.colors.secondaryInk,
    }}>{score.context}</div>
    {score.tracks.map((label, row) => {
      const y = rowStart + row * score.rowHeight;
      const resolvedY = mix(y, rowStart + score.rowHeight, resolve);
      return <div key={`${row}-${label}`}>
        <div style={{
          position: 'absolute', top: y - 9, left: 0, ...mono,
          color: brand.colors.secondaryInk, opacity: 1 - progress(resolve, 0, 0.4),
        }}>{label}</div>
        <div style={{
          position: 'absolute', top: resolvedY, left: score.labelWidth,
          width: graphWidth * entrance, height: 1,
          background: brand.colors.ink, opacity: score.ruleOpacity,
        }} />
      </div>;
    })}
    {productOrder.map((id, index) => {
      const track = Math.max(0, Math.min(2, config.score.chapters[id].track));
      const x = score.labelWidth + index * column;
      const isActive = chapter === index;
      const isPast = chapter > index || isClosing;
      const y = rowStart + track * score.rowHeight;
      return <div key={id} style={{opacity: entrance}}>
        <div style={{
          position: 'absolute', left: x + score.barInset, top: 30,
          ...mono, opacity: (isActive ? 1 : 0.48) * (1 - resolve),
        }}>{ordinal(index)} / {score.chapters[id].label}</div>
        <div style={{
          position: 'absolute',
          left: mix(x + score.barInset, stripWidth - 2, resolve),
          top: mix(y - (isActive ? 4 : 2), rowStart + score.rowHeight - 2, resolve),
          width: mix(column - score.barInset * 2, 2, resolve),
          height: isActive ? 8 : 4,
          background: brand.colors.ink,
          opacity: isActive || isPast ? 1 : 0.15,
        }} />
        {isActive && accent > 0 ? <div style={{
          position: 'absolute', left: x + column / 2 - motion.cueAccentSize / 2,
          top: y - motion.cueAccentSize / 2,
          width: motion.cueAccentSize, height: motion.cueAccentSize,
          outline: `${2 + accent * 2}px solid ${brand.colors.ink}`,
          outlineOffset: (1 - accent) * 12, opacity: accent,
          background: brand.colors.canvas,
        }} /> : null}
      </div>;
    })}
    <div style={{
      position: 'absolute', left: score.labelWidth + playhead, top: 50,
      height: graphBottom - 40, width: 2, background: brand.colors.ink,
      opacity: active.id === 'opening' ? entrance * 0.45 : 1,
    }} />
    {isClosing ? <div style={{
      ...mono, position: 'absolute', top: rowStart + score.rowHeight - 10,
      left: 0, opacity: progress(resolve, 0.65, 0.35),
    }}>{score.closingIndex}</div> : null}
  </div>;
};

const TitleScene = ({config, closing}: {config: MusicalScoreConfig; closing: boolean}) => {
  const frame = useCurrentFrame();
  const {width} = useVideoConfig();
  const {brand, layout, motion} = config;
  const enter = easeInOut(progress(frame, 0, closing ? motion.resolveFrames : motion.entranceFrames));
  const main = closing ? config.copy.closing : config.copy.opening;
  const headline: CSSProperties = {
    fontSize: brand.typography.headingSize,
    fontWeight: 400,
    lineHeight: brand.typography.headingLineHeight,
    letterSpacing: brand.typography.headingTracking,
    margin: 0,
  };
  return <AbsoluteFill style={{padding: layout.margin}}>
    <div style={{position: 'absolute', top: layout.margin, left: layout.margin}}>
      <SourceImage {...config.media.logo} width={220} height={72} />
    </div>
    <div style={{
      position: 'absolute', top: layout.margin + 17, right: layout.margin,
      fontFamily: brand.typography.monoFamily, fontSize: 21,
    }}>{closing ? config.score.closingIndex : config.score.introIndex} / {config.copy.featureName}</div>
    <div style={{
      position: 'absolute', top: 250, left: layout.margin, width: width - layout.margin * 2,
      display: 'grid', gridTemplateColumns: 'minmax(0, 1fr) 300px', gap: layout.gutter * 2,
    }}>
      <div style={{opacity: 0.2 + enter * 0.8, transform: `translateY(${(1 - enter) * 20}px)`}}>
        <h1 style={{...headline, maxWidth: 1340}}>{main}</h1>
        <div style={{
          marginTop: brand.spacing.titleGap * 1.6, fontSize: brand.typography.bodySize,
          maxWidth: 1060, lineHeight: brand.typography.bodyLineHeight,
          color: brand.colors.secondaryInk,
        }}>{closing ? config.copy.cta : config.copy.benefit}</div>
        {closing ? <div style={{
          marginTop: brand.spacing.titleGap, display: 'inline-block',
          padding: '16px 24px', background: brand.colors.ink, color: brand.colors.white,
          fontSize: 30, borderRadius: 2,
        }}>{config.copy.url}</div> : null}
      </div>
      <div style={{
        borderLeft: `1px solid ${brand.colors.secondaryInk}`, paddingLeft: layout.gutter,
        paddingTop: 6, fontFamily: brand.typography.monoFamily, fontSize: 23,
        alignSelf: 'start', lineHeight: 1.5,
      }}>
        {productOrder.map((id, index) => <div key={id} style={{
          display: 'flex', gap: 22, marginBottom: 14,
          opacity: closing ? enter : progress(frame, index * 5, motion.entranceFrames),
        }}>
          <span style={{color: brand.colors.secondaryInk}}>{ordinal(index)}</span>
          <span>{config.score.chapters[id].label}</span>
        </div>)}
      </div>
    </div>
  </AbsoluteFill>;
};

const Product = ({config, scene}: {config: MusicalScoreConfig; scene: SceneTiming}) => {
  const frame = useCurrentFrame();
  const {width, fps} = useVideoConfig();
  const id = scene.id as ProductScene;
  const {layout, brand} = config;
  const mediaWidth = width - layout.margin * 2;
  const mediaHeight = layout.grid.mediaHeight;
  const split = Math.max(1, Math.min(scene.durationInFrames - 1,
    Math.round(scene.durationInFrames * config.motion.iphoneSplit)));
  const cue = [...config.score.cues].reverse().find((item) =>
    item.scene === id && frame >= Math.round(item.atSeconds * fps));
  const caption: CSSProperties = {
    fontSize: brand.typography.bodySize * 1.2,
    lineHeight: 1.15, letterSpacing: brand.typography.bodyTracking,
    maxWidth: mediaWidth - 260, fontWeight: 400, margin: 0,
  };

  return <AbsoluteFill>
    <div style={{
      position: 'absolute', left: layout.margin, top: 35,
      height: layout.captionHeight - 35, display: 'flex', alignItems: 'flex-start',
    }}><h2 style={caption}>{config.copy[id]}</h2></div>
    <div style={{position: 'absolute', right: layout.margin, top: 30}}>
      <SourceImage {...config.media.logo} width={166} height={58} />
    </div>
    <div style={{
      position: 'absolute', top: layout.grid.mediaTop, left: layout.margin,
      width: mediaWidth, height: mediaHeight,
      background: brand.colors.mediaMat,
    }}>
      {id === 'environment' ? <SourceImage {...config.media.environment} width={mediaWidth} height={mediaHeight} /> : null}
      {id === 'agent' ? <SourceVideo
        {...config.media.agent} width={mediaWidth} height={mediaHeight}
        durationInFrames={scene.durationInFrames}
      /> : null}
      {id === 'iphone' ? <SourceImage
        {...config.media.iphone[frame < split ? 0 : 1]} width={mediaWidth} height={mediaHeight}
      /> : null}
      {id === 'webQa' ? <SourceVideo
        {...config.media.webQa} width={mediaWidth} height={mediaHeight}
        durationInFrames={scene.durationInFrames}
        labelHeight={44}
        labelStyle={{
          background: brand.colors.ink, color: brand.colors.white, justifyContent: 'center',
          fontFamily: brand.typography.fontFamily, fontSize: 26,
        }}
      /> : null}
      {id === 'ipad' ? <SourceImage {...config.media.ipad} width={mediaWidth} height={mediaHeight} /> : null}
    </div>
    {cue ? <div style={{
      position: 'absolute', top: layout.grid.mediaTop + mediaHeight + 5,
      left: layout.margin, color: brand.colors.secondaryInk,
      fontFamily: brand.typography.monoFamily, fontSize: 17,
      lineHeight: 1,
    }}>{cue.label}</div> : null}
  </AbsoluteFill>;
};

export const Template = ({config}: {config: MusicalScoreConfig}) => {
  const {fps} = useVideoConfig();
  const timeline = makeTimeline(config.durations, fps);
  if (config.sound.enabled && (!config.sound.asset || /^(https?:|data:)/.test(config.sound.asset))) {
    throw new Error('Optional sound accents require a local file in the ignored public directory.');
  }
  return <AbsoluteFill style={{
    background: config.brand.colors.canvas,
    color: config.brand.colors.ink,
    fontFamily: config.brand.typography.fontFamily,
    letterSpacing: config.brand.typography.bodyTracking,
  }}>
    {timeline.map((scene) => <Sequence
      key={scene.id} from={scene.from} durationInFrames={scene.durationInFrames}
    >
      {scene.id === 'opening' || scene.id === 'closing'
        ? <TitleScene config={config} closing={scene.id === 'closing'} />
        : <Product config={config} scene={scene} />}
    </Sequence>)}
    <Score config={config} timeline={timeline} />
    {config.sound.enabled ? config.score.cues.map((cue, index) => {
      const scene = timeline.find((item) => item.id === cue.scene)!;
      const offset = Math.round(cue.atSeconds * fps);
      const duration = Math.min(scene.durationInFrames - offset, Math.round(config.sound.durationSeconds * fps));
      return duration > 0 && offset >= 0 ? <Sequence
        key={index} from={scene.from + offset} durationInFrames={duration} layout="none"
      ><Audio src={staticFile(config.sound.asset)} volume={config.sound.volume} /></Sequence> : null;
    }) : null}
  </AbsoluteFill>;
};
