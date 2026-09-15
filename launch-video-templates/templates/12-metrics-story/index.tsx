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
import {story, type Scene} from './config';
import manifest from './template.json';

const palette = {
  paper: brand.paper,
  ink: brand.ink,
  blue: brand.blue,
  muted: '#666e74',
  line: '#d8dee2',
  wash: '#edf3f7',
};

const clamped = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'} as const;
const out = Easing.out(Easing.cubic);
const move = Easing.inOut(Easing.cubic);

const enter = (frame: number) =>
  interpolate(frame, [0, story.motion.entranceFrames], [0, 1], {
    ...clamped,
    easing: out,
  });

const progress = (frame: number, start: number = story.motion.chartStart, duration: number = story.motion.chartFrames) =>
  interpolate(frame, [start, start + duration], [0, 1], {...clamped, easing: move});

const Small: React.FC<React.PropsWithChildren<{style?: React.CSSProperties}>> = ({
  children,
  style,
}) => (
  <div style={{fontSize: 20, fontWeight: 500, letterSpacing: 2, ...style}}>
    {children}
  </div>
);

const Crop: React.FC<{
  src: string;
  x: number;
  y: number;
  width: number;
  height: number;
  displayWidth: number;
  radius?: number;
}> = ({src, x, y, width, height, displayWidth, radius = 0}) => {
  const scale = displayWidth / width;
  return (
    <div style={{
      position: 'relative',
      width: displayWidth,
      height: height * scale,
      overflow: 'hidden',
      borderRadius: radius,
      flexShrink: 0,
    }}>
      <Img src={staticFile(src)} style={{
        position: 'absolute',
        width: 1568 * scale,
        height: 'auto',
        maxWidth: 'none',
        left: -x * scale,
        top: -y * scale,
      }} />
    </div>
  );
};

const Phone: React.FC<{src: string; width?: number}> = ({src, width = 328}) => (
  <div style={{filter: 'drop-shadow(0 20px 20px rgba(25,25,25,0.17))'}}>
    <Crop src={src} x={358} y={122} width={306} height={626} displayWidth={width} radius={width * 0.19} />
  </div>
);

const Header: React.FC<{dark: boolean}> = ({dark}) => (
  <>
    <div style={{position: 'absolute', left: 96, right: 96, top: 60, display: 'flex', alignItems: 'center', justifyContent: 'space-between'}}>
      <div style={{display: 'flex', alignItems: 'center', gap: 22}}>
        <Img src={staticFile(dark ? sources.markWhite : sources.markBlack)} style={{width: 36, height: 42, objectFit: 'contain'}} />
        <Small>{story.header}</Small>
      </div>
      <Small style={{color: dark ? '#b8c1c8' : palette.muted}}>{story.footer}</Small>
    </div>
    <div style={{position: 'absolute', left: 96, right: 96, top: 127, height: 1, background: dark ? '#3d454c' : palette.line}} />
  </>
);

const Footer: React.FC<{label: string; dark: boolean}> = ({label, dark}) => (
  <div style={{position: 'absolute', left: 96, right: 96, bottom: 48, display: 'flex', justifyContent: 'space-between', color: dark ? '#b8c1c8' : palette.muted}}>
    <Small style={{fontSize: 17}}>{label}</Small>
    <Small style={{fontSize: 17, letterSpacing: 1}}>METRICS STORY</Small>
  </div>
);

const Metric: React.FC<{scene: Scene; frame: number; dark?: boolean}> = ({scene, frame, dark = false}) => {
  const p = enter(frame);
  return (
    <div style={{position: 'absolute', left: 96, top: 174, width: 822}}>
      <div style={{
        fontSize: scene.key === 'context' ? 244 : 250,
        lineHeight: 0.92,
        fontWeight: 500,
        letterSpacing: -15,
        fontVariantNumeric: 'tabular-nums',
        color: dark ? '#fcfcfc' : palette.ink,
        clipPath: `inset(${(1 - p) * 100}% 0 0 0)`,
        transform: `translateY(${(1 - p) * story.motion.entranceDistance}px)`,
      }}>
        {scene.number}
      </div>
      <div style={{fontSize: 29, marginTop: 20, color: dark ? '#b7c3cb' : palette.muted}}>
        {scene.unit}
      </div>
    </div>
  );
};

