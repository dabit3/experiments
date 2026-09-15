import React from 'react';
import {
  AbsoluteFill,
  Composition,
  Easing,
  Img,
  OffthreadVideo,
  Sequence,
  interpolate,
  interpolateColors,
  registerRoot,
  staticFile,
  useCurrentFrame,
} from 'remotion';
import {brand, sources} from '../../shared/brand';
import {config, durationInFrames, sceneStarts, type Scene} from './config';

const clamp = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'} as const;
const easeOut = Easing.out(Easing.cubic);
const easeInOut = Easing.inOut(Easing.cubic);
const muted = '#68736f';

const Phone: React.FC<{variant?: 'wisp' | 'rescue'; width?: number}> = ({
  variant = 'rescue',
  width = 318,
}) => {
  const crop = variant === 'rescue'
    ? {source: sources.simulator, x: 681, y: 237, w: 579, h: 1182, full: 2978}
    : {source: 'assets/devin-web-10.png', x: 683, y: 236, w: 579, h: 1182, full: 2990};
  const scale = width / crop.w;
  return (
    <div style={{
      position: 'relative',
      width,
      height: crop.h * scale,
      overflow: 'hidden',
      borderRadius: width * 0.17,
      boxShadow: '0 24px 48px rgba(27,47,51,0.12)',
    }}>
      <Img src={staticFile(crop.source)} style={{
        position: 'absolute',
        width: crop.full * scale,
        maxWidth: 'none',
        height: 'auto',
        left: -crop.x * scale,
        top: -crop.y * scale,
      }}/>
    </div>
  );
};

const Tag: React.FC<{children: React.ReactNode; color?: string}> = ({
  children, color = brand.blue,
}) => (
  <div style={{
    display: 'inline-flex',
    alignItems: 'center',
    gap: 12,
    padding: '12px 18px',
    border: `1px solid ${color}30`,
    borderRadius: 9,
    background: '#ffffff',
    color,
    fontSize: 21,
    fontWeight: 500,
    letterSpacing: -0.2,
  }}>
    <span style={{width: 7, height: 7, borderRadius: '50%', background: color}}/>
    {children}
  </div>
);

const Mesh: React.FC = () => {
  const frame = useCurrentFrame();
  const index = sceneStarts.reduce((current, start, next) => frame >= start ? next : current, 0);
  const local = frame - sceneStarts[index];
  const hue = interpolateColors(
    easeInOut(Math.min(1, local / config.hueShiftFrames)),
    [0, 1],
    [config.scenes[Math.max(0, index - 1)].hue, config.scenes[index].hue],
  );
  const drift = Math.sin((frame / durationInFrames) * Math.PI * 2);
  return (
    <AbsoluteFill style={{background: '#edf2f0', overflow: 'hidden'}}>
      <div style={{
        position: 'absolute', inset: -120, opacity: 0.22,
        background: `radial-gradient(ellipse at ${24 + drift * 7}% 12%, ${hue} 0%, transparent 54%),
          radial-gradient(ellipse at 88% ${67 + drift * 8}%, ${brand.purple} 0%, transparent 48%),
          radial-gradient(ellipse at 15% 95%, ${brand.green} 0%, transparent 52%)`,
      }}/>
      <div style={{
        position: 'absolute', inset: 0,
        background: 'linear-gradient(120deg, rgba(255,255,255,.4), transparent 70%)',
      }}/>
    </AbsoluteFill>
  );
};

const StepRail: React.FC<{
  title: string;
  steps: readonly string[];
  active: number;
  color: string;
  footnote?: string;
}> = ({title, steps, active, color, footnote}) => (
  <div style={{width: 300}}>
    <div style={{
      fontSize: 18, letterSpacing: 2, color: muted,
      marginBottom: 30, fontWeight: 500,
    }}>{title}</div>
    {steps.map((step, index) => (
      <div key={step} style={{
        height: 74, display: 'flex', gap: 16, alignItems: 'center',
        borderBottom: `1px solid ${brand.border}`,
        color: index === active ? brand.ink : '#939a97',
        fontSize: 26, fontWeight: index === active ? 500 : 400,
      }}>
        <span style={{
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          height: 27, width: 27, borderRadius: '50%',
          border: `1px solid ${index === active ? color : '#dbe0de'}`,
          color: index === active ? color : '#939a97',
          fontSize: 14,
        }}>{index + 1}</span>
        {step}
      </div>
    ))}
    {footnote ? <div style={{
      color: muted, fontSize: 19, lineHeight: 1.5, marginTop: 28,
    }}>{footnote}</div> : null}
  </div>
);

