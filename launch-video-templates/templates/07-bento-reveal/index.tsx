import React, {type CSSProperties} from 'react';
import {
  AbsoluteFill,
  Composition,
  Easing,
  Freeze,
  Img,
  OffthreadVideo,
  interpolate,
  registerRoot,
  staticFile,
  useCurrentFrame,
} from 'remotion';
import {brand, sources} from '../../shared/brand';
import {config, type Feature} from './config';

const W = 1920;
const H = 1080;
const at = (seconds: number) => Math.round(seconds * config.fps);
const clamp = (value: number) => Math.min(1, Math.max(0, value));
const easeOut = Easing.out(Easing.cubic);
const easeMove = Easing.inOut(Easing.cubic);
const mix = (a: number, b: number, p: number) => a + (b - a) * p;
const smallCaps: CSSProperties = {
  fontSize: 22,
  letterSpacing: 2.4,
  fontWeight: 500,
  textTransform: 'uppercase',
};

const crops = {
  maze: {src: sources.simulatorGame, x: 702, y: 254, w: 537, h: 1098, naturalW: 2986},
  wisp: {src: 'assets/devin-web-10.png', x: 686, y: 237, w: 574, h: 1184, naturalW: 2990},
  review: {src: 'assets/devin-web-10.png', x: 1945, y: 141, w: 1035, h: 1090, naturalW: 2990},
  rescue: {src: sources.simulator, x: 686, y: 237, w: 574, h: 1184, naturalW: 2978},
} as const;

const Crop: React.FC<{
  name: keyof typeof crops;
  width: number;
  style?: CSSProperties;
}> = ({name, width, style}) => {
  const crop = crops[name];
  const scale = width / crop.w;
  return (
    <div style={{
      position: 'relative', width, height: crop.h * scale, overflow: 'hidden',
      flexShrink: 0, ...style,
    }}>
      <Img src={staticFile(crop.src)} style={{
        position: 'absolute', width: crop.naturalW * scale, maxWidth: 'none',
        height: 'auto', left: -crop.x * scale, top: -crop.y * scale,
      }} />
    </div>
  );
};

const Pill: React.FC<{children: React.ReactNode; dark?: boolean}> = ({children, dark}) => (
  <div style={{
    display: 'inline-flex', alignItems: 'center', borderRadius: 40,
    padding: '12px 20px', fontSize: 22, letterSpacing: 0.1,
    background: dark ? '#ffffff12' : '#ffffffb0',
    border: `1px solid ${dark ? '#ffffff25' : '#19191912'}`,
  }}>{children}</div>
);

const Arrow = () => <span style={{fontSize: 32, lineHeight: 1}}>↗</span>;

const MiniBuild = () => (
  <div style={{
    position: 'absolute', left: 424, top: 48, width: 500, height: 222,
    borderRadius: '20px 20px 0 0', background: '#fcfcfc',
    border: `1px solid ${brand.border}`, padding: '24px 28px',
  }}>
    <div style={{display: 'flex', gap: 7, marginBottom: 28}}>
      {['#d4d9dd', '#d4d9dd', '#d4d9dd'].map((color, i) => (
        <div key={i} style={{width: 9, height: 9, borderRadius: '50%', background: color}} />
      ))}
      <span style={{marginLeft: 18, fontSize: 15, color: '#666'}}>Native project</span>
    </div>
    <div style={{fontFamily: brand.monoFont, fontSize: 22, color: brand.blue}}>› xcodebuild</div>
    <div style={{fontSize: 22, marginTop: 26}}>Open in Simulator <span style={{float: 'right'}}>→</span></div>
  </div>
);

const MiniFix = () => (
  <div style={{position: 'absolute', bottom: 38, left: 36, right: 36}}>
    <div style={{display: 'flex', alignItems: 'center', gap: 14}}>
      {['Reproduce', 'Fix', 'Retest'].map((word, i) => (
        <React.Fragment key={word}>
          {i > 0 && <span style={{color: '#749487'}}>→</span>}
          <span style={{fontSize: 20, color: '#d5f0e8'}}>{word}</span>
        </React.Fragment>
      ))}
    </div>
    <div style={{height: 4, borderRadius: 10, background: '#d5f0e824', marginTop: 32}}>
      <div style={{height: '100%', width: '66%', borderRadius: 10, background: '#b6d9cc'}} />
    </div>
  </div>
);