const Copy: React.FC<{scene: Scene; frame: number; dark?: boolean}> = ({scene, frame, dark = false}) => (
  <div style={{
    position: 'absolute',
    left: 96,
    top: 493,
    width: 832,
    transform: `translateY(${(1 - enter(frame)) * story.motion.entranceDistance}px)`,
    opacity: 0.4 + 0.6 * enter(frame),
  }}>
    <div style={{fontSize: scene.key === 'interact' ? 75 : 78, fontWeight: 500, lineHeight: 1.04, letterSpacing: -3.6, whiteSpace: 'pre-line'}}>
      {scene.headline}
    </div>
    <div style={{marginTop: 28, fontSize: 27, lineHeight: 1.4, color: dark ? '#b7c3cb' : palette.muted}}>
      {scene.detail}
    </div>
  </div>
);

const FlowChart: React.FC<{frame: number; active: number; dark?: boolean}> = ({frame, active, dark = false}) => {
  const p = progress(frame);
  const positions = [24, 267, 510, 753];
  const foreground = dark ? '#8abcec' : palette.blue;
  return (
    <div style={{position: 'absolute', left: 96, top: 820, width: 800}}>
      <Small style={{fontSize: 17, color: dark ? '#b7c3cb' : palette.muted, letterSpacing: 1}}>
        WORKFLOW PROGRESS · NOT ELAPSED TIME
      </Small>
      <svg width="790" height="72" viewBox="0 0 790 72" style={{overflow: 'visible', marginTop: 16}}>
        <path d="M24 40 L267 40 L510 40 L753 40" fill="none" stroke={dark ? '#48545d' : palette.line} strokeWidth="3" />
        <path d="M24 40 L267 40 L510 40 L753 40" fill="none" stroke={foreground} strokeWidth="4" strokeLinecap="round" pathLength="1" strokeDasharray="1" strokeDashoffset={1 - p * ((active + 1) / 4)} />
        {positions.map((x, i) => (
          <g key={x}>
            <circle cx={x} cy={40} r={i === active ? 12 : 7} fill={i <= active ? foreground : dark ? '#252d33' : palette.paper} stroke={i <= active ? foreground : dark ? '#667681' : '#bec7ce'} strokeWidth="2" />
            {i === active ? <circle cx={x} cy={40} r={4} fill={dark ? '#191f24' : '#fcfcfc'} /> : null}
          </g>
        ))}
      </svg>
      <div style={{display: 'flex', justifyContent: 'space-between', fontSize: 20, color: dark ? '#b7c3cb' : palette.muted}}>
        {story.steps.map((step, i) => (
          <span key={step} style={{color: i === active ? foreground : undefined, fontWeight: i === active ? 600 : 400}}>{step}</span>
        ))}
      </div>
    </div>
  );
};

const NativePanel: React.FC<{src: string; title: string; caption?: string}> = ({src, title, caption = story.illustrative}) => (
  <div style={{position: 'absolute', left: 998, top: 166, width: 826, height: 784, background: palette.wash, borderRadius: 28, border: `1px solid ${palette.line}`}}>
    <div style={{position: 'absolute', left: 32, right: 32, top: 25, display: 'flex', justifyContent: 'space-between', alignItems: 'center'}}>
      <Small style={{fontSize: 18, letterSpacing: 1}}>{title}</Small>
      <span style={{display: 'flex', gap: 9, alignItems: 'center', fontSize: 18, color: palette.blue}}>
        <span style={{width: 8, height: 8, background: palette.blue, borderRadius: '50%'}} /> iOS Simulator
      </span>
    </div>
    <div style={{position: 'absolute', left: 252, top: 72}}>
      <Phone src={src} width={322} />
    </div>
    <div style={{position: 'absolute', bottom: 22, left: 32, right: 32, color: palette.muted, fontSize: 17, textAlign: 'center'}}>
      {caption}
    </div>
  </div>
);

