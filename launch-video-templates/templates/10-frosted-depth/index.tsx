import React, {type CSSProperties, type ReactNode} from 'react';
import {
  AbsoluteFill,
  Composition,
  Easing,
  Img,
  interpolate,
  OffthreadVideo,
  registerRoot,
  Sequence,
  staticFile,
  useCurrentFrame,
} from 'remotion';
import {brand, sources} from '../../shared/brand';
import {film, type Scene} from './config';
import metadata from './template.json';

const clamp = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'} as const;
const easeOut = Easing.out(Easing.cubic);
const easeMove = Easing.inOut(Easing.cubic);
const ink = '#17303b';
const muted = '#47606c';
const glass: CSSProperties = {
  boxSizing: 'border-box',
  background: 'linear-gradient(135deg, rgba(255,255,255,.72), rgba(245,252,253,.38) 60%, rgba(222,238,244,.40))',
  backdropFilter: 'blur(30px) saturate(125%)',
  WebkitBackdropFilter: 'blur(30px) saturate(125%)',
  border: '1.5px solid rgba(255,255,255,.8)',
  borderRightColor: 'rgba(255,255,255,.28)',
  borderBottomColor: 'rgba(123,157,172,.25)',
  boxShadow: 'inset 1px 1px 1px rgba(255,255,255,.95), 16px 25px 60px rgba(30,72,88,.12)',
  borderRadius: 36,
};

const Glass = ({children, style}: {children?: ReactNode; style?: CSSProperties}) => (
  <div style={{...glass, ...style}}>{children}</div>
);

const Plane = ({level, children}: {level: 0 | 1 | 2; children: ReactNode}) => {
  const frame = useCurrentFrame();
  const times = [0, ...film.scenes.flatMap((scene) => [scene.to * 30 - film.transitionFrames, scene.to * 30])];
  const positions = [-1, ...film.cameraStops.flatMap((position) => [position, position])];
  const travel = interpolate(frame, times, positions, {easing: easeMove, ...clamp});
  const depth = [0.22, 0.56, 1][level];
  return (
    <AbsoluteFill
      style={{
        zIndex: level,
        transform: `translate(${travel * depth * 22}px, ${travel * depth * -12}px)`,
      }}
    >
      {children}
    </AbsoluteFill>
  );
};

const SceneFade = ({scene, children}: {scene: Scene; children: ReactNode}) => {
  const frame = useCurrentFrame();
  const start = scene.from * metadata.fps;
  const end = scene.to * metadata.fps;
  const transition = film.transitionFrames;
  const enter = scene.from === 0 ? 1 : interpolate(frame, [start - transition, start], [0, 1], {easing: easeOut, ...clamp});
  const exit = scene.key === 'end' ? 1 : interpolate(frame, [end - transition, end], [1, 0], {easing: easeOut, ...clamp});
  if (frame < start - transition || frame >= end) return null;
  return (
    <AbsoluteFill style={{opacity: enter * exit, transform: `translateY(${(1 - enter) * 22 - (1 - exit) * 8}px)`}}>
      {children}
    </AbsoluteFill>
  );
};

const Backdrop = () => (
  <Plane level={0}>
    <AbsoluteFill style={{left: -100, top: -100, width: 2120, height: 1280, background: 'radial-gradient(ellipse at 15% 8%, #fffef4 0%, #ecf2ee 32%, #d4e7ee 64%, #aacbd8 100%)'}} />
    <div style={{position: 'absolute', left: 1210, top: -280, width: 370, height: 1650, transform: 'rotate(-31deg)', borderRadius: 200, background: 'linear-gradient(90deg, rgba(255,255,255,.55), rgba(87,160,171,.24))', boxShadow: '30px 25px 85px rgba(71,132,151,.14)'}} />
    <div style={{position: 'absolute', left: 740, top: 575, width: 1330, height: 350, transform: 'rotate(-30deg)', borderRadius: '50%', border: '42px solid rgba(255,255,255,.35)', boxShadow: 'inset 0 0 100px rgba(43,114,131,.10)'}} />
    <div style={{position: 'absolute', left: -180, top: 800, width: 880, height: 370, borderRadius: '50%', background: 'radial-gradient(ellipse, rgba(12,166,120,.16), transparent 68%)'}} />
    <div style={{position: 'absolute', left: 850, top: 180, width: 950, height: 690, borderRadius: 110, border: '2px solid rgba(255,255,255,.58)', transform: 'rotate(-8deg)', background: 'linear-gradient(125deg, rgba(255,255,255,.27), rgba(155,197,207,.18))'}} />
  </Plane>
);

