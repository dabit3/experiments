import React, {type CSSProperties} from 'react';
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
import {edit, type Scene} from './config';
import mazePhone from './assets/phone-maze.png';
import wispPhone from './assets/phone-wisp.png';
import chartsPhone from './assets/phone-charts.png';
import nativeReview from './assets/native-review.png';
import wispReview from './assets/wisp-review.png';
import macSession from './assets/mac-session.png';

const blue = edit.accent;
const easeOut = Easing.out(Easing.cubic);
const easeMove = Easing.inOut(Easing.cubic);
const progress = (frame: number, start: number, end: number, easing = easeOut) =>
  interpolate(frame, [start, end], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing,
  });
const position = (left: number, top: number, width?: number): CSSProperties => ({
  position: 'absolute', left, top, width,
});

const Caption = ({children, style}: {children: React.ReactNode; style?: CSSProperties}) => (
  <div style={{fontFamily: edit.bodyFont, fontSize: 24, lineHeight: 1.35, ...style}}>
    {children}
  </div>
);

const Headline = ({text, style}: {text: string; style?: CSSProperties}) => (
  <div style={{
    fontFamily: edit.font, fontWeight: 900, fontSize: 110, lineHeight: 1.07,
    letterSpacing: -6, whiteSpace: 'pre-line', ...style,
  }}>{text}</div>
);

const Phone = ({src, height, left, top}: {src: string; height: number; left: number; top: number}) => (
  <Img src={src} style={{position: 'absolute', left, top, height, width: 'auto', borderRadius: height * 0.075}} />
);

const ChromeBar = ({title, dark = false}: {title: string; dark?: boolean}) => (
  <div style={{
    height: 54, display: 'flex', alignItems: 'center', padding: '0 24px', gap: 10,
    background: dark ? '#000' : '#fff', color: dark ? '#fff' : '#000',
    borderBottom: `1px solid ${dark ? '#555' : '#ccc'}`,
  }}>
    {[0, 1, 2].map((n) => <span key={n} style={{height: 8, width: 8, background: n === 0 ? blue : '#999'}} />)}
    <span style={{fontSize: 21, marginLeft: 16, fontFamily: edit.bodyFont}}>{title}</span>
  </div>
);

