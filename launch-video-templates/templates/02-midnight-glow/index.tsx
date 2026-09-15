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
import {brand, sources} from '../../shared/brand';
import {config, type Scene} from './config';
import metadata from './template.json';

const c = config.colors;
const fps = metadata.fps;
const clamp = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'} as const;
const easeOut = Easing.out(Easing.cubic);
const easeMove = Easing.inOut(Easing.cubic);
const box: CSSProperties = {
  background: c.surface,
  border: `1px solid ${c.border}`,
  borderRadius: 22,
};

const appear = (frame: number, delay = 0, duration = 24) =>
  interpolate(frame, [delay, delay + duration], [0, 1], {...clamp, easing: easeOut});

const Crop: React.FC<{
  source: string;
  sourceWidth: number;
  region: readonly [number, number, number, number];
  width: number;
  radius?: number;
}> = ({source, sourceWidth, region: [x, y, w, h], width, radius = 0}) => {
  const scale = width / w;
  return (
    <div style={{width, height: h * scale, overflow: 'hidden', position: 'relative', borderRadius: radius}}>
      <Img src={staticFile(source)} style={{
        position: 'absolute', width: sourceWidth * scale, maxWidth: 'none',
        height: 'auto', left: -x * scale, top: -y * scale,
      }}/>
    </div>
  );
};

const Phone: React.FC<{x: number; y: number; width: number; wisp?: boolean}> =
  ({x, y, width, wisp = false}) => (
    <div style={{
      position: 'absolute', left: x, top: y, borderRadius: width * 0.18,
      boxShadow: '0 32px 100px #0009, 0 0 70px #1971c212',
      border: '1px solid #a7b5d92b', overflow: 'hidden',
    }}>
      <Crop source={wisp ? 'assets/devin-web-10.png' : sources.simulator}
        sourceWidth={wisp ? 2990 : 2978}
        region={wisp ? [687, 237, 579, 1184] : [682, 237, 579, 1184]}
        width={width} radius={width * 0.18}/>
    </div>
  );

const Pill: React.FC<{children: React.ReactNode; style?: CSSProperties}> = ({children, style}) => (
  <div style={{
    ...box, borderRadius: 999, padding: '14px 23px', color: '#d7d9e2',
    fontSize: 22, whiteSpace: 'nowrap', ...style,
  }}>{children}</div>
);

const Callout: React.FC<{
  label: string; frame: number; delay?: number;
  x: number; y: number; width: number; target: readonly [number, number];
}> = ({label, frame, delay = 36, x, y, width, target: [tx, ty]}) => {
  const p = appear(frame, delay, 24);
  const facingRight = tx > x + width / 2;
  const slide = (1 - p) * (facingRight ? -48 : 48);
  const sx = facingRight ? x + width : x;
  const elbow = facingRight ? sx + 42 : sx - 42;
  return (
    <AbsoluteFill style={{opacity: p, transform: `translateX(${slide}px)`}}>
      <svg width={1920} height={1080} style={{position: 'absolute'}}>
        <path d={`M ${sx} ${y + 27} H ${elbow} L ${tx} ${ty}`} fill="none"
          stroke="#b9a1ed" strokeOpacity={0.55} strokeWidth={1}/>
        <circle cx={tx} cy={ty} r={4} fill={c.accent}/>
        <circle cx={tx} cy={ty} r={10} fill="none" stroke={c.accent} strokeOpacity={0.25}/>
      </svg>
      <Pill style={{
        position: 'absolute', left: x, top: y, width, padding: '15px 0',
        textAlign: 'center', fontSize: 20, lineHeight: '24px',
        background: '#11121beF', boxShadow: '0 0 24px #956cde12',
      }}>{label}</Pill>
    </AbsoluteFill>
  );
};

const Copy: React.FC<{scene: Scene; size?: number; y?: number; width?: number}> =
  ({scene, size = 88, y = 294, width = 750}) => (
    <div style={{position: 'absolute', left: 144, top: y, width}}>
      <div style={{fontSize: 19, letterSpacing: 3.3, color: c.accent, marginBottom: 30}}>{scene.eyebrow}</div>
      <div style={{
        fontSize: size, lineHeight: 1.05, letterSpacing: -size * 0.041,
        fontWeight: 500, whiteSpace: 'pre-line', textShadow: '0 0 28px #d8d1ff12',
      }}>{scene.title}</div>
      <div style={{
        marginTop: 33, fontSize: 29, lineHeight: 1.45,
        color: c.secondary, whiteSpace: 'pre-line', letterSpacing: -0.5,
      }}>{scene.detail}</div>
    </div>
  );