const Topline = () => (
  <>
    <Img src={staticFile(sources.logoBlack)} style={{position: 'absolute', left: 96, top: 58, width: 150, height: 'auto'}} />
    <div style={{position: 'absolute', right: 94, top: 78, fontSize: 20, letterSpacing: 3, color: muted}}>NATIVE POSSIBILITIES</div>
  </>
);

const Footer = () => {
  const frame = useCurrentFrame();
  return (
    <div style={{position: 'absolute', left: 104, right: 104, bottom: 55, display: 'flex', alignItems: 'center', gap: 10}}>
      {film.scenes.map((scene) => (
        <div key={scene.key} style={{height: 4, width: frame >= scene.from * 30 && frame < scene.to * 30 ? 78 : 24, borderRadius: 4, background: frame >= scene.from * 30 ? '#547c8b' : 'rgba(74,104,114,.18)'}} />
      ))}
      <div style={{marginLeft: 'auto', color: muted, fontSize: 19, letterSpacing: 2}}>DEVIN / macOS + iOS</div>
    </div>
  );
};

const Copy = ({scene}: {scene: Scene}) => (
  <Glass style={{position: 'absolute', left: 90, top: 218, width: 755, height: 641, padding: '49px 54px'}}>
    <div style={{fontSize: 20, letterSpacing: 2.8, fontWeight: 500, color: '#416574', marginBottom: 35}}>{scene.eyebrow}</div>
    <div style={{fontSize: scene.key === 'hook' ? 111 : scene.key === 'outcome' ? 73 : 89, fontWeight: 500, lineHeight: 1.02, letterSpacing: -4.5, whiteSpace: 'pre-line'}}>{scene.headline}</div>
    <div style={{fontSize: 29, lineHeight: 1.43, color: muted, marginTop: 34, whiteSpace: 'pre-line'}}>{scene.body}</div>
    {scene.key === 'outcome' && <div style={{marginTop: 34, fontSize: 26, color: '#216553'}}>{film.copy.price}</div>}
  </Glass>
);

const Caption = ({text, top = 932}: {text: string; top?: number}) => (
  <div style={{position: 'absolute', top, left: 902, width: 892, textAlign: 'center', color: '#3f5d69', fontSize: 20}}>{text}</div>
);

const Phone = ({width = 342}: {width?: number}) => {
  const crop = film.crops.rescuePhone;
  const ratio = width / crop.width;
  return (
    <div style={{position: 'relative', width, height: crop.height * ratio, overflow: 'hidden', borderRadius: 91 * ratio, boxShadow: '14px 24px 30px rgba(15,44,57,.20)'}}>
      <Img
        src={staticFile(crop.source)}
        style={{
          position: 'absolute',
          width: crop.originalWidth * ratio,
          height: crop.originalHeight * ratio,
          maxWidth: 'none',
          left: -crop.x * ratio,
          top: -crop.y * ratio,
        }}
      />
    </div>
  );
};