const MiniEvidence = () => (
  <div style={{
    position: 'absolute', left: 36, right: 36, bottom: 30, height: 122,
    background: '#ffffffb3', borderRadius: 18, display: 'flex',
    alignItems: 'center', padding: '0 26px', gap: 26,
  }}>
    <div style={{
      width: 58, height: 58, background: brand.ink, color: 'white',
      borderRadius: '50%', display: 'grid', placeItems: 'center', fontSize: 23,
    }}>▶</div>
    <div style={{flex: 1}}>
      <div style={{fontSize: 21, marginBottom: 16}}>Recorded steps</div>
      <div style={{display: 'flex', gap: 5}}>
        {[48, 62, 30, 46].map((width, i) => (
          <div key={i} style={{height: 7, width, borderRadius: 8, background: '#b3a2c9'}} />
        ))}
      </div>
    </div>
  </div>
);

const TileFace: React.FC<{feature: Feature; outcome: boolean}> = ({feature, outcome}) => (
  <AbsoluteFill style={{color: feature.id === 'fix' ? '#fff' : brand.ink}}>
    <div style={{position: 'absolute', left: 36, top: 31, ...smallCaps, fontSize: 17, opacity: 0.65}}>
      {feature.number} / {feature.id === 'build' ? 'Managed Mac VM' : feature.id === 'simulator' ? 'iOS Simulator' : 'Workflow'}
    </div>
    <div style={{
      position: 'absolute', left: 36, top: 77, fontSize: feature.id === 'build' ? 45 : 37,
      fontWeight: 500, letterSpacing: -1.6,
    }}>{feature.title}</div>
    <div style={{position: 'absolute', right: 34, top: 30}}><Arrow /></div>
    {feature.id === 'build' && <MiniBuild />}
    {feature.id === 'simulator' && (
      <>
        <Crop name={outcome ? 'rescue' : 'wisp'} width={205} style={{
          position: 'absolute', left: 428, top: 152, borderRadius: 40,
          boxShadow: '0 16px 30px #1647351a',
        }} />
        <div style={{position: 'absolute', left: 36, top: 195, fontSize: 29, lineHeight: 1.45, letterSpacing: -0.6}}>
          A live iPhone.<br />In your session.
        </div>
        <div style={{position: 'absolute', left: 36, bottom: 44}}>
          <Pill>Native apps</Pill>
        </div>
      </>
    )}
    {feature.id === 'fix' && <MiniFix />}
    {feature.id === 'evidence' && <MiniEvidence />}
  </AbsoluteFill>
);

const FeatureHeader: React.FC<{feature: Feature; fontSize?: number}> = ({feature, fontSize = 100}) => (
  <>
    <div style={{position: 'absolute', left: 96, top: 76, ...smallCaps}}>
      {feature.number} / {feature.title}
    </div>
    <div style={{
      position: 'absolute', left: 90, top: 174, fontSize, fontWeight: 500,
      letterSpacing: -4.5, lineHeight: 1.035,
    }}>
      {feature.headline.map((line) => <div key={line}>{line}</div>)}
    </div>
  </>
);

const Footnote: React.FC<{children: React.ReactNode}> = ({children}) => (
  <div style={{position: 'absolute', left: 96, bottom: 46, fontSize: 20, opacity: 0.65}}>
    {children}
  </div>
);

