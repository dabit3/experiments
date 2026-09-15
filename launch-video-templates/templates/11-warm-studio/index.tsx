import React from 'react';
import {
  AbsoluteFill,
  Composition,
  Easing,
  Freeze,
  Img,
  OffthreadVideo,
  Sequence,
  interpolate,
  registerRoot,
  staticFile,
  useCurrentFrame,
} from 'remotion';
import {sources} from '../../shared/brand';
import {studio, type Scene} from './config';
import manifest from './template.json';

const C = studio.colors;
const easeOut = Easing.out(Easing.cubic);
const easeMove = Easing.inOut(Easing.cubic);
const clamp = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'} as const;

const fade = (frame: number, start = 0) =>
  interpolate(frame, [start, start + studio.fadeFrames], [0, 1], {...clamp, easing: easeOut});

type Crop = {file: string; width: number; x: number; y: number; w: number; h: number};
const crops: Record<'rescue' | 'wisp' | 'welcome' | 'maze', Crop> = {
  rescue: {file: 'devin-web-18.png', width: 2978, x: 686, y: 238, w: 572, h: 1182},
  wisp: {file: 'devin-web-10.png', width: 2990, x: 689, y: 238, w: 569, h: 1182},
  welcome: {file: 'devin-web-11.png', width: 2986, x: 688, y: 239, w: 568, h: 1184},
  maze: {file: 'devin-web-14.png', width: 2986, x: 707, y: 253, w: 530, h: 1094},
};

function NativePhone({kind = 'rescue', height = 748}: {kind?: keyof typeof crops; height?: number}) {
  const crop = crops[kind];
  const scale = height / crop.h;
  return (
    <div style={{
      position: 'relative', width: crop.w * scale, height,
      overflow: 'hidden', borderRadius: height * 0.097,
      boxShadow: '0 28px 54px rgba(66, 55, 40, 0.17)',
      backgroundColor: '#161918',
    }}>
      <Img src={staticFile(`assets/${crop.file}`)} style={{
        position: 'absolute', width: crop.width * scale, maxWidth: 'none',
        left: -crop.x * scale, top: -crop.y * scale,
      }} />
    </div>
  );
}

function SmallLabel({children, style}: {children: React.ReactNode; style?: React.CSSProperties}) {
  return <div style={{fontSize: 21, fontWeight: 500, letterSpacing: 2.8, color: C.muted, ...style}}>{children}</div>;
}

function Pill({children, fill = C.light}: {children: React.ReactNode; fill?: string}) {
  return <div style={{display: 'inline-flex', alignItems: 'center', gap: 13, padding: '17px 25px', borderRadius: 40, background: fill, fontSize: 25, color: C.ink}}>
    <div style={{height: 8, width: 8, borderRadius: 8, background: C.clay}} />{children}
  </div>;
}

function Copy({scene, top = 337, width = 900, size = 84}: {scene: Scene; top?: number; width?: number; size?: number}) {
  return <div style={{position: 'absolute', left: 112, top, width}}>
    <SmallLabel>{scene.label}</SmallLabel>
    <h1 style={{fontSize: size, lineHeight: 1.08, letterSpacing: -3.1, fontWeight: 500, margin: '34px 0 30px', whiteSpace: 'pre-line'}}>{scene.title}</h1>
    <div style={{fontSize: 30, lineHeight: 1.52, color: C.muted, whiteSpace: 'pre-line'}}>{scene.detail}</div>
  </div>;
}

function Chrome({index}: {index: number}) {
  return <>
    <div style={{position: 'absolute', left: 112, top: 63, display: 'flex', gap: 23, alignItems: 'center'}}>
      <Img src={staticFile(sources.logoBlack)} style={{width: 142, height: 'auto', mixBlendMode: 'multiply'}} />
      <div style={{width: 1, height: 26, background: C.line}} />
      <span style={{fontSize: 22, color: C.muted}}>macOS + iOS</span>
    </div>
    <div style={{position: 'absolute', bottom: 56, left: 112, right: 112, display: 'flex', justifyContent: 'space-between', alignItems: 'center', color: C.muted, fontSize: 20}}>
      <span>Native workflows, with you in the loop.</span>
      <span style={{letterSpacing: 2}}>{String(index + 1).padStart(2, '0')} / 08</span>
    </div>
  </>;
}