const SceneContent = ({scene, frame}: {scene: Scene; frame: number}) => {
  if (scene.id === 'hook') {
    return <>
      <div style={{...position(1168, 0, 752), height: 1080, background: blue}} />
      <div style={{...position(1170, 180, 620), height: 775, border: '1px solid rgba(255,255,255,.45)'}} />
      <Phone src={mazePhone} left={1280} top={138} height={872} />
      <Headline text={scene.title} style={{...position(96, 285, 1070), fontSize: 132}} />
      <Caption style={{...position(101, 625, 900), fontSize: 35, color: '#ccc'}}>Devin builds and tests native apps.</Caption>
      <Caption style={{...position(101, 911), fontSize: 22, color: '#bbb'}}>iPhone Simulator / supplied native UI</Caption>
    </>;
  }

  if (scene.id === 'context') {
    return <>
      <div style={{...position(96, 236, 17), height: 577, background: blue}} />
      <Headline text={scene.title} style={{...position(160, 219, 1310), fontSize: 144, letterSpacing: -8}} />
      <div style={{...position(1464, 252, 335), height: 516, borderTop: '8px solid #000', borderBottom: '8px solid #000'}}>
        {[0, 1, 2, 3, 4, 5].map((i) => <div key={i} style={{
          position: 'absolute', left: 0, top: 68 + i * 62, width: 335, height: 2,
          background: i === 3 ? blue : '#bbb',
        }} />)}
        <div style={{position: 'absolute', top: 250, right: -2, width: 104, height: 54, background: blue}} />
      </div>
      <Caption style={{...position(160, 867), color: '#555'}}>Before: manual checks or delayed CI feedback.</Caption>
    </>;
  }

  if (scene.id === 'build') {
    return <>
      <Headline text={scene.title} style={{...position(96, 247, 925), fontSize: 109}} />
      <Caption style={{...position(101, 661), fontSize: 30, color: '#bbb'}}>Build and run with Xcode.</Caption>
      <div style={{...position(957, 229, 867), height: 436, background: '#fff', color: '#000'}}>
        <ChromeBar title="Devin / macOS session" />
        <Img src={macSession} style={{width: 867, height: 'auto', marginTop: 14}} />
        <Caption style={{padding: '4px 24px', fontSize: 21, color: '#555'}}>Supplied session excerpt</Caption>
      </div>
      <div style={{...position(1100, 704, 386), height: 101, border: '1px solid #777', display: 'flex', alignItems: 'center', paddingLeft: 32, fontSize: 30}}>
        Build <span style={{color: blue, margin: '0 27px'}}>→</span> Run
      </div>
      <div style={{...position(1540, 573, 282), height: 380, background: blue}} />
      <Phone src={mazePhone} left={1549} top={439} height={538} />
      <Caption style={{...position(101, 926), color: '#bbb', fontSize: 22}}>{edit.labels.illustrative}</Caption>
    </>;
  }

  if (scene.id === 'interact') {
    const action = Math.min(2, Math.max(0, Math.floor((frame - 35) / 43)));
    const gesture = progress(frame % 43, 6, 28, easeMove);
    return <>
      <div style={{...position(96, 174, 745), height: 760, background: '#ededed'}} />
      <div style={{...position(96, 174, 10), height: 760, background: blue}} />
      <Phone src={wispPhone} left={282} top={139} height={806} />
      <div style={{...position(943, 211, 870)}}>
        {scene.title.split('\n').map((line, i) => (
          <Headline key={line} text={line} style={{fontSize: 128, color: action === i ? blue : '#000', marginBottom: 12}} />
        ))}
        <Caption style={{marginTop: 41, fontSize: 29}}>Devin interacts with iOS Simulator.</Caption>
      </div>
      <div style={{
        position: 'absolute', left: action === 1 ? 450 : 610, top: action === 2 ? 685 - gesture * 160 : 850,
        width: 47, height: 47, border: `4px solid ${blue}`,
        borderRadius: '50%', opacity: frame > 36 ? 1 : 0,
        transform: `scale(${action === 0 ? 1 + gesture * 0.28 : 1})`,
      }} />
      <Caption style={{...position(99, 965), fontSize: 22, color: '#555'}}>{edit.labels.illustrative}</Caption>
    </>;
  }

  if (scene.id === 'repair') {
    const phase = Math.min(2, Math.max(0, Math.floor((frame - 29) / 48)));
    return <>
      <div style={{...position(96, 218, 945)}}>
        {scene.title.split('\n').map((line, i) => (
          <Headline key={line} text={line} style={{fontSize: 113, color: phase === i ? blue : '#fff', marginBottom: 8}} />
        ))}
        <Caption style={{marginTop: 48, fontSize: 29, color: '#ccc'}}>Find the failure. Work through it.</Caption>
      </div>
      <div style={{...position(1190, 179, 570), height: 801, overflow: 'hidden', background: '#fff'}}>
        <Img src={wispReview} style={{width: 570, height: 'auto'}} />
      </div>
      <div style={{...position(1166, 179, 8), height: 801, background: blue}} />
      <Caption style={{...position(97, 908, 1000), color: '#bbb', fontSize: 22}}>
        Supplied native test evidence · includes failures
      </Caption>
    </>;
  }

  if (scene.id === 'evidence') {
    return <>
      <Headline text={scene.title} style={{...position(96, 289, 530), fontSize: 96}} />
      <Caption style={{...position(102, 589, 425), fontSize: 30}}>Recordings and screenshots.<br />Ready for review.</Caption>
      <div style={{...position(656, 229, 1168), border: '1px solid #bbb', background: '#fff'}}>
        <ChromeBar title="Recorded evidence" />
        <OffthreadVideo
          src={staticFile('assets/devin-testing-2.mp4')}
          muted
          trimBefore={edit.evidenceVideoStartSeconds * edit.fps}
          style={{width: 1168, height: 'auto', display: 'block', filter: 'grayscale(1)'}}
        />
      </div>
      <div style={{...position(657, 966, 12), height: 12, background: blue}} />
      <Caption style={{...position(685, 957), fontSize: 23}}>{edit.labels.sourceVideo}</Caption>
    </>;
  }

  if (scene.id === 'outcome') {
    return <>
      <div style={{...position(96, 201, 802), height: 635, border: '1px solid #444', overflow: 'hidden'}}>
        <ChromeBar title="Live iPhone in the session" dark />
        <Img src={nativeReview} style={{width: 802, height: 'auto', marginTop: 24}} />
      </div>
      <Phone src={chartsPhone} left={265} top={340} height={590} />
      <Headline text={scene.title} style={{...position(989, 274, 840), fontSize: 89, letterSpacing: -4}} />
      <Caption style={{...position(995, 529, 790), fontSize: 33, color: '#bbb'}}>Inspect the app. See the result.</Caption>
      <div style={{...position(991, 663, 801), height: 91, background: blue, display: 'flex', alignItems: 'center', padding: '0 29px'}}>
        <Caption style={{fontSize: 33, fontWeight: 600}}>{edit.labels.price}</Caption>
      </div>
      <Caption style={{...position(99, 938), fontSize: 22, color: '#bbb'}}>{edit.labels.sourceNative} · representative session layout</Caption>
    </>;
  }

  return <>
    <div style={{...position(96, 248, 11), height: 582, background: blue}} />
    <Img src={staticFile('assets/logo-white.png')} style={{...position(517, 253, 886), height: 'auto'}} />
    <Caption style={{position: 'absolute', top: 641, width: '100%', textAlign: 'center', fontSize: 35, letterSpacing: 2}}>{scene.label}</Caption>
    <Caption style={{position: 'absolute', top: 735, width: '100%', textAlign: 'center', fontSize: 44, fontWeight: 500}}>{scene.title}</Caption>
  </>;
};

