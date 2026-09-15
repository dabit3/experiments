import React, {type CSSProperties, type ReactNode} from 'react';
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
import {copy, design, durationSeconds, interactions, media, phoneLayout, scenes, timing} from './config';

const clamp = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'} as const;
const easeOut = Easing.out(Easing.cubic);
const easeMove = Easing.inOut(Easing.cubic);
const at = (left: number, top: number, extra: CSSProperties = {}): CSSProperties => ({
  position: 'absolute', left, top, ...extra,
});
const mono: CSSProperties = {fontFamily: 'Menlo, monospace', fontSize: 19, letterSpacing: 1.5};

function Entrance({children, style, rotate = 0}: {children: ReactNode; style?: CSSProperties; rotate?: number}) {
  const frame = useCurrentFrame();
  const p = interpolate(frame, [0, timing.entranceFrames], [0, 1], {...clamp, easing: easeOut});
  return <div style={{
    ...style,
    opacity: 0.75 + p * 0.25,
    transform: `translate(${(1 - p) * 20}px, ${(1 - p) * 28}px) rotate(${rotate}deg)`,
  }}>{children}</div>;
}

function Paper({children, width, height, style, rotate = 0, animate = true}: {
  children: ReactNode; width: number; height: number; style?: CSSProperties; rotate?: number; animate?: boolean;
}) {
  const paperStyle: CSSProperties = {
    width, height, background: design.paper, border: '1px solid #d8d5cc',
    boxShadow: '0 26px 48px -30px #3d382c66, 0 2px 3px #3d382c16',
    ...style,
  };
  const content = <>
    {children}
    <div style={{position: 'absolute', right: 0, bottom: 0, width: 19, height: 19,
      background: 'linear-gradient(135deg, #f4f1e8 50%, #dedbd3 51%, #e9e7e1 55%)'}} />
  </>;
  return animate
    ? <Entrance style={paperStyle} rotate={rotate}>{content}</Entrance>
    : <div style={{...paperStyle, transform: `rotate(${rotate}deg)`}}>{content}</div>;
}

function Pen({path, delay = 20, color = design.blue, width = 5, style}: {
  path: string; delay?: number; color?: string; width?: number; style?: CSSProperties;
}) {
  const frame = useCurrentFrame();
  const progress = interpolate(frame, [delay, delay + timing.inkFrames], [0, 1], {...clamp, easing: easeMove});
  return <svg width={1920} height={1080} viewBox="0 0 1920 1080"
    style={{position: 'absolute', inset: 0, pointerEvents: 'none', overflow: 'visible', ...style}}>
    <path d={path} fill="none" stroke={color} strokeWidth={width} strokeLinecap="round"
      strokeLinejoin="round" pathLength={1} strokeDasharray={1} strokeDashoffset={1 - progress} />
  </svg>;
}

function Sticky({children, x, y, width = 260, delay = 32, rotate = -3, background = design.highlighter}: {
  children: ReactNode; x: number; y: number; width?: number; delay?: number; rotate?: number; background?: string;
}) {
  const frame = useCurrentFrame();
  const p = interpolate(frame, [delay, delay + timing.noteFrames], [0, 1], {...clamp, easing: easeOut});
  return <div style={at(x, y, {
    width, padding: '18px 24px 22px', background,
    color: design.ink, fontFamily: design.handwriting, fontSize: 32, lineHeight: 1.23,
    whiteSpace: 'pre-line', boxShadow: '0 10px 12px -10px #514a3977',
    opacity: p, transform: `translateY(${(1 - p) * 12}px) rotate(${rotate}deg)`,
    borderTop: '12px solid #ffffff1a',
  })}>{children}</div>;
}

function Crop({src, sourceWidth, rect, width, style}: {
  src: string; sourceWidth: number; rect: readonly [number, number, number, number]; width: number; style?: CSSProperties;
}) {
  const [x, y, w, h] = rect;
  const scale = width / w;
  return <div style={{position: 'relative', width, height: h * scale, overflow: 'hidden', ...style}}>
    <Img src={staticFile(src)} style={{
      position: 'absolute', width: sourceWidth * scale, maxWidth: 'none',
      height: 'auto', left: -x * scale, top: -y * scale,
    }} />
  </div>;
}

