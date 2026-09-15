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
import {blueprint, durationInFrames, FPS} from './config';
import metadata from './template.json';

const color = blueprint.palette;
const mono = brand.monoFont;
type Scene = (typeof blueprint.scenes)[number];

const progress = (frame: number, start = 0, frames: number = blueprint.motion.entranceFrames) =>
  interpolate(frame, [start, start + frames], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.out(Easing.cubic),
  });

const move = (frame: number, start: number, end: number) =>
  interpolate(frame, [start, end], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.inOut(Easing.cubic),
  });

const Box = ({children, style}: {children?: ReactNode; style?: CSSProperties}) => (
  <div style={{position: 'absolute', ...style}}>{children}</div>
);

const Mono = ({
  children,
  style,
}: {
  children: ReactNode;
  style?: CSSProperties;
}) => (
  <div style={{fontFamily: mono, fontSize: 20, letterSpacing: 1, ...style}}>
    {children}
  </div>
);

const Stroke = ({
  d,
  delay = 0,
  opacity = 1,
  dashed = false,
}: {
  d: string;
  delay?: number;
  opacity?: number;
  dashed?: boolean;
}) => {
  const f = useCurrentFrame();
  const p = progress(f, delay, blueprint.motion.lineFrames);
  return (
    <path
      d={d}
      fill="none"
      stroke={color.accent}
      strokeWidth={1.5}
      pathLength={1}
      strokeDasharray={dashed ? '0.012 0.009' : 1}
      strokeDashoffset={dashed ? 0 : 1 - p}
      opacity={opacity * (dashed ? p : 1)}
    />
  );
};

const Lines = ({children}: {children: ReactNode}) => (
  <svg
    width={1920}
    height={1080}
    viewBox="0 0 1920 1080"
    style={{position: 'absolute', inset: 0, pointerEvents: 'none'}}
  >
    {children}
  </svg>
);

const Cross = ({x, y}: {x: number; y: number}) => (
  <g stroke={color.accent} strokeWidth={1} opacity={0.8}>
    <path d={`M${x - 9} ${y}h18 M${x} ${y - 9}v18`} />
    <circle cx={x} cy={y} r={3} fill={color.background} />
  </g>
);

const Shell = ({scene, index}: {scene: Scene; index: number}) => (
  <AbsoluteFill
    style={{
      background: color.background,
      color: color.ink,
      fontFamily: brand.displayFont,
      backgroundImage:
        'linear-gradient(rgba(112,220,232,.035) 1px, transparent 1px), linear-gradient(90deg, rgba(112,220,232,.035) 1px, transparent 1px)',
      backgroundSize: '64px 64px',
    }}
  >
    <Box style={{inset: 54, border: `1px solid ${color.rule}`}} />
    <Box style={{left: 88, top: 89, display: 'flex', alignItems: 'center', gap: 22}}>
      <Img src={staticFile(sources.markWhite)} style={{width: 32, height: 32, objectFit: 'contain'}} />
      <Mono style={{fontSize: 21}}>DEVIN / NATIVE SYSTEMS</Mono>
    </Box>
    <Box style={{right: 88, top: 89, color: color.accent}}>
      <Mono>BLUEPRINT — 05</Mono>
    </Box>
    <Box style={{left: 88, right: 88, top: 146, height: 1, background: color.rule}} />
    <Box style={{left: 88, right: 88, top: 931, height: 1, background: color.rule}} />
    <Box style={{left: 88, top: 962}}>
      <Mono style={{fontSize: 17, color: color.secondary}}>LAUNCH / macOS + iOS</Mono>
      <div style={{display: 'flex', gap: 8, marginTop: 14}}>
        {blueprint.scenes.map((s, i) => (
          <div
            key={s.key}
            style={{
              width: 52,
              height: 3,
              background: i <= index ? color.accent : color.rule,
            }}
          />
        ))}
      </div>
    </Box>
    <Box style={{left: 1418, top: 931, width: 414, height: 95, borderLeft: `1px solid ${color.rule}`}}>
      <Box style={{left: 20, top: 13}}>
        <Mono style={{fontSize: 13, color: color.secondary}}>DRAWING / {String(index + 1).padStart(2, '0')}</Mono>
        <div style={{marginTop: 10, fontSize: 22}}>{scene.drawing}</div>
      </Box>
      <Box style={{right: 0, top: 0, width: 70, height: 95, borderLeft: `1px solid ${color.rule}`, display: 'grid', placeItems: 'center'}}>
        <Mono style={{fontSize: 23, color: color.accent}}>{String(index + 1).padStart(2, '0')}</Mono>
      </Box>
    </Box>
    <Lines>
      <Cross x={54} y={54} />
      <Cross x={1866} y={54} />
      <Cross x={54} y={1026} />
      <Cross x={1866} y={1026} />
    </Lines>
  </AbsoluteFill>
);