function Hero({scene, outcome = false}: {scene: Scene; outcome?: boolean}) {
  const f = useCurrentFrame();
  const drift = interpolate(f, [0, scene.seconds * 30], [12, -8], {...clamp, easing: easeMove});
  return <>
    <Copy scene={scene} size={outcome ? 78 : 91} width={935} top={318} />
    {outcome && <div style={{position: 'absolute', left: 112, top: 742}}><Pill fill={C.sage}>Same price as Linux VMs.</Pill></div>}
    <div style={{position: 'absolute', left: 1116, top: 169, width: 660, height: 720, borderRadius: '48% 48% 42% 42%', background: outcome ? C.sage : C.stone}} />
    <div style={{position: 'absolute', left: 1259, top: 164, transform: `translateY(${drift}px)`}}>
      <NativePhone height={756} />
    </div>
    <div style={{position: 'absolute', left: 1047, top: 259}}><Pill>iPhone Simulator</Pill></div>
    <SmallLabel style={{position: 'absolute', left: 1311, top: 951, fontSize: 16, letterSpacing: 1}}>SUPPLIED NATIVE APP VIEW</SmallLabel>
  </>;
}

function Context({scene}: {scene: Scene}) {
  const f = useCurrentFrame();
  return <>
    <div style={{position: 'absolute', left: 218, right: 218, top: 245, textAlign: 'center'}}>
      <SmallLabel>{scene.label}</SmallLabel>
      <h1 style={{fontSize: 112, fontWeight: 500, lineHeight: 1.1, letterSpacing: -4.4, margin: '46px 0 27px'}}>{scene.title}</h1>
      <div style={{fontSize: 33, color: C.muted}}>{scene.detail}</div>
    </div>
    <div style={{position: 'absolute', top: 609, left: 480, display: 'flex', gap: 24}}>
      {['You check it by hand.', 'You wait for CI.'].map((text, i) =>
        <div key={text} style={{
          width: 468, height: 150, border: `1px solid ${C.line}`, borderRadius: 32,
          background: i ? C.stone : C.light, padding: 40, boxSizing: 'border-box',
          opacity: fade(f, i * 12), transform: `translateY(${interpolate(f, [i * 12, i * 12 + 36], [12, 0], {...clamp, easing: easeOut})}px)`,
        }}>
          <SmallLabel style={{fontSize: 16, letterSpacing: 1.6, marginBottom: 16}}>YOUR CURRENT LOOP</SmallLabel>
          <span style={{fontSize: 30}}>{text}</span>
        </div>,
      )}
    </div>
  </>;
}

function Build({scene}: {scene: Scene}) {
  const f = useCurrentFrame();
  return <>
    <Copy scene={scene} size={73} width={920} top={332} />
    <div style={{position: 'absolute', left: 1090, top: 167, width: 698, height: 760, borderRadius: 48, background: C.stone}} />
    <div style={{position: 'absolute', left: 1218, top: 213}}>
      <NativePhone kind="welcome" height={669} />
    </div>
    <div style={{position: 'absolute', left: 989, top: 663, width: 476, padding: '31px 35px', borderRadius: 27, background: C.light, boxShadow: '0 18px 42px rgba(66,55,40,0.10)', opacity: fade(f, 19)}}>
      <SmallLabel style={{fontSize: 16, marginBottom: 19}}>YOUR MANAGED MAC VM</SmallLabel>
      <div style={{fontSize: 30, marginBottom: 17}}>Build → Run → Inspect</div>
      <div style={{fontSize: 21, color: C.muted}}>Xcode + iOS Simulator</div>
    </div>
    <SmallLabel style={{position: 'absolute', left: 1151, top: 951, fontSize: 16, letterSpacing: 1}}>ILLUSTRATIVE WORKFLOW · SUPPLIED APP VIEW</SmallLabel>
  </>;
}

