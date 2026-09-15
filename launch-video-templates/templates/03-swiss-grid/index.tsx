import React from 'react';
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
import {design, media, scenes, type CropSource, type Scene} from './config';
import manifest from './template.json';

const columnX = (column: number) =>
  design.margin + column * (design.column + design.gutter);
const span = (columns: number) =>
  columns * design.column + (columns - 1) * design.gutter;
const clamp = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'} as const;
const easeOut = Easing.out(Easing.cubic);
const easeMove = Easing.inOut(Easing.cubic);

const Text: React.FC<{
  children: React.ReactNode;
  size?: keyof typeof design.sizes;
  style?: React.CSSProperties;
}> = ({children, size = 'label', style}) => (
  <div style={{
    fontSize: design.sizes[size],
    lineHeight: size === 'headline' ? 1.02 : 1.2,
    letterSpacing: size === 'headline' ? -5 : size === 'body' ? -1.5 : 0,
    whiteSpace: 'pre-line',
    fontWeight: size === 'headline' ? 500 : 400,
    textAlign: 'left',
    ...style,
  }}>{children}</div>
);

const Crop: React.FC<{source: CropSource; width: number; phone?: boolean}> = ({
  source, width, phone = false,
}) => {
  const scale = width / source.crop.width;
  return (
    <div style={{
      width,
      height: source.crop.height * scale,
      overflow: 'hidden',
      position: 'relative',
      borderRadius: phone ? width * 0.16 : 0,
    }}>
      <Img src={staticFile(source.src)} style={{
        position: 'absolute',
        maxWidth: 'none',
        width: source.width * scale,
        height: source.height * scale,
        left: -source.crop.x * scale,
        top: -source.crop.y * scale,
        filter: 'grayscale(1)',
      }}/>
    </div>
  );
};

const Rule: React.FC<{top: number; left?: number; width?: number; color?: string}> = ({
  top, left = design.margin, width = span(12), color = '#c9c9c9',
}) => <div style={{position: 'absolute', top, left, width, height: 1, background: color}}/>;

const Grid: React.FC<{frame: number; duration: number}> = ({frame, duration}) => {
  const opacity = interpolate(
    frame,
    [0, design.entranceFrames, duration - design.transitionFrames, duration - 1],
    [0.15, 0.025, 0.025, 0.15],
    clamp,
  );
  return <AbsoluteFill style={{pointerEvents: 'none'}}>
    {Array.from({length: 12}, (_, i) => (
      <div key={i} style={{
        position: 'absolute',
        top: 0,
        bottom: 0,
        left: columnX(i),
        width: design.column,
        borderLeft: `1px solid ${design.accent}`,
        borderRight: `1px solid ${design.accent}`,
        opacity,
      }}/>
    ))}
  </AbsoluteFill>;
};

const Rail: React.FC<{scene: Scene; index: number}> = ({scene, index}) => (
  <>
    {['CONTEXT', 'WORKFLOW', 'OUTCOME'].map((label, i) => (
      <div key={label} style={{
        position: 'absolute',
        left: columnX(i * 4),
        top: 48,
        width: span(4),
        display: 'flex',
        gap: 32,
        color: scene.section === i + 1 ? design.accent : design.muted,
      }}>
        <Text>{`0${i + 1}`}</Text>
        <Text>{label}</Text>
      </div>
    ))}
    <Rule top={108}/>
    <Rule top={968}/>
    <Text style={{position: 'absolute', left: 96, top: 994, color: design.muted}}>
      {scene.footer}
    </Text>
    <Text style={{position: 'absolute', left: columnX(11), top: 994}}>
      {`${String(index + 1).padStart(2, '0')} / 08`}
    </Text>
  </>
);

const StepRows: React.FC<{labels: readonly string[]; active: number; width?: number}> = ({
  labels, active, width = span(4),
}) => (
  <div style={{width}}>
    {labels.map((label, index) => (
      <div key={label} style={{
        height: 76,
        borderTop: '1px solid #c9c9c9',
        display: 'flex',
        alignItems: 'center',
        gap: 32,
        color: index === active ? design.accent : design.muted,
      }}>
        <div style={{
          width: 12, height: 12,
          background: index === active ? design.accent : 'transparent',
          border: `1px solid ${index === active ? design.accent : '#b5b5b5'}`,
        }}/>
        <Text>{label}</Text>
      </div>
    ))}
  </div>
);

