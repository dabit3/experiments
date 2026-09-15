import {AbsoluteFill, Sequence, useCurrentFrame, useVideoConfig} from 'remotion';
import {makeTimeline, SourceImage, SourceVideo, type SceneTiming} from '../../shared';
import type {BroadcastConfig} from './config';
import {
  Closing, Demonstration, Evidence, productBounds, Title, Transition,
} from './components';

const Scene = ({config, scene}: {config: BroadcastConfig; scene: SceneTiming}) => {
  const frame = useCurrentFrame();
  const {width, height} = useVideoConfig();
  const box = productBounds(config, width, height);
  const size = {width: box.width, height: box.height};
  if (scene.id === 'opening') return <Title config={config} duration={scene.durationInFrames} />;
  if (scene.id === 'closing') return <Closing config={config} duration={scene.durationInFrames} />;

  const split = Math.max(1, Math.min(scene.durationInFrames - 1,
    Math.round(scene.durationInFrames * config.motion.iphoneSplit)));
  const stillIndex = frame < split ? 0 : 1;
  const note = scene.id === 'iphone'
    ? `${config.broadcast.stillLabel} ${stillIndex + 1}/2 · ${config.broadcast.montageLabel}`
    : scene.id === 'ipad' ? `${config.broadcast.stillLabel} · ${config.broadcast.montageLabel}` : undefined;

  return <Demonstration config={config} scene={scene.id} duration={scene.durationInFrames} note={note}>
    {scene.id === 'environment' ? <Transition config={config} frame={frame} duration={scene.durationInFrames}>
      <SourceImage {...config.media.environment} {...size} />
    </Transition> : null}
    {scene.id === 'agent' || scene.id === 'webQa' ?
      <SourceVideo {...config.media[scene.id]} {...size} durationInFrames={scene.durationInFrames}
        labelStyle={{
          background: config.brand.colors.ink, color: config.brand.colors.white,
          fontFamily: config.brand.typography.fontFamily,
        }} /> : null}
    {scene.id === 'iphone' ? <Evidence config={config} {...size}
      media={config.media.iphone[stillIndex]} frame={frame < split ? frame : frame - split}
      duration={frame < split ? split : scene.durationInFrames - split} /> : null}
    {scene.id === 'ipad' ? <Evidence config={config} {...size}
      media={config.media.ipad} frame={frame} duration={scene.durationInFrames} /> : null}
  </Demonstration>;
};

export const Template = ({config}: {config: BroadcastConfig}) => {
  const {fps} = useVideoConfig();
  return <AbsoluteFill style={{
    background: config.brand.colors.canvas, color: config.brand.colors.ink,
    fontFamily: config.brand.typography.fontFamily,
    fontSize: config.brand.typography.bodySize,
    lineHeight: config.brand.typography.bodyLineHeight,
    letterSpacing: config.brand.typography.bodyTracking,
  }}>
    {makeTimeline(config.durations, fps).map((scene) =>
      <Sequence key={scene.id} from={scene.from} durationInFrames={scene.durationInFrames}>
        <Scene config={config} scene={scene} />
      </Sequence>)}
  </AbsoluteFill>;
};
