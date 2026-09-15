import React from 'react';
import {
  AbsoluteFill, Composition, Easing, Img, OffthreadVideo, Sequence,
  interpolate, registerRoot, staticFile, useCurrentFrame,
} from 'remotion';
import {brand, sources} from '../../shared/brand';
import {config, type Scene} from './config';

const C = {
  ink: brand.ink, paper: brand.paper, accent: brand.green,
  pencil: '#989d9b', soft: '#e8ebe8', muted: '#656b68', line: '#dce1dd',
};
const ease = Easing.out(Easing.cubic);
const move = Easing.inOut(Easing.cubic);
const range = (f: number, a: number, b: number, easing = ease) =>
  interpolate(f, [a, b], [0, 1], {easing, extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});

type Crop = {src: string; originalWidth: number; x: number; y: number; width: number; height: number};
const crops = {
  game: {src: sources.simulatorGame, originalWidth: 2986, x: 697, y: 246, width: 550, height: 1110},
  charts: {src: sources.simulator, originalWidth: 2978, x: 681, y: 234, width: 582, height: 1192},
  chat: {src: 'assets/devin-web-10.png', originalWidth: 2990, x: 683, y: 236, width: 581, height: 1190},
  session: {src: sources.session, originalWidth: 2982, x: 590, y: 845, width: 1860, height: 452},
  issues: {src: 'assets/devin-web-10.png', originalWidth: 2990, x: 1948, y: 145, width: 1020, height: 460},
} satisfies Record<string, Crop>;

const SourceCrop: React.FC<{crop: Crop; width: number}> = ({crop, width}) => {
  const scale = width / crop.width;
  return <div style={{width, height: crop.height * scale, overflow: 'hidden', position: 'relative'}}>
    <Img src={staticFile(crop.src)} style={{
      position: 'absolute', width: crop.originalWidth * scale, maxWidth: 'none',
      left: -crop.x * scale, top: -crop.y * scale,
    }}/>
  </div>;
};

const RoughBox: React.FC<{x: number; y: number; w: number; h: number; r?: number; fill?: string}> =
  ({x, y, w, h, r = 12, fill = '#f0f1ef'}) => <g>
    <rect x={x} y={y} width={w} height={h} rx={r} fill={fill} stroke={C.pencil} strokeWidth={2.3}/>
    <rect x={x + 2} y={y - 2} width={w - 3} height={h + 4} rx={r + 2} fill="none"
      stroke={C.pencil} strokeWidth={0.8} opacity={0.55} transform={`rotate(.24 ${x + w / 2} ${y + h / 2})`}/>
  </g>;

const PencilLines: React.FC<{x: number; y: number; widths: number[]; gap?: number}> =
  ({x, y, widths, gap = 23}) => <g fill="none" stroke={C.pencil} strokeWidth={3} strokeLinecap="round">
    {widths.map((w, i) => <path key={i} d={`M${x},${y + i * gap} Q${x + w / 2},${y + i * gap - 2} ${x + w},${y + i * gap + 1}`}/>)}
  </g>;

