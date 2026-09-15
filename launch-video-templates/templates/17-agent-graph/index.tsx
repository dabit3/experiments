import React from 'react';
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
import {config} from './config';
import manifest from './template.json';

const C = config.colors;
const mono = brand.monoFont;
const sans = '"Helvetica Neue", Helvetica, Arial, sans-serif';
const clamp = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'} as const;
const easeOut = Easing.out(Easing.cubic);
const easeMove = Easing.inOut(Easing.cubic);
const mix = (a: number, b: number, p: number) => a + (b - a) * p;
const ramp = (f: number, a: number, b: number) =>
  interpolate(f, [a, b], [0, 1], {...clamp, easing: easeOut});

type NativeSource = 'rescue' | 'wisp' | 'onboarding';
const native = {
  rescue: {file: sources.simulator, width: 2978, height: 1626, x: 685, y: 238, w: 574, h: 1181},
  wisp: {file: 'assets/devin-web-10.png', width: 2990, height: 1624, x: 686, y: 237, w: 575, h: 1178},
  onboarding: {file: 'assets/devin-web-11.png', width: 2986, height: 1630, x: 685, y: 239, w: 574, h: 1183},
} as const;

const Phone: React.FC<{source?: NativeSource; width: number}> = ({source = 'rescue', width}) => {
  const image = native[source];
  const scale = width / image.w;
  return (
    <div style={{position: 'relative', width, height: image.h * scale, overflow: 'hidden', borderRadius: width * 0.18, boxShadow: '0 20px 50px #0006'}}>
      <Img src={staticFile(image.file)} style={{position: 'absolute', maxWidth: 'none', width: image.width * scale, height: image.height * scale, left: -image.x * scale, top: -image.y * scale}} />
    </div>
  );
};

const Label: React.FC<{children: React.ReactNode; color?: string; style?: React.CSSProperties}> = ({children, color = C.muted, style}) => (
  <div style={{fontFamily: mono, fontSize: 20, letterSpacing: 1.2, color, ...style}}>{children}</div>
);

const Headline: React.FC<{children: string; size?: number}> = ({children, size = 80}) => (
  <div style={{fontSize: size, fontWeight: 500, lineHeight: 1.06, letterSpacing: -3.3, whiteSpace: 'pre-line'}}>{children}</div>
);

const Background: React.FC = () => (
  <AbsoluteFill style={{backgroundColor: C.background, backgroundImage: 'radial-gradient(#25353f88 1px, transparent 1px)', backgroundSize: '40px 40px'}}>
    <AbsoluteFill style={{background: 'radial-gradient(ellipse at 70% 45%, transparent, #080f16 85%)'}} />
    <div style={{position: 'absolute', top: 56, left: 96, right: 96, height: 58, display: 'flex', justifyContent: 'space-between', alignItems: 'center'}}>
      <Img src={staticFile(sources.logoWhite)} style={{width: 144, height: 'auto'}} />
      <Label>AGENT GRAPH <span style={{color: C.connection, margin: '0 18px'}}> / </span> macOS + iOS</Label>
    </div>
    <div style={{position: 'absolute', top: 142, left: 96, right: 96, height: 1, background: C.border}} />
  </AbsoluteFill>
);

const MiniPath: React.FC<{active?: number; width?: number}> = ({active = -1, width = 980}) => (
  <div style={{display: 'flex', width, alignItems: 'center'}}>
    {config.features.map((step, i) => (
      <React.Fragment key={step.node}>
        {i > 0 && <div style={{height: 1, flex: 1, background: i <= active ? C.connection : C.border}} />}
        <div style={{display: 'flex', alignItems: 'center', gap: 12, padding: '0 16px', color: active === i ? C.accent : i < active ? C.text : C.muted, fontFamily: mono, fontSize: 18}}>
          <span style={{width: 9, height: 9, borderRadius: 9, background: i <= active ? C.accent : C.border}} />
          {step.node}
        </div>
      </React.Fragment>
    ))}
  </div>
);

