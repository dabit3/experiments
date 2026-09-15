import React from 'react';
import {
  AbsoluteFill, Composition, Easing, Freeze, Img, OffthreadVideo, Sequence,
  interpolate, registerRoot, staticFile, useCurrentFrame,
} from 'remotion';
import {film, type Scene} from './config';
import metadata from './template.json';

const {colors, aperture} = film;
const bounded = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'} as const;
const moveEase = Easing.inOut(Easing.cubic);

type CropSpec = {source: string; imageWidth: number; x: number; y: number; width: number; height: number};
const images = {
  rescue: {source: 'devin-web-18.png', imageWidth: 2978, x: 690, y: 238, width: 566, height: 1180},
  wisp: {source: 'devin-web-10.png', imageWidth: 2990, x: 690, y: 235, width: 570, height: 1185},
  button: {source: 'devin-web-18.png', imageWidth: 2978, x: 723, y: 332, width: 516, height: 420},
  cursor: {source: 'devin-web-10.png', imageWidth: 2990, x: 717, y: 1205, width: 519, height: 166},
  failedReview: {source: 'devin-web-10.png', imageWidth: 2990, x: 1950, y: 145, width: 1040, height: 430},
} satisfies Record<string, CropSpec>;

const Crop: React.FC<{image: CropSpec; width: number; style?: React.CSSProperties}> = ({image, width, style}) => {
  const scale = width / image.width;
  return <div style={{position: 'relative', width, height: image.height * scale, overflow: 'hidden', ...style}}>
    <Img src={staticFile(`assets/${image.source}`)} style={{
      position: 'absolute', width: image.imageWidth * scale, maxWidth: 'none',
      height: 'auto', left: -image.x * scale, top: -image.y * scale,
    }}/>
  </div>;
};

const LowerThird: React.FC<{scene: Scene; frame: number}> = ({scene, frame}) => {
  const entrance = interpolate(frame, [8, 34], [0, 1], {...bounded, easing: Easing.out(Easing.cubic)});
  const end = scene.seconds * metadata.fps;
  const exit = interpolate(frame, [end - 14, end - 1], [1, 0], {...bounded, easing: moveEase});
  const opacity = entrance * exit;
  return <div style={{position: 'absolute', left: 112, bottom: 82, opacity}}>
    <div style={{color: colors.ice, fontSize: 17, fontWeight: 500, letterSpacing: 3.3, marginBottom: 21}}>
      {scene.eyebrow}
    </div>
    <div style={{fontSize: 49, lineHeight: 1.13, fontWeight: 400, letterSpacing: -1.5}}>
      {scene.headline}
    </div>
    <div style={{color: colors.muted, fontSize: 25, lineHeight: 1.4, marginTop: 18, letterSpacing: -.3}}>
      {scene.detail}
    </div>
  </div>;
};

const Label: React.FC<{children: React.ReactNode; right?: boolean}> = ({children, right = true}) =>
  <div style={{position: 'absolute', top: 24, ...(right ? {right: 72} : {left: 112}),
    fontSize: 16, color: '#b5c2cb', letterSpacing: 1.2}}>{children}</div>;

const Phone: React.FC<{kind?: 'rescue' | 'wisp'; width?: number; left?: number; top?: number; blur?: number}> =
  ({kind = 'rescue', width = 322, left = 1335, top = 52, blur = 0}) =>
    <Crop image={images[kind]} width={width} style={{
      position: 'absolute', left, top, borderRadius: width * .165,
      filter: blur ? `blur(${blur}px)` : undefined,
      boxShadow: '0 0 0 2px #63778770, 0 0 0 8px #0a0f15, 0 50px 100px #000c, 0 0 110px #1971c226',
    }}/>;

const Light: React.FC<{top?: number; left?: number; opacity?: number}> = ({top = 260, left = 600, opacity = .65}) =>
  <div style={{position: 'absolute', top, left, width: 1200, height: 2, opacity,
    background: 'linear-gradient(90deg, transparent, #1971c288 28%, #b8edff 50%, #1971c233 74%, transparent)',
    boxShadow: '0 0 12px 3px #249ad94a, 0 0 32px 9px #1971c21a',
    filter: 'blur(.6px)'}}/>;

