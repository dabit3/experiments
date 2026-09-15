import React from 'react';
import {
  AbsoluteFill, Composition, Img, OffthreadVideo, Sequence,
  interpolate, registerRoot, staticFile, useCurrentFrame,
} from 'remotion';
import {brand, sources} from '../../shared/brand';
import {durationInFrames, studio, type Scene, type SceneId} from './config';
import {cameraTransform, Cursor, enter} from './motion';

const ink = '#26353d';
const muted = '#737f84';
const windowWidth = 1408;
const windowHeight = 738;
const contentHeight = 674;

const labelStyle: React.CSSProperties = {
  fontSize: 18, letterSpacing: 2.2, fontWeight: 600, color: muted,
};

type Crop = {source: string; fullWidth: number; x: number; y: number; width: number; height: number};
const phoneCrops = {
  charts: {source: sources.simulator, fullWidth: 2978, x: 682, y: 234, width: 581, height: 1191},
  game: {source: sources.simulatorGame, fullWidth: 2986, x: 698, y: 247, width: 550, height: 1103},
  wisp: {source: 'assets/devin-web-10.png', fullWidth: 2990, x: 682, y: 233, width: 585, height: 1195},
} satisfies Record<string, Crop>;

const CropImage: React.FC<{crop: Crop; height: number}> = ({crop, height}) => {
  const scale = height / crop.height;
  return (
    <div style={{height, width: crop.width * scale, position: 'relative', overflow: 'hidden'}}>
      <Img src={staticFile(crop.source)} style={{
        position: 'absolute', maxWidth: 'none', width: crop.fullWidth * scale,
        left: -crop.x * scale, top: -crop.y * scale,
      }} />
    </div>
  );
};

const Pill: React.FC<{children: React.ReactNode; accent?: boolean}> = ({children, accent = false}) => (
  <div style={{
    display: 'inline-flex', alignItems: 'center', gap: 9, padding: '9px 14px',
    background: accent ? '#e6f3ee' : '#f1f3f4', color: accent ? '#36735e' : '#67767d',
    borderRadius: 8, fontSize: 18, fontWeight: 500,
  }}>
    {accent ? <span style={{width: 7, height: 7, borderRadius: '50%', background: brand.green}} /> : null}
    {children}
  </div>
);

const Phone: React.FC<{kind?: keyof typeof phoneCrops}> = ({kind = 'charts'}) => (
  <div style={{position: 'absolute', left: 900, top: 30, width: 370, height: 610}}>
    <div style={{
      position: 'absolute', inset: '7px 5px 0', borderRadius: 100,
      background: 'radial-gradient(ellipse, #91b7b345, transparent 69%)',
    }} />
    <div style={{
      position: 'absolute', top: 4, left: 32, borderRadius: 60, overflow: 'hidden',
      filter: 'drop-shadow(0 19px 18px #20364120)',
    }}>
      <CropImage crop={phoneCrops[kind]} height={594} />
    </div>
  </div>
);

const Prompt: React.FC = () => (
  <div style={{
    position: 'absolute', left: 76, top: 460, width: 575,
    background: '#fff', border: '1px solid #dce3e6', borderRadius: 18,
    padding: '22px 25px', boxShadow: '0 6px 18px #384b5406',
  }}>
    <div style={{fontSize: 24, color: '#56666d', marginBottom: 24}}>{studio.copy.prompt}</div>
    <div style={{display: 'flex', alignItems: 'center', justifyContent: 'space-between'}}>
      <span style={{fontSize: 18, color: '#8a959a'}}>+ &nbsp; macOS</span>
      <span style={{
        borderRadius: '50%', background: ink, color: 'white', width: 34,
        height: 34, textAlign: 'center', lineHeight: '31px', fontSize: 26,
      }}>↑</span>
    </div>
  </div>
);

const HeroText: React.FC<{eyebrow: string; title: string; detail?: string}> = ({eyebrow, title, detail}) => (
  <div style={{position: 'absolute', left: 76, top: 74}}>
    <div style={{...labelStyle, marginBottom: 24, color: '#687b81'}}>{eyebrow}</div>
    <div style={{
      fontSize: 61, lineHeight: 1.075, fontWeight: 500, letterSpacing: -2.2,
      color: ink, whiteSpace: 'pre-line', maxWidth: 660,
    }}>{title}</div>
    {detail ? <div style={{fontSize: 25, color: muted, marginTop: 28, maxWidth: 640, lineHeight: 1.4}}>{detail}</div> : null}
  </div>
);