const Heading = ({scene}: {scene: Scene}) => {
  const f = useCurrentFrame();
  const p = scene.key === 'evidence' ? 1 : progress(f);
  const fontSize = scene.key === 'context' || scene.key === 'evidence' ? 100 : 112;
  return (
    <Box style={{left: 96, top: 216, width: 660, transform: `translateY(${(1 - p) * 22}px)`}}>
      <Mono style={{color: color.accent, fontSize: 22, textTransform: 'uppercase', marginBottom: 36}}>
        {scene.label}
      </Mono>
      <h1 style={{fontSize, lineHeight: 1.02, letterSpacing: -4.5, fontWeight: 500, margin: 0}}>
        {scene.headline.map((line) => <div key={line}>{line}</div>)}
      </h1>
      <p style={{fontSize: 31, lineHeight: 1.4, color: color.secondary, whiteSpace: 'pre-line', margin: '34px 0 0', maxWidth: 600}}>
        {scene.detail}
      </p>
    </Box>
  );
};

const Label = ({children, x, y, width = 380}: {children: ReactNode; x: number; y: number; width?: number}) => (
  <Box style={{left: x, top: y, width, color: color.accent}}>
    <Mono style={{fontSize: 18, lineHeight: 1.45}}>{children}</Mono>
  </Box>
);

const NativeNote = () => (
  <Box style={{left: 96, top: 870}}>
    <Mono style={{fontSize: 17, color: color.secondary}}>ILLUSTRATIVE WORKFLOW / SUPPLIED iOS STILLS</Mono>
  </Box>
);

const Phone = ({
  source = 'rescue',
  width = 330,
}: {
  source?: 'rescue' | 'wisp';
  width?: number;
}) => {
  const image = source === 'rescue'
    ? {file: sources.simulator, width: 2978, height: 1626, x: 678, y: 226}
    : {file: 'assets/devin-web-10.png', width: 2990, height: 1624, x: 682, y: 226};
  const scale = width / 590;
  return (
    <div style={{position: 'relative', width, height: 1200 * scale, overflow: 'hidden', borderRadius: width * 0.105, background: color.panel, boxShadow: '0 18px 50px rgba(0,0,0,.32)'}}>
      <Img
        src={staticFile(image.file)}
        style={{
          position: 'absolute',
          width: image.width * scale,
          height: image.height * scale,
          maxWidth: 'none',
          left: -image.x * scale,
          top: -image.y * scale,
        }}
      />
    </div>
  );
};

const Screenshot = ({source, width}: {source: string; width: number}) => (
  <Img src={staticFile(source)} style={{display: 'block', width, height: 'auto'}} />
);

