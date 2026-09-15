import {AbsoluteFill, Sequence, useVideoConfig} from 'remotion';
import {makeTimeline, type SceneTiming} from '../shared/timeline';
import {SourceImage, SourceVideo} from '../shared/media';
import type {TemplateProps} from '../shared/contract';

const SmokeScene = ({config, scene}: TemplateProps & {scene: SceneTiming}) => {
  const {width, height} = useVideoConfig();
  const {margin, captionHeight} = config.layout;
  const mediaWidth = width - margin * 2;
  const mediaHeight = height - margin * 2 - captionHeight;
  const size = {width: mediaWidth, height: mediaHeight};
  const heading = {
    fontSize: config.brand.typography.headingSize,
    lineHeight: config.brand.typography.headingLineHeight,
    letterSpacing: config.brand.typography.headingTracking,
  };
  if (scene.id === 'opening' || scene.id === 'closing') {
    return <AbsoluteFill style={{padding: margin, justifyContent: 'center', gap: 32}}>
      <SourceImage {...config.media.logo} width={350} height={130} />
      <div style={heading}>{config.copy[scene.id]}</div>
      <div style={{fontSize: 42, maxWidth: 1600}}>
        {scene.id === 'opening' ? config.copy.benefit : config.copy.cta}
      </div>
      {scene.id === 'closing' ? <div>{config.copy.url}</div> : null}
      <div style={{fontFamily: config.brand.typography.monoFamily, fontSize: 22}}>
        FOUNDATION SMOKE • separate examples • 1920 × 1080 / 30 fps
      </div>
    </AbsoluteFill>;
  }
  return <AbsoluteFill style={{padding: margin}}>
    <div style={{height: captionHeight, fontSize: 42, lineHeight: 1.2}}>
      {config.copy[scene.id]}
    </div>
    {scene.id === 'environment' ? <SourceImage {...config.media.environment} {...size} /> : null}
    {scene.id === 'agent' || scene.id === 'webQa' ?
      <SourceVideo {...config.media[scene.id]} {...size} durationInFrames={scene.durationInFrames} /> : null}
    {scene.id === 'iphone' ? <>
      <Sequence durationInFrames={Math.floor(scene.durationInFrames / 2)} layout="none">
        <SourceImage {...config.media.iphone[0]} {...size} />
      </Sequence>
      <Sequence from={Math.floor(scene.durationInFrames / 2)} layout="none">
        <SourceImage {...config.media.iphone[1]} {...size} />
      </Sequence>
    </> : null}
    {scene.id === 'ipad' ? <SourceImage {...config.media.ipad} {...size} /> : null}
  </AbsoluteFill>;
};

export const Smoke = ({config}: TemplateProps) => {
  const {fps} = useVideoConfig();
  return <AbsoluteFill style={{
    backgroundColor: config.brand.colors.canvas,
    color: config.brand.colors.ink,
    fontFamily: config.brand.typography.fontFamily,
    fontSize: config.brand.typography.bodySize,
    lineHeight: config.brand.typography.bodyLineHeight,
    letterSpacing: config.brand.typography.bodyTracking,
  }}>
    {makeTimeline(config.durations, fps).map((scene) =>
      <Sequence key={scene.id} from={scene.from} durationInFrames={scene.durationInFrames}>
        <SmokeScene config={config} scene={scene} />
      </Sequence>,
    )}
  </AbsoluteFill>;
};