const StepRows: React.FC<{items: readonly string[]; active: number; top?: number}> = ({items, active, top = 315}) => (
  <div style={{position: 'absolute', left: 76, top, width: 581, display: 'grid', gap: 12}}>
    {items.map((item, index) => (
      <div key={item} style={{
        height: 65, borderRadius: 12, display: 'flex', alignItems: 'center', gap: 20,
        padding: '0 21px', background: index === active ? '#e8f1f6' : '#fff9',
        border: `1px solid ${index === active ? '#cadde7' : '#e4e9ec'}`,
        color: index === active ? '#215b7a' : '#819097', fontSize: 25,
      }}>
        <span style={{fontSize: 16, fontWeight: 600, letterSpacing: 1.5}}>0{index + 1}</span>
        {item}
        {index === active ? <span style={{marginLeft: 'auto', fontSize: 26}}>↗</span> : null}
      </div>
    ))}
  </div>
);

const NativeScene: React.FC<{id: SceneId; frame: number}> = ({id, frame}) => {
  const activeGesture = Math.min(2, Math.floor(frame / 70));
  const kind = id === 'loop' ? 'wisp'
    : id === 'interact' ? (['game', 'wisp', 'charts'] as const)[activeGesture]
      : 'charts';
  const track = id === 'build' ? studio.cursor.build : id === 'interact'
    ? studio.cursor.interact : id === 'loop' ? studio.cursor.loop : studio.cursor.hook;
  const cameraFrame = id === 'context' ? 0 : Math.max(0, frame - 26);
  return (
    <AbsoluteFill style={{
      background: 'linear-gradient(110deg, #f8fafb 0%, #f8fafb 52%, #e9f0f1 100%)',
      transform: cameraTransform(cameraFrame, studio.camera.native),
      transformOrigin: '73% 50%',
    }}>
      <div style={{position: 'absolute', left: 792, width: 1, top: 34, bottom: 34, background: '#dce5e8'}} />
      <Phone kind={kind} />
      {id === 'hook' ? <>
        <HeroText eyebrow="INTRODUCING NATIVE APP WORKFLOWS" title={studio.copy.hookTitle} />
        <div style={{position: 'absolute', left: 76, top: 340}}><Pill accent>Managed macOS</Pill></div>
        <Prompt />
      </> : null}
      {id === 'context' ? <>
        <HeroText eyebrow="THE OLD FEEDBACK LOOP" title={studio.copy.contextTitle} />
        <div style={{
          position: 'absolute', left: 76, top: 347, width: 578, padding: '25px 26px',
          background: '#edf0f2', borderRadius: 14, display: 'flex', alignItems: 'center', gap: 20,
        }}>
          <div style={{
            width: 46, height: 46, border: '2px solid #869399', borderRadius: '50%',
            position: 'relative', flexShrink: 0,
          }}>
            <div style={{position: 'absolute', left: 21, top: 9, height: 14, width: 2, background: '#869399'}} />
            <div style={{position: 'absolute', left: 21, top: 22, height: 2, width: 12, background: '#869399'}} />
          </div>
          <div>
            <div style={{fontSize: 30, letterSpacing: -0.6}}>{studio.copy.contextDetail}</div>
            <div style={{fontSize: 18, color: muted, marginTop: 5}}>Prior CI workflow</div>
          </div>
        </div>
        <div style={{position: 'absolute', left: 76, top: 513, fontSize: 22, color: muted}}>Your app is ready for a closer look.</div>
      </> : null}
      {id === 'build' ? <>
        <HeroText eyebrow="NATIVE TOOLS. MANAGED CAPACITY." title={studio.copy.buildTitle} />
        <StepRows items={studio.copy.buildSteps} active={Math.min(2, Math.floor(frame / 58))} />
      </> : null}
      {id === 'interact' ? <>
        <HeroText eyebrow="IOS SIMULATOR" title={studio.copy.interactTitle} />
        <StepRows items={studio.copy.gestures} active={activeGesture} />
      </> : null}
      {id === 'loop' ? <>
        <HeroText eyebrow="SEE THE ISSUE. KEEP WORKING." title={studio.copy.loopTitle} />
        <div style={{
          position: 'absolute', left: 76, top: 305, width: 581,
          borderRadius: 14, padding: '21px 22px', background: '#fff2ed', border: '1px solid #efd8cd',
        }}>
          <div style={{fontSize: 20, color: '#9c624d'}}>{studio.copy.loopNote}</div>
          <div style={{fontSize: 18, color: '#9a8178', marginTop: 8}}>{studio.copy.loopDisclaimer}</div>
        </div>
        <div style={{position: 'absolute', left: 76, top: 449, display: 'flex', gap: 12}}>
          {studio.copy.loopSteps.map((step, index) => (
            <div key={step} style={{
              padding: '19px 23px', fontSize: 24, borderRadius: 10,
              background: Math.min(2, Math.floor(frame / 70)) === index ? '#2b566b' : '#eaf0f3',
              color: Math.min(2, Math.floor(frame / 70)) === index ? 'white' : '#78909b',
            }}>{step}</div>
          ))}
        </div>
      </> : null}
      {id === 'outcome' ? <>
        <HeroText eyebrow="READY TO INSPECT" title={studio.copy.outcomeTitle} detail={studio.copy.outcomeDetail} />
        <div style={{
          position: 'absolute', left: 76, top: 453, borderTop: '1px solid #d7e1e5',
          paddingTop: 32, width: 600, fontSize: 34, letterSpacing: -0.6,
        }}>{studio.copy.price}</div>
      </> : null}
      {id !== 'context' && id !== 'outcome' ? (
        <Cursor frame={frame} points={track} clicks={id === 'interact' ? [48, 110, 157] : id === 'build' ? [91] : []} />
      ) : null}
    </AbsoluteFill>
  );
};