const Label: React.FC<{text: string; x?: number; y?: number}> = ({text, x = 144, y = 941}) => (
  <div style={{position: 'absolute', left: x, top: y, fontSize: 18, color: '#8e97a9', letterSpacing: 0.3}}>
    {text}
  </div>
);

const Hook: React.FC<{scene: Scene; frame: number}> = ({scene, frame}) => (
  <>
    <Copy scene={scene} size={130} y={258}/>
    <div style={{position: 'absolute', left: 144, top: 751, display: 'flex', gap: 12}}>
      <Pill>macOS</Pill><Pill>iOS</Pill>
    </div>
    <Phone x={1150} y={160} width={363}/>
    <Callout label={config.labels.livePhone} frame={frame} x={1490} y={365} width={275} target={[1455, 480]}/>
    <Label text={config.labels.native} x={1090}/>
  </>
);

const Context: React.FC<{scene: Scene}> = ({scene}) => (
  <>
    <Copy scene={scene} size={105} y={298} width={910}/>
    <div style={{position: 'absolute', left: 1200, top: 320, width: 570}}>
      <div style={{height: 1, background: 'linear-gradient(90deg,#956cde66,transparent)', marginBottom: 42}}/>
      <div style={{fontSize: 168, letterSpacing: -9, lineHeight: 1, fontWeight: 400}}>20<span style={{color: c.accent}}>+</span></div>
      <div style={{fontSize: 30, color: c.secondary, marginTop: 22}}>minutes waiting on CI</div>
      <div style={{fontSize: 18, color: '#7a8293', marginTop: 26}}>Prior workflow context</div>
    </div>
    <div style={{position: 'absolute', left: 144, top: 842, width: 1632, height: 1, background: '#ffffff14'}}/>
    <Label text="The next loop happens inside the session." y={876}/>
  </>
);

const Build: React.FC<{scene: Scene; frame: number}> = ({scene, frame}) => {
  const step = Math.min(2, Math.floor(Math.max(0, frame - 42) / 40));
  return (
    <>
      <Copy scene={scene} size={82} y={340} width={720}/>
      <div style={{...box, position: 'absolute', left: 904, top: 189, width: 870, height: 707}}>
        <div style={{height: 71, borderBottom: `1px solid ${c.border}`, display: 'flex', alignItems: 'center', padding: '0 29px'}}>
          <Img src={staticFile(sources.markWhite)} style={{width: 27, height: 'auto', marginRight: 17}}/>
          <span style={{fontSize: 21}}>Native app workspace</span>
          <span style={{marginLeft: 'auto', color: c.accent, fontSize: 19}}>macOS</span>
        </div>
        <div style={{position: 'absolute', left: 32, top: 119, width: 337}}>
          <div style={{fontSize: 17, color: c.secondary, letterSpacing: 2}}>DEVIN SESSION</div>
          <div style={{fontSize: 27, marginTop: 20, lineHeight: 1.35}}>Build the app.<br/>Run it in Simulator.</div>
          <div style={{fontFamily: brand.monoFont, color: '#adb4c6', fontSize: 18, marginTop: 30}}>
            <span style={{color: c.accent}}>$</span> xcodebuild …
          </div>
          <div style={{marginTop: 40, display: 'grid', gap: 12}}>
            {['Build with Xcode', 'Run the app', 'Open Simulator'].map((text, i) => (
              <div key={text} style={{
                ...box, padding: '19px 18px', borderRadius: 11, fontSize: 21,
                color: step === i ? c.foreground : c.secondary,
                background: step === i ? '#1971c21a' : '#0b0d13',
                borderColor: step === i ? '#1971c27a' : c.border,
              }}>
                <span style={{color: c.accent, marginRight: 15, fontFamily: brand.monoFont, fontSize: 16}}>0{i + 1}</span>{text}
              </div>
            ))}
          </div>
        </div>
      </div>
      <Phone x={1360} y={291} width={275}/>
      <Callout label={config.labels.mac} frame={frame} x={1440} y={120} width={255} target={[1660, 225]}/>
      <Callout label={config.labels.simulator} frame={frame} delay={80} x={1115} y={823} width={250} target={[1410, 747]}/>
      <Label text={config.labels.staged} x={904}/>
    </>
  );
};

