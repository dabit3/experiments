import type {CSSProperties, ReactNode} from 'react';
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
import {editorial, type EditorialScene} from './config';
import manifest from './template.json';

const palette = {
  paper: '#f4f1e9',
  ink: brand.ink,
  muted: '#5e625b',
  rule: '#a8aca2',
  sage: '#dee5db',
  blue: brand.blue,
};
const serif = 'Georgia, "Times New Roman", serif';
const sans = '"Helvetica Neue", Helvetica, Arial, sans-serif';
const motion = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'} as const;
const fps = manifest.fps;

const sourceImages = {
  harbor: {file: sources.simulator, width: 2978, height: 1626},
  maze: {file: sources.simulatorGame, width: 2986, height: 1626},
  wisp: {file: 'assets/devin-web-10.png', width: 2990, height: 1624},
} as const;

const SmallCaps = ({children, style}: {children: ReactNode; style?: CSSProperties}) => (
  <div style={{fontFamily: sans, fontSize: 22, fontWeight: 500, letterSpacing: 2.4, lineHeight: 1.3, ...style}}>
    {children}
  </div>
);

const Headline = ({children, size = 104, style}: {children: ReactNode; size?: number; style?: CSSProperties}) => (
  <div style={{fontFamily: serif, fontSize: size, lineHeight: 1.02, letterSpacing: -4.5, whiteSpace: 'pre-line', ...style}}>
    {children}
  </div>
);

const Body = ({children, style}: {children: ReactNode; style?: CSSProperties}) => (
  <div style={{fontSize: 34, lineHeight: 1.35, whiteSpace: 'pre-line', letterSpacing: -0.5, ...style}}>{children}</div>
);

const Caption = ({children, style}: {children: ReactNode; style?: CSSProperties}) => (
  <div style={{fontSize: 22, lineHeight: 1.4, color: palette.muted, ...style}}>{children}</div>
);

const Chrome = ({page, section}: {page: number; section: string}) => (
  <>
    <div style={{position: 'absolute', left: 112, right: 112, top: 52, display: 'flex', justifyContent: 'space-between'}}>
      <SmallCaps>{editorial.issue}</SmallCaps>
      <SmallCaps>{editorial.publication}</SmallCaps>
    </div>
    <div style={{position: 'absolute', left: 112, right: 112, top: 104, height: 1, background: palette.ink}} />
    <div style={{position: 'absolute', left: 112, right: 112, bottom: 66, height: 1, background: palette.rule}} />
    <div style={{position: 'absolute', left: 112, right: 112, bottom: 28, display: 'flex', justifyContent: 'space-between'}}>
      <SmallCaps style={{fontSize: 17, letterSpacing: 2}}>{editorial.footer}</SmallCaps>
      <SmallCaps style={{fontSize: 17}}>{section} / {String(page).padStart(2, '0')}</SmallCaps>
    </div>
  </>
);

const Photo = ({
  image,
  x,
  y,
  width,
  height,
  center,
  cropHeight,
  drift = false,
}: {
  image: keyof typeof sourceImages;
  x: number;
  y: number;
  width: number;
  height: number;
  center: [number, number];
  cropHeight: number;
  drift?: boolean;
}) => {
  const frame = useCurrentFrame();
  const source = sourceImages[image];
  const scale = height / cropHeight;
  const zoom = drift
    ? interpolate(frame, [30, 140], [1, 1.025], {...motion, easing: Easing.inOut(Easing.cubic)})
    : 1;
  return (
    <div style={{position: 'absolute', left: x, top: y, width, height, overflow: 'hidden', background: palette.sage}}>
      <div style={{position: 'absolute', width, height, transform: `scale(${zoom})`}}>
        <Img
          src={staticFile(source.file)}
          style={{
            position: 'absolute',
            width: source.width * scale,
            height: source.height * scale,
            maxWidth: 'none',
            left: width / 2 - center[0] * scale,
            top: height / 2 - center[1] * scale,
          }}
        />
      </div>
    </div>
  );
};

const Cover = ({scene}: {scene: EditorialScene}) => (
  <>
    <SmallCaps style={{position: 'absolute', top: 206, left: 112}}>{scene.section}</SmallCaps>
    <Headline size={142} style={{position: 'absolute', left: 104, top: 291}}>{scene.headline}</Headline>
    <Body style={{position: 'absolute', left: 112, top: 658, fontSize: 40}}>{scene.body}</Body>
    <div style={{position: 'absolute', left: 112, top: 790, width: 114, height: 5, background: palette.blue}} />
    <Caption style={{position: 'absolute', left: 112, top: 829, width: 600}}>The coding agent meets native apps.</Caption>
    <Photo image="harbor" x={1004} y={157} width={804} height={753} center={[970, 827]} cropHeight={1240} drift />
    <Caption style={{position: 'absolute', left: 1004, top: 929}}>{scene.caption}</Caption>
  </>
);