const PhoneScene = ({scene}: {scene: Scene}) => {
  const frame = useCurrentFrame();
  const local = frame - scene.from * 30;
  const interaction = scene.key === 'interact';
  const active = Math.min(2, Math.max(0, Math.floor(local / 60)));
  const gestureY = interpolate(local, [122, 155], [415, 280], {easing: easeMove, ...clamp});
  const tapScale = interpolate(local, [20, 30, 42], [1, 0.8, 1], {easing: easeMove, ...clamp});
  return (
    <>
      <Glass style={{position: 'absolute', left: 1033, top: 147, width: 623, height: 756, padding: 25}}>
        <div style={{display: 'flex', justifyContent: 'space-between', fontSize: 20, color: muted}}>
          <span>{film.copy.simulatorLabel}</span><span style={{color: brand.green}}>Native app</span>
        </div>
        <div style={{position: 'absolute', left: 140, top: 69}}>
          <Phone width={316} />
          {interaction && active !== 1 && (
            <div style={{position: 'absolute', left: 268, top: active === 0 ? 192 : gestureY, width: 38, height: 38, borderRadius: '50%', border: '3px solid #f3fdfc', background: 'rgba(12,166,120,.3)', boxShadow: '0 0 0 6px rgba(12,166,120,.22)', transform: `scale(${active === 0 ? tapScale : 1})`}} />
          )}
        </div>
      </Glass>
      {interaction && (
        <Glass style={{position: 'absolute', left: 996, top: 781, width: 700, minHeight: 112, padding: '24px 30px', background: 'rgba(245,252,253,.87)'}}>
          <div style={{display: 'flex', alignItems: 'center', gap: 20}}>
            {film.copy.gestures.map((label, i) => <span key={label} style={{padding: '8px 17px', borderRadius: 18, color: active === i ? '#fff' : muted, background: active === i ? '#2d6572' : 'transparent', fontSize: 24}}>{label}</span>)}
            <span style={{marginLeft: 'auto', fontSize: 16, color: muted}}>Illustrative</span>
          </div>
          {active === 1 && <div style={{marginTop: 12, fontSize: 23, color: ink}}>{film.copy.prompt}</div>}
        </Glass>
      )}
      <Caption text={scene.caption} />
    </>
  );
};

const MediaPanel = ({title, children, footer}: {title: string; children: ReactNode; footer?: ReactNode}) => (
  <Glass style={{position: 'absolute', left: 890, top: 221, width: 932, padding: 22}}>
    <div style={{display: 'flex', alignItems: 'center', marginBottom: 19, fontSize: 21, color: muted}}>
      <div style={{display: 'flex', gap: 7, marginRight: 18}}>
        {[0, 1, 2].map((dot) => <span key={dot} style={{width: 9, height: 9, background: '#96acb3', borderRadius: '50%'}} />)}
      </div>
      {title}
    </div>
    <div style={{overflow: 'hidden', borderRadius: 18, background: brand.paper}}>{children}</div>
    {footer && <div style={{paddingTop: 22, paddingBottom: 5}}>{footer}</div>}
  </Glass>
);

const SourceScreenshot = ({src}: {src: string}) => <Img src={staticFile(src)} style={{display: 'block', width: '100%', height: 'auto'}} />;

const Repair = ({scene}: {scene: Scene}) => {
  const frame = useCurrentFrame();
  const active = Math.min(2, Math.max(0, Math.floor((frame - scene.from * 30) / 60)));
  return (
    <>
      <MediaPanel title="Wisp · native Simulator checks" footer={
        <>
          <div style={{display: 'flex', gap: 12}}>
            {film.copy.repairSteps.map((step, i) => <div key={step} style={{flex: 1, padding: '17px 10px', textAlign: 'center', borderRadius: 18, fontSize: 25, color: active === i ? '#fff' : muted, background: active === i ? '#315c70' : 'rgba(255,255,255,.38)'}}>{step}</div>)}
          </div>
          <div style={{marginTop: 18, fontSize: 18, color: muted}}>Illustrative workflow · original results preserved</div>
        </>
      }>
        <SourceScreenshot src="assets/devin-web-10.png" />
      </MediaPanel>
      <Caption text={scene.caption} />
    </>
  );
};