const Interact: React.FC<{scene: Scene; frame: number}> = ({scene, frame}) => {
  const phase = frame < 72 ? 0 : frame < 123 ? 1 : 2;
  const labels = ['Tap controls', 'Type in fields', 'Scroll the view'];
  const points: readonly (readonly [number, number])[] = [[1190, 230], [1260, 820], [1353, 540]];
  const move = interpolate(frame, [130, 155, 177], [0, -48, -48], {...clamp, easing: easeMove});
  return (
    <>
      <Copy scene={scene} size={101} y={237}/>
      <Phone x={1095} y={146} width={382} wisp/>
      <Callout key={phase} label={labels[phase]} frame={frame}
        delay={phase === 0 ? 35 : phase === 1 ? 72 : 123}
        x={1520} y={phase === 0 ? 246 : phase === 1 ? 737 : 491}
        width={245} target={points[phase]}/>
      {phase === 2 && (
        <div style={{
          position: 'absolute', left: 1420, top: 568 + move, width: 26, height: 94,
          border: `1px solid ${c.accent}`, borderRadius: 20, opacity: appear(frame, 130, 15),
          background: '#956cde17', textAlign: 'center', paddingTop: 10, fontSize: 20, color: c.accent,
        }}>↑</div>
      )}
      <Label text={config.labels.native} x={1090}/>
    </>
  );
};

const Retest: React.FC<{scene: Scene; frame: number}> = ({scene, frame}) => {
  const active = Math.min(2, Math.floor(Math.max(0, frame - 38) / 43));
  return (
    <>
      <Copy scene={scene} size={94} y={255}/>
      <div style={{...box, position: 'absolute', left: 926, top: 294, width: 850, overflow: 'hidden', borderRadius: 16}}>
        <div style={{fontSize: 18, padding: '18px 22px', color: c.secondary}}>Wisp Simulator · supplied report</div>
        <Crop source="assets/devin-web-10.png" sourceWidth={2990} region={[1950, 142, 1040, 445]} width={848}/>
      </div>
      <div style={{position: 'absolute', left: 926, top: 770, display: 'flex', gap: 12}}>
        {['Reproduce', 'Edit code', 'Retest'].map((text, i) => (
          <div key={text} style={{
            ...box, width: 274, height: 112, display: 'flex', flexDirection: 'column',
            justifyContent: 'center', paddingLeft: 24,
            borderColor: active === i ? '#956cde80' : c.border,
            background: active === i ? '#956cde14' : '#0b0d13',
          }}>
            <div style={{fontSize: 16, letterSpacing: 2, color: c.accent, marginBottom: 9}}>0{i + 1}</div>
            <div style={{fontSize: 25, color: active === i ? c.foreground : c.secondary}}>{text}</div>
          </div>
        ))}
      </div>
      <Callout label="Keep failures visible" frame={frame} x={1413} y={179} width={300} target={[1234, 372]}/>
      <Label text="Illustrative workflow · source report includes failed and untested checks" x={926}/>
    </>
  );
};

const Evidence: React.FC<{scene: Scene; frame: number}> = ({scene, frame}) => (
  <>
    <Copy scene={scene} size={80} y={331} width={645}/>
    <div style={{...box, position: 'absolute', left: 796, top: 270, width: 982, overflow: 'hidden', borderRadius: 15}}>
      <div style={{height: 55, display: 'flex', alignItems: 'center', padding: '0 22px', gap: 12, fontSize: 18, color: '#cbd2df'}}>
        <span style={{width: 7, height: 7, borderRadius: 8, background: brand.green}}/>
        {config.labels.video}
      </div>
      <OffthreadVideo src={staticFile(config.video.file)} muted
        trimBefore={config.video.startSeconds * fps}
        style={{display: 'block', width: 980, height: 980 * 1080 / 1918, objectFit: 'contain'}}/>
    </div>
    <Callout label={config.labels.review} frame={frame} x={1420} y={166} width={257} target={[1620, 592]}/>
    <Label text="Generic web QA insert · native scenes use supplied stills" x={796}/>
  </>
);

const Outcome: React.FC<{scene: Scene; frame: number}> = ({scene, frame}) => (
  <>
    <Copy scene={scene} size={92} y={295} width={1000}/>
    <div style={{position: 'absolute', left: 144, top: 677}}>
      <Pill style={{color: '#d5f0e8', borderColor: '#0ca67850', background: '#0ca6780a'}}>macOS + iOS, now in Devin</Pill>
    </div>
    <Phone x={1190} y={167} width={351}/>
    <Callout label="Inspect it in-session" frame={frame} x={1475} y={620} width={298} target={[1446, 742]}/>
    <Label text={config.labels.native} x={1090}/>
  </>
);