const Code: React.FC<{fix?: boolean}> = ({fix = false}) =>
  <div style={{position: 'absolute', left: 330, top: 180, width: 1680, fontFamily: film.mono,
    fontSize: 51, lineHeight: 1.8, letterSpacing: -1.2, transform: 'perspective(2200px) rotateY(-8deg)'}}>
    <div style={{color: '#456274', filter: 'blur(5px)'}}>{fix ? 'func restoreSession() async {' : '// Native app workspace'}</div>
    <div style={{color: '#729cb1', filter: 'blur(2.5px)'}}>{fix ? '    let state = await loadState()' : 'cd NativeApp'}</div>
    <div style={{color: colors.white, textShadow: '0 0 22px #83d2f133'}}>
      <span style={{color: colors.ice}}>{fix ? '    await ' : '$ '}</span>
      {fix ? 'state.restore()' : 'xcodebuild'}
      <span style={{color: '#7995a8'}}>{fix ? '' : ' build'}</span>
      <span style={{display: 'inline-block', width: 3, height: 48, background: '#d5f0e8', verticalAlign: 'middle', marginLeft: 12}}/>
    </div>
    <div style={{color: '#577384', filter: 'blur(5px)'}}>{fix ? '    await verifySession()' : '// Run in iOS Simulator'}</div>
    <div style={{color: '#345065', filter: 'blur(9px)'}}>{fix ? '}' : 'open -a Simulator'}</div>
  </div>;

const Visual: React.FC<{scene: Scene; frame: number; duration: number}> = ({scene, frame, duration}) => {
  const progress = interpolate(frame, [0, duration], [0, 1], {...bounded, easing: moveEase});
  const dolly = {transform: `scale(${1 + progress * .045}) translateX(${-progress * 13}px)`, transformOrigin: '67% 45%'};

  if (scene.id === 'hook') {
    return <>
      <AbsoluteFill style={dolly}>
        <div style={{position: 'absolute', left: 570, top: 100}}>
          <Crop image={images.button} width={1260} style={{filter: 'blur(8px)', opacity: .85}}/>
          <Crop image={images.button} width={1260} style={{
            position: 'absolute', top: 0, left: 0,
            maskImage: 'radial-gradient(ellipse 40% 22% at 86% 9%, #000 16%, transparent 100%)',
          }}/>
        </div>
        <Light top={169} left={960} opacity={.45}/>
      </AbsoluteFill>
      <AbsoluteFill style={{background: 'linear-gradient(90deg, #060b10 4%, #060b10e8 22%, transparent 65%), linear-gradient(0deg, #060b10, transparent 50%)'}}/>
      <Label>iPhone Simulator / detail</Label>
    </>;
  }
  if (scene.id === 'context') {
    return <>
      <AbsoluteFill style={dolly}>
        <div style={{position: 'absolute', left: 415, top: 225, color: '#7698ad', fontFamily: film.mono,
          fontSize: 116, fontWeight: 300, filter: 'blur(8px)', opacity: .36}}>20+ min</div>
        <Phone width={276} left={1380} top={97} blur={1.2}/>
        <Light top={198} left={780} opacity={.32}/>
      </AbsoluteFill>
      <Label>Prior CI context</Label>
    </>;
  }
  if (scene.id === 'build') {
    return <>
      <AbsoluteFill style={dolly}><Code/><Light top={413} left={880} opacity={.6}/></AbsoluteFill>
      <AbsoluteFill style={{background: 'linear-gradient(0deg, #060b10 4%, transparent 57%), linear-gradient(90deg, #060b10 1%, transparent 38%)'}}/>
      <Label>Illustrative workflow</Label>
      <Label right={false}>MANAGED MAC VM</Label>
    </>;
  }
  if (scene.id === 'interact') {
    return <>
      <AbsoluteFill style={dolly}>
        <Phone kind="wisp" width={317} left={1350} top={76}/>
        <div style={{position: 'absolute', left: 192, top: 212, width: 850, height: 272, overflow: 'hidden', borderRadius: 12}}>
          <Crop image={images.cursor} width={850} style={{filter: 'blur(6px)', opacity: .48}}/>
          <Crop image={images.cursor} width={850} style={{position: 'absolute', inset: 0,
            maskImage: 'radial-gradient(ellipse 31% 45% at 85% 66%, #000 28%, transparent 100%)'}}/>
        </div>
        <Light top={484} left={590} opacity={.45}/>
      </AbsoluteFill>
      <Label>Illustrative workflow / supplied iOS still</Label>
    </>;
  }
  if (scene.id === 'fix') {
    return <>
      <AbsoluteFill style={dolly}>
        <div style={{position: 'absolute', inset: 0, transform: 'translate(-175px, -102px) scale(.85)', transformOrigin: 'left center'}}><Code fix/></div>
        <Crop image={images.failedReview} width={598} style={{position: 'absolute', left: 1210, top: 315,
          borderRadius: 12, opacity: .91, boxShadow: '0 35px 70px #0008'}}/>
        <Light top={267} left={550} opacity={.45}/>
      </AbsoluteFill>
      <AbsoluteFill style={{background: 'linear-gradient(0deg, #060b10 3%, transparent 56%)'}}/>
      <Label>Illustrative fix / actual mixed test results</Label>
    </>;
  }
  if (scene.id === 'evidence') {
    return <>
      <div style={{position: 'absolute', left: 820, top: 105, width: 982, borderRadius: 10,
        overflow: 'hidden', boxShadow: '0 25px 100px #000c', border: '1px solid #adc2d026'}}>
        <Freeze frame={Math.min(frame, duration - 1)}>
          <OffthreadVideo src={staticFile('assets/devin-testing-2.mp4')} trimBefore={18 * 30}
            muted style={{display: 'block', width: '100%', height: 'auto'}}/>
        </Freeze>
      </div>
      <AbsoluteFill style={{background: 'linear-gradient(90deg, #060b10 1%, #060b10 18%, transparent 44%)'}}/>
      <Label>Actual recording / web-app QA example</Label>
      <Light top={685} left={720} opacity={.25}/>
    </>;
  }
  if (scene.id === 'outcome') {
    return <>
      <AbsoluteFill style={dolly}>
        <Phone width={328} left={1360} top={76}/>
        <div style={{position: 'absolute', left: 994, top: 247, width: 135, height: 1, background: '#63839a66'}}/>
        <div style={{position: 'absolute', left: 995, top: 271, color: '#91aab9', fontSize: 16, letterSpacing: 1.8}}>IN YOUR SESSION</div>
        <Light top={179} left={1100} opacity={.4}/>
      </AbsoluteFill>
      <Label>Illustrative workflow / supplied iOS still</Label>
    </>;
  }
  return <AbsoluteFill style={{alignItems: 'center', justifyContent: 'center'}}>
    <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', transform: `scale(${1 + progress * .018})`}}>
      <Img src={staticFile('assets/logo-white.png')} style={{width: 405, height: 'auto'}}/>
      <div style={{fontSize: 28, letterSpacing: 4.5, color: '#bfccd6', marginTop: 49}}>{scene.headline}</div>
      <div style={{fontSize: 22, color: '#879cac', marginTop: 24, letterSpacing: .6}}>{scene.detail}</div>
    </div>
    <Light top={665} left={360} opacity={.24}/>
  </AbsoluteFill>;
};