const NativeStage: React.FC<{scene: Scene}> = ({scene}) => {
  const frame = useCurrentFrame();
  const active = Math.min(2, Math.floor(Math.max(0, frame - 28) / 39));
  const isRepair = scene.kind === 'repair';
  const isInteraction = scene.kind === 'interact';
  const isBuild = scene.kind === 'build';
  const hasRail = isBuild || isInteraction || isRepair;
  const phoneX = hasRail ? 1260 : 1170;
  return (
    <>
      <div style={{
        position: 'absolute', left: 914, top: 208, width: 816, height: 682,
        borderRadius: 16,
        background: `radial-gradient(ellipse at 64% 45%, ${scene.hue}13, ${scene.hue}04 70%, transparent)`,
      }}/>
      <div style={{
        position: 'absolute', left: phoneX, top: 212,
      }}>
        <Phone variant={isRepair || isInteraction ? 'wisp' : 'rescue'} width={318}/>
      </div>
      {hasRail ? (
        <div style={{position: 'absolute', left: 914, top: isRepair ? 328 : 364}}>
          <StepRail
            title={isBuild ? 'MANAGED MAC VM' : isInteraction ? 'IOS SIMULATOR' : 'THE NEXT ACTION'}
            steps={isBuild
              ? ['Build the app', 'Run the app', 'Open Simulator']
              : isInteraction ? ['Tap', 'Type', 'Scroll'] : ['Reproduce', 'Fix', 'Retest']}
            active={active}
            color={scene.hue}
            footnote={isRepair ? 'Source finding:\nModel details absent.' : undefined}
          />
        </div>
      ) : (
        <>
          <div style={{position: 'absolute', left: 940, top: 333}}>
            <Tag color={scene.hue}>{scene.kind === 'outcome' ? 'In your session' : 'Managed Mac VM'}</Tag>
          </div>
          <div style={{position: 'absolute', left: 1440, top: 758}}>
            <Tag color={scene.hue}>iPhone Simulator</Tag>
          </div>
        </>
      )}
    </>
  );
};

const ContextVisual: React.FC = () => (
  <div style={{position: 'absolute', left: 992, top: 280, width: 650}}>
    <div style={{
      display: 'flex', justifyContent: 'space-between', alignItems: 'center',
      paddingBottom: 34, borderBottom: `1px solid ${brand.border}`,
      color: muted, fontSize: 28,
    }}>
      <span>Manual QA</span>
      <span style={{fontSize: 34, color: '#a1aaa5'}}>↗</span>
    </div>
    <div style={{fontSize: 176, lineHeight: 1, letterSpacing: -11, marginTop: 48, color: '#665875'}}>
      20<span style={{fontWeight: 300}}>+</span>
      <span style={{fontSize: 44, letterSpacing: -1, marginLeft: 20}}>min</span>
    </div>
    <div style={{fontSize: 28, color: muted, marginTop: 24}}>Waiting for CI feedback</div>
    <div style={{
      marginTop: 58, borderTop: `1px solid ${brand.border}`, paddingTop: 24,
      color: muted, fontSize: 20,
    }}>Before Devin on macOS + iOS</div>
  </div>
);

const EvidenceVisual: React.FC = () => (
  <div style={{
    position: 'absolute', left: 858, top: 281, width: 890,
    overflow: 'hidden', border: `1px solid ${brand.border}`,
    borderRadius: 12, background: '#f8f9f8',
  }}>
    <div style={{
      height: 51, display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      padding: '0 22px', fontSize: 18, color: '#55665d',
      borderBottom: `1px solid ${brand.border}`,
    }}>
      <span>Recorded evidence</span>
      <span>Generic web QA</span>
    </div>
    <OffthreadVideo
      src={staticFile(sources.testingVideo)}
      startFrom={config.sourceVideoStartSeconds * config.fps}
      muted
      style={{display: 'block', width: '100%', height: 890 * 1080 / 1918, objectFit: 'contain'}}
    />
  </div>
);