const End: React.FC<{scene: Scene}> = ({scene}) => (
  <AbsoluteFill style={{alignItems: 'center', justifyContent: 'center'}}>
    <div style={{fontSize: 21, color: c.accent, letterSpacing: 4, marginBottom: 57}}>MACOS + IOS</div>
    <Img src={staticFile(sources.logoWhite)} style={{width: 590, height: 'auto'}}/>
    <div style={{fontSize: 39, letterSpacing: -1, marginTop: 54, color: '#cbd0dc'}}>{scene.title}</div>
    <div style={{width: 88, height: 1, background: '#956cde88', marginTop: 56}}/>
  </AbsoluteFill>
);

const SceneContent: React.FC<{scene: Scene; frame: number}> = ({scene, frame}) => {
  switch (scene.id) {
    case 'hook': return <Hook scene={scene} frame={frame}/>;
    case 'context': return <Context scene={scene}/>;
    case 'build': return <Build scene={scene} frame={frame}/>;
    case 'interact': return <Interact scene={scene} frame={frame}/>;
    case 'retest': return <Retest scene={scene} frame={frame}/>;
    case 'evidence': return <Evidence scene={scene} frame={frame}/>;
    case 'outcome': return <Outcome scene={scene} frame={frame}/>;
    case 'end': return <End scene={scene}/>;
  }
};

const SceneLayer: React.FC<{scene: Scene; index: number}> = ({scene, index}) => {
  const frame = useCurrentFrame();
  const incoming = index === 0 ? 1 : appear(frame, 0, config.transitionFrames);
  return (
    <AbsoluteFill style={{
      opacity: 0.55 + incoming * 0.45,
      transform: `translateY(${(1 - incoming) * 22}px)`,
    }}>
      <SceneContent scene={scene} frame={frame}/>
    </AbsoluteFill>
  );
};

const Launch: React.FC = () => {
  const frame = useCurrentFrame();
  let start = 0;
  const timeline = config.scenes.map((scene, index) => {
    const from = start;
    start += scene.seconds * fps;
    return {scene, index, from};
  });
  const current = timeline.filter(({from}) => frame >= from).at(-1);
  const featureIndex = current ? current.index - 2 : -1;
  return (
    <AbsoluteFill style={{
      backgroundColor: c.background, color: c.foreground, fontFamily: brand.displayFont,
      overflow: 'hidden', WebkitFontSmoothing: 'antialiased',
      backgroundImage: 'radial-gradient(ellipse 740px 660px at 72% 47%, #1971c219, transparent 78%), radial-gradient(ellipse 820px 500px at 82% 80%, #956cde15, transparent 76%)',
    }}>
      <div style={{position: 'absolute', inset: 40, border: '1px solid #ffffff05', borderRadius: 18}}/>
      <div style={{position: 'absolute', left: 144, top: 68, display: 'flex', alignItems: 'center', gap: 17, color: '#a1a8b8'}}>
        <Img src={staticFile(sources.markWhite)} style={{width: 30, height: 'auto'}}/>
        <span style={{fontSize: 16, letterSpacing: 2.8}}>DEVIN / PRODUCT UPDATE</span>
      </div>
      <div style={{position: 'absolute', right: 144, top: 76, fontSize: 17, letterSpacing: 2, color: '#8891a4'}}>MACOS + IOS</div>
      {timeline.map(({scene, index, from}) => (
        <Sequence key={scene.id} from={from} durationInFrames={scene.seconds * fps}>
          <SceneLayer scene={scene} index={index}/>
        </Sequence>
      ))}
      <div style={{position: 'absolute', left: 144, right: 144, top: 1005, height: 1, background: '#ffffff12'}}/>
      <div style={{position: 'absolute', left: 144, top: 1024, fontSize: 15, color: '#737d91', letterSpacing: 2}}>DEVIN ON MACOS + IOS</div>
      {featureIndex >= 0 && featureIndex < 4 && (
        <div style={{position: 'absolute', right: 144, top: 1028, display: 'flex', gap: 8}}>
          {[0, 1, 2, 3].map((i) => (
            <div key={i} style={{width: 42, height: 3, background: i === featureIndex ? c.accent : '#ffffff1a'}}/>
          ))}
        </div>
      )}
    </AbsoluteFill>
  );
};

const Root: React.FC = () => (
  <Composition id={metadata.compositionId} component={Launch}
    durationInFrames={metadata.durationSeconds * fps} fps={fps}
    width={metadata.width} height={metadata.height}/>
);

registerRoot(Root);