function PhonePrint({source = 'charts', x = phoneLayout.x, y = phoneLayout.y, rotate = phoneLayout.angle}: {
  source?: 'charts' | 'game' | 'wisp'; x?: number; y?: number; rotate?: number;
}) {
  const image = media[source];
  return <Paper width={phoneLayout.width} height={phoneLayout.height} rotate={rotate} style={at(x, y)}>
    <div style={at(29, 22, {...mono, fontSize: 15, color: design.muted})}>IPHONE / SIMULATOR</div>
    <Crop src={image.src} sourceWidth={image.width} rect={image.crop} width={phoneLayout.imageWidth}
      style={at(phoneLayout.imageX, phoneLayout.imageY)} />
    <div style={at(30, 805, {...mono, fontSize: 14, color: design.muted})}>SOURCE STILL · NATIVE APP</div>
  </Paper>;
}

function phonePoint(source: 'charts' | 'game' | 'wisp', point: readonly [number, number]) {
  const [cropX, cropY, cropWidth] = media[source].crop;
  const scale = phoneLayout.imageWidth / cropWidth;
  const x = phoneLayout.imageX + (point[0] - cropX) * scale - phoneLayout.width / 2;
  const y = phoneLayout.imageY + (point[1] - cropY) * scale - phoneLayout.height / 2;
  const angle = phoneLayout.angle * Math.PI / 180;
  return {
    x: phoneLayout.x + phoneLayout.width / 2 + x * Math.cos(angle) - y * Math.sin(angle),
    y: phoneLayout.y + phoneLayout.height / 2 + x * Math.sin(angle) + y * Math.cos(angle),
  };
}

function Header({index}: {index: number}) {
  return <>
    <div style={at(92, 59, {...mono, color: design.muted})}>{copy.series}</div>
    <div style={at(1474, 59, {...mono, color: design.muted, fontSize: 17})}>{copy.edition}</div>
    <div style={at(92, 105, {width: 1736, height: 1, background: '#cbc8bf'})} />
    <div style={at(92, 1008, {...mono, color: design.muted, fontSize: 16})}>MACOS + IOS</div>
    <div style={at(1670, 1008, {...mono, color: design.muted, fontSize: 16})}>NOTE {String(index + 1).padStart(2, '0')} / 08</div>
  </>;
}

function Headline({index, width = 830}: {index: number; width?: number}) {
  const scene = scenes[index];
  return <Entrance style={at(96, 221, {width})}>
    <div style={{...mono, color: design.blue, marginBottom: 30}}>{scene.eyebrow}</div>
    <h1 style={{fontSize: index === 6 ? 78 : 98, lineHeight: 1.03, letterSpacing: -3.8,
      fontWeight: 500, whiteSpace: 'pre-line', margin: 0}}>{scene.headline}</h1>
    <p style={{fontSize: 28, lineHeight: 1.45, margin: '34px 0 0', color: design.muted}}>{scene.detail}</p>
  </Entrance>;
}

function SourceNote({children = copy.illustrative}: {children?: ReactNode}) {
  return <div style={at(96, 938, {fontSize: 19, color: design.muted})}>{children}</div>;
}

function Hook() {
  return <>
    <Headline index={0} />
    <div style={at(101, 658, {fontFamily: design.handwriting, color: design.blue, fontSize: 42})}>macOS + iOS</div>
    <Pen path="M 100 710 Q 239 697 379 704" delay={22} color={design.highlighter} width={19} style={{mixBlendMode: 'multiply'}} />
    <div style={at(1100, 164, {width: 535, height: 817, background: '#f4f1e9',
      border: '1px solid #d8d5cc', transform: 'rotate(-3.5deg)'})} />
    <PhonePrint />
    <Sticky x={801} y={694} width={250} delay={30}>{copy.phoneNote}</Sticky>
    <Pen path="M 1060 746 C 1144 749 1140 678 1218 626 M 1195 632 L 1218 626 L 1213 652" delay={34} />
    <Pen path="M 1255 308 C 1309 290 1428 290 1469 317 C 1495 352 1334 371 1268 351 C 1229 339 1238 316 1268 307" delay={51} width={4} />
    <SourceNote />
  </>;
}