const Exploded = ({assembled = false}: {assembled?: boolean}) => {
  const f = useCurrentFrame();
  const p = progress(f);
  const assembly = assembled ? move(f, 24, 64) : 0;
  return (
    <>
      <Box style={{left: 970, top: 398, transformOrigin: '0 0', transform: `matrix(.91,.13,-.20,.84,0,${32 * (1 - p)})`, opacity: p}}>
        <div style={{width: 790, border: `1px solid ${color.accent}`, padding: 8, background: color.panel}}>
          <div style={{height: 34, padding: '2px 10px', color: color.accent, fontFamily: mono, fontSize: 17}}>LAYER A / DEVIN SESSION</div>
          <Screenshot source={sources.session} width={790} />
        </div>
      </Box>
      {[0, 1].map((n) => (
        <Box
          key={n}
          style={{
            left: 1376 - n * 57 - assembly * (86 - n * 40),
            top: 179 + n * 34,
            width: 334,
            height: 674,
            border: `1px ${n === 0 ? 'dashed' : 'solid'} ${color.accent}`,
            borderRadius: 36,
            background: n === 1 ? 'rgba(11,40,56,.84)' : 'transparent',
            opacity: p * (1 - assembly * 0.8) * 0.62,
            transformOrigin: '0 0',
            transform: `matrix(.98,.17,-.26,.96,0,${(1 - p) * 45})`,
          }}
        />
      ))}
      <Box style={{left: 1252 + assembly * 42, top: 202, transformOrigin: '0 0', transform: `matrix(.98,.17,-.26,.96,0,${(1 - p) * 60})`, opacity: p}}>
        <Phone />
      </Box>
      <Lines>
        <Stroke d="M1215 177 L1532 232 M1215 166v22 M1532 221v22" />
        <Stroke d="M1533 285 L1670 232 H1788" delay={8} />
        <Stroke d="M1005 804 L931 868 H844" delay={8} />
        <Cross x={1533} y={285} />
        <Cross x={1005} y={804} />
      </Lines>
      <Label x={1588} y={188} width={230}>iPHONE SIMULATOR</Label>
      <Label x={832} y={880} width={330}>MANAGED Mac WORKSPACE</Label>
    </>
  );
};

const Context = () => {
  const f = useCurrentFrame();
  const p = progress(f);
  return (
    <>
      <Box style={{left: 914, top: 274, width: 816, opacity: p, transform: `translateY(${28 * (1 - p)}px)`}}>
        <Mono style={{color: color.secondary, marginBottom: 22}}>PREVIOUS FEEDBACK PATH</Mono>
        <div style={{borderTop: `1px solid ${color.accent}`, borderBottom: `1px solid ${color.rule}`, padding: '28px 0 32px'}}>
          <div style={{fontSize: 64, letterSpacing: -2}}>Manual checks</div>
          <Mono style={{color: color.secondary, marginTop: 12}}>QA BY HAND</Mono>
        </div>
        <div style={{display: 'flex', alignItems: 'baseline', gap: 22, marginTop: 42}}>
          <span style={{fontSize: 148, fontWeight: 400, letterSpacing: -7, color: color.accent}}>20+</span>
          <span style={{fontSize: 54}}>min</span>
        </div>
        <div style={{fontSize: 31, color: color.secondary, marginTop: 7}}>Waiting for CI feedback</div>
        <Mono style={{fontSize: 16, color: color.secondary, marginTop: 28}}>PRIOR TEAM WORKFLOW / FROM THE LAUNCH BRIEF</Mono>
      </Box>
      <Lines>
        <Stroke d="M824 320v420 M812 320h24 M812 740h24" />
        <Stroke d="M914 806 H1730 M914 794v24 M1730 794v24" />
      </Lines>
      <Label x={1030} y={832} width={650}>THE GAP BETWEEN CODE + CONFIDENCE</Label>
    </>
  );
};

const Build = () => (
  <>
    <Exploded assembled />
    <Box style={{left: 96, top: 736, display: 'flex', gap: 16}}>
      {['XCODE', 'BUILD', 'RUN'].map((text) => (
        <Mono key={text} style={{border: `1px solid ${color.rule}`, padding: '15px 22px', color: color.accent, fontSize: 20}}>{text}</Mono>
      ))}
    </Box>
    <NativeNote />
  </>
);