const BuildScene: React.FC<{feature: Feature; frame: number}> = ({feature, frame}) => {
  const focus = clamp((frame - at(feature.start + 1.7)) / at(0.65));
  return (
    <AbsoluteFill>
      <FeatureHeader feature={feature} fontSize={91} />
      <div style={{position: 'absolute', left: 96, top: 445, fontSize: 31, color: '#4d657e'}}>
        Your native project. A managed Mac VM.
      </div>
      <div style={{
        position: 'absolute', left: 96, top: 586, width: 666,
        padding: 32, borderRadius: 26, background: '#ffffffa8',
        border: `1px solid ${brand.border}`,
      }}>
        <div style={{...smallCaps, fontSize: 17, color: '#627388', marginBottom: 23}}>Devin / native workflow</div>
        {config.buildSteps.map((step, i) => (
          <div key={step} style={{
            display: 'flex', justifyContent: 'space-between', alignItems: 'center',
            padding: '22px 20px', fontSize: 29, borderRadius: 15,
            background: i === 0 ? `rgba(25,113,194,${0.12 * (1 - focus)})` : `rgba(25,113,194,${0.12 * focus})`,
          }}>
            <span>{step}</span><span style={{color: brand.blue}}>→</span>
          </div>
        ))}
      </div>
      <div style={{
        position: 'absolute', left: 1020, top: 102, width: 686, height: 874,
        borderRadius: 40, background: '#d3e1f2', border: '1px solid #bdcfe2',
      }}>
        <div style={{position: 'absolute', top: 24, left: 30, fontSize: 20, color: '#425d7a'}}>iPhone · Simulator</div>
        <Crop name="maze" width={356} style={{position: 'absolute', left: 165, top: 92, borderRadius: 68}} />
      </div>
      <Footnote>Illustrative workflow · supplied native iOS screenshot</Footnote>
    </AbsoluteFill>
  );
};

const SimulatorScene: React.FC<{feature: Feature; frame: number}> = ({feature, frame}) => {
  const local = frame - at(feature.start + 0.8);
  const active = Math.min(2, Math.max(0, Math.floor(local / at(1.6))));
  const gesture = easeMove(clamp((local - at(3.2)) / at(1.0)));
  const pulse = Math.sin(clamp(local / at(0.7)) * Math.PI);
  return (
    <AbsoluteFill>
      <FeatureHeader feature={feature} fontSize={132} />
      <div style={{position: 'absolute', left: 96, top: 518, fontSize: 31, color: '#45685b'}}>
        Devin interacts with iOS Simulator.
      </div>
      <div style={{position: 'absolute', left: 96, top: 662, display: 'flex', gap: 18}}>
        {config.simulatorSteps.map((step, i) => (
          <div key={step} style={{
            padding: '22px 36px', borderRadius: 20, fontSize: 32,
            color: active === i ? '#fff' : '#3c6252',
            background: active === i ? '#254d3e' : '#ffffff78',
          }}>{step}</div>
        ))}
      </div>
      <div style={{position: 'absolute', left: 96, top: 800, fontSize: 25, color: '#527364'}}>
        One interactive device at a time.
      </div>
      <div style={{position: 'absolute', left: 1232, top: 84}}><Pill>Live iPhone · Simulator</Pill></div>
      <Crop name="wisp" width={370} style={{
        position: 'absolute', left: 1190, top: 192, borderRadius: 72,
        boxShadow: '0 24px 48px #244d3e20',
      }} />
      <div style={{
        position: 'absolute', left: active === 1 ? 1440 : 1340,
        top: active === 2 ? mix(705, 420, gesture) : active === 1 ? 875 : 363,
        width: 36 + pulse * 24, height: 36 + pulse * 24,
        border: '3px solid #0ca678', background: '#0ca67830',
        borderRadius: '50%', transform: 'translate(-50%, -50%)',
        opacity: local < 0 ? 0 : 0.95,
      }} />
      <Footnote>Illustrative gestures · supplied iOS screenshot</Footnote>
    </AbsoluteFill>
  );
};

const FixScene: React.FC<{feature: Feature; frame: number}> = ({feature, frame}) => {
  const focus = Math.min(2, Math.max(0, Math.floor((frame - at(feature.start + 0.8)) / at(1.4))));
  return (
    <AbsoluteFill style={{color: '#fff'}}>
      <FeatureHeader feature={feature} fontSize={107} />
      <div style={{position: 'absolute', left: 96, top: 530, width: 660}}>
        {config.fixSteps.map((step, i) => (
          <div key={step} style={{
            display: 'flex', gap: 24, alignItems: 'center', padding: '23px 0',
            borderBottom: '1px solid #ffffff22',
            color: focus === i ? '#d5f0e8' : '#92a39c',
          }}>
            <span style={{fontFamily: brand.monoFont, fontSize: 21}}>0{i + 1}</span>
            <span style={{fontSize: 33}}>{step}</span>
            {focus === i && <span style={{marginLeft: 'auto', fontSize: 30}}>→</span>}
          </div>
        ))}
      </div>
      <div style={{position: 'absolute', left: 977, top: 82}}><Pill dark>Inspect the reported failure</Pill></div>
      <Crop name="review" width={742} style={{
        position: 'absolute', left: 977, top: 163, borderRadius: 24,
        border: '1px solid #ffffff30',
      }} />
      <Footnote>Illustrative workflow · source report includes failed and untested checks</Footnote>
    </AbsoluteFill>
  );
};