const Evidence: React.FC<{frame: number}> = ({frame}) => (
  <AbsoluteFill style={{background: '#eef2f5'}}>
    <AbsoluteFill style={{
      transform: cameraTransform(Math.max(0, frame - 15), studio.camera.evidence),
      transformOrigin: '50% 50%',
    }}>
      <OffthreadVideo
        src={staticFile(studio.sourceVideo.file)}
        trimBefore={studio.sourceVideo.startSeconds * studio.fps}
        muted
        style={{
          position: 'absolute', width: 1408, height: contentHeight,
          objectFit: 'contain',
        }}
      />
    </AbsoluteFill>
  </AbsoluteFill>
);

const Window: React.FC<{scene: Scene; frame: number; sceneStart: number}> = ({scene, frame, sceneStart}) => {
  const isSource = scene.id === 'evidence';
  const entrance = enter(frame, studio.entranceFrames);
  const scale = interpolate(entrance, [0, 1], [0.984, 1]);
  return (
    <div style={{
      position: 'absolute', left: (studio.width - windowWidth) / 2, top: 145,
      width: windowWidth, height: windowHeight, borderRadius: 22, overflow: 'hidden',
      border: '1px solid #ffffffcc', background: 'white',
      boxShadow: '0 40px 95px #37506b28, 0 10px 28px #384e6317, 0 1px 2px #0002',
      transform: `translateY(${(1 - entrance) * 14}px) scale(${scale})`,
    }}>
      <div style={{
        position: 'absolute', left: 0, top: 0, right: 0, height: 64, padding: '0 25px',
        display: 'flex', alignItems: 'center', background: '#fcfcfdef',
        borderBottom: '1px solid #e0e7e9', zIndex: 10,
      }}>
        <div style={{display: 'flex', gap: 8, width: 94}}>
          {['#ed8f86', '#ebca80', '#9cc9aa'].map((color) => (
            <div key={color} style={{background: color, width: 12, height: 12, borderRadius: '50%'}} />
          ))}
        </div>
        <Img src={staticFile(sources.markBlack)} style={{width: 22, height: 22, objectFit: 'contain', marginRight: 12}} />
        <div style={{fontSize: 20, color: '#62727a'}}>{isSource ? 'Devin · Recorded evidence' : studio.copy.session}</div>
        <div style={{
          marginLeft: 'auto', padding: '7px 12px', borderRadius: 7,
          background: isSource ? '#edf2fa' : '#eef3f3', fontSize: 17,
          color: isSource ? '#536f9b' : '#718487',
        }}>{isSource ? studio.sourceVideo.label : studio.copy.illustrative}</div>
      </div>
      <div style={{position: 'absolute', top: 64, height: contentHeight, width: windowWidth, overflow: 'hidden'}}>
        {isSource ? (
          <Sequence from={sceneStart} layout="none"><Evidence frame={frame} /></Sequence>
        ) : (
          <NativeScene id={scene.id} frame={frame} />
        )}
      </div>
    </div>
  );
};

