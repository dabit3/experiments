import React from 'react';
import {AbsoluteFill, Composition, Easing, Img, OffthreadVideo, Sequence, interpolate, registerRoot, staticFile, useCurrentFrame} from 'remotion';
import {brand, sources} from '../../shared/brand';
import {config, media, type SceneKind} from './config';
import manifest from './template.json';

const fps = manifest.fps;
const totalFrames = manifest.durationSeconds * fps;
const asset = (file: string) => staticFile(`assets/${file}`);
const ease = Easing.out(Easing.cubic);
const move = Easing.inOut(Easing.cubic);
const clamp = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'} as const;
const text: React.CSSProperties = {margin: 0, whiteSpace: 'pre-line'};
const small: React.CSSProperties = {fontFamily: config.mono, fontSize: 20, letterSpacing: 2};

function CroppedPhone({image, height = 680}: {image: typeof media.charts | typeof media.chat | typeof media.game; height?: number}) {
  const scale = height / image.cropHeight;
  return <div style={{position: 'relative', width: image.cropWidth * scale, height, overflow: 'hidden', borderRadius: 54, boxShadow: '0 32px 65px #0005'}}>
    <Img src={asset(image.file)} style={{position: 'absolute', width: image.width * scale, height: image.height * scale, maxWidth: 'none', left: -image.x * scale, top: -image.y * scale}} />
  </div>;
}

function Timeline() {
  const frame = useCurrentFrame();
  let start = 0;
  return <div style={{position: 'absolute', top: 39, left: 64, right: 64, display: 'flex', gap: 12}}>
    {config.scenes.map((scene) => {
      const duration = scene.seconds * fps;
      const progress = interpolate(frame, [start, start + duration], [0, 1], clamp);
      const active = frame >= start && frame < start + duration;
      start += duration;
      return <div key={scene.kind} style={{flex: scene.seconds}}>
        <div style={{height: 3, background: '#86918e45', overflow: 'hidden'}}>
          <div style={{height: '100%', width: `${progress * 100}%`, background: scene.kind === 'hook' || scene.kind === 'context' || scene.kind === 'build' ? brand.green : config.mint}} />
        </div>
        <div style={{fontFamily: config.mono, fontSize: 16, letterSpacing: 1.5, marginTop: 15, color: ['hook', 'context', 'build', 'interact'].includes(scene.kind) ? '#53615b' : '#c8d9d3', opacity: active ? 1 : 0.52}}>{scene.nav}</div>
      </div>;
    })}
  </div>;
}

function Prompt({copy, localFrame, still}: {copy: string; localFrame: number; still: boolean}) {
  const length = still ? copy.length : Math.floor(interpolate(localFrame, [24, 65], [0, copy.length], clamp));
  return <div style={{position: 'absolute', left: 64, top: 674, width: 672, minHeight: 204, padding: '26px 28px 28px', boxSizing: 'border-box', border: `1px solid ${brand.border}`, borderRadius: 18, background: '#f3f5f3'}}>
    <div style={{...small, color: config.muted, fontSize: 17, marginBottom: 26}}>YOU / INSTRUCTION</div>
    <div style={{...text, fontFamily: config.mono, fontSize: 25, lineHeight: 1.5, letterSpacing: -0.5, color: config.ink}}>
      {copy.slice(0, length)}{length < copy.length ? <span style={{background: brand.green, display: 'inline-block', width: 12, height: 27, verticalAlign: 'text-bottom'}} /> : null}
    </div>
    <div style={{position: 'absolute', right: 23, top: 20, width: 32, height: 32, borderRadius: 16, background: '#e0e7e2', color: '#4b6458', textAlign: 'center', fontSize: 24}}>↑</div>
  </div>;
}

function ActionRail({items, active, top = 388}: {items: readonly string[]; active: number; top?: number}) {
  return <div style={{position: 'absolute', left: 1546, top, width: 300}}>
    {items.map((label, i) => <div key={label} style={{borderTop: '1px solid #bfd5cd25', padding: '25px 0', color: i === active ? config.mint : '#7d9993', fontSize: 27, lineHeight: 1.18}}>
      <div style={{fontFamily: config.mono, fontSize: 15, letterSpacing: 1.3, marginBottom: 11, color: '#72958b'}}>0{i + 1}</div>
      {label}
      {i === active ? <span style={{marginLeft: 16, fontSize: 22}}>←</span> : null}
    </div>)}
  </div>;
}

