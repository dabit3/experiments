import type {CSSProperties, ReactNode} from 'react';
import {
  AbsoluteFill,
  Composition,
  Easing,
  Img,
  OffthreadVideo,
  Sequence,
  interpolate,
  registerRoot,
  staticFile,
  useCurrentFrame,
} from 'remotion';
import {brand, sources} from '../../shared/brand';
import {config, type Scene} from './config';
import metadata from './template.json';

const clamp = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'} as const;
const easeOut = Easing.out(Easing.cubic);
const easeInOut = Easing.inOut(Easing.cubic);
const shadow = '0 16px 40px rgba(25,25,25,0.14)';

const fade = (frame: number, start: number, length: number) =>
  interpolate(frame, [start, start + length], [0, 1], {...clamp, easing: easeOut});

const push = (frame: number, duration: number) =>
  interpolate(frame, [0, duration], [1, config.pushIn], {...clamp, easing: easeInOut});

const Headline = ({
  children,
  style,
}: {
  children: ReactNode;
  style?: CSSProperties;
}) => (
  <div
    style={{
      fontSize: 126,
      fontWeight: 500,
      lineHeight: 1.04,
      letterSpacing: -6,
      whiteSpace: 'pre-line',
      ...style,
    }}
  >
    {children}
  </div>
);

const Phone = ({kind}: {kind: 'game' | 'rescue'}) => {
  const crop = kind === 'game'
    ? {src: sources.simulatorGame, originalWidth: 2986, x: 704, y: 256, w: 533, h: 1090}
    : {src: sources.simulator, originalWidth: 2978, x: 689, y: 240, w: 567, h: 1172};
  const height = 812;
  const scale = height / crop.h;
  return (
    <div
      style={{
        width: crop.w * scale,
        height,
        overflow: 'hidden',
        position: 'relative',
        borderRadius: 78,
        background: '#080b0c',
        boxShadow: shadow,
      }}
    >
      <Img
        src={staticFile(crop.src)}
        style={{
          position: 'absolute',
          width: crop.originalWidth * scale,
          maxWidth: 'none',
          height: 'auto',
          left: -crop.x * scale,
          top: -crop.y * scale,
        }}
      />
    </div>
  );
};

const Hero = ({
  scene,
  frame,
  duration,
  copyOpacity,
}: {
  scene: Scene;
  frame: number;
  duration: number;
  copyOpacity: number;
}) => {
  const outcome = scene.id === 'outcome';
  const priceOut = outcome ? fade(frame, scene.priceRevealFrame, config.copyFadeFrames) : 0;
  const priceIn = outcome ? fade(frame, scene.priceRevealFrame + config.copyFadeFrames, config.copyFadeFrames) : 0;
  return (
    <AbsoluteFill>
      <div style={{position: 'absolute', left: 158, top: outcome ? 298 : 300, width: 990, opacity: copyOpacity}}>
        <Headline style={{opacity: 1 - priceOut}}>{scene.headline}</Headline>
        {outcome && (
          <Headline style={{position: 'absolute', top: 58, left: 0, opacity: priceIn, fontSize: 116}}>
            {scene.priceHeadline}
          </Headline>
        )}
      </div>
      <div
        style={{
          position: 'absolute',
          left: 1268,
          top: 132,
          transform: `scale(${push(frame, duration)})`,
          transformOrigin: 'center',
        }}
      >
        <Phone kind={outcome ? 'rescue' : 'game'} />
      </div>
      <div style={{position: 'absolute', bottom: 53, left: 158, fontSize: 22, color: '#747474'}}>
        Illustrative workflow
      </div>
    </AbsoluteFill>
  );
};