function Context() {
  return <>
    <Headline index={1} />
    <Paper width={740} height={615} rotate={1.3} style={at(1004, 241)}>
      <div style={at(54, 44, {...mono, color: design.muted})}>BEFORE / FEEDBACK</div>
      <div style={at(54, 108, {fontSize: 49, fontWeight: 500})}>{copy.manual}</div>
      <div style={at(54, 188, {width: 630, borderTop: '1px dashed #cfcbc0'})} />
      <div style={at(47, 228, {fontSize: 123, fontWeight: 500, letterSpacing: -5})}>{copy.wait}</div>
      <div style={at(56, 386, {fontSize: 30, color: design.muted})}>{copy.waitCaption}</div>
      <div style={at(56, 474, {width: 630, height: 1, background: '#dedbd3'})} />
      <div style={at(56, 510, {fontSize: 20, color: design.muted})}>Your next check is still ahead of you.</div>
    </Paper>
    <Pen path="M 1058 424 Q 1260 408 1410 420" delay={20} color={design.highlighter} width={19} style={{mixBlendMode: 'multiply'}} />
    <Pen path="M 1047 583 C 990 453 1498 454 1550 535 C 1608 655 1053 668 1047 583" delay={33} />
    <Sticky x={1346} y={794} width={363} delay={48}>{copy.contextNote}</Sticky>
    <SourceNote>{copy.priorContext}</SourceNote>
  </>;
}

function Build() {
  return <>
    <Headline index={2} />
    <Paper width={1112} height={651} rotate={0.8} style={at(711, 249)}>
      <div style={at(32, 29, {...mono, fontSize: 16, color: design.muted})}>PRINT 01 / DEVIN SESSION</div>
      <Crop src={media.session.src} sourceWidth={media.session.width}
        rect={[0, 0, 1400, 97]} width={1044} style={at(32, 82)} />
      <Crop src={media.session.src} sourceWidth={media.session.width}
        rect={[572, 801, 1850, 455]} width={1044} style={at(32, 208)} />
      <div style={at(32, 505, {width: 1044, height: 1, background: '#dedbd3'})} />
      <div style={at(32, 544, {fontSize: 24, color: design.muted})}>Build and test native apps in the session.</div>
    </Paper>
    <Sticky x={1419} y={145} width={286} delay={23} background={design.mint}>{copy.managedNote}</Sticky>
    <Pen path="M 1654 249 C 1701 266 1687 295 1626 322 M 1643 298 L 1626 322 L 1654 319" delay={25} />
    <Pen path="M 1528 361 C 1512 322 1628 314 1659 342 C 1692 376 1539 399 1528 361" delay={40} width={4} />
    <Pen path="M 1380 577 Q 1516 575 1654 583" delay={62} color={design.highlighter} width={16} style={{mixBlendMode: 'multiply'}} />
    <Sticky x={1154} y={840} width={328} delay={68}>{copy.buildNote}</Sticky>
    <SourceNote>Source session excerpt · supplied screenshot</SourceNote>
  </>;
}

