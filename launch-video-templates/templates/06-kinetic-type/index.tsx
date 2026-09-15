import React from 'react';
import {
  AbsoluteFill,
  Audio,
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
import {config, timeline, type Scene} from './config';
import manifest from './template.json';
import beat from './original-beat.wav';

const palettes = {
  ink: {bg: '#111313', fg: brand.paper, subdued: '#a7afaa', rule: '#434a46'},
  paper: {bg: brand.paper, fg: '#111313', subdued: '#535d56', rule: '#c7ceca'},
  mint: {bg: brand.paleGreen, fg: '#111313', subdued: '#39584a', rule: '#9ebeb0'},
};

const enter = (frame: number) => interpolate(frame, [0, config.entranceFrames], [0, 1], {
  easing: Easing.out(Easing.cubic),
  extrapolateLeft: 'clamp',
  extrapolateRight: 'clamp',
});

const cropData = {
  maze: {src: sources.simulatorGame, x: 367, y: 129, w: 286, h: 584},
  wisp: {src: 'assets/devin-web-10.png', x: 359, y: 122, w: 306, h: 625},
  rescue: {src: sources.simulator, x: 359, y: 122, w: 306, h: 625},
};

const Phone: React.FC<{kind: NonNullable<Scene['phone']>}> = ({kind}) => {
  const crop = cropData[kind];
  const height = 764;
  const scale = height / crop.h;
  return (
    <div style={{
      position: 'absolute', right: 166, top: 185,
      width: crop.w * scale, height, overflow: 'hidden', borderRadius: 70,
      boxShadow: '0 24px 60px rgba(0,0,0,0.17)',
    }}>
      <Img src={staticFile(crop.src)} style={{
        position: 'absolute', width: 1568 * scale, maxWidth: 'none', height: 'auto',
        left: -crop.x * scale, top: -crop.y * scale,
      }}/>
    </div>
  );
};

const Type: React.FC<{scene: Scene; compact?: boolean}> = ({scene, compact = false}) => {
  const frame = useCurrentFrame();
  const isPhone = scene.kind === 'phone';
  return (
    <div style={{
      position: 'absolute', left: config.margin, right: isPhone ? 610 : config.margin,
      top: compact ? 137 : undefined, bottom: compact ? undefined : 227,
      fontSize: scene.size, fontWeight: 700, letterSpacing: '-0.065em', lineHeight: 0.98,
    }}>
      {scene.lines.map((line, index) => {
        const progress = enter(frame - index * 3);
        const scale = scene.motion === 'slam' ? 1.055 - 0.055 * progress : 1;
        const x = scene.motion === 'split' ? (index % 2 ? 48 : -48) * (1 - progress) : 0;
        const y = scene.motion === 'slam' ? 20 * (1 - progress) : 30 * (1 - progress);
        return (
          <div key={line} style={{
            whiteSpace: 'nowrap', transformOrigin: 'left center',
            transform: `translate(${x}px, ${y}px) scale(${scale})`,
          }}>{line}</div>
        );
      })}
    </div>
  );
};

const SceneFrame: React.FC<{scene: Scene; index: number}> = ({scene, index}) => {
  const frame = useCurrentFrame();
  const palette = palettes[scene.theme];
  const isMedia = scene.kind === 'review' || scene.kind === 'video';
  return (
    <AbsoluteFill style={{background: palette.bg, color: palette.fg, fontFamily: config.font}}>
      <div style={{
        position: 'absolute', top: 66, left: 96, right: 96,
        display: 'flex', justifyContent: 'space-between', alignItems: 'center',
        fontSize: 23, fontWeight: 600, letterSpacing: '0.06em',
      }}>
        <span>{scene.eyebrow}</span>
        <span style={{color: palette.subdued, fontWeight: 400}}>KINETIC TYPE / 06</span>
      </div>

      {scene.kind === 'logo' ? (
        <>
          <Img src={staticFile(sources.logoWhite)} style={{
            position: 'absolute', width: 908, height: 'auto', left: 506, top: 296,
            transform: `scale(${0.97 + 0.03 * enter(frame)})`,
          }}/>
          <div style={{position: 'absolute', top: 680, width: '100%', textAlign: 'center', fontSize: scene.size, letterSpacing: '-0.045em'}}>
            {scene.lines[0]}
          </div>
        </>
      ) : (
        <>
          <Type scene={scene} compact={isMedia}/>
          {scene.kind === 'phone' && scene.phone && <Phone kind={scene.phone}/>}
          {scene.kind === 'review' && (
            <Img src={staticFile('assets/devin-web-10.png')} style={{
              position: 'absolute', left: 355, top: 284, width: 1210, height: 'auto',
              border: `1px solid ${palette.rule}`,
            }}/>
          )}
          {scene.kind === 'video' && (
            <OffthreadVideo
              src={staticFile(sources.testingVideo)}
              muted
              trimBefore={config.sourceVideoStartSeconds * manifest.fps}
              style={{position: 'absolute', left: 365, top: 282, width: 1190, height: 'auto'}}
            />
          )}
          <div style={{
            position: 'absolute', left: 100, top: isMedia ? 974 : 900,
            fontSize: isMedia ? 25 : 30, letterSpacing: '-0.02em', color: palette.subdued,
          }}>{scene.note}</div>
          {scene.kind === 'phone' && (
            <div style={{
              position: 'absolute', right: 142, top: 970, width: 424,
              textAlign: 'center', fontSize: 19, color: palette.subdued,
            }}>iPhone Simulator · Illustrative workflow</div>
          )}
        </>
      )}

      <div style={{
        position: 'absolute', bottom: 36, left: 96, right: 96,
        display: 'flex', gap: 7,
      }}>
        {timeline.map((item, itemIndex) => (
          <div key={item.id} style={{
            flex: item.beats, height: 3,
            background: itemIndex === index ? palette.fg : palette.rule,
          }}/>
        ))}
      </div>
    </AbsoluteFill>
  );
};

const Launch: React.FC = () => (
  <AbsoluteFill>
    <Audio src={beat} volume={0.8}/>
    {timeline.map((scene, index) => (
      <Sequence key={scene.id} from={scene.from} durationInFrames={scene.duration}>
        <SceneFrame scene={scene} index={index}/>
      </Sequence>
    ))}
  </AbsoluteFill>
);

registerRoot(() => (
  <Composition
    id="Launch"
    component={Launch}
    durationInFrames={manifest.durationSeconds * manifest.fps}
    fps={manifest.fps}
    width={manifest.width}
    height={manifest.height}
  />
));