const PhoneSketch: React.FC<{width: number; height: number; variant: 'game' | 'charts' | 'chat'}> =
  ({width, height, variant}) => <svg width={width} height={height} viewBox="0 0 342 700">
    <RoughBox x={5} y={5} w={332} h={689} r={60} fill="#fafbf9"/>
    <RoughBox x={21} y={21} w={300} h={656} r={45} fill="#f4f5f2"/>
    <RoughBox x={127} y={28} w={86} h={23} r={12} fill="#d7d9d6"/>
    <PencilLines x={44} y={80} widths={[81, 243]} gap={34}/>
    {variant === 'charts' ? [0, 1, 2, 3].map((i) => <g key={i}>
      <RoughBox x={43} y={174 + i * 83} w={42} h={47} r={3}/>
      <PencilLines x={101} y={182 + i * 83} widths={[141, 109, 126]} gap={13}/>
    </g>) : variant === 'chat' ? <>
      <RoughBox x={146} y={133} w={151} h={58} r={8}/>
      <PencilLines x={159} y={153} widths={[117, 91]} gap={17}/>
      <RoughBox x={37} y={617} w={266} h={33} r={5}/>
    </> : <>
      <RoughBox x={72} y={220} w={198} h={184} r={4}/>
      <path d="M88 238H253V382H98V257H233V361H121V279H208V337H148V304H188" fill="none" stroke="#b8bcb7" strokeWidth={8}/>
      <PencilLines x={65} y={470} widths={[197, 139]} gap={35}/>
      <RoughBox x={42} y={575} w={258} h={39} r={4}/>
    </>}
    <path d="M132 661L209 662" stroke={C.pencil} strokeWidth={3} strokeLinecap="round"/>
  </svg>;

const Resolve: React.FC<{frame: number; real: React.ReactNode; sketch: React.ReactNode; width: number; height: number}> =
  ({frame, real, sketch, width, height}) => {
    const p = range(frame, config.resolveStart, config.resolveStart + config.resolveFrames, move);
    return <div style={{position: 'relative', width, height}}>
      <div style={{position: 'absolute', inset: 0, clipPath: `inset(0 0 0 ${p * 100}%)`}}>{sketch}</div>
      <div style={{position: 'absolute', inset: 0, clipPath: `inset(0 ${100 - p * 100}% 0 0)`}}>{real}</div>
      {p > 0 && p < 1 ? <div style={{position: 'absolute', left: p * width, top: 0, bottom: 0, width: 2, background: C.accent}}/> : null}
    </div>;
  };

const Phone: React.FC<{frame: number; variant?: 'game' | 'charts' | 'chat'; width?: number}> =
  ({frame, variant = 'charts', width = 342}) => {
    const crop = crops[variant];
    const height = crop.height / crop.width * width;
    return <Resolve frame={frame} width={width} height={height}
      real={<div style={{borderRadius: width * .18, overflow: 'hidden', width, height}}><SourceCrop crop={crop} width={width}/></div>}
      sketch={<PhoneSketch width={width} height={height} variant={variant}/>}/>;
  };

const Label: React.FC<React.PropsWithChildren<{color?: string}>> = ({children, color = C.muted}) =>
  <div style={{fontFamily: config.mono, fontSize: 19, letterSpacing: 1.3, color, lineHeight: 1.5}}>{children}</div>;

const Header: React.FC<{scene: Scene; index: number}> = ({scene, index}) => <>
  <div style={{position: 'absolute', left: 96, right: 96, top: 60, display: 'flex', alignItems: 'center', justifyContent: 'space-between'}}>
    <div style={{display: 'flex', gap: 20, alignItems: 'center'}}>
      <Img src={staticFile(sources.markBlack)} style={{width: 34, height: 34, objectFit: 'contain'}}/>
      <Label>DEVIN / NATIVE WORKFLOWS</Label>
    </div>
    <Label>{scene.id === 'hook' || scene.id === 'end' ? 'MACOS + IOS' : 'WIREFRAME → REAL'}</Label>
  </div>
  <div style={{position: 'absolute', bottom: 58, left: 96, right: 96, display: 'flex', justifyContent: 'space-between', alignItems: 'center'}}>
    <div style={{display: 'flex', gap: 8}}>
      {config.scenes.map((s, i) => <div key={s.id} style={{height: 3, width: 46, background: index === i ? C.accent : '#d8ddda'}}/>)}
    </div>
    <Label>{String(index + 1).padStart(2, '0')} / 08</Label>
  </div>
</>;