function Interaction({phase}: {phase: number}) {
  const current = interactions[phase];
  const target = phonePoint(current.source, current.focus);
  return <>
    <PhonePrint source={current.source} />
    <div style={at(99, 665, {display: 'flex', gap: 16})}>
      {interactions.map((item, i) => <div key={item.label} style={{
        width: 154, textAlign: 'center', padding: '14px 0', fontSize: 26,
        border: `1px solid ${i === phase ? design.blue : '#c8c5bc'}`,
        color: i === phase ? design.blue : design.muted,
        background: i === phase ? '#e0eaf3' : 'transparent',
      }}>{item.label}</div>)}
    </div>
    <Sticky x={773} y={759} width={292} delay={12}>{current.note}</Sticky>
    <Pen path={`M 1090 815 C 1180 813 1184 ${target.y} ${target.x - 118} ${target.y}
      M ${target.x - 140} ${target.y - 13} L ${target.x - 118} ${target.y} L ${target.x - 139} ${target.y + 12}`}
      delay={18} width={4} />
    {phase === 2
      ? <Pen path="M 1414 614 C 1451 582 1453 499 1429 446 M 1415 468 L 1429 446 L 1450 465" delay={28} />
      : <Pen path={`M ${target.x - 96} ${target.y - 17}
        C ${target.x - 70} ${target.y - 47} ${target.x + 107} ${target.y - 49} ${target.x + 117} ${target.y - 3}
        C ${target.x + 124} ${target.y + 38} ${target.x - 113} ${target.y + 47} ${target.x - 96} ${target.y - 17}`}
        delay={26} width={4} />}
  </>;
}

function Interact() {
  let start = 0;
  return <>
    <Headline index={3} />
    {interactions.map((phase, index) => {
      const from = start;
      const frames = phase.seconds * timing.fps;
      start += frames;
      return <Sequence key={phase.source} from={from} durationInFrames={frames}>
        <Interaction phase={index} />
      </Sequence>;
    })}
    <SourceNote />
  </>;
}

function Fix() {
  return <>
    <Headline index={4} />
    <Paper width={1090} height={700} rotate={-0.9} style={at(735, 222)}>
      <div style={at(36, 35, {...mono, fontSize: 16, color: design.muted})}>{copy.sourceReport}</div>
      <Crop src={media.wisp.src} sourceWidth={media.wisp.width}
        rect={[1962, 140, 1028, 437]} width={1018} style={at(35, 93)} />
      <div style={at(40, 531, {width: 1010, height: 1, background: '#dad7cd'})} />
      <div style={at(42, 561, {fontSize: 21, color: design.muted, lineHeight: 1.5})}>
        {copy.failureCaveat}<br />The workflow continues with a code change and another check.
      </div>
    </Paper>
    <Pen path="M 1002 360 C 967 297 1188 296 1190 340 C 1204 390 1004 398 1002 360" delay={23} color={design.coral} />
    <Sticky x={1341} y={157} width={316} delay={30}>{copy.failureNote}</Sticky>
    <Pen path="M 1371 252 Q 1272 302 1194 329 M 1214 306 L 1194 329 L 1221 332" delay={38} color={design.coral} width={4} />
    <div style={at(101, 645, {display: 'flex', flexDirection: 'column', gap: 28})}>
      {copy.fixSteps.map((step, i) => <div key={step} style={{
        fontSize: 28, display: 'flex', alignItems: 'center', gap: 20,
      }}>
        <span style={{...mono, fontSize: 18, color: design.blue}}>0{i + 1}</span>{step}
      </div>)}
    </div>
    <Pen path="M 145 685 Q 300 679 420 683" delay={36} color={design.highlighter} width={12} style={{mixBlendMode: 'multiply'}} />
    <Pen path="M 145 746 Q 300 739 403 744" delay={76} color={design.highlighter} width={12} style={{mixBlendMode: 'multiply'}} />
    <Pen path="M 145 808 Q 300 801 426 806" delay={116} color={design.highlighter} width={12} style={{mixBlendMode: 'multiply'}} />
    <SourceNote>Illustrative workflow · original failure state preserved</SourceNote>
  </>;
}