const actions = [
  {label: 'Tap', kind: 'maze'},
  {label: 'Type', kind: 'wisp'},
  {label: 'Scroll', kind: 'rescue'},
] as const;

function Interact({scene}: {scene: Scene}) {
  const f = useCurrentFrame();
  return <>
    <Copy scene={scene} size={83} width={910} top={245} />
    <div style={{position: 'absolute', left: 112, top: 652, display: 'flex', gap: 15}}>
      {actions.map((a, i) => {
        const active = fade(f, i * 60);
        return <div key={a.label} style={{padding: '20px 35px', borderRadius: 26, background: i === 0 ? C.sage : C.stone, fontSize: 36, opacity: 0.35 + 0.65 * active}}>{a.label}</div>;
      })}
    </div>
    <div style={{position: 'absolute', left: 1140, top: 146, width: 650, height: 794, borderRadius: 50, background: C.stone}} />
    {actions.map((a, i) => <Sequence key={a.label} from={i * 60} durationInFrames={84}>
      <InteractionPhone kind={a.kind} first={i === 0} />
    </Sequence>)}
    <SmallLabel style={{position: 'absolute', left: 1158, top: 966, fontSize: 16, letterSpacing: 1}}>ILLUSTRATIVE WORKFLOW · SUPPLIED IOS VIEWS</SmallLabel>
  </>;
}

function InteractionPhone({kind, first}: {kind: keyof typeof crops; first: boolean}) {
  const f = useCurrentFrame();
  const gesture = interpolate(f, [27, 62], [0, 1], {...clamp, easing: easeMove});
  const visible = fade(f, 20) * interpolate(f, [62, 80], [1, 0], clamp);
  return <div style={{position: 'absolute', left: 1284, top: 177, opacity: first ? 1 : fade(f)}}>
    <NativePhone kind={kind} height={735} />
    {kind !== 'wisp' && <div style={{
      position: 'absolute', left: kind === 'maze' ? 157 : 198,
      top: kind === 'maze' ? 619 : 472 - 155 * gesture,
      width: 38, height: 38, border: `3px solid ${C.clay}`, borderRadius: '50%',
      boxShadow: '0 0 0 7px rgba(188,146,122,0.16)', opacity: visible,
    }} />}
  </div>;
}

function Fix({scene}: {scene: Scene}) {
  const f = useCurrentFrame();
  return <>
    <Copy scene={scene} size={72} width={950} top={252} />
    <div style={{position: 'absolute', left: 112, top: 646, display: 'flex', gap: 14}}>
      {['Reproduce', 'Fix', 'Retest'].map((text, i) => <div key={text} style={{
        borderRadius: 24, padding: '24px 29px', background: i === 1 ? C.sage : C.light,
        fontSize: 28, opacity: fade(f, i * 29),
      }}>{text}</div>)}
    </div>
    <div style={{position: 'absolute', left: 1120, top: 206, width: 650, height: 671, background: C.stone, borderRadius: 40, padding: 42, boxSizing: 'border-box'}}>
      <SmallLabel style={{fontSize: 18, marginBottom: 24}}>FROM A SUPPLIED IOS REVIEW</SmallLabel>
      <div style={{height: 246, overflow: 'hidden', borderRadius: 19, background: 'white', position: 'relative'}}>
        <Img src={staticFile('assets/devin-web-10.png')} style={{position: 'absolute', width: 1620, maxWidth: 'none', left: -1046, top: -77}} />
      </div>
      <div style={{height: 1, background: C.line, marginTop: 30}} />
      <div style={{fontSize: 32, lineHeight: 1.25, marginTop: 30}}>Keep the rough edges visible.</div>
      <div style={{fontSize: 25, color: C.muted, lineHeight: 1.45, marginTop: 18}}>Failures and untested checks stay in the review.</div>
    </div>
    <SmallLabel style={{position: 'absolute', left: 1210, top: 926, fontSize: 16, letterSpacing: 1}}>ILLUSTRATIVE WORKFLOW · ORIGINAL RESULTS</SmallLabel>
  </>;
}