const EvidenceScene: React.FC<{feature: Feature; frame: number}> = ({feature, frame}) => (
  <AbsoluteFill>
    <FeatureHeader feature={feature} fontSize={94} />
    <div style={{position: 'absolute', left: 98, top: 309, ...smallCaps, fontSize: 18, color: '#715d88'}}>
      Source recording / web app QA
    </div>
    <div style={{
      position: 'absolute', left: 96, top: 350, width: 1210,
      height: 1210 * 1080 / 1918, borderRadius: 20, overflow: 'hidden',
      boxShadow: '0 15px 45px #30184a12', border: '1px solid #4e356623',
    }}>
      <Freeze frame={Math.max(0, Math.min(
        at(feature.collapse - feature.start - config.transitionSeconds) - 1,
        frame - at(feature.start + config.transitionSeconds),
      ))}>
        <OffthreadVideo
          src={staticFile(sources.testingVideo)}
          trimBefore={at(config.sourceVideoStartSeconds)}
          muted
          style={{width: '100%', height: '100%', objectFit: 'contain'}}
        />
      </Freeze>
    </div>
    <div style={{position: 'absolute', left: 1400, top: 442, width: 398}}>
      {['Replay the steps.', 'Inspect the result.', 'Review the evidence.'].map((line, i) => (
        <div key={line} style={{
          fontSize: 36, lineHeight: 1.25, letterSpacing: -0.7,
          padding: '32px 0', borderBottom: '1px solid #725b9029',
        }}>
          <div style={{...smallCaps, fontSize: 15, color: '#82669e', marginBottom: 13}}>0{i + 1}</div>
          {line}
        </div>
      ))}
    </div>
    <div style={{position: 'absolute', left: 1400, bottom: 71, fontSize: 22, color: '#745f88'}}>
      Generic QA example.<br />Not iOS footage.
    </div>
  </AbsoluteFill>
);

const Expanded: React.FC<{feature: Feature; frame: number}> = ({feature, frame}) => {
  if (feature.id === 'build') return <BuildScene feature={feature} frame={frame} />;
  if (feature.id === 'simulator') return <SimulatorScene feature={feature} frame={frame} />;
  if (feature.id === 'fix') return <FixScene feature={feature} frame={frame} />;
  return <EvidenceScene feature={feature} frame={frame} />;
};

const expansion = (feature: Feature, frame: number) => {
  const duration = at(config.transitionSeconds);
  if (frame < at(feature.start)) return 0;
  if (frame < at(feature.collapse)) return easeMove(clamp((frame - at(feature.start)) / duration));
  return 1 - easeMove(clamp((frame - at(feature.collapse)) / duration));
};