function Evidence() {
  return <>
    <div style={at(96, 221, {width: 550})}>
      <div style={{...mono, color: design.blue, marginBottom: 30}}>{scenes[5].eyebrow}</div>
      <h1 style={{fontSize: 91, lineHeight: 1.03, letterSpacing: -3.8, fontWeight: 500,
        whiteSpace: 'pre-line', margin: 0}}>{scenes[5].headline}</h1>
      <p style={{fontSize: 27, lineHeight: 1.45, marginTop: 34, color: design.muted, width: 430}}>{scenes[5].detail}</p>
    </div>
    <Paper width={1173} height={743} rotate={0} animate={false} style={at(665, 204)}>
      <div style={at(29, 28, {...mono, fontSize: 16, color: design.blue})}>{copy.videoLabel}</div>
      <OffthreadVideo src={staticFile(media.testingVideo)} muted
        trimBefore={media.videoStartSeconds * timing.fps}
        style={at(28, 76, {width: 1117, height: 1117 * 1080 / 1918, objectFit: 'contain'})} />
      <div style={at(29, 714, {fontSize: 15, color: design.muted})}>{copy.videoCaveat}</div>
    </Paper>
    <Sticky x={1513} y={126} width={292} delay={17} background={design.mint}>{copy.evidenceNote}</Sticky>
    <Pen path="M 1778 239 Q 1848 306 1743 516 M 1748 487 L 1743 516 L 1766 499" delay={28} width={4} />
    <div style={at(103, 783, {fontFamily: design.handwriting, fontSize: 33, color: design.blue,
      lineHeight: 1.3})}>Keep the evidence.<br />Review the details.</div>
    <SourceNote>Actual source video · audio muted</SourceNote>
  </>;
}

function Outcome() {
  return <>
    <Headline index={6} width={960} />
    <PhonePrint x={1160} rotate={-1.4} />
    <Sticky x={105} y={660} width={386} delay={25} background={design.mint}>{copy.price}</Sticky>
    <Sticky x={781} y={721} width={316} delay={49}>{copy.outcomeNote}</Sticky>
    <Pen path="M 1121 770 C 1201 770 1194 660 1264 624 M 1240 627 L 1264 624 L 1256 650" delay={57} />
    <Pen path="M 134 794 Q 273 782 420 790" delay={39} color={design.blue} width={4} />
    <SourceNote />
  </>;
}

function End() {
  return <>
    <Paper width={1280} height={735} rotate={-0.5} style={at(320, 190)}>
      <div style={at(76, 59, {...mono, color: design.muted, fontSize: 16})}>THE NEXT CHAPTER OF BUILDING</div>
      <Img src={staticFile(media.logo)} style={at(300, 166, {width: 680, height: 'auto'})} />
      <div style={at(0, 449, {width: 1280, textAlign: 'center', fontSize: 35, color: design.muted})}>
        {scenes[7].detail}
      </div>
      <div style={at(0, 536, {width: 1280, textAlign: 'center', fontSize: 62, fontWeight: 500, letterSpacing: -2})}>
        {scenes[7].headline}
      </div>
    </Paper>
    <Pen path="M 704 819 Q 969 810 1225 816" delay={30} color={design.highlighter} width={17} style={{mixBlendMode: 'multiply'}} />
  </>;
}

const sceneComponents = [Hook, Context, Build, Interact, Fix, Evidence, Outcome, End];

function Launch() {
  let from = 0;
  return <AbsoluteFill style={{
    backgroundColor: design.surface, color: design.ink, fontFamily: design.font,
    backgroundImage: 'radial-gradient(#aaa49719 0.6px, transparent 0.6px)',
    backgroundSize: '7px 7px',
  }}>
    {scenes.map((scene, index) => {
      const start = from;
      const duration = scene.seconds * timing.fps;
      from += duration;
      const Scene = sceneComponents[index];
      return <Sequence key={scene.id} from={start} durationInFrames={duration} name={scene.id}>
        <Header index={index} />
        <Scene />
      </Sequence>;
    })}
  </AbsoluteFill>;
}

const Root = () => <Composition id="Launch" component={Launch}
  durationInFrames={durationSeconds * timing.fps} fps={timing.fps} width={1920} height={1080} />;

registerRoot(Root);