const ContextPanel: React.FC<{frame: number}> = ({frame}) => {
  const p = progress(frame);
  return (
    <div style={{position: 'absolute', left: 998, top: 166, width: 826, height: 784, borderRadius: 28, border: `1px solid ${palette.line}`, background: '#f4f5f6', padding: '40px 38px', boxSizing: 'border-box'}}>
      <Small style={{color: palette.muted}}>PRIOR TEAM WORKFLOW</Small>
      <div style={{position: 'relative', marginTop: 85, paddingBottom: 56, borderBottom: `1px solid ${palette.line}`}}>
        <div style={{fontSize: 29, marginBottom: 18}}>CI feedback wait</div>
        <div style={{width: '100%', height: 80, background: '#e4e7e9', borderRadius: 6}}>
          <div style={{width: `${p * 100}%`, height: '100%', background: palette.blue, borderRadius: 6}} />
        </div>
        <div style={{fontSize: 36, fontVariantNumeric: 'tabular-nums', marginTop: 18}}>20+ min</div>
      </div>
      <div style={{fontSize: 29, marginTop: 48, color: palette.muted}}>The alternative</div>
      <div style={{fontSize: 48, marginTop: 16, letterSpacing: -1.5}}>Test it by hand.</div>
      <div style={{position: 'absolute', left: 38, bottom: 38, right: 38, fontSize: 20, color: palette.muted, lineHeight: 1.4}}>
        Context from the launch brief.<br />No measured speedup is shown.
      </div>
    </div>
  );
};

const BuildPanel: React.FC<{frame: number}> = ({frame}) => (
  <div style={{position: 'absolute', left: 998, top: 166, width: 826, height: 784, background: palette.wash, borderRadius: 28, border: `1px solid ${palette.line}`}}>
    <div style={{position: 'absolute', left: 32, top: 28, fontSize: 22, color: palette.blue}}>Managed Mac VM</div>
    <div style={{position: 'absolute', left: 30, top: 95, width: 364, height: 555, background: palette.paper, border: `1px solid ${palette.line}`, borderRadius: 18, padding: 28, boxSizing: 'border-box'}}>
      <Small style={{fontSize: 15, color: palette.muted}}>REPRESENTATIVE SESSION</Small>
      <div style={{fontSize: 31, marginTop: 36, lineHeight: 1.15, letterSpacing: -1}}>Build and run<br />the native app.</div>
      <div style={{marginTop: 44, fontFamily: story.mono, fontSize: 19, lineHeight: 2.4}}>
        <div style={{color: palette.blue}}>› xcodebuild</div>
        <div style={{color: palette.muted}}>Compile</div>
        <div style={{color: palette.muted}}>Launch Simulator</div>
        <div style={{color: palette.ink}}>Open the app</div>
      </div>
      <div style={{marginTop: 36, height: 5, background: palette.line, borderRadius: 4}}>
        <div style={{width: `${progress(frame) * 100}%`, height: '100%', borderRadius: 4, background: palette.blue}} />
      </div>
      <div style={{fontSize: 16, color: palette.muted, marginTop: 12}}>Workflow progress</div>
    </div>
    <div style={{position: 'absolute', left: 446, top: 69}}><Phone src={story.media.nativeHome} width={303} /></div>
    <div style={{position: 'absolute', left: 32, right: 32, bottom: 30, fontSize: 17, textAlign: 'center', color: palette.muted}}>{story.illustrative}</div>
  </div>
);

const InteractionGraph: React.FC<{frame: number}> = ({frame}) => (
  <div style={{position: 'absolute', left: 96, top: 815, width: 800}}>
    <Small style={{fontSize: 17, color: palette.muted, letterSpacing: 1}}>WORKFLOW PROGRESS · NOT ELAPSED TIME</Small>
    <svg width="792" height="93" viewBox="0 0 792 93" style={{marginTop: 12}}>
      <path d="M0 73H792 M0 46H792 M0 19H792" stroke="#e3e8ec" strokeWidth="1" />
      <path d="M16 73H220 Q245 73 268 47 H487 Q512 47 536 19 H776" fill="none" stroke={palette.blue} strokeWidth="4" strokeLinecap="round" pathLength="1" strokeDasharray="1" strokeDashoffset={1 - progress(frame, 28, 94)} />
    </svg>
    <div style={{display: 'flex', justifyContent: 'space-between', fontSize: 21, color: palette.blue, padding: '0 12px'}}><span>Tap</span><span>Type</span><span>Scroll</span></div>
  </div>
);