const Headline: React.FC<{scene: Scene; frame: number}> = ({scene, frame}) => {
  const p = range(frame, 0, 18);
  return <div style={{position: 'absolute', left: 96, top: 322, width: 588, opacity: .4 + .6 * p, transform: `translateY(${22 * (1 - p)}px)`}}>
    <Label color={C.accent}>{scene.kicker}</Label>
    <h1 style={{whiteSpace: 'pre-line', fontSize: 82, lineHeight: 1.04, fontWeight: 500, letterSpacing: -3.6, margin: '26px 0 28px'}}>{scene.title}</h1>
    <div style={{fontSize: 29, lineHeight: 1.4, color: C.muted, maxWidth: 495}}>{scene.detail}</div>
  </div>;
};

const StageLabel: React.FC<{frame: number; text?: string}> = ({frame, text = 'Illustrative workflow'}) =>
  <div style={{position: 'absolute', top: 171, left: 756, right: 112, display: 'flex', justifyContent: 'space-between'}}>
    <Label>{frame < 18 ? '01 / WIREFRAME' : frame < 36 ? '02 / RESOLVE' : '03 / REAL'}</Label>
    <Label>{text}</Label>
  </div>;

const SketchCard: React.FC<{width: number; height: number; kind?: 'session' | 'issue' | 'actions'}> =
  ({width, height, kind = 'session'}) => <svg width={width} height={height}>
    <RoughBox x={3} y={3} w={width - 6} h={height - 6} r={15} fill="#f6f7f4"/>
    <PencilLines x={31} y={42} widths={[171]} gap={20}/>
    <path d={`M20 69L${width - 20} 67`} stroke={C.pencil} strokeWidth={1}/>
    {kind === 'actions' ? [0, 1, 2].map((i) => <g key={i}>
      <RoughBox x={30} y={105 + i * 93} w={47} h={46} r={10}/>
      <PencilLines x={103} y={116 + i * 93} widths={[width - 154, width - 205]} gap={22}/>
    </g>) : <>
      <RoughBox x={30} y={92} w={40} h={40} r={7}/>
      <PencilLines x={90} y={104} widths={[width - 132, width - 171, width - 141, width - 201]} gap={23}/>
      {kind === 'session' ? <PencilLines x={90} y={232} widths={[191, 158]} gap={34}/> : null}
    </>}
  </svg>;

const PaperCard: React.FC<React.PropsWithChildren<{title: string; width: number; height: number}>> =
  ({children, title, width, height}) => <div style={{
    width, height, background: 'white', border: `1px solid ${C.line}`, borderRadius: 16,
    boxShadow: '0 18px 50px rgba(25,40,32,0.045)', overflow: 'hidden',
  }}>
    <div style={{height: 68, borderBottom: `1px solid ${C.line}`, padding: '20px 28px'}}><Label>{title}</Label></div>
    {children}
  </div>;

const ActionRow: React.FC<{title: string; detail: string; active: boolean; index: number}> =
  ({title, detail, active, index}) => <div style={{
    display: 'flex', gap: 22, alignItems: 'center', padding: '19px 26px',
    background: active ? '#edf7f1' : 'white', borderBottom: `1px solid ${C.line}`,
  }}>
    <div style={{width: 43, height: 43, borderRadius: 10, border: `1px solid ${active ? C.accent : C.line}`, display: 'grid', placeItems: 'center', color: active ? C.accent : C.muted, fontSize: 21}}>{index}</div>
    <div><div style={{fontSize: 27, lineHeight: 1.2}}>{title}</div>
      <div style={{fontSize: 18, color: C.muted, marginTop: 5}}>{detail}</div></div>
  </div>;