const Interact = () => {
  const f = useCurrentFrame();
  const p = progress(f);
  const current = f < 60 ? 0 : f < 114 ? 1 : 2;
  const touch = move(f, 26, 46);
  return (
    <>
      <Box style={{left: 1076, top: 180, width: 370, height: 715, border: `1px dashed ${color.rule}`, borderRadius: 40, transform: 'matrix(.98,.10,-.16,.98,0,0)'}} />
      <Box style={{left: 1156, top: 186, transformOrigin: '0 0', transform: `matrix(.98,.10,-.16,.98,0,${(1 - p) * 40})`, opacity: p}}>
        <Phone source="wisp" width={344} />
        <div style={{position: 'absolute', left: 244, top: 622, width: 45, height: 45, border: `2px solid ${color.accent}`, borderRadius: '50%', opacity: touch, transform: `scale(${1.3 - touch * 0.3})`}} />
      </Box>
      <Box style={{left: 1518, top: 360}}>
        {['TAP', 'TYPE', 'SCROLL'].map((action, i) => (
          <div key={action} style={{marginBottom: 34, display: 'flex', alignItems: 'center', gap: 22, color: current === i ? color.accent : color.secondary}}>
            <Mono style={{fontSize: 15}}>0{i + 1}</Mono>
            <div style={{fontSize: 36, letterSpacing: 0.5}}>{action}</div>
            <div style={{width: 6, height: 6, borderRadius: '50%', background: current === i ? color.accent : 'transparent'}} />
          </div>
        ))}
      </Box>
      <Lines>
        <Stroke d="M1161 162 H1490 M1161 150v24 M1490 150v24" />
        <Stroke d="M1454 520 H1500" delay={6} />
        <Stroke d="M1121 772 L1030 822 H861" delay={6} />
      </Lines>
      <Label x={884} y={839}>INPUT / iOS SIMULATOR</Label>
      <NativeNote />
    </>
  );
};

const Iterate = () => {
  const f = useCurrentFrame();
  const p = progress(f);
  const step = f < 65 ? 0 : f < 120 ? 1 : 2;
  return (
    <>
      <Box style={{left: 1140, top: 216, opacity: p, transformOrigin: '0 0', transform: `matrix(.97,.13,-.20,.93,0,${(1 - p) * 36})`}}>
        <Phone source="wisp" width={307} />
      </Box>
      <Box style={{left: 1350, top: 407, width: 382, background: color.panel, border: `1px solid ${color.accent}`, padding: 26, opacity: p, transform: `translateY(${(1 - p) * 24}px)`}}>
        <Mono style={{color: color.accent, fontSize: 17}}>OBSERVED IN SOURCE</Mono>
        <div style={{fontSize: 30, lineHeight: 1.25, marginTop: 20}}>Model metadata<br />missing</div>
        <div style={{fontSize: 20, lineHeight: 1.45, color: color.secondary, marginTop: 20}}>A finding to reproduce.<br />No new test result implied.</div>
      </Box>
      <Box style={{left: 96, top: 726, display: 'flex', gap: 20, alignItems: 'center'}}>
        {['REPRODUCE', 'FIX', 'RETEST'].map((label, i) => (
          <Mono key={label} style={{fontSize: 18, color: step === i ? color.accent : color.secondary, borderBottom: `2px solid ${step === i ? color.accent : color.rule}`, paddingBottom: 18}}>
            {label}{i < 2 ? '  →' : ''}
          </Mono>
        ))}
      </Box>
      <Lines>
        <Stroke d="M1346 442 L1268 392 H1122" delay={4} />
        <Stroke d="M1510 766 V834 H924 V315 H1074 M1062 307l12 8 -12 8" dashed />
        <Cross x={1122} y={392} />
      </Lines>
      <Label x={1400} y={862}>REPAIR LOOP / SCHEMATIC</Label>
      <NativeNote />
    </>
  );
};

const Evidence = () => (
  <>
    <Box style={{left: 796, top: 255, width: 988, border: `1px solid ${color.accent}`, padding: 12, background: color.panel}}>
      <Mono style={{fontSize: 17, color: color.accent, height: 40, paddingLeft: 8, paddingTop: 3}}>
        SOURCE RECORDING / WEB APP QA
      </Mono>
      <OffthreadVideo
        src={staticFile(blueprint.recording.source)}
        trimBefore={blueprint.recording.startSeconds * FPS}
        muted
        style={{width: 988, height: 988 * 1080 / 1918, display: 'block', objectFit: 'contain'}}
      />
    </Box>
    <Lines>
      <Stroke d="M782 281v-42h42 M1780 239h42v42 M1822 841v42h-42 M824 883h-42v-42" />
      <Stroke d="M800 203 H1808 M800 191v24 M1808 191v24" />
    </Lines>
    <Label x={940} y={170} width={620}>ASSEMBLED FRAME / ACTION + REVIEW EVIDENCE</Label>
    <Box style={{left: 96, top: 753, width: 550, borderLeft: `2px solid ${color.accent}`, paddingLeft: 24}}>
      <div style={{fontSize: 25, color: color.secondary, lineHeight: 1.5}}>
        Generic web testing example.<br />
        Native scenes use supplied stills.
      </div>
    </Box>
  </>
);