const FixPanel: React.FC = () => (
  <div style={{position: 'absolute', left: 998, top: 166, width: 826, height: 784, background: '#252d33', borderRadius: 28, border: '1px solid #48545d'}}>
    <div style={{position: 'absolute', left: 32, right: 32, top: 28, fontSize: 22, color: '#b7c3cb'}}>Inspect the failure. Continue the loop.</div>
    <div style={{position: 'absolute', left: 50, top: 96}}><Phone src={story.media.nativeChat} width={286} /></div>
    <div style={{position: 'absolute', left: 370, right: 28, top: 142, background: '#fcfcfc', borderRadius: 18, overflow: 'hidden', color: palette.ink}}>
      <div style={{fontSize: 18, padding: '22px 20px', borderBottom: `1px solid ${palette.line}`, color: palette.blue}}>SUPPLIED TEST EVIDENCE</div>
      <div style={{padding: '26px 22px', fontSize: 30, lineHeight: 1.25, letterSpacing: -0.6}}>
        “Failed key persistence and model metadata checks.”
      </div>
      <div style={{padding: '0 22px 26px', fontSize: 20, lineHeight: 1.5, color: palette.muted}}>
        Wisp Simulator checks<br />Source has mixed results.
      </div>
    </div>
    <div style={{position: 'absolute', left: 32, right: 32, bottom: 28, fontSize: 17, color: '#b7c3cb', textAlign: 'center'}}>{story.illustrative}</div>
  </div>
);

const ReviewPanel: React.FC = () => (
  <div style={{position: 'absolute', left: 922, top: 210, width: 902}}>
    <div style={{display: 'flex', justifyContent: 'space-between', fontSize: 20, color: palette.muted, marginBottom: 20}}>
      <span style={{color: palette.blue}}>RECORDED EVIDENCE</span>
      <span>Source recording · web QA</span>
    </div>
    <div style={{background: '#fff', borderRadius: 22, overflow: 'hidden', border: `1px solid ${palette.line}`, boxShadow: '0 24px 64px rgba(25,25,25,0.09)'}}>
      <OffthreadVideo
        src={staticFile(story.media.testing)}
        trimBefore={story.media.testingStartSeconds * manifest.fps}
        muted
        style={{display: 'block', width: '100%', aspectRatio: '1918 / 1080', objectFit: 'contain'}}
      />
    </div>
    <div style={{display: 'flex', alignItems: 'center', gap: 18, marginTop: 28, fontSize: 23}}>
      <span style={{width: 34, height: 34, background: palette.wash, border: `1px solid ${palette.line}`, borderRadius: '50%', display: 'grid', placeItems: 'center', fontSize: 14, color: palette.blue}}>▶</span>
      <span>Watch the action. Read the checks.</span>
    </div>
    <div style={{fontSize: 19, marginTop: 18, color: palette.muted}}>Generic web testing example · not iOS footage</div>
  </div>
);

const PriceChart: React.FC<{frame: number; dark?: boolean}> = ({frame, dark = false}) => (
  <div style={{position: 'absolute', left: 96, top: 805, width: 792}}>
    <Small style={{fontSize: 17, color: dark ? '#b7c3cb' : palette.muted, letterSpacing: 1}}>SAME PRICE</Small>
    {['Linux VMs', 'Mac VMs'].map((label) => (
      <div key={label} style={{display: 'flex', alignItems: 'center', gap: 24, marginTop: 22}}>
        <div style={{width: 126, fontSize: 21, color: dark ? '#b7c3cb' : palette.muted}}>{label}</div>
        <div style={{width: 570, height: 21, borderRadius: 3, background: dark ? '#39434a' : '#e3e8ec'}}>
          <div style={{width: `${progress(frame) * 100}%`, height: '100%', borderRadius: 3, background: dark ? '#8abcec' : palette.blue}} />
        </div>
      </div>
    ))}
  </div>
);