const Feature = ({
  scene,
  frame,
  duration,
  copyOpacity,
}: {
  scene: Extract<Scene, {asset: string}>;
  frame: number;
  duration: number;
  copyOpacity: number;
}) => {
  const reveal = fade(
    frame,
    config.featureRevealFrame + config.featureMediaDelayFrames,
    config.featureRevealDuration - config.featureMediaDelayFrames,
  );
  const titleOut = fade(frame, config.featureRevealFrame, config.featureTitleFadeFrames);
  const isVideo = scene.id === 'evidence';
  return (
    <AbsoluteFill>
      <AbsoluteFill
        style={{
          alignItems: 'center',
          justifyContent: 'center',
          opacity: copyOpacity * (1 - titleOut),
          transform: `scale(${interpolate(reveal, [0, 1], [1, 1.03])})`,
        }}
      >
        <Headline style={{textAlign: 'center', fontSize: 132}}>{scene.headline}</Headline>
        {scene.subline && (
          <div style={{fontSize: 36, color: '#767676', marginTop: 32, letterSpacing: -0.8}}>
            {scene.subline}
          </div>
        )}
      </AbsoluteFill>
      <AbsoluteFill style={{opacity: reveal, alignItems: 'center', justifyContent: 'center'}}>
        <div
          style={{
            width: isVideo ? 1696 : 1740,
            borderRadius: 18,
            overflow: 'hidden',
            boxShadow: shadow,
            transform: `scale(${push(frame - config.featureRevealFrame, duration - config.featureRevealFrame)})`,
          }}
        >
          {isVideo ? (
            <Sequence from={config.featureRevealFrame} layout="none">
              <OffthreadVideo
                src={staticFile(scene.asset)}
                muted
                trimBefore={scene.videoStartSeconds * metadata.fps}
                style={{display: 'block', width: '100%', height: 'auto'}}
              />
            </Sequence>
          ) : (
            <Img src={staticFile(scene.asset)} style={{display: 'block', width: '100%', height: 'auto'}} />
          )}
        </div>
        {isVideo && (
          <div style={{position: 'absolute', bottom: 14, fontSize: 22, color: '#5e5e5e'}}>
            Recorded web QA · source footage
          </div>
        )}
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

const SceneContent = ({scene, duration}: {scene: Scene; duration: number}) => {
  const frame = useCurrentFrame();
  const enter = scene.id === 'hook' ? 1 : fade(frame, config.copyFadeFrames, config.copyFadeFrames);
  const copyOpacity = enter * (1 - fade(frame, duration, config.copyFadeFrames));
  if (scene.id === 'hook' || scene.id === 'outcome') {
    return <Hero scene={scene} frame={frame} duration={duration} copyOpacity={copyOpacity} />;
  }
  if ('asset' in scene) {
    return <Feature scene={scene} frame={frame} duration={duration} copyOpacity={copyOpacity} />;
  }
  if (scene.id === 'end') {
    return (
      <AbsoluteFill style={{alignItems: 'center', justifyContent: 'center', opacity: copyOpacity}}>
        <div style={{width: 630, transform: `scale(${push(frame, duration)})`}}>
          <Img src={staticFile(sources.logoBlack)} style={{display: 'block', width: '100%', height: 'auto'}} />
        </div>
        <div style={{fontSize: 40, fontWeight: 500, letterSpacing: -1.2, marginTop: 42}}>
          {scene.headline}
        </div>
        <div style={{fontSize: 30, color: '#737373', marginTop: 26, letterSpacing: -0.6}}>
          {scene.cta}
        </div>
      </AbsoluteFill>
    );
  }
  return (
    <AbsoluteFill style={{alignItems: 'center', justifyContent: 'center'}}>
      <Headline style={{fontSize: 118, textAlign: 'center', opacity: copyOpacity, transform: `scale(${push(frame, duration)})`}}>
        {scene.headline}
      </Headline>
    </AbsoluteFill>
  );
};

const SceneLayer = ({scene, duration, first}: {scene: Scene; duration: number; first: boolean}) => {
  const frame = useCurrentFrame();
  return (
    <AbsoluteFill
      style={{
        backgroundColor: config.background,
        opacity: first ? 1 : fade(frame, 0, config.transitionFrames),
      }}
    >
      <SceneContent scene={scene} duration={duration} />
    </AbsoluteFill>
  );
};

const Launch = () => {
  let start = 0;
  return (
    <AbsoluteFill style={{background: config.background, color: brand.ink, fontFamily: config.font}}>
      {config.scenes.map((scene, index) => {
        const duration = scene.seconds * metadata.fps;
        const from = start;
        start += duration;
        return (
          <Sequence key={scene.id} from={from} durationInFrames={duration + (index < config.scenes.length - 1 ? config.transitionFrames : 0)}>
            <SceneLayer scene={scene} duration={duration} first={index === 0} />
          </Sequence>
        );
      })}
    </AbsoluteFill>
  );
};

const Root = () => (
  <Composition
    id={metadata.compositionId}
    component={Launch}
    width={metadata.width}
    height={metadata.height}
    fps={metadata.fps}
    durationInFrames={config.scenes.reduce((sum, scene) => sum + scene.seconds * metadata.fps, 0)}
  />
);

registerRoot(Root);