const Build: React.FC<{frame: number}> = ({frame}) => {
  const step = frame < 94 ? 0 : 1;
  return <>
    <div style={{position: 'absolute', left: 748, top: 235}}><Phone frame={frame} variant="game"/></div>
    <div style={{position: 'absolute', left: 1130, top: 285}}>
      <Resolve frame={frame} width={660} height={385} sketch={<SketchCard width={660} height={385}/>}
        real={<PaperCard title="MANAGED MAC VM / DEVIN SESSION" width={660} height={385}>
          <div style={{margin: '26px 18px 18px'}}><SourceCrop crop={crops.session} width={620}/></div>
          <div style={{margin: '19px 28px 0', borderTop: `1px solid ${C.line}`, paddingTop: 20, fontSize: 24, color: C.accent}}>
            {frame < config.actionStart ? 'Native app workflow' : step === 0 ? 'Build with Xcode' : 'Run in iOS Simulator'}
          </div>
          <div style={{display: 'flex', gap: 8, margin: '18px 28px'}}>
            {[0, 1].map((i) => <div key={i} style={{height: 4, width: 282, background: frame >= config.actionStart && i <= step ? C.accent : C.line}}/>)}
          </div>
        </PaperCard>}/>
      <div style={{marginTop: 28}}><Label>IDEA → BUILD → RUN</Label></div>
    </div>
  </>;
};

const Interact: React.FC<{frame: number}> = ({frame}) => {
  const action = frame < 86 ? 0 : frame < 127 ? 1 : 2;
  const pointerY = action === 0 ? 516 : action === 1 ? 575 : 410 - 64 * range(frame, 130, 160, move);
  const text = 'Check this flow'.slice(0, Math.floor(15 * range(frame, 88, 120)));
  return <>
    <div style={{position: 'absolute', left: 748, top: 235}}>
      <Phone frame={frame} variant="chat"/>
      {frame >= config.actionStart ? <div style={{
        position: 'absolute', left: 249, top: pointerY, width: 36, height: 36,
        border: `2px solid ${C.accent}`, borderRadius: 50, background: 'rgba(12,166,120,.12)',
      }}/> : null}
    </div>
    <div style={{position: 'absolute', left: 1130, top: 298}}>
      <Resolve frame={frame} width={660} height={405}
        sketch={<SketchCard width={660} height={405} kind="actions"/>}
        real={<PaperCard title="REPRESENTATIVE SIMULATOR ACTIONS" width={660} height={405}>
          <ActionRow index={1} title="Tap" detail="Select an app control" active={frame >= 54 && action === 0}/>
          <ActionRow index={2} title="Type" detail={action === 1 ? `${text}▏` : 'Enter text in the app'} active={action === 1}/>
          <ActionRow index={3} title="Scroll" detail="Inspect the next part of the screen" active={action === 2}/>
        </PaperCard>}/>
      <div style={{marginTop: 28}}><Label>SUPPLIED IOS SCREENSHOT + MOTION OVERLAY</Label></div>
    </div>
  </>;
};

const Fix: React.FC<{frame: number}> = ({frame}) => {
  const step = frame < 90 ? 0 : frame < 128 ? 1 : 2;
  return <>
    <div style={{position: 'absolute', left: 748, top: 235}}><Phone frame={frame} variant="chat"/></div>
    <div style={{position: 'absolute', left: 1130, top: 283}}>
      <Resolve frame={frame} width={660} height={388}
        sketch={<SketchCard width={660} height={388} kind="issue"/>}
        real={<PaperCard title="OBSERVED ISSUE / SUPPLIED TEST EVIDENCE" width={660} height={388}>
          <div style={{padding: '14px 12px'}}><SourceCrop crop={crops.issues} width={636}/></div>
        </PaperCard>}/>
      <div style={{display: 'flex', gap: 10, marginTop: 27}}>
        {['Reproduce', 'Fix', 'Retest'].map((name, i) => <div key={name} style={{
          border: `1px solid ${frame >= 54 && i === step ? C.accent : C.line}`,
          color: frame >= 54 && i === step ? C.accent : C.muted,
          background: frame >= 54 && i === step ? '#edf7f1' : C.paper,
          borderRadius: 8, padding: '14px 25px', fontSize: 23,
        }}>{name}</div>)}
      </div>
      <div style={{marginTop: 24}}><Label>REPRESENTATIVE WORKFLOW / ORIGINAL EVIDENCE</Label></div>
    </div>
  </>;
};