const Context = ({scene}: {scene: EditorialScene}) => (
  <>
    <SmallCaps style={{position: 'absolute', top: 212, left: 112}}>{scene.section}</SmallCaps>
    <Headline size={104} style={{position: 'absolute', left: 106, top: 309, width: 900}}>{scene.headline}</Headline>
    <Body style={{position: 'absolute', left: 112, top: 610, width: 680}}>{scene.body}</Body>
    <div style={{position: 'absolute', left: 1014, top: 205, width: 1, height: 665, background: palette.rule}} />
    <Headline size={284} style={{position: 'absolute', left: 1110, top: 290, letterSpacing: -15}}>{editorial.copy.priorWait}</Headline>
    <SmallCaps style={{position: 'absolute', left: 1120, top: 630, fontSize: 21}}>{editorial.copy.priorWaitUnit}</SmallCaps>
    <Caption style={{position: 'absolute', left: 1120, top: 705, width: 550}}>{scene.caption}</Caption>
    <Caption style={{position: 'absolute', left: 112, top: 896}}>A familiar gap between writing code and seeing it work.</Caption>
  </>
);

const Build = ({scene}: {scene: EditorialScene}) => (
  <>
    <SmallCaps style={{position: 'absolute', top: 225, left: 112}}>{scene.section}</SmallCaps>
    <Headline size={128} style={{position: 'absolute', left: 106, top: 328}}>{scene.headline}</Headline>
    <Body style={{position: 'absolute', left: 112, top: 660, width: 650}}>{scene.body}</Body>
    <SmallCaps style={{position: 'absolute', left: 112, top: 855, fontSize: 18, color: palette.muted}}>XCODE / NATIVE APPS / SIMULATOR</SmallCaps>
    <Photo image="maze" x={816} y={185} width={992} height={743} center={[972, 797]} cropHeight={1314} drift />
    <Caption style={{position: 'absolute', left: 816, top: 945, fontSize: 21}}>{scene.caption}</Caption>
  </>
);

const Gesture = () => {
  const frame = useCurrentFrame();
  const gesture = Math.min(2, Math.max(0, Math.floor((frame - 30) / 36)));
  const pulse = interpolate(frame % 36, [0, 12, 28, 35], [0, 0.7, 0.7, 0], motion);
  const scroll = interpolate(frame, [107, 133], [0, -90], {...motion, easing: Easing.inOut(Easing.cubic)});
  return (
    <>
      <div style={{position: 'absolute', left: 1072, top: 746, display: 'flex', gap: 30}}>
        {editorial.copy.gestures.map((label, index) => (
          <SmallCaps key={label} style={{paddingBottom: 15, borderBottom: `2px solid ${gesture === index ? palette.blue : 'transparent'}`, color: gesture === index ? palette.ink : palette.muted}}>
            {label}
          </SmallCaps>
        ))}
      </div>
      {frame > 30 && (
        <div style={{position: 'absolute', left: 504, top: 797 + (gesture === 2 ? scroll : 0), width: 48, height: 48, border: `3px solid ${palette.blue}`, borderRadius: '50%', opacity: pulse, boxShadow: '0 0 0 9px rgba(25,113,194,0.10)'}} />
      )}
    </>
  );
};

const Interact = ({scene}: {scene: EditorialScene}) => (
  <>
    <Photo image="wisp" x={112} y={172} width={814} height={748} center={[973, 828]} cropHeight={1240} />
    <Caption style={{position: 'absolute', left: 112, top: 940, fontSize: 21}}>{scene.caption}</Caption>
    <SmallCaps style={{position: 'absolute', left: 1072, top: 228}}>{scene.section}</SmallCaps>
    <Headline size={112} style={{position: 'absolute', left: 1067, top: 326}}>{scene.headline}</Headline>
    <Body style={{position: 'absolute', left: 1072, top: 600}}>{scene.body}</Body>
    <Gesture />
    <SmallCaps style={{position: 'absolute', left: 1072, top: 875, fontSize: 18, color: palette.muted}}>{editorial.copy.illustrative}</SmallCaps>
  </>
);

const Iterate = ({scene}: {scene: EditorialScene}) => {
  const frame = useCurrentFrame();
  const progress = Math.min(2, Math.max(0, Math.floor((frame - 30) / 38)));
  return (
    <>
      <SmallCaps style={{position: 'absolute', top: 216, left: 112}}>{scene.section}</SmallCaps>
      <Headline size={112} style={{position: 'absolute', left: 106, top: 311}}>{scene.headline}</Headline>
      <div style={{position: 'absolute', left: 112, top: 754, display: 'flex', gap: 30}}>
        {editorial.copy.loop.map((label, index) => (
          <SmallCaps key={label} style={{fontSize: 20, borderTop: `2px solid ${progress === index ? palette.blue : palette.rule}`, paddingTop: 20, color: progress === index ? palette.ink : palette.muted}}>{label}</SmallCaps>
        ))}
      </div>
      <SmallCaps style={{position: 'absolute', left: 112, top: 882, fontSize: 18, color: palette.muted}}>{editorial.copy.illustrative}</SmallCaps>
      <Photo image="wisp" x={1004} y={178} width={804} height={750} center={[2465, 655]} cropHeight={978} />
      <Caption style={{position: 'absolute', left: 1004, top: 945, fontSize: 21}}>{scene.caption}</Caption>
    </>
  );
};