const SceneContent: React.FC<{scene: Scene; frame: number}> = ({scene, frame}) => {
  const entrance = scene.id === 'evidence' ? 0 : interpolate(frame, [0, design.entranceFrames], [24, 0], {
    ...clamp, easing: easeOut,
  });
  const phoneBase: React.CSSProperties = {
    position: 'absolute', left: columnX(8), top: 194,
    transform: `translateX(${entrance}px)`,
  };
  if (scene.id === 'context') {
    return <div style={{
      position: 'absolute', left: columnX(8), top: 292,
      transform: `translateY(${entrance}px)`, width: span(4),
    }}>
      <Text size="headline" style={{color: design.accent}}>20+</Text>
      <Text size="body" style={{marginTop: 20}}>minutes</Text>
      <div style={{height: 1, background: design.ink, marginTop: 62}}/>
      <Text style={{marginTop: 24}}>Waiting for CI feedback.</Text>
      <Text style={{marginTop: 16, color: design.muted}}>The prior workflow.</Text>
    </div>;
  }
  if (scene.id === 'hook') {
    return <>
      <div style={phoneBase}><Crop source={media.charts} width={350} phone/></div>
      <Text style={{
        position: 'absolute', left: columnX(8), top: 936, color: design.muted,
      }}>iPhone Simulator / source still</Text>
      <div style={{position: 'absolute', left: 96, top: 772, width: span(6)}}>
        <Rule top={0} left={0} width={span(6)} color={design.ink}/>
        <Text style={{paddingTop: 24}}>MACOS + IOS / NOW AVAILABLE</Text>
      </div>
    </>;
  }
  if (scene.id === 'build') {
    const active = frame < 72 ? 0 : frame < 114 ? 1 : 2;
    return <>
      <div style={{...phoneBase, top: 204}}>
        <Crop source={media.maze} width={350} phone/>
      </div>
      <div style={{position: 'absolute', left: 96, top: 662}}>
        <StepRows labels={['Xcode project', 'Build on macOS', 'Run in iOS Simulator']} active={active}/>
      </div>
      <Text style={{position: 'absolute', left: columnX(8), top: 918}}>
        Native app / iOS Simulator
      </Text>
    </>;
  }
  if (scene.id === 'interact') {
    const active = frame < 60 ? 0 : frame < 114 ? 1 : 2;
    const cursorY = interpolate(frame, [34, 58, 94, 114, 148, 165],
      [256, 478, 478, 545, 545, 396], {...clamp, easing: easeMove});
    return <>
      <div style={phoneBase}>
        <Crop source={frame < 60 ? media.wispStart : media.wispChat} width={350} phone/>
        <div style={{
          position: 'absolute', left: 236, top: cursorY,
          width: 30, height: 30, border: `3px solid ${design.accent}`,
          borderRadius: '50%', background: 'rgba(25,113,194,0.12)',
          opacity: frame > 24 ? 1 : 0,
        }}/>
      </div>
      <div style={{position: 'absolute', left: columnX(4), top: 732}}>
        <StepRows labels={['Tap controls', 'Type input', 'Scroll views']} active={active} width={span(3)}/>
      </div>
    </>;
  }
  if (scene.id === 'repair') {
    const active = frame < 64 ? 0 : frame < 120 ? 1 : 2;
    return <>
      <div style={{
        position: 'absolute', left: columnX(6), top: 210,
        transform: `translateX(${entrance}px)`,
      }}>
        <Crop source={media.wispChat} width={270} phone/>
      </div>
      <div style={{
        position: 'absolute', left: columnX(9), top: 216, width: span(3),
        borderTop: `2px solid ${design.accent}`, paddingTop: 16,
        transform: `translateX(${entrance}px)`,
      }}>
        <Text style={{marginBottom: 24, color: design.accent}}>SOURCE FINDINGS</Text>
        <Crop source={media.nativeEvidence} width={span(3)}/>
        <Text style={{marginTop: 24}}>Passed, failed, untested.</Text>
      </div>
      <div style={{
        position: 'absolute', left: columnX(6), top: 808,
        width: span(6), display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 24,
      }}>
        {['Reproduce\nthe issue', 'Fix\nthe code', 'Run\nthe check again'].map((label, i) => (
          <div key={label} style={{
            borderTop: `2px solid ${active === i ? design.accent : '#c9c9c9'}`,
            paddingTop: 20, color: active === i ? design.accent : design.muted,
          }}><Text>{label}</Text></div>
        ))}
      </div>
    </>;
  }
  if (scene.id === 'evidence') {
    return <div style={{
      position: 'absolute', left: columnX(4), top: 200, width: span(8),
    }}>
      <Text style={{marginBottom: 22, color: design.accent}}>
        RECORDED WEB QA / SOURCE CLIP
      </Text>
      <div style={{border: '1px solid #c9c9c9'}}>
        <OffthreadVideo
          src={staticFile(media.qaVideo)}
          trimBefore={media.qaStartSeconds * manifest.fps}
          muted
          style={{width: '100%', display: 'block', filter: 'grayscale(1)'}}
        />
      </div>
      <Text style={{marginTop: 24, color: design.muted}}>
        Actions and review notes, together.
      </Text>
    </div>;
  }
  if (scene.id === 'outcome') {
    return <>
      <div style={phoneBase}><Crop source={media.charts} width={350} phone/></div>
      <div style={{position: 'absolute', left: 96, top: 752}}>
        <Rule top={0} left={0} width={span(6)} color={design.accent}/>
        <Text style={{paddingTop: 24, color: design.accent}}>
          OPEN THE SESSION. INSPECT THE APP.
        </Text>
      </div>
    </>;
  }
  return <>
    <Img src={staticFile(media.logo)} style={{
      position: 'absolute', left: 96, top: 242, width: 730,
      height: 'auto', transform: `translateY(${entrance}px)`,
    }}/>
    <Text size="headline" style={{position: 'absolute', left: 96, top: 568}}>
      {scene.headline}
    </Text>
    <Text size="body" style={{position: 'absolute', left: 96, top: 730, color: design.accent}}>
      {scene.detail}
    </Text>
    <div style={{
      position: 'absolute', left: columnX(8), top: 252, width: span(4),
      borderTop: `2px solid ${design.accent}`, paddingTop: 24,
    }}>
      <Text>NATIVE DEVELOPMENT</Text>
      <Text style={{marginTop: 36, color: design.muted}}>One session.</Text>
      <Text style={{marginTop: 16, color: design.muted}}>A working app.</Text>
      <Text style={{marginTop: 16, color: design.muted}}>Visible evidence.</Text>
    </div>
  </>;
};