function PhoneStage({kind, frame}: {kind: SceneKind; frame: number}) {
  const interaction = Math.min(2, Math.floor(frame / 60));
  const image = kind === 'interact' ? [media.game, media.chat, media.charts][interaction] : kind === 'fix' ? media.chat : media.charts;
  const action = Math.min(2, Math.floor(frame / 60));
  const label = kind === 'build' ? 'iOS SIMULATOR' : kind === 'fix' ? 'SUPPLIED NATIVE CHECK' : 'iPHONE / SIMULATOR';
  const phoneHeight = 680;
  const gestureLocal = frame % 60;
  const gestureY = interaction === 2 ? interpolate(gestureLocal, [32, 50], [655, 477], {...clamp, easing: move}) : interaction === 1 ? 820 : 783;
  const gestureOpacity = kind === 'interact' ? interpolate(gestureLocal, [26, 32, 48, 55], [0, 1, 1, 0], clamp) : 0;
  return <>
    <div style={{position: 'absolute', left: 905, top: 268, width: 576, height: 692, borderRadius: 32, background: '#153039', border: '1px solid #8aada521'}} />
    <div style={{position: 'absolute', left: 1024, top: 253}}>
      <CroppedPhone image={image} height={phoneHeight} />
    </div>
    <div style={{...small, position: 'absolute', top: 972, left: 905, width: 576, textAlign: 'center', color: '#aac3ba', fontSize: 15}}>{label}</div>
    {kind === 'interact' ? <div style={{position: 'absolute', left: 1181, top: gestureY, width: 42, height: 42, borderRadius: '50%', border: `3px solid ${config.mint}`, boxShadow: '0 0 0 8px #bfe9d933', opacity: gestureOpacity}} /> : null}
    {kind === 'hook' ? <div style={{position: 'absolute', left: 1546, top: 435}}>
      <div style={{fontSize: 52, color: config.mint, lineHeight: 1.1}}>Mac VM.<br />iPhone UI.</div>
      <div style={{width: 240, height: 1, background: '#bfe9d933', margin: '35px 0'}} />
      <div style={{fontSize: 26, lineHeight: 1.4, color: '#adc2bd'}}>One place<br />to do the work.</div>
    </div> : null}
    {kind === 'build' ? <ActionRail items={['Managed Mac VM', 'Build the app', 'Run in Simulator']} active={action} /> : null}
    {kind === 'interact' ? <ActionRail items={['Tap', 'Type', 'Scroll']} active={interaction} /> : null}
    {kind === 'fix' ? <>
      <ActionRail items={['Reproduce', 'Fix', 'Retest']} active={action} top={322} />
      <div style={{position: 'absolute', left: 1546, top: 790, width: 285, paddingTop: 24, borderTop: '1px solid #bfd5cd25'}}>
        <div style={{fontFamily: config.mono, fontSize: 16, color: '#adc2bd', lineHeight: 1.5}}>SOURCE CHECK RESULTS</div>
        <div style={{color: '#e5a698', fontSize: 23, marginTop: 14}}>12 passed · 3 failed</div>
        <div style={{color: '#c4b391', fontSize: 21, marginTop: 8}}>2 untested</div>
      </div>
    </> : null}
    {kind === 'outcome' ? <div style={{position: 'absolute', left: 1535, top: 426, width: 315}}>
      <div style={{...small, fontSize: 16, color: '#91b1a5'}}>AVAILABLE IN SESSION</div>
      <div style={{fontSize: 52, lineHeight: 1.1, color: config.mint, marginTop: 28}}>A live<br />iPhone.</div>
      <div style={{marginTop: 48, paddingTop: 28, borderTop: '1px solid #bfe9d933', fontSize: 28, lineHeight: 1.3, color: '#dfebe6'}}>Same price<br />as Linux VMs.</div>
    </div> : null}
  </>;
}

function ContextStage() {
  return <>
    <div style={{position: 'absolute', left: 902, top: 296, width: 900, borderRadius: 18, overflow: 'hidden', border: '1px solid #667e7244'}}>
      <Img src={asset(media.session)} style={{width: '100%', display: 'block'}} />
    </div>
    <div style={{position: 'absolute', left: 949, top: 735, width: 805, background: config.mint, color: config.stage, padding: '31px 38px', boxSizing: 'border-box', borderRadius: 18}}>
      <div style={{...small, fontSize: 16, marginBottom: 12}}>PRIOR CI FEEDBACK</div>
      <div style={{display: 'flex', alignItems: 'baseline', justifyContent: 'space-between'}}>
        <span style={{fontSize: 83, lineHeight: 1, letterSpacing: -4}}>20+ min</span>
        <span style={{fontSize: 27}}>Or manual QA.</span>
      </div>
    </div>
  </>;
}

function EvidenceStage() {
  return <>
    <div style={{position: 'absolute', left: 902, top: 296, width: 916, overflow: 'hidden', borderRadius: 16, background: '#fff'}}>
      <OffthreadVideo src={asset(media.evidence)} startFrom={media.evidenceStartSeconds * fps} muted style={{width: '100%', aspectRatio: '1918 / 1080', objectFit: 'contain', display: 'block'}} />
    </div>
    <div style={{position: 'absolute', left: 905, top: 851, display: 'flex', gap: 15, alignItems: 'center', color: config.mint}}>
      <span style={{width: 8, height: 8, borderRadius: 4, background: config.mint}} />
      <span style={{...small, fontSize: 18}}>ACTUAL SOURCE RECORDING / WEB QA</span>
    </div>
    <div style={{position: 'absolute', left: 905, top: 900, fontSize: 25, color: '#a8c0b6'}}>Generic evidence example · not iOS footage</div>
  </>;
}