const SceneLayer: React.FC<{scene: Scene; frame: number; start: number}> = ({scene, frame, start}) => {
  if (scene.id === 'end') {
    const reveal = enter(frame, 32);
    return (
      <AbsoluteFill style={{alignItems: 'center', justifyContent: 'center'}}>
        <div style={{textAlign: 'center', transform: `translateY(${(1 - reveal) * 22}px)`}}>
          <Img src={staticFile(sources.logoBlack)} style={{width: 470, height: 'auto', objectFit: 'contain'}} />
          <div style={{fontSize: 30, letterSpacing: -0.5, color: '#61727b', marginTop: 32}}>{studio.copy.endPlatform}</div>
          <div style={{fontSize: 52, fontWeight: 500, letterSpacing: -1.8, marginTop: 54}}>{studio.copy.endCta}</div>
        </div>
      </AbsoluteFill>
    );
  }
  return (
    <AbsoluteFill>
      <Window scene={scene} frame={frame} sceneStart={start} />
      <div style={{
        position: 'absolute', left: 150, right: 150, top: 927, textAlign: 'center',
        opacity: enter(frame, 20), transform: `translateY(${(1 - enter(frame, 24)) * 10}px)`,
      }}>
        <div style={{fontSize: 46, lineHeight: 1.2, fontWeight: 500, letterSpacing: -1.3}}>{scene.caption}</div>
        <div style={{...labelStyle, fontSize: 15, letterSpacing: 1.8, marginTop: 20}}>{scene.chapter}</div>
      </div>
    </AbsoluteFill>
  );
};

const Launch: React.FC = () => {
  const frame = useCurrentFrame();
  let accumulated = 0;
  const scenes = studio.scenes.map((scene) => {
    const start = accumulated;
    accumulated += scene.seconds * studio.fps;
    return {scene, start, end: accumulated};
  });
  const activeIndex = scenes.findIndex(({end}) => frame < end);
  return (
    <AbsoluteFill style={{fontFamily: studio.font, color: ink, background: '#e9edf4'}}>
      <AbsoluteFill style={{
        background: 'radial-gradient(ellipse at 12% 20%, #d5dfed 0%, transparent 53%), radial-gradient(ellipse at 88% 12%, #dbd3e7 0%, transparent 50%), radial-gradient(ellipse at 82% 98%, #c9e2df 0%, transparent 53%), radial-gradient(ellipse at 8% 95%, #e9d8c9 0%, transparent 50%), #edf0f5',
      }} />
      <div style={{
        position: 'absolute', left: 93, right: 93, top: 54, display: 'flex',
        alignItems: 'center', justifyContent: 'space-between', opacity: activeIndex === 7 ? 0 : 1,
      }}>
        <span style={{...labelStyle, fontSize: 16, color: '#697984'}}>{studio.copy.eyebrow}</span>
        <div style={{display: 'flex', alignItems: 'center', gap: 13}}>
          <span style={{fontSize: 15, color: '#7b8690', letterSpacing: 1}}>NATIVE WORKFLOWS</span>
          <span style={{width: 6, height: 6, borderRadius: '50%', background: '#9eafb8'}} />
          <span style={{fontSize: 15, color: '#7b8690'}}>20</span>
        </div>
      </div>
      {scenes.map(({scene, start, end}) => {
        if (frame < start || frame >= end) return null;
        const local = frame - start;
        return <SceneLayer key={scene.id} scene={scene} frame={local} start={start} />;
      })}
    </AbsoluteFill>
  );
};

const Root: React.FC = () => (
  <Composition id="Launch" component={Launch} durationInFrames={durationInFrames} fps={studio.fps} width={studio.width} height={studio.height} />
);

registerRoot(Root);