const EvidenceSketch = () => <svg width={1060} height={579} viewBox="0 0 1060 579">
  <RoughBox x={2} y={2} w={1056} h={575} r={12}/>
  <PencilLines x={24} y={29} widths={[268]}/>
  <RoughBox x={34} y={52} w={624} h={468} r={2} fill="#e8ebe7"/>
  <RoughBox x={246} y={88} w={201} h={416} r={37}/>
  <PencilLines x={268} y={150} widths={[136, 100, 143, 120]} gap={51}/>
  <PencilLines x={708} y={86} widths={[290, 253, 303, 278]} gap={27}/>
  <PencilLines x={746} y={248} widths={[240, 211, 230, 245, 195, 236, 203]} gap={34}/>
  <path d="M29 536H657" stroke={C.pencil} strokeWidth={8} strokeLinecap="round"/>
</svg>;

const Evidence: React.FC<{frame: number}> = ({frame}) => {
  const videoStart = config.sourceVideo.sceneStartFrame;
  const blend = range(frame, videoStart, videoStart + 10);
  return <div style={{position: 'absolute', left: 754, top: 274}}>
    <Resolve frame={frame} width={1060} height={579} sketch={<EvidenceSketch/>}
      real={<Img src={staticFile(sources.simulator)} style={{width: 1060, height: 579, objectFit: 'contain', borderRadius: 12}}/>}/>
    {frame >= videoStart ? <div style={{position: 'absolute', inset: '0 0 auto 0', opacity: blend, height: 597, borderRadius: 12, overflow: 'hidden'}}>
      <Sequence from={videoStart} layout="none">
        <OffthreadVideo muted src={staticFile(sources.testingVideo)} trimBefore={config.sourceVideo.startSeconds * config.fps}
          style={{width: 1060, height: 597, objectFit: 'contain'}}/>
      </Sequence>
    </div> : null}
    <div style={{marginTop: 36, display: 'flex', gap: 14, alignItems: 'center'}}>
      <div style={{width: 9, height: 9, borderRadius: '50%', background: C.accent}}/>
      <Label>{frame < videoStart ? 'NATIVE IOS / SUPPLIED REVIEW SCREENSHOT' : 'SOURCE RECORDING / WEB QA — NOT IOS FOOTAGE'}</Label>
    </div>
  </div>;
};

const Hook: React.FC<{frame: number; outcome?: boolean}> = ({frame, outcome = false}) => <>
  <div style={{position: 'absolute', left: 1050, top: 181}}>
    <div style={{position: 'absolute', left: -120, top: 88, height: 605, borderLeft: `1px dashed ${C.line}`}}/>
    <Phone frame={outcome ? 100 : frame - 12} width={350} variant={outcome ? 'charts' : 'game'}/>
    <div style={{position: 'absolute', right: -207, top: 84, width: 159}}>
      <Label>{outcome ? 'IN YOUR\nSESSION' : 'ONE IDEA'}</Label>
      <svg width={141} height={55}><path d="M130 18 Q75 22 5 42 M5 42L17 23 M5 42L28 45" fill="none" stroke={C.pencil} strokeWidth={2}/></svg>
    </div>
  </div>
  <div style={{position: 'absolute', left: 96, top: 780}}>
    <div style={{display: 'inline-flex', border: `1px solid ${C.line}`, borderRadius: 9, padding: '15px 21px', fontSize: 24, background: outcome ? '#edf7f1' : 'transparent'}}>
      {outcome ? 'Same price as Linux VMs.' : 'Managed Mac VMs. Native apps.'}
    </div>
  </div>
  <div style={{position: 'absolute', left: 1050, bottom: 129}}><Label>{outcome ? 'LIVE IPHONE SIMULATOR / REPRESENTATIVE VIEW' : 'SKETCH → NATIVE APP'}</Label></div>