const Shot: React.FC<{scene: Scene; duration: number}> = ({scene, duration}) => {
  const frame = useCurrentFrame();
  const opacity = interpolate(frame, [0, film.fadeFrames], [0, 1], {...bounded, easing: Easing.out(Easing.cubic)});
  return <AbsoluteFill style={{background: colors.background, opacity: scene.id === 'hook' ? 1 : opacity, overflow: 'hidden'}}>
    <AbsoluteFill style={{background: 'radial-gradient(ellipse at 75% 33%, #15334665, transparent 57%)'}}/>
    <Visual scene={scene} frame={frame} duration={duration}/>
    {scene.id !== 'end' && <LowerThird scene={scene} frame={frame}/>}
  </AbsoluteFill>;
};

const Launch: React.FC = () => {
  return <AbsoluteFill style={{background: '#000', color: colors.white, fontFamily: film.font}}>
    <div style={{position: 'absolute', left: 0, top: aperture.top, width: aperture.width, height: aperture.height, overflow: 'hidden'}}>
      {film.scenes.map((scene) =>
        <Sequence key={scene.id} from={scene.start * metadata.fps}
          durationInFrames={scene.seconds * metadata.fps + (scene.id === 'end' ? 0 : film.fadeFrames)} layout="none">
          <Shot scene={scene} duration={scene.seconds * metadata.fps}/>
        </Sequence>,
      )}
      <svg width="1920" height="804" style={{position: 'absolute', inset: 0, opacity: .045, mixBlendMode: 'screen', pointerEvents: 'none'}}>
        <filter id="grain"><feTurbulence type="fractalNoise" baseFrequency=".72" numOctaves="3" seed="13" stitchTiles="stitch"/></filter>
        <rect width="100%" height="100%" filter="url(#grain)" opacity=".55"/>
      </svg>
    </div>
  </AbsoluteFill>;
};

const Root: React.FC = () =>
  <Composition id={metadata.compositionId} component={Launch}
    width={metadata.width} height={metadata.height} fps={metadata.fps}
    durationInFrames={metadata.durationSeconds * metadata.fps}/>;

registerRoot(Root);
