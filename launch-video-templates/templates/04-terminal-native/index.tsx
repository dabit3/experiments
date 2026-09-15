import type {CSSProperties, ReactNode} from 'react';
import {
  AbsoluteFill, Composition, Easing, Img, OffthreadVideo, Sequence,
  interpolate, registerRoot, staticFile, useCurrentFrame,
} from 'remotion';
import {brand, sources} from '../../shared/brand';
import {config, type Scene} from './config';
import metadata from './template.json';

const palette = {
  background: '#111111',
  surface: brand.ink,
  inset: '#141414',
  line: '#393939',
  text: '#eeeeee',
  dim: '#ababab',
  faint: '#747474',
};

const range = (frame: number, from: number, to: number) =>
  interpolate(frame, [from, to], [0, 1], {
    extrapolateLeft: 'clamp', extrapolateRight: 'clamp',
    easing: Easing.out(Easing.cubic),
  });

const place = (left: number, top: number, width?: number): CSSProperties => ({
  position: 'absolute', left, top, width,
});

const reveal = (frame: number): CSSProperties => {
  const progress = range(frame, config.revealFrame, config.revealFrame + config.revealDuration);
  return {opacity: progress, transform: `translateY(${(1 - progress) * 24}px)`};
};

const Cursor = ({frame}: {frame: number}) => (
  <span style={{
    display: 'inline-block', width: 16, height: 28, marginLeft: 5,
    background: palette.text, verticalAlign: '-4px',
    opacity: Math.floor(frame / 15) % 2 === 0 ? 1 : 0,
  }}/>
);