const EndCard: React.FC<{frame: number; scene: Scene}> = ({frame, scene}) => (
  <>
    <div style={{position: 'absolute', left: 100, top: 177, display: 'flex', alignItems: 'center', gap: 24}}>
      <div style={{fontSize: 116, lineHeight: 1, fontVariantNumeric: 'tabular-nums', letterSpacing: -6}}>{scene.number}</div>
      <div style={{fontSize: 24, color: '#b7c3cb', lineHeight: 1.4}}>{scene.unit}<br />{scene.detail}</div>
    </div>
    <div style={{position: 'absolute', left: 506, top: 356, width: 908, transform: `translateY(${(1 - enter(frame)) * 28}px)`, opacity: 0.6 + enter(frame) * 0.4}}>
      <Img src={staticFile(sources.logoWhite)} style={{display: 'block', width: '100%', height: 'auto'}} />
    </div>
    <div style={{position: 'absolute', top: 733, left: 0, right: 0, textAlign: 'center'}}>
      <div style={{fontSize: 30, color: '#b7c3cb', letterSpacing: 2}}>macOS + iOS</div>
      <div style={{marginTop: 32, fontSize: 62, fontWeight: 400, letterSpacing: -2}}>{scene.headline}</div>
    </div>
    <div style={{position: 'absolute', left: 772, top: 931, width: 376, height: 3, background: '#39434a'}}>
      <div style={{width: `${progress(frame) * 100}%`, height: 3, background: '#8abcec'}} />
    </div>
  </>
);

const SceneView: React.FC<{scene: Scene}> = ({scene}) => {
  const frame = useCurrentFrame();
  const dark = scene.key === 'fix' || scene.key === 'end';
  return (
    <AbsoluteFill style={{background: dark ? '#191f24' : palette.paper, color: dark ? palette.paper : palette.ink, fontFamily: story.font}}>
      <Header dark={dark} />
      <Footer label={scene.label} dark={dark} />
      {scene.key === 'end' ? <EndCard frame={frame} scene={scene} /> : <>
        <Metric scene={scene} frame={frame} dark={dark} />
        <Copy scene={scene} frame={frame} dark={dark} />
        {scene.key === 'hook' ? <>
          <NativePanel src={story.media.nativeChat} title="INSIDE YOUR DEVIN SESSION" />
          <div style={{position: 'absolute', left: 96, top: 846, width: 740, fontSize: 25, color: palette.blue, borderTop: `3px solid ${palette.blue}`, paddingTop: 25}}>
            Managed Mac VMs. Native iPhone workflows.
          </div>
        </> : null}
        {scene.key === 'context' ? <ContextPanel frame={frame} /> : null}
        {scene.key === 'build' ? <><BuildPanel frame={frame} /><FlowChart frame={frame} active={0} /></> : null}
        {scene.key === 'interact' ? <><NativePanel src={story.media.nativeChat} title="NATIVE INTERACTION" /><InteractionGraph frame={frame} /></> : null}
        {scene.key === 'fix' ? <><FixPanel /><FlowChart frame={frame} active={2} dark /></> : null}
        {scene.key === 'review' ? <><ReviewPanel /><FlowChart frame={frame} active={3} /></> : null}
        {scene.key === 'outcome' ? <>
          <NativePanel src={story.media.nativeReview} title="INSPECT THE WORKING APP" caption="Supplied native app screenshot" />
          <PriceChart frame={frame} />
        </> : null}
      </>}
    </AbsoluteFill>
  );
};

const Launch: React.FC = () => (
  <AbsoluteFill>
    {story.scenes.map((scene, index) => {
      const from = story.scenes.slice(0, index).reduce((sum, item) => sum + item.seconds * manifest.fps, 0);
      return (
        <Sequence key={scene.key} from={from} durationInFrames={scene.seconds * manifest.fps}>
          <SceneView scene={scene} />
        </Sequence>
      );
    })}
  </AbsoluteFill>
);

const Root: React.FC = () => (
  <Composition id="Launch" component={Launch} width={manifest.width} height={manifest.height} fps={manifest.fps} durationInFrames={manifest.durationSeconds * manifest.fps} />
);

registerRoot(Root);