function Scene({scene}: {scene: typeof config.scenes[number]}) {
  const frame = useCurrentFrame();
  const isVideo = scene.kind === 'evidence';
  const reveal = isVideo ? 1 : interpolate(frame, [0, 21], [0, 1], {...clamp, easing: ease});
  const translate = (1 - reveal) * 22;
  return <AbsoluteFill>
    <div style={{opacity: 0.35 + reveal * 0.65, transform: `translateY(${translate}px)`}}>
      <div style={{...small, position: 'absolute', left: 64, top: 226, color: '#51776b'}}>{scene.eyebrow}</div>
      <h1 style={{...text, position: 'absolute', left: 60, top: 301, width: 697, fontWeight: 450, fontSize: scene.kind === 'hook' ? 81 : 82, lineHeight: 1.055, letterSpacing: -3.6}}>{scene.headline}</h1>
      <Prompt copy={scene.prompt} localFrame={frame} still={isVideo || scene.kind === 'interact'} />
      <div style={{position: 'absolute', left: 64, top: 949, fontSize: 23, color: config.muted}}>{scene.foot}</div>
      <div style={{position: 'absolute', left: 903, top: 207, color: '#deede6', fontSize: 30, letterSpacing: -0.5}}>{scene.stageTitle}</div>
      {scene.kind === 'context' ? <ContextStage /> : scene.kind === 'evidence' ? <EvidenceStage /> : scene.kind === 'end' ? <>
        <Img src={staticFile(sources.logoWhite)} style={{position: 'absolute', left: 1095, top: 421, width: 530, height: 'auto'}} />
        <div style={{position: 'absolute', left: 1095, top: 675, width: 530, height: 1, background: '#bfe9d944'}} />
        <div style={{position: 'absolute', left: 1095, top: 718, width: 530, textAlign: 'center', fontSize: 40, color: config.mint}}>macOS + iOS</div>
      </> : <PhoneStage kind={scene.kind} frame={frame} />}
    </div>
  </AbsoluteFill>;
}

const Launch: React.FC = () => {
  const frame = useCurrentFrame();
  let start = 0;
  const sceneIndex = config.scenes.findIndex((scene) => {
    const end = start + scene.seconds * fps;
    const match = frame >= start && frame < end;
    start = end;
    return match;
  });
  const current = config.scenes[sceneIndex];
  let sequenceStart = 0;
  return <AbsoluteFill style={{background: config.paper, color: config.ink, fontFamily: config.font}}>
    <div style={{position: 'absolute', inset: `0 0 0 ${config.split}px`, background: config.stage}} />
    <div style={{position: 'absolute', left: config.split - 1, top: 113, bottom: 49, width: 1, background: '#768e802e'}} />
    <Timeline />
    <div style={{...small, position: 'absolute', left: 64, top: 131, fontSize: 17, color: '#57675e'}}>DEVELOPER INTENT</div>
    <div style={{...small, position: 'absolute', left: 904, top: 131, fontSize: 17, color: '#98b5a9'}}>DEVIN EXECUTION</div>
    <div style={{...small, position: 'absolute', right: 64, top: 131, fontSize: 17, color: '#98b5a9'}}>{String(sceneIndex + 1).padStart(2, '0')} / 08</div>
    {config.scenes.map((scene) => {
      const from = sequenceStart;
      sequenceStart += scene.seconds * fps;
      return <Sequence key={scene.kind} from={from} durationInFrames={scene.seconds * fps}><Scene scene={scene} /></Sequence>;
    })}
    <div style={{position: 'absolute', left: 776, top: 521, width: 48, height: 48, borderRadius: 24, background: config.paper, border: '1px solid #bbcfc2', color: '#4e7a62', fontSize: 30, display: 'flex', alignItems: 'center', justifyContent: 'center'}}>→</div>
    <div style={{position: 'absolute', left: 64, bottom: 30, fontFamily: config.mono, fontSize: 14, letterSpacing: 1.5, color: '#93a197'}}>SPLIT TIMELINE / DEVIN</div>
    <div style={{position: 'absolute', right: 64, bottom: 28, fontFamily: config.mono, fontSize: 16, letterSpacing: 0.5, color: '#8fae9f'}}>{current.kind === 'end' ? 'Build. Run. See it.' : current.kind === 'evidence' ? 'Supplied web QA recording · muted' : 'Illustrative workflow · supplied native screenshots'}</div>
  </AbsoluteFill>;
};

function Root() {
  return <Composition id="Launch" component={Launch} width={manifest.width} height={manifest.height} fps={fps} durationInFrames={totalFrames} />;
}

registerRoot(Root);