const Outcome = () => {
  const f = useCurrentFrame();
  const p = progress(f);
  const turn = move(f, 12, 44);
  return (
    <>
      <Box style={{left: 1120, top: 180, opacity: p, transform: `translateY(${(1 - p) * 20}px) rotate(${(1 - turn) * 8}deg)`}}>
        <Phone width={349} />
      </Box>
      <Lines>
        <Stroke d="M1048 185 V894 M1036 185h24 M1036 894h24" />
        <Stroke d="M1478 296 H1593 L1635 250 H1775" />
        <Stroke d="M1118 907 H1471 M1118 899v16 M1471 899v16" />
      </Lines>
      <Label x={1582} y={205} width={240}>IN YOUR SESSION</Label>
      <Box style={{left: 96, top: 728, borderTop: `1px solid ${color.accent}`, paddingTop: 25, width: 610}}>
        <div style={{fontSize: 40, letterSpacing: -0.7}}>Same price as Linux VMs.</div>
      </Box>
      <NativeNote />
    </>
  );
};

const End = () => {
  const f = useCurrentFrame();
  const p = progress(f);
  return (
    <>
      <Lines>
        <Stroke d="M601 347 H1319 M601 335v24 M1319 335v24" />
        <Stroke d="M573 399 V657 M561 399h24 M561 657h24" />
        <Stroke d="M1347 399 V657 M1335 399h24 M1335 657h24" />
      </Lines>
      <Box style={{left: 0, top: 225, width: '100%', textAlign: 'center', transform: `translateY(${18 * (1 - p)}px)`}}>
        <Mono style={{fontSize: 25, color: color.accent, letterSpacing: 3}}>macOS + iOS</Mono>
        <Img src={staticFile(sources.logoWhite)} style={{width: 680, height: 'auto', marginTop: 139}} />
        <div style={{fontSize: 49, letterSpacing: -1.5, marginTop: 70}}>{blueprint.scenes[7].headline[0]}</div>
        <div style={{fontSize: 27, color: color.secondary, marginTop: 26}}>{blueprint.scenes[7].detail}</div>
      </Box>
    </>
  );
};

const SceneContent = ({scene, index}: {scene: Scene; index: number}) => (
  <AbsoluteFill style={{color: color.ink, fontFamily: brand.displayFont}}>
    <Shell scene={scene} index={index} />
    {scene.key !== 'end' && <Heading scene={scene} />}
    {scene.key === 'hook' && <><Exploded /><NativeNote /></>}
    {scene.key === 'context' && <Context />}
    {scene.key === 'build' && <Build />}
    {scene.key === 'interact' && <Interact />}
    {scene.key === 'iterate' && <Iterate />}
    {scene.key === 'evidence' && <Evidence />}
    {scene.key === 'outcome' && <Outcome />}
    {scene.key === 'end' && <End />}
  </AbsoluteFill>
);

const Launch = () => (
  <AbsoluteFill>
    {blueprint.scenes.map((scene, index) => {
      const from = blueprint.scenes.slice(0, index).reduce((sum, s) => sum + s.seconds * FPS, 0);
      return (
        <Sequence key={scene.key} from={from} durationInFrames={scene.seconds * FPS}>
          <SceneContent scene={scene} index={index} />
        </Sequence>
      );
    })}
  </AbsoluteFill>
);

const Root = () => (
  <Composition
    id="Launch"
    component={Launch}
    durationInFrames={durationInFrames}
    fps={metadata.fps}
    width={metadata.width}
    height={metadata.height}
  />
);

registerRoot(Root);