const Command = ({scene, frame}: {scene: Scene; frame: number}) => {
  const length = Math.floor(interpolate(
    frame, [config.commandStartFrame, config.commandEndFrame], [0, scene.command.length],
    {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'},
  ));
  return (
    <div style={{...place(128, 157, 1664), fontSize: 28, whiteSpace: 'pre'}}>
      <span style={{color: palette.faint}}>native ~ </span>
      <span style={{color: palette.dim}}>$ </span>
      {scene.command.slice(0, length)}
      <Cursor frame={scene.kind === 'evidence' && frame > config.commandEndFrame ? 15 : frame}/>
    </div>
  );
};

const Logs = ({lines, frame, top = 566}: {lines: readonly string[]; frame: number; top?: number}) => (
  <div style={{...place(130, top, 845), overflow: 'hidden'}}>
    {lines.map((line, index) => {
      const progress = range(frame, config.logStartFrame + index * config.logStepFrames,
        config.logStartFrame + index * config.logStepFrames + 14);
      return (
        <div key={line} style={{
          height: 61, fontSize: 27, color: palette.dim,
          opacity: progress, transform: `translateY(${(1 - progress) * 24}px)`,
          display: 'flex', alignItems: 'center', gap: 19,
        }}>
          <span style={{color: palette.faint}}>›</span>{line}
        </div>
      );
    })}
  </div>
);

const Headline = ({scene, frame}: {scene: Scene; frame: number}) => (
  <div style={{
    ...place(128, 269, 920), ...reveal(frame),
    fontSize: scene.kind === 'outcome' ? 70 : 86,
    fontWeight: 500, lineHeight: 1.17, letterSpacing: -4,
  }}>
    {scene.headline.map((line) => <div key={line}>{line}</div>)}
  </div>
);

type Crop = {file: string; imageWidth: number; x: number; y: number; width: number; height: number};

const crops: Record<'game' | 'wisp' | 'charts', Crop> = {
  game: {file: sources.simulatorGame, imageWidth: 2986, x: 710, y: 254, width: 524, height: 1090},
  wisp: {file: 'assets/devin-web-10.png', imageWidth: 2990, x: 683, y: 237, width: 582, height: 1184},
  charts: {file: sources.simulator, imageWidth: 2978, x: 681, y: 237, width: 579, height: 1186},
};

const Phone = ({source, height = 640}: {source: keyof typeof crops; height?: number}) => {
  const crop = crops[source];
  const scale = height / crop.height;
  return (
    <div style={{
      width: crop.width * scale, height, position: 'relative', overflow: 'hidden',
      borderRadius: height * (source === 'game' ? 0.105 : 0.086),
      boxShadow: '0 28px 64px #00000080',
    }}>
      <Img src={staticFile(crop.file)} style={{
        position: 'absolute', width: crop.imageWidth * scale, maxWidth: 'none',
        left: -crop.x * scale, top: -crop.y * scale,
        filter: 'grayscale(1)',
      }}/>
    </div>
  );
};

const Pane = ({frame, title, children}: {frame: number; title: string; children: ReactNode}) => (
  <div style={{
    ...place(1070, 234, 710), height: 698, ...reveal(frame),
    border: `1px solid ${palette.line}`, borderRadius: 10, background: palette.inset,
  }}>
    <div style={{
      height: 49, borderBottom: `1px solid ${palette.line}`,
      display: 'flex', alignItems: 'center', paddingLeft: 24, fontSize: 19,
      color: palette.dim,
    }}>{title}</div>
    {children}
  </div>
);

const Native = ({scene, frame}: {scene: Scene; frame: number}) => {
  const isInteraction = scene.kind === 'interact';
  const source = scene.kind === 'outcome' ? 'charts' : isInteraction ? 'wisp' : 'game';
  const stage = frame < 86 ? 'tap' : frame < 126 ? 'type' : 'scroll';
  const move = interpolate(frame, [130, 151], [0, 1], {
    extrapolateLeft: 'clamp', extrapolateRight: 'clamp', easing: Easing.inOut(Easing.cubic),
  });
  return (
    <Pane frame={frame} title={scene.kind === 'build' ? 'managed Mac VM / Simulator' : 'iPhone / iOS Simulator'}>
      <div style={{...place(203, 67), display: 'flex'}}><Phone source={source} height={600}/></div>
      {isInteraction && frame >= 64 && (
        <>
          <div style={{
            ...place(37, 95), fontSize: 19, color: palette.dim, lineHeight: 2.2,
          }}>
            {['tap', 'type', 'scroll'].map((action) => (
              <div key={action} style={{color: stage === action ? palette.text : palette.faint}}>
                {stage === action ? '› ' : '  '}{action}
              </div>
            ))}
          </div>
          <div style={{
            position: 'absolute', left: stage === 'tap' ? 461 : stage === 'type' ? 335 : 491,
            top: stage === 'tap' ? 132 : stage === 'type' ? 611 : 466 - move * 138,
            width: 34, height: 34, border: '2px solid #ffffff',
            borderRadius: '50%', background: '#ffffff19', boxShadow: '0 0 0 7px #ffffff14',
          }}/>
        </>
      )}
    </Pane>
  );
};

const Context = ({frame}: {frame: number}) => (
  <div style={{
    ...place(1114, 287, 617), ...reveal(frame),
    borderLeft: `1px solid ${palette.line}`, height: 510, paddingLeft: 57,
  }}>
    <div style={{fontSize: 180, lineHeight: 1.2, letterSpacing: -12}}>20+</div>
    <div style={{fontSize: 30, color: palette.dim, marginTop: 8}}>minutes</div>
    <div style={{fontSize: 22, color: palette.faint, marginTop: 94, lineHeight: 1.6}}>
      waiting for CI feedback<br/>in the prior workflow
    </div>
  </div>
);

const Fix = ({frame}: {frame: number}) => (
  <Pane frame={frame} title="review / supplied Wisp test evidence">
    <div style={{padding: '37px 35px'}}>
      <div style={{fontSize: 20, color: palette.faint}}>SOURCE CAPTURE / MIXED RESULTS</div>
      <div style={{fontSize: 29, marginTop: 26, lineHeight: 1.6}}>
        Failed key persistence<br/>and model metadata checks.
      </div>
      <div style={{marginTop: 31, height: 1, background: palette.line}}/>
      <div style={{display: 'flex', alignItems: 'center', gap: 39, marginTop: 30}}>
        <Phone source="wisp" height={290}/>
        <div style={{fontSize: 25, lineHeight: 1.9, color: palette.dim}}>
          12 passed<br/>3 failed<br/>2 untested
        </div>
      </div>
      <div style={{fontSize: 19, color: palette.faint, marginTop: 24}}>Inspect failures. Keep the evidence.</div>
    </div>
  </Pane>
);

const Evidence = ({frame}: {frame: number}) => {
  const expansion = interpolate(frame,
    [config.evidenceExpandStartFrame, config.evidenceExpandEndFrame], [0, 1], {
      extrapolateLeft: 'clamp', extrapolateRight: 'clamp',
      easing: Easing.inOut(Easing.cubic),
    });
  const width = interpolate(expansion, [0, 1], [840, 1920]);
  const height = interpolate(expansion, [0, 1], [840 * 1080 / 1918, 1080]);
  const left = interpolate(expansion, [0, 1], [960, 0]);
  const top = interpolate(expansion, [0, 1], [338, 0]);
  return (
    <div style={{
      position: 'absolute', left, top, width, height, zIndex: 5,
      ...reveal(frame), borderRadius: 10 * (1 - expansion),
      boxShadow: '0 20px 90px #00000070',
    }}>
      <div style={{width: '100%', height: '100%', overflow: 'hidden', borderRadius: 'inherit'}}>
        <OffthreadVideo
          src={staticFile(sources.testingVideo)}
          trimBefore={config.evidenceSourceStartSeconds * metadata.fps}
          muted
          style={{width: '100%', height: '100%', objectFit: 'contain', filter: 'grayscale(1)'}}
        />
      </div>
      <div style={{
        position: 'absolute', left: 0, right: 0, top: -53 * (1 - expansion),
        height: 54, padding: '0 22px', display: 'flex', alignItems: 'center',
        background: palette.inset, border: `1px solid ${palette.line}`,
        color: palette.text, fontSize: 20 + 5 * expansion,
      }}>
        <span style={{marginRight: 18, color: palette.dim}}>▶</span>
        evidence / actual web-app QA recording
        {expansion > 0.85 && <span style={{marginLeft: 'auto', fontSize: 21}}>devin / native</span>}
      </div>
      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: -45 * (1 - expansion),
        height: 46, padding: '0 22px', display: 'flex', alignItems: 'center',
        background: palette.inset, border: `1px solid ${palette.line}`,
        color: palette.dim, fontSize: 19,
      }}>Source: web-app testing · shown as a generic evidence example</div>
    </div>
  );
};