const SceneFrame: React.FC<{scene: Scene; index: number; duration: number}> = ({
  scene, index, duration,
}) => {
  const frame = useCurrentFrame();
  const entrance = interpolate(frame, [0, design.entranceFrames], [24, 0], {
    ...clamp, easing: easeOut,
  });
  const exit = scene.id === 'evidence' ? 0 : interpolate(frame, [duration - design.transitionFrames, duration - 1], [0, -12], {
    ...clamp, easing: easeMove,
  });
  const isThreeLine = ['interact', 'repair', 'evidence'].includes(scene.id);
  return <AbsoluteFill style={{
    backgroundColor: design.paper, color: design.ink, fontFamily: design.font,
  }}>
    <Grid frame={frame} duration={duration}/>
    <Rail scene={scene} index={index}/>
    <div style={{transform: `translateY(${exit}px)`}}>
      <Text style={{
        position: 'absolute', left: 96, top: 158, color: design.accent,
      }}>{scene.label}</Text>
      {scene.id !== 'end' && <div style={{
        position: 'absolute', left: 96, top: 266,
        width: scene.id === 'evidence' ? span(4) : span(8),
        transform: `translateY(${scene.id === 'evidence' ? 0 : entrance}px)`,
      }}>
        <Text size="headline">{scene.headline}</Text>
        <Text size="body" style={{
          marginTop: isThreeLine ? 36 : 48,
          maxWidth: scene.id === 'evidence' ? span(4) : span(7),
          color: design.muted,
        }}>{scene.detail}</Text>
      </div>}
      <SceneContent scene={scene} frame={frame}/>
    </div>
  </AbsoluteFill>;
};

const Launch: React.FC = () => {
  let from = 0;
  return <AbsoluteFill>
    {scenes.map((scene, index) => {
      const duration = Math.round(scene.seconds * manifest.fps);
      const start = from;
      from += duration;
      return <Sequence key={scene.id} from={start} durationInFrames={duration}>
        <SceneFrame scene={scene} index={index} duration={duration}/>
      </Sequence>;
    })}
  </AbsoluteFill>;
};

const Root: React.FC = () => <Composition
  id="Launch"
  component={Launch}
  durationInFrames={Math.round(scenes.reduce((sum, scene) => sum + scene.seconds, 0) * manifest.fps)}
  fps={manifest.fps}
  width={manifest.width}
  height={manifest.height}
/>;

registerRoot(Root);