const Footer: React.FC<{active?: number; label?: string}> = ({active = -1, label = 'ILLUSTRATIVE WORKFLOW'}) => (
  <div style={{position: 'absolute', bottom: 48, left: 96, right: 96, height: 60, borderTop: `1px solid ${C.border}`, display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between'}}>
    <MiniPath active={active} />
    <Label style={{fontSize: 16}}>{label}</Label>
  </div>
);

const Hook: React.FC = () => {
  const f = useCurrentFrame();
  const text = ramp(f, 0, 25);
  const phone = ramp(f, 7, 34);
  return (
    <AbsoluteFill>
      <div style={{position: 'absolute', left: 112, top: 258, width: 1100, opacity: text, transform: `translateY(${mix(24, 0, text)}px)`}}>
        <Label color={C.accent}>{config.hook.eyebrow}</Label>
        <div style={{marginTop: 34}}><Headline size={130}>{config.hook.headline}</Headline></div>
        <div style={{marginTop: 38, color: C.muted, fontSize: 30}}>{config.hook.supporting}</div>
        <div style={{marginTop: 75}}><MiniPath width={1020} /></div>
      </div>
      <div style={{position: 'absolute', left: 1350, top: 184, opacity: phone, transform: `translateY(${mix(40, 0, phone)}px)`}}>
        <Phone width={352} />
        <Label style={{fontSize: 16, textAlign: 'center', marginTop: 23}}>iPHONE SIMULATOR / SOURCE STILL</Label>
      </div>
    </AbsoluteFill>
  );
};

const Context: React.FC = () => {
  const f = useCurrentFrame();
  const enter = ramp(f, 0, 24);
  const line = ramp(f, 24, 62);
  return (
    <AbsoluteFill>
      <div style={{position: 'absolute', left: 112, top: 238, opacity: enter, transform: `translateY(${mix(20, 0, enter)}px)`}}>
        <Label color={C.accent}>BEFORE / THE FEEDBACK GAP</Label>
        <div style={{marginTop: 32}}><Headline size={100}>{config.context.headline}</Headline></div>
        <div style={{display: 'flex', alignItems: 'center', marginTop: 100, gap: 100}}>
          <div style={{width: 430}}>
            <Label>HANDS ON THE DEVICE</Label>
            <div style={{fontSize: 66, marginTop: 30, letterSpacing: -2}}>{config.context.manual}</div>
          </div>
          <svg width="240" height="110"><path d="M0 55 H240" stroke={C.border} strokeWidth="2" /><path d="M0 55 H240" pathLength="1" stroke={C.violet} strokeWidth="3" strokeDasharray="1" strokeDashoffset={1 - line} /></svg>
          <div>
            <div style={{fontFamily: mono, fontSize: 136, letterSpacing: -7, color: C.accent}}>{config.context.wait}</div>
            <div style={{fontSize: 30, color: C.muted, marginTop: 12}}>{config.context.supporting}</div>
          </div>
        </div>
      </div>
      <Footer label="PRIOR CI CONTEXT" />
    </AbsoluteFill>
  );
};

const nodes = [
  {x: 112, y: 398},
  {x: 550, y: 398},
  {x: 988, y: 660},
  {x: 1426, y: 660},
] as const;
const nodeSize = {w: 310, h: 152};
const edges = [
  'M422 474 H550',
  'M860 474 H896 Q922 474 922 500 V710 Q922 736 948 736 H988',
  'M1298 736 H1426',
];

const Graph: React.FC<{active: number; frame: number; opacity: number}> = ({active, frame, opacity}) => {
  const pulse = interpolate(frame, [0, 20], [0, 1], {...clamp, easing: easeMove});
  return (
    <AbsoluteFill style={{opacity}}>
      <div style={{position: 'absolute', top: 228, left: 112}}>
        <Label color={C.accent}>AGENT PLAN / NATIVE APP</Label>
        <div style={{fontSize: 46, marginTop: 20, letterSpacing: -1.2}}>One connected workflow.</div>
      </div>
      <svg width="1920" height="1080" style={{position: 'absolute'}}>
        {edges.map((d, i) => (
          <React.Fragment key={d}>
            <path d={d} fill="none" stroke={i < active ? C.connection : C.border} strokeWidth="3" />
            {i === active - 1 && <path d={d} fill="none" stroke={C.accent} strokeWidth="5" pathLength="1" strokeDasharray=".2 .8" strokeDashoffset={1 - pulse} />}
          </React.Fragment>
        ))}
        <path d="M1143 812 V875 Q1143 897 1119 897 H729 Q705 897 705 873 V550" fill="none" stroke={active === 2 ? C.violet : C.border} strokeWidth="2" strokeDasharray="8 10" />
      </svg>
      <Label style={{position: 'absolute', left: 786, top: 860, fontSize: 18, background: C.background, padding: '10px 20px'}} color={active === 2 ? C.violet : C.muted}>FIX → RETEST</Label>
      {config.features.map((step, i) => (
        <div key={step.node} style={{position: 'absolute', left: nodes[i].x, top: nodes[i].y, width: nodeSize.w, height: nodeSize.h, padding: 26, boxSizing: 'border-box', background: i === active ? '#16362f' : C.surface, border: `1px solid ${i === active ? C.accent : i < active ? C.connection : C.border}`, borderRadius: 14, boxShadow: i === active ? '0 0 45px #0ca67818' : 'none'}}>
          <div style={{display: 'flex', justifyContent: 'space-between'}}><Label color={i === active ? C.accent : C.muted}>0{i + 1}</Label><Label style={{fontSize: 15}} color={i === active ? C.accent : C.muted}>{i === active ? 'ACTIVE' : i < active ? 'VISITED' : 'QUEUED'}</Label></div>
          <div style={{fontFamily: mono, fontSize: 27, marginTop: 14}}>{step.node.toLowerCase()}()</div>
          <div style={{fontFamily: mono, fontSize: 15, color: C.muted, marginTop: 13}}>{step.detail}</div>
        </div>
      ))}
    </AbsoluteFill>
  );
};

const BuildScreen: React.FC<{frame: number}> = ({frame}) => {
  const active = Math.min(2, Math.max(0, Math.floor((frame - 46) / 34)));
  const commands = ['Build with Xcode', 'Open iOS Simulator', 'Run the native app'];
  return (
    <>
      <div style={{position: 'absolute', left: 55, top: 116}}>
        <Label color={C.accent}>ENVIRONMENT</Label>
        <div style={{fontSize: 68, letterSpacing: -2, marginTop: 16}}>macOS</div>
        <Label style={{marginTop: 18}}>Managed Mac VM</Label>
        <div style={{marginTop: 60, width: 595}}>
          {commands.map((command, i) => (
            <div key={command} style={{borderTop: `1px solid ${C.border}`, display: 'flex', alignItems: 'center', gap: 20, padding: '25px 0', fontFamily: mono, color: i === active ? C.accent : C.muted, fontSize: 24}}>
              <span style={{fontSize: 18}}>0{i + 1}</span><span>{command}</span><span style={{marginLeft: 'auto'}}>{i === active ? '←' : '·'}</span>
            </div>
          ))}
        </div>
      </div>
      <div style={{position: 'absolute', left: 734, top: 77}}><Phone width={292} /></div>
    </>
  );
};

const InteractScreen: React.FC<{frame: number}> = ({frame}) => {
  const active = Math.min(2, Math.max(0, Math.floor((frame - 48) / 34)));
  const destinations = [{x: 791, y: 145}, {x: 884, y: 633}, {x: 884, y: 356}];
  const previous = destinations[Math.max(0, active - 1)];
  const destination = destinations[active];
  const progress = interpolate(frame, [48 + active * 34, 64 + active * 34], [0, 1], {...clamp, easing: easeMove});
  return (
    <>
      <div style={{position: 'absolute', left: 58, top: 99}}>
        <Label color={C.muted}>INPUT / NATIVE APP</Label>
        {['tap()', 'type()', 'scroll()'].map((action, i) => (
          <div key={action} style={{fontFamily: mono, fontSize: 66, marginTop: 43, color: i === active ? C.accent : '#566771', letterSpacing: -3}}>{action}</div>
        ))}
        <Label style={{fontSize: 17, marginTop: 49}}>REPRESENTATIVE INPUT CUES</Label>
      </div>
      <div style={{position: 'absolute', left: 734, top: 77}}><Phone source={frame < 76 ? 'onboarding' : 'wisp'} width={292} /></div>
      <div style={{position: 'absolute', left: mix(previous.x, destination.x, progress) - 23, top: mix(previous.y, destination.y, progress) - 23, width: 46, height: 46, border: `3px solid ${C.accent}`, borderRadius: '50%', boxShadow: '0 0 0 9px #0ca67833', opacity: frame > 45 ? 1 : 0}} />
    </>
  );
};

const IterateScreen: React.FC = () => {
  const scale = 544 / 1035;
  return (
    <>
      <div style={{position: 'absolute', left: 64, top: 80}}><Phone source="wisp" width={288} /></div>
      <div style={{position: 'absolute', left: 462, top: 84, width: 544, height: 584, borderRadius: 12, overflow: 'hidden', background: 'white'}}>
        <Img src={staticFile('assets/devin-web-10.png')} style={{position: 'absolute', maxWidth: 'none', width: 2990 * scale, height: 1624 * scale, left: -1955 * scale, top: -140 * scale}} />
      </div>
      <Label style={{position: 'absolute', left: 462, bottom: 17, fontSize: 16}} color={C.muted}>MIXED RESULTS PRESERVED / SOURCE STILL</Label>
    </>
  );
};

const ReviewScreen: React.FC = () => (
  <>
    <Sequence from={config.recording.revealFrame} layout="none">
      <OffthreadVideo
        src={staticFile(config.recording.file)}
        trimBefore={config.recording.startSeconds * config.fps}
        muted
        style={{position: 'absolute', left: 0, top: 56, width: 1080, height: 1080 * 1080 / 1918, objectFit: 'contain'}}
      />
    </Sequence>
    <Label style={{position: 'absolute', left: 30, bottom: 15, fontSize: 18}} color={C.accent}>ACTUAL SOURCE VIDEO · WEB QA</Label>
  </>
);

const Feature: React.FC<{index: number}> = ({index}) => {
  const f = useCurrentFrame();
  const step = config.features[index];
  const motion = config.motion;
  const open = interpolate(f, [motion.graphHoldFrames, motion.zoomEndFrame], [0, 1], {...clamp, easing: easeMove});
  const close = interpolate(f, [motion.returnStartFrame, motion.returnEndFrame], [0, 1], {...clamp, easing: easeMove});
  const zoom = open * (1 - close);
  const content = ramp(f, motion.contentStartFrame, motion.contentEndFrame) * (1 - ramp(f, 155, 166));
  const n = nodes[index];
  const panel = {x: 744, y: 220, w: 1080, h: 716};
  const w = mix(nodeSize.w, panel.w, zoom);
  const h = mix(nodeSize.h, panel.h, zoom);
  return (
    <AbsoluteFill>
      <Graph active={index} frame={f} opacity={1 - zoom} />
      <div style={{position: 'absolute', left: 112, top: index === 0 ? 358 : 300, width: 586, opacity: content, transform: `translateY(${mix(16, 0, content)}px)`}}>
        <Label color={C.accent}>0{index + 1} / {step.node}</Label>
        <div style={{marginTop: 34}}><Headline size={index === 0 ? 67 : 86}>{step.headline}</Headline></div>
        <div style={{marginTop: 34, fontSize: 29, lineHeight: 1.4, maxWidth: 510, color: C.muted}}>{step.supporting}</div>
      </div>
      {zoom > 0 && <div style={{position: 'absolute', left: mix(n.x, panel.x, zoom), top: mix(n.y, panel.y, zoom), width: w, height: h, overflow: 'hidden', background: C.surface, border: `1px solid ${C.connection}`, borderRadius: mix(14, 20, zoom), boxShadow: '0 30px 80px #0005'}}>
        <div style={{position: 'absolute', left: 26, top: 28, fontFamily: mono, fontSize: 27, color: C.accent, opacity: 1 - content}}>0{index + 1} / {step.node.toLowerCase()}()</div>
        <div style={{position: 'absolute', left: 0, top: 0, width: 1080, height: 716, transform: `scale(${w / panel.w})`, transformOrigin: 'top left', opacity: content}}>
          <div style={{height: 55, boxSizing: 'border-box', padding: '18px 24px', borderBottom: `1px solid ${C.border}`, display: 'flex', alignItems: 'center', justifyContent: 'space-between'}}>
            <Label style={{fontSize: 17}}>{step.panelTitle}</Label>
            <div style={{width: 8, height: 8, borderRadius: 8, background: C.accent}} />
          </div>
          {index === 0 && <BuildScreen frame={f} />}
          {index === 1 && <InteractScreen frame={f} />}
          {index === 2 && <IterateScreen />}
          {index === 3 && <ReviewScreen />}
        </div>
      </div>}
      <Footer active={index} label={index === 3 ? 'WEB QA / SUPPLIED RECORDING' : 'ILLUSTRATIVE WORKFLOW'} />
    </AbsoluteFill>
  );
};

const Outcome: React.FC = () => {
  const f = useCurrentFrame();
  const enter = ramp(f, 0, config.motion.entranceFrames);
  const screen = ramp(f, 8, 34);
  return (
    <AbsoluteFill>
      <div style={{position: 'absolute', left: 112, top: 318, width: 580, opacity: enter, transform: `translateY(${mix(20, 0, enter)}px)`}}>
        <Label color={C.accent}>OUTCOME / INSPECTABLE</Label>
        <div style={{marginTop: 32}}><Headline size={72}>{config.outcome.headline}</Headline></div>
        <div style={{fontSize: 29, lineHeight: 1.4, color: C.muted, marginTop: 32, maxWidth: 520}}>{config.outcome.supporting}</div>
        <div style={{marginTop: 55, display: 'inline-block', border: `1px solid ${C.connection}`, borderRadius: 12, padding: '18px 23px', color: C.accent, fontSize: 27}}>{config.outcome.price}</div>
      </div>
      <div style={{position: 'absolute', left: 744, top: 244, width: 1080, opacity: screen, transform: `translateY(${mix(30, 0, screen)}px)`}}>
        <div style={{background: C.surface, border: `1px solid ${C.border}`, borderRadius: 18, overflow: 'hidden'}}>
          <Label style={{padding: '20px 24px', fontSize: 18}}>SESSION / NATIVE APP + REVIEW EVIDENCE</Label>
          <Img src={staticFile(sources.simulator)} style={{width: 1080, height: 'auto', display: 'block'}} />
        </div>
        <Label style={{fontSize: 17, marginTop: 20}}>SUPPLIED NATIVE REVIEW SCREENSHOT</Label>
      </div>
      <Footer active={4} label="macOS + iOS" />
    </AbsoluteFill>
  );
};

const EndCard: React.FC = () => {
  const f = useCurrentFrame();
  const enter = ramp(f, 0, 26);
  return (
    <AbsoluteFill style={{background: C.background, justifyContent: 'center', alignItems: 'center'}}>
      <div style={{position: 'absolute', width: 920, height: 1, top: 286, background: C.border}} />
      <div style={{textAlign: 'center', transform: `translateY(${mix(22, 0, enter)}px)`}}>
        <Img src={staticFile(sources.logoWhite)} style={{width: 586, height: 'auto', display: 'block', margin: '0 auto'}} />
        <Label color={C.accent} style={{fontSize: 30, marginTop: 44, opacity: enter}}>{config.end.platform}</Label>
        <div style={{fontSize: 44, letterSpacing: -1, marginTop: 38, opacity: enter}}>{config.end.cta}</div>
      </div>
      <div style={{position: 'absolute', width: 920, height: 1, bottom: 250, background: C.border}} />
    </AbsoluteFill>
  );
};

const Launch: React.FC = () => (
  <AbsoluteFill style={{fontFamily: sans, color: C.text}}>
    <Background />
    <Sequence from={config.hook.start * config.fps} durationInFrames={config.hook.duration * config.fps}><Hook /></Sequence>
    <Sequence from={config.context.start * config.fps} durationInFrames={config.context.duration * config.fps}><Context /></Sequence>
    {config.features.map((step, index) => <Sequence key={step.node} from={step.start * config.fps} durationInFrames={step.duration * config.fps}><Feature index={index} /></Sequence>)}
    <Sequence from={config.outcome.start * config.fps} durationInFrames={config.outcome.duration * config.fps}><Outcome /></Sequence>
    <Sequence from={config.end.start * config.fps} durationInFrames={config.end.duration * config.fps}><EndCard /></Sequence>
  </AbsoluteFill>
);

const Root: React.FC = () => (
  <Composition id={manifest.compositionId} component={Launch} width={manifest.width} height={manifest.height} fps={manifest.fps} durationInFrames={config.durationSeconds * config.fps} />
);

registerRoot(Root);