const SceneContent: React.FC<{scene: Scene}> = ({scene}) => {
  const frame = useCurrentFrame();
  const entrance = interpolate(frame, [0, config.entranceFrames], [18, 0], {
    ...clamp, easing: easeOut,
  });
  if (scene.kind === 'end') {
    return (
      <AbsoluteFill style={{
        alignItems: 'center', justifyContent: 'center',
        transform: `translateY(${entrance}px)`,
      }}>
        <Img src={staticFile(sources.logoBlack)} style={{
          width: 486, height: 'auto', objectFit: 'contain',
        }}/>
        <div style={{
          marginTop: 39, color: muted, fontSize: 31, letterSpacing: -0.5,
        }}>{scene.headline}</div>
        <div style={{
          marginTop: 42, fontSize: 62, fontWeight: 400, letterSpacing: -2.6,
        }}>{scene.detail}</div>
      </AbsoluteFill>
    );
  }
  return (
    <AbsoluteFill style={{
      transform: scene.kind === 'evidence' ? undefined : `translateY(${entrance}px)`,
    }}>
      <div style={{position: 'absolute', left: 176, top: 312, width: 675}}>
        <div style={{
          fontSize: 19, letterSpacing: 2.2, fontWeight: 500, color: scene.hue,
          marginBottom: 32,
        }}>{scene.eyebrow}</div>
        <h1 style={{
          fontSize: scene.kind === 'outcome' ? 84 : 92,
          fontWeight: 400, lineHeight: 1.055, letterSpacing: -4.3,
          margin: 0, whiteSpace: 'pre-line',
        }}>{scene.headline}</h1>
        <p style={{
          marginTop: 36, fontSize: 27, lineHeight: 1.45,
          maxWidth: 560, color: muted, letterSpacing: -0.4,
        }}>{scene.detail}</p>
        {scene.kind === 'outcome' ? (
          <div style={{
            marginTop: 30, width: 92, height: 3, background: scene.hue,
          }}/>
        ) : null}
      </div>
      {scene.kind === 'context' ? <ContextVisual/>
        : scene.kind === 'evidence' ? <EvidenceVisual/>
          : <NativeStage scene={scene}/>}
      <div style={{
        position: 'absolute', left: 176, right: 176, top: 888,
        paddingTop: 18, borderTop: `1px solid ${brand.border}`,
        fontSize: 17, color: '#74807b', letterSpacing: 0.2,
      }}>{scene.label}</div>
    </AbsoluteFill>
  );
};

const Launch: React.FC = () => {
  const frame = useCurrentFrame();
  const index = sceneStarts.reduce((current, start, next) => frame >= start ? next : current, 0);
  return (
    <AbsoluteFill style={{fontFamily: config.font, color: brand.ink}}>
      <Mesh/>
      <div style={{
        position: 'absolute', left: 104, top: 78, right: 104,
        display: 'flex', justifyContent: 'space-between', alignItems: 'center',
      }}>
        <div style={{display: 'flex', alignItems: 'center', gap: 20}}>
          <Img src={staticFile(sources.markBlack)} style={{width: 37, height: 37}}/>
          <span style={{fontSize: 22, fontWeight: 500, letterSpacing: -0.5}}>Devin</span>
          <span style={{width: 1, height: 21, margin: '0 4px', background: '#b4c0ba'}}/>
          <span style={{fontSize: 20, color: '#52645c'}}>Native apps</span>
        </div>
        <span style={{fontSize: 18, letterSpacing: 1.7, color: '#52645c'}}>macOS + iOS</span>
      </div>
      <div style={{
        position: 'absolute', left: 104, top: 166, width: 1712, height: 780,
        borderRadius: 22, border: `1px solid ${brand.border}`,
        background: 'rgba(255,255,255,0.97)',
        boxShadow: '0 16px 64px rgba(38,61,53,0.035)',
      }}/>
      {config.scenes.map((scene, sceneIndex) => (
        <Sequence
          key={scene.kind}
          from={sceneStarts[sceneIndex]}
          durationInFrames={scene.seconds * config.fps}
        >
          <SceneContent scene={scene}/>
        </Sequence>
      ))}
      <div style={{
        position: 'absolute', left: 104, right: 104, top: 990,
        display: 'flex', justifyContent: 'space-between', alignItems: 'center',
        color: '#52645c',
      }}>
        <span style={{fontSize: 17, letterSpacing: 1.6}}>BUILT TO BE SEEN.</span>
        <div style={{display: 'flex', gap: 10, alignItems: 'center'}}>
          {config.scenes.map((scene, sceneIndex) => (
            <span key={scene.kind} style={{
              width: 44, height: 3,
              background: index === sceneIndex ? scene.hue : '#c1cec7',
            }}/>
          ))}
        </div>
      </div>
    </AbsoluteFill>
  );
};

const Root: React.FC = () => (
  <Composition
    id="Launch"
    component={Launch}
    width={config.width}
    height={config.height}
    fps={config.fps}
    durationInFrames={durationInFrames}
  />
);

registerRoot(Root);