const BentoTile: React.FC<{feature: Feature; index: number; frame: number; outcome: boolean}> = ({feature, index, frame, outcome}) => {
  const p = expansion(feature, frame);
  const enter = easeOut(clamp((frame - (8 + index * 7)) / 30));
  const target = feature.rect;
  const width = mix(target.width, W, p);
  const height = mix(target.height, H, p);
  const left = mix(mix(W / 2 - target.width / 2, target.x, enter), 0, p);
  const top = mix(mix(H / 2 - target.height / 2, target.y, enter), 0, p);
  const detailOpacity = interpolate(p, [0.2, 0.66], [0, 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
  const detailScale = Math.min(width / W, height / H);
  return (
    <div style={{
      position: 'absolute', left, top, width, height, zIndex: p > 0 ? 10 : index,
      opacity: enter, transform: `scale(${mix(0.8, 1, enter)})`,
      borderRadius: mix(30, 0, p), overflow: 'hidden', background: feature.color,
      boxShadow: p > 0 ? '0 0 0 1px #19191908' : undefined,
    }}>
      <div style={{
        position: 'absolute', width: target.width, height: target.height,
        opacity: 1 - clamp(p / 0.48),
      }}>
        <TileFace feature={feature} outcome={outcome} />
      </div>
      {p > 0 && (
        <div style={{
          position: 'absolute', left: (width - W * detailScale) / 2,
          top: (height - H * detailScale) / 2,
          width: W, height: H, transformOrigin: 'top left',
          transform: `scale(${detailScale})`, opacity: detailOpacity,
        }}>
          <Expanded feature={feature} frame={frame} />
        </div>
      )}
    </div>
  );
};

const GridHeader: React.FC<{frame: number}> = ({frame}) => {
  const context = frame >= at(config.contextStart) && frame < at(config.features[0].start);
  const workflow = frame >= at(config.features[0].start) && frame < at(config.outcomeStart);
  const outcome = frame >= at(config.outcomeStart);
  const start = outcome ? at(config.outcomeStart) : context ? at(config.contextStart) : 0;
  const progress = start === 0 ? 1 : easeOut(clamp((frame - start) / 18));
  const lines = outcome ? config.outcome : context ? config.context : workflow ? config.workflow : config.hook;
  return (
    <div style={{opacity: progress, transform: `translateY(${mix(18, 0, progress)}px)`}}>
      <div style={{position: 'absolute', left: 96, top: 50, ...smallCaps, fontSize: 19, color: '#5d6662'}}>
        {outcome || workflow ? 'The complete workflow' : context ? 'Before native testing in Devin' : 'Introducing Devin on macOS + iOS'}
      </div>
      <div style={{
        position: 'absolute', left: 90, top: 102, fontSize: 80,
        fontWeight: 500, letterSpacing: -3.6, lineHeight: 1.03,
      }}>{lines.map((line) => <div key={line}>{line}</div>)}</div>
      <div style={{
        position: 'absolute', left: 1316, top: 171, width: 486,
        fontSize: 29, lineHeight: 1.42, letterSpacing: -0.5, color: '#64706a',
      }}>
        {outcome ? config.outcomeDetail : context ? 'Teams tested by hand.\nOr waited for CI feedback.' : 'Build, test, and inspect\nnative Mac and iPhone apps.'}
      </div>
    </div>
  );
};

const EndCard: React.FC<{frame: number}> = ({frame}) => {
  const p = easeOut(clamp((frame - at(config.endStart)) / 24));
  return (
    <AbsoluteFill style={{zIndex: 20, background: '#fcfcfc', opacity: p}}>
      <div style={{
        position: 'absolute', width: '100%', height: '100%',
        transform: `translateY(${mix(20, 0, p)}px)`,
      }}>
        <div style={{position: 'absolute', top: 267, width: '100%', textAlign: 'center', ...smallCaps, textTransform: 'none', fontSize: 25, color: '#6d776f'}}>
          {config.end.platform}
        </div>
        <Img src={staticFile(sources.logoBlack)} style={{
          position: 'absolute', width: 680, height: 'auto', left: 620, top: 371,
          mixBlendMode: 'multiply',
        }} />
        <div style={{position: 'absolute', top: 725, width: '100%', textAlign: 'center', fontSize: 45, letterSpacing: -1.2}}>
          {config.end.cta}
        </div>
      </div>
    </AbsoluteFill>
  );
};

const Launch = () => {
  const frame = useCurrentFrame();
  return (
    <AbsoluteFill style={{
      background: '#fcfcfc', color: brand.ink, fontFamily: brand.displayFont,
      WebkitFontSmoothing: 'antialiased',
    }}>
      <GridHeader frame={frame} />
      {config.features.map((feature, index) => (
        <BentoTile key={feature.id} feature={feature} index={index} frame={frame} outcome={frame >= at(config.outcomeStart)} />
      ))}
      <div style={{
        position: 'absolute', left: 96, bottom: 37, right: 96, display: 'flex',
        justifyContent: 'space-between', fontSize: 18, letterSpacing: 0.3, color: '#788079',
      }}>
        <span>Illustrative workflow · supplied native screenshots</span>
        <span>Devin / macOS + iOS</span>
      </div>
      {frame >= at(config.endStart) && <EndCard frame={frame} />}
    </AbsoluteFill>
  );
};

const Root = () => (
  <Composition id="Launch" component={Launch} width={W} height={H} fps={config.fps} durationInFrames={at(config.durationSeconds)} />
);

registerRoot(Root);