</>;

const Context: React.FC<{frame: number}> = ({frame}) => {
  const p = range(frame, 14, 38);
  return <div style={{position: 'absolute', left: 805, top: 299, width: 920}}>
    <svg width={920} height={403}>
      <RoughBox x={5} y={3} w={905} h={385} r={18} fill="#f5f6f2"/>
      <PencilLines x={41} y={42} widths={[145]}/>
      <PencilLines x={42} y={333} widths={[585, 741]} gap={22}/>
    </svg>
    <div style={{position: 'absolute', top: 77, left: 49, opacity: p, transform: `translateY(${18 * (1 - p)}px)`}}>
      <div style={{fontSize: 141, letterSpacing: -7, lineHeight: 1}}>20+ <span style={{fontSize: 65, letterSpacing: -2}}>min</span></div>
      <div style={{fontSize: 28, color: C.muted, marginTop: 23}}>Waiting for CI feedback.</div>
    </div>
    <div style={{marginTop: 28}}><Label>PRIOR WORKFLOW CONTEXT · NOT A DEMO BENCHMARK</Label></div>
  </div>;
};

const End: React.FC<{frame: number}> = ({frame}) => {
  const p = range(frame, 0, 20);
  return <div style={{position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', flexDirection: 'column', justifyContent: 'center', transform: `translateY(${18 * (1 - p)}px)`, opacity: .4 + .6 * p}}>
    <Label>FROM IDEA TO REAL</Label>
    <Img src={staticFile(sources.logoBlack)} style={{width: 610, height: 209.33, objectFit: 'contain', margin: '34px 0 40px'}}/>
    <div style={{fontSize: 43, letterSpacing: -1.5}}>macOS + iOS</div>
    <div style={{fontSize: 30, marginTop: 22, color: C.muted}}>{config.scenes[7].title}</div>
    <div style={{width: 56, height: 3, background: C.accent, marginTop: 39}}/>
  </div>;
};

const SceneView: React.FC<{scene: Scene; index: number}> = ({scene, index}) => {
  const frame = useCurrentFrame();
  return <AbsoluteFill style={{background: C.paper, color: C.ink, fontFamily: config.font}}>
    <div style={{position: 'absolute', top: 131, right: 68, width: 1100, height: 824, opacity: .43,
      backgroundImage: 'radial-gradient(#d5dbd5 .7px, transparent .7px)', backgroundSize: '24px 24px'}}/>
    <Header scene={scene} index={index}/>
    {scene.id !== 'end' ? <Headline scene={scene} frame={frame}/> : null}
    {['build', 'interact', 'fix', 'evidence'].includes(scene.id) ? <StageLabel frame={frame} text={scene.id === 'evidence' ? 'Supplied evidence' : 'Illustrative workflow'}/> : null}
    {scene.id === 'hook' ? <Hook frame={frame}/> : null}
    {scene.id === 'context' ? <Context frame={frame}/> : null}
    {scene.id === 'build' ? <Build frame={frame}/> : null}
    {scene.id === 'interact' ? <Interact frame={frame}/> : null}
    {scene.id === 'fix' ? <Fix frame={frame}/> : null}
    {scene.id === 'evidence' ? <Evidence frame={frame}/> : null}
    {scene.id === 'outcome' ? <Hook frame={frame} outcome/> : null}
    {scene.id === 'end' ? <End frame={frame}/> : null}
  </AbsoluteFill>;
};

const Launch = () => <AbsoluteFill>
  {config.scenes.map((scene, index) => <Sequence key={scene.id} from={scene.start * config.fps} durationInFrames={scene.duration * config.fps}>
    <SceneView scene={scene} index={index}/>
  </Sequence>)}
</AbsoluteFill>;

const Root = () => <Composition id="Launch" component={Launch} durationInFrames={config.durationSeconds * config.fps} fps={config.fps} width={1920} height={1080}/>;
registerRoot(Root);