const Evidence = ({scene}: {scene: EditorialScene}) => (
  <>
    <SmallCaps style={{position: 'absolute', left: 112, top: 237}}>{scene.section}</SmallCaps>
    <Headline size={101} style={{position: 'absolute', left: 106, top: 348}}>{scene.headline}</Headline>
    <Body style={{position: 'absolute', left: 112, top: 627}}>{scene.body}</Body>
    <SmallCaps style={{position: 'absolute', left: 764, top: 230, fontSize: 21}}>{editorial.copy.videoLabel}</SmallCaps>
    <div style={{position: 'absolute', left: 764, top: 283, width: 1044, height: 588, background: brand.white, boxShadow: '0 12px 24px rgba(25,25,25,0.08)'}}>
      <OffthreadVideo
        src={staticFile(sources.testingVideo)}
        muted
        trimBefore={editorial.videoStartSeconds * fps}
        style={{width: '100%', height: '100%', objectFit: 'contain'}}
      />
    </div>
    <Caption style={{position: 'absolute', left: 764, top: 897}}>{scene.caption}</Caption>
  </>
);

const Outcome = ({scene}: {scene: EditorialScene}) => (
  <>
    <Photo image="harbor" x={112} y={165} width={754} height={757} center={[970, 827]} cropHeight={1240} drift />
    <Caption style={{position: 'absolute', left: 112, top: 941, fontSize: 21}}>{scene.caption}</Caption>
    <SmallCaps style={{position: 'absolute', left: 1016, top: 216}}>{scene.section}</SmallCaps>
    <Headline size={104} style={{position: 'absolute', left: 1010, top: 312}}>{scene.headline}</Headline>
    <Body style={{position: 'absolute', left: 1016, top: 601}}>{scene.body}</Body>
    <div style={{position: 'absolute', left: 1016, top: 771, width: 792, height: 1, background: palette.rule}} />
    <Headline size={46} style={{position: 'absolute', left: 1016, top: 812, letterSpacing: -1.5}}>{editorial.copy.price}</Headline>
  </>
);

const End = ({scene}: {scene: EditorialScene}) => (
  <>
    <SmallCaps style={{position: 'absolute', left: 0, right: 0, top: 224, textAlign: 'center'}}>{scene.section}</SmallCaps>
    <Img src={staticFile(sources.logoBlack)} style={{position: 'absolute', width: 700, height: 700 * 1024 / 2984, objectFit: 'contain', left: 610, top: 362}} />
    <SmallCaps style={{position: 'absolute', left: 0, right: 0, top: 663, textAlign: 'center', fontSize: 26}}>{scene.body}</SmallCaps>
    <Headline size={58} style={{position: 'absolute', left: 0, right: 0, top: 790, textAlign: 'center', letterSpacing: -2}}>{scene.headline}</Headline>
  </>
);

const layouts = {cover: Cover, context: Context, build: Build, interact: Interact, iterate: Iterate, evidence: Evidence, outcome: Outcome, end: End};

const Page = ({scene, page}: {scene: EditorialScene; page: number}) => {
  const frame = useCurrentFrame();
  const wipe = page === 1 ? 1 : interpolate(frame, [0, editorial.transitionFrames], [0, 1], {...motion, easing: Easing.inOut(Easing.cubic)});
  const rise = page === 1
    ? interpolate(frame, [0, editorial.entranceFrames], [18, 0], {...motion, easing: Easing.out(Easing.cubic)})
    : 0;
  const Layout = layouts[scene.kind];
  return (
    <AbsoluteFill style={{clipPath: `inset(0 0 0 ${(1 - wipe) * 100}%)`}}>
      <AbsoluteFill style={{background: scene.kind === 'end' ? brand.white : palette.paper, color: palette.ink, fontFamily: sans}}>
        <Chrome page={page} section={scene.section} />
        <AbsoluteFill style={{transform: `translateY(${rise}px)`}}>
          <Layout scene={scene} />
        </AbsoluteFill>
        {wipe < 1 && <div style={{position: 'absolute', left: (1 - wipe) * 1920, top: 0, bottom: 0, width: 54, background: 'linear-gradient(90deg, rgba(25,25,25,0.18), rgba(25,25,25,0.04) 35%, transparent)'}} />}
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

const EditorialLaunch = () => (
  <AbsoluteFill style={{background: palette.paper}}>
    {editorial.scenes.map((scene, index) => (
      <Sequence
        key={scene.kind}
        from={scene.start * fps}
        durationInFrames={(scene.end - scene.start) * fps + (index < editorial.scenes.length - 1 ? editorial.transitionFrames : 0)}
      >
        <Page scene={scene} page={index + 1} />
      </Sequence>
    ))}
  </AbsoluteFill>
);

const Root = () => (
  <Composition
    id={manifest.compositionId}
    component={EditorialLaunch}
    width={manifest.width}
    height={manifest.height}
    fps={manifest.fps}
    durationInFrames={manifest.durationSeconds * manifest.fps}
  />
);

registerRoot(Root);