const Foreground = ({scene}: {scene: Scene}) => {
  if (scene.key === 'hook' || scene.key === 'interact') return <PhoneScene scene={scene} />;
  if (scene.key === 'context') return (
    <>
      <Glass style={{position: 'absolute', left: 967, top: 300, width: 753, height: 459, padding: '46px 54px'}}>
        <div style={{fontSize: 25, color: muted}}>Waiting for feedback</div>
        <div style={{fontSize: 183, letterSpacing: -12, lineHeight: 1.18, color: '#315d73'}}>{film.copy.waitNumber}<span style={{fontSize: 50, letterSpacing: -1, marginLeft: 18}}>min</span></div>
        <div style={{fontSize: 27, color: muted}}>{film.copy.waitUnit}</div>
        <div style={{marginTop: 33, height: 5, background: 'rgba(54,93,110,.14)', borderRadius: 5}}><div style={{width: '26%', height: '100%', background: '#718f9d', borderRadius: 5}} /></div>
      </Glass>
      <Caption text={scene.caption} top={799} />
    </>
  );
  if (scene.key === 'build') return (
    <>
      <MediaPanel title="Native app · running in iPhone Simulator" footer={<div style={{display: 'flex', justifyContent: 'space-between', color: '#315d70', fontSize: 25}}><span>macOS</span><span>Xcode</span><span>iOS Simulator</span></div>}>
        <SourceScreenshot src={sources.simulatorGame} />
      </MediaPanel>
      <Caption text={scene.caption} />
    </>
  );
  if (scene.key === 'repair') return <Repair scene={scene} />;
  if (scene.key === 'evidence') return (
    <>
      <MediaPanel title={film.copy.videoTitle} footer={<div style={{display: 'flex', alignItems: 'center', justifyContent: 'space-between'}}><span style={{fontSize: 21, letterSpacing: 2, color: muted}}>{film.copy.videoLabel}</span><span style={{fontSize: 21, color: '#315d70'}}>Recording + test annotations</span></div>}>
        <Sequence from={scene.from * 30 - film.transitionFrames} layout="none">
          <OffthreadVideo src={staticFile(sources.testingVideo)} muted trimBefore={film.sourceVideo.startSeconds * 30} style={{display: 'block', width: '100%', height: 'auto'}} />
        </Sequence>
      </MediaPanel>
      <Caption text={scene.caption} />
    </>
  );
  if (scene.key === 'outcome') return (
    <>
      <MediaPanel title="Your app. Visible in the session." footer={<div style={{fontSize: 26, color: '#315d70'}}>Inspect the app. Review the evidence.</div>}>
        <SourceScreenshot src={sources.simulator} />
      </MediaPanel>
      <Caption text={scene.caption} />
    </>
  );
  return null;
};

const EndCard = () => (
  <Glass style={{position: 'absolute', left: 442, top: 268, width: 1036, height: 543, display: 'flex', alignItems: 'center', flexDirection: 'column', paddingTop: 78}}>
    <Img src={staticFile(sources.logoBlack)} style={{width: 445, height: 'auto'}} />
    <div style={{marginTop: 38, fontSize: 31, letterSpacing: 4, color: muted}}>macOS + iOS</div>
    <div style={{marginTop: 43, fontSize: 47, letterSpacing: -1.5}}>{film.scenes[7].headline}</div>
  </Glass>
);

const Launch = () => (
  <AbsoluteFill style={{fontFamily: film.font, background: '#dae8ed', color: ink}}>
    <Backdrop />
    <Plane level={1}>
      <Topline />
      <Footer />
      {film.scenes.map((scene) => <SceneFade key={scene.key} scene={scene}>{scene.key === 'end' ? <EndCard /> : <Copy scene={scene} />}</SceneFade>)}
    </Plane>
    <Plane level={2}>
      {film.scenes.filter((scene) => scene.key !== 'end').map((scene) => <SceneFade key={scene.key} scene={scene}><Foreground scene={scene} /></SceneFade>)}
    </Plane>
  </AbsoluteFill>
);

const Root = () => <Composition id="Launch" component={Launch} durationInFrames={metadata.durationSeconds * metadata.fps} fps={metadata.fps} width={metadata.width} height={metadata.height} />;

registerRoot(Root);