const SceneFrame = ({scene, index}: {scene: Scene; index: number}) => {
  const frame = useCurrentFrame();
  const dark = ['hook', 'build', 'repair', 'outcome', 'end'].includes(scene.id);
  const wipe = index === 0 ? 1 : progress(frame, 0, edit.wipeFrames, easeMove);
  const entrance = index === 0 ? 1 : progress(frame, edit.wipeFrames, edit.wipeFrames + edit.entranceFrames);
  return (
    <AbsoluteFill style={{
      background: dark ? '#000' : '#fff', color: dark ? '#fff' : '#000',
      fontFamily: edit.bodyFont, overflow: 'hidden',
      clipPath: `inset(0 0 0 ${(1 - wipe) * 100}%)`,
    }}>
      <AbsoluteFill style={{opacity: 0.85 + entrance * 0.15, transform: `translateY(${(1 - entrance) * 24}px)`}}>
        <SceneContent scene={scene} frame={frame} />
        {scene.id !== 'end' && (
          <div style={{...position(97, 79), fontSize: 24, fontWeight: 600, letterSpacing: 2}}>
            {scene.label}
          </div>
        )}
        <div style={{
          position: 'absolute', left: 96, right: 96, bottom: 33, height: 1,
          background: dark ? '#444' : '#ccc',
        }} />
        <div style={{
          position: 'absolute', right: 96, bottom: 50, display: 'flex', gap: 11,
        }}>
          {edit.scenes.map((s, i) => (
            <div key={s.id} style={{width: i === index ? 39 : 11, height: 6, background: i === index ? blue : dark ? '#777' : '#aaa'}} />
          ))}
        </div>
      </AbsoluteFill>
      {wipe < 1 && <div style={{position: 'absolute', left: `${(1 - wipe) * 100}%`, top: 0, width: 16, height: 1080, background: blue}} />}
    </AbsoluteFill>
  );
};

const Launch = () => (
  <AbsoluteFill style={{background: '#000'}}>
    {edit.scenes.map((scene, index) => (
      <Sequence
        key={scene.id}
        from={Math.round(scene.start * edit.fps)}
        durationInFrames={Math.round((scene.end - scene.start) * edit.fps) + edit.wipeFrames}
      >
        <SceneFrame scene={scene} index={index} />
      </Sequence>
    ))}
  </AbsoluteFill>
);

const Root = () => (
  <Composition
    id="Launch"
    component={Launch}
    width={1920}
    height={1080}
    fps={edit.fps}
    durationInFrames={edit.durationSeconds * edit.fps}
  />
);

registerRoot(Root);