const End = ({frame}: {frame: number}) => (
  <div style={{...place(0, 310, 1920), ...reveal(frame), textAlign: 'center'}}>
    <Img src={staticFile(sources.logoWhite)} style={{width: 625, height: 'auto'}}/>
    <div style={{fontSize: 33, color: palette.dim, marginTop: 51}}>macOS + iOS</div>
    <div style={{fontSize: 44, marginTop: 36, letterSpacing: -1.4}}>{config.scenes[7].headline[0]}</div>
  </div>
);

const Frame = ({scene, frame, children}: {scene: Scene; frame: number; children: ReactNode}) => {
  const active = ['build', 'interact', 'fix', 'evidence'].indexOf(scene.kind);
  return (
    <AbsoluteFill style={{
      background: palette.background, color: palette.text, fontFamily: config.font,
      fontVariantLigatures: 'none',
    }}>
      <div style={{
        position: 'absolute', inset: 44, border: `1px solid ${palette.line}`,
        borderRadius: 15, background: palette.surface,
      }}/>
      <div style={{
        ...place(45, 44, 1830), height: 73, borderBottom: `1px solid ${palette.line}`,
        display: 'flex', alignItems: 'center', padding: '0 35px', boxSizing: 'border-box',
      }}>
        <div style={{display: 'flex', gap: 10}}>
          {[0, 1, 2].map((dot) => <div key={dot} style={{
            width: 13, height: 13, border: '1px solid #777777', borderRadius: '50%',
            background: dot === 0 ? '#777777' : 'transparent',
          }}/>)}
        </div>
        <span style={{fontSize: 22, marginLeft: 29}}>{config.title}</span>
        <span style={{fontSize: 19, color: palette.dim, marginLeft: 'auto'}}>{scene.label}</span>
      </div>
      <Command scene={scene} frame={frame}/>
      <div style={{...place(128, 222, 1664), height: 1, background: palette.line}}/>
      {children}
      <div style={{
        ...place(80, 966, 1760), borderTop: `1px solid ${palette.line}`, height: 69,
        display: 'flex', alignItems: 'center', gap: 31, fontSize: 19, color: palette.faint,
      }}>
        {['01 build/run', '02 interact', '03 fix/retest', '04 evidence'].map((step, index) => (
          <span key={step} style={{color: index === active ? palette.text : palette.faint}}>{step}</span>
        ))}
        <span style={{marginLeft: 'auto', fontSize: 18, color: palette.dim}}>
          {scene.kind === 'context' ? 'Prior CI context' : scene.kind === 'end' ? 'Build. Run. See it.' : 'Illustrative workflow'}
        </span>
      </div>
    </AbsoluteFill>
  );
};

const SceneView = ({scene}: {scene: Scene}) => {
  const frame = useCurrentFrame();
  return (
    <Frame scene={scene} frame={frame}>
      {scene.kind !== 'end' && (
        <div style={{opacity: scene.kind === 'evidence' ?
          1 - range(frame, config.evidenceExpandStartFrame, config.evidenceExpandStartFrame + 13) : 1}}>
          <Headline scene={scene} frame={frame}/>
          <Logs lines={scene.lines} frame={frame}/>
        </div>
      )}
      {['hook', 'build', 'interact', 'outcome'].includes(scene.kind) && <Native scene={scene} frame={frame}/>}
      {scene.kind === 'context' && <Context frame={frame}/>}
      {scene.kind === 'fix' && <Fix frame={frame}/>}
      {scene.kind === 'evidence' && <Evidence frame={frame}/>}
      {scene.kind === 'end' && <End frame={frame}/>}
      {scene.kind === 'outcome' && (
        <div style={{
          ...place(128, 792, 840), ...reveal(frame), fontSize: 20,
          padding: '23px 0', color: palette.faint,
          borderTop: `1px solid ${palette.line}`,
        }}>macOS capacity. Linux VM pricing.</div>
      )}
    </Frame>
  );
};

const Launch = () => (
  <AbsoluteFill style={{background: palette.background}}>
    {config.scenes.map((scene) => (
      <Sequence key={scene.kind} from={Math.round(scene.start * metadata.fps)}
        durationInFrames={Math.round(scene.seconds * metadata.fps)}>
        <SceneView scene={scene}/>
      </Sequence>
    ))}
  </AbsoluteFill>
);

const Root = () => (
  <Composition id="Launch" component={Launch}
    width={metadata.width} height={metadata.height} fps={metadata.fps}
    durationInFrames={metadata.durationSeconds * metadata.fps}/>
);

registerRoot(Root);