function Evidence({scene}: {scene: Scene}) {
  const f = useCurrentFrame();
  const clipFrames = scene.seconds * manifest.fps;
  return <>
    <Copy scene={scene} size={80} width={580} top={301} />
    <div style={{position: 'absolute', left: 755, top: 215, width: 1046}}>
      <SmallLabel style={{fontSize: 18, letterSpacing: 1.6, marginBottom: 23}}>RECORDED EXAMPLE / WEB-APP QA</SmallLabel>
      <div style={{padding: 20, borderRadius: 33, background: C.light, boxShadow: '0 24px 60px rgba(66,55,40,0.11)'}}>
        <Freeze frame={clipFrames - 1} active={f >= clipFrames}>
          <OffthreadVideo src={staticFile(sources.testingVideo)} muted trimBefore={7 * 30}
            style={{display: 'block', width: '100%', aspectRatio: '1918 / 1080', objectFit: 'contain', borderRadius: 17}} />
        </Freeze>
      </div>
      <div style={{fontSize: 22, color: C.muted, marginTop: 25}}>Actual source recording · generic testing example</div>
    </div>
  </>;
}

function End({scene}: {scene: Scene}) {
  return <div style={{position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center'}}>
    <SmallLabel style={{marginBottom: 54, textTransform: 'uppercase'}}>{scene.title}</SmallLabel>
    <Img src={staticFile(sources.logoBlack)} style={{width: 572, height: 'auto', mixBlendMode: 'multiply'}} />
    <div style={{fontSize: 33, color: C.muted, marginTop: 48}}>Devin for macOS + iOS</div>
    <div style={{marginTop: 48, borderRadius: 40, background: C.sage, padding: '20px 38px', fontSize: 28}}>{scene.detail}</div>
  </div>;
}

function SceneContent({scene, index}: {scene: Scene; index: number}) {
  const f = useCurrentFrame();
  const entrance = index === 0 ? 1 : fade(f);
  return <AbsoluteFill style={{
    background: C.cream, opacity: entrance, color: C.ink, fontFamily: studio.font,
    transform: `translateY(${index === 0 || scene.key === 'evidence' ? 0 : interpolate(f, [0, 35], [9, 0], {...clamp, easing: easeOut})}px)`,
  }}>
    <div style={{position: 'absolute', inset: 0, background: 'radial-gradient(ellipse at 68% 24%, rgba(255,255,255,0.60), transparent 67%)'}} />
    {scene.key !== 'end' && <Chrome index={index} />}
    {scene.key === 'hook' && <Hero scene={scene} />}
    {scene.key === 'context' && <Context scene={scene} />}
    {scene.key === 'build' && <Build scene={scene} />}
    {scene.key === 'interact' && <Interact scene={scene} />}
    {scene.key === 'fix' && <Fix scene={scene} />}
    {scene.key === 'evidence' && <Evidence scene={scene} />}
    {scene.key === 'outcome' && <Hero scene={scene} outcome />}
    {scene.key === 'end' && <End scene={scene} />}
  </AbsoluteFill>;
}

function Launch() {
  let start = 0;
  return <AbsoluteFill style={{background: C.cream}}>
    {studio.scenes.map((scene, index) => {
      const from = start;
      const duration = scene.seconds * manifest.fps;
      start += duration;
      return <Sequence key={scene.key} from={from} durationInFrames={duration + (index === 7 ? 0 : studio.fadeFrames)}>
        <SceneContent scene={scene} index={index} />
      </Sequence>;
    })}
  </AbsoluteFill>;
}

registerRoot(() => <Composition id={manifest.compositionId} component={Launch}
  width={manifest.width} height={manifest.height} fps={manifest.fps}
  durationInFrames={manifest.durationSeconds * manifest.fps} />);
