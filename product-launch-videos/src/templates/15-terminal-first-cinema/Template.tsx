import type {CSSProperties, ReactNode} from 'react';
import {AbsoluteFill, Sequence, useCurrentFrame, useVideoConfig} from 'remotion';
import {
  makeTimeline, SourceImage, SourceVideo, type ImageSelection,
  type SceneId, type TemplateProps,
} from '../../shared';
import type {TerminalConfig} from './config';
import {cursorVisible, phase, revealFrames, smooth, splitFrame, typedLength} from './motion';

type SceneProps = TemplateProps<TerminalConfig> & {duration: number};
type ProductId = Exclude<SceneId, 'opening' | 'closing'>;

const geometry = (config: TerminalConfig) => {
  const {margin, captionHeight, grid, gutter} = config.layout;
  return {
    left: margin,
    top: captionHeight,
    width: 1920 - margin * 2,
    height: 1080 - captionHeight - grid.footerHeight - gutter / 2,
    textLeft: margin + grid.indexWidth,
  };
};

const mono = (config: TerminalConfig): CSSProperties => ({
  fontFamily: config.brand.typography.monoFamily,
  fontSize: 19,
  letterSpacing: '0.035em',
  lineHeight: 1.3,
  fontWeight: 400,
});

const body = (config: TerminalConfig): CSSProperties => ({
  fontFamily: config.brand.typography.fontFamily,
  fontSize: config.brand.typography.bodySize,
  lineHeight: config.brand.typography.bodyLineHeight,
  letterSpacing: config.brand.typography.bodyTracking,
  fontWeight: 400,
});

const title = (config: TerminalConfig): CSSProperties => ({
  ...body(config),
  fontSize: config.brand.typography.headingSize,
  lineHeight: config.brand.typography.headingLineHeight,
  letterSpacing: config.brand.typography.headingTracking,
});

const TypedLine = ({
  text, config, frame, duration, style,
}: {
  text: string; config: TerminalConfig; frame: number; duration: number; style?: CSSProperties;
}) => {
  const count = typedLength(text, frame, duration);
  return <div style={{...style, whiteSpace: 'pre-wrap'}}>
    {text.slice(0, count)}
    <span style={{
      display: 'inline-block', width: config.motion.caretWidth, height: '0.82em',
      background: 'currentColor', marginLeft: 12, verticalAlign: '-0.05em',
      opacity: cursorVisible(frame, duration, config.motion.caretBlinkFrames,
        config.motion.blinkDuringHolds) ? 1 : 0,
    }} />
    <span style={{visibility: 'hidden'}}>{text.slice(count)}</span>
  </div>;
};

const Logo = ({config}: TemplateProps<TerminalConfig>) =>
  <SourceImage {...config.media.logo}
    width={config.layout.grid.logoWidth} height={config.layout.grid.logoHeight} />;

const Footer = ({
  config, source, index,
}: TemplateProps<TerminalConfig> & {source: string; index?: number}) => {
  const {margin, grid} = config.layout;
  return <div style={{
    ...mono(config), position: 'absolute', bottom: 0, left: margin, right: margin,
    height: grid.footerHeight, display: 'flex', alignItems: 'center',
    justifyContent: 'space-between', color: config.brand.colors.canvas,
  }}>
    <span style={{opacity: 0.7}}>{source}</span>
    {index !== undefined ? <div style={{display: 'flex', gap: 20}}>
      {[0, 1, 2, 3, 4].map((step) => <span key={step} style={{
        opacity: step === index ? 1 : 0.35,
        borderBottom: step === index ? '2px solid currentColor' : '2px solid transparent',
        paddingBottom: 3,
      }}>{String(step + 1).padStart(2, '0')}</span>)}
    </div> : null}
    <span style={{opacity: 0.7}}>{config.editorial.montage}</span>
  </div>;
};

const Header = ({
  config, index, caption, frame = 0, typing = 0,
}: TemplateProps<TerminalConfig> & {index: number; caption: string; frame?: number; typing?: number}) => {
  const g = geometry(config);
  return <div style={{
    position: 'absolute', top: 0, left: 0, right: 0, height: config.layout.captionHeight,
  }}>
    <div style={{
      ...mono(config), position: 'absolute', top: config.layout.captionHeight - 104, left: g.textLeft,
      color: config.brand.colors.canvas, opacity: 0.62,
    }}>{config.editorial.series} / {config.editorial.sectionNames[index]}</div>
    <div style={{...mono(config), position: 'absolute', left: g.left, top: config.layout.captionHeight - 52, fontSize: 22}}>
      {String(index + 1).padStart(2, '0')}
    </div>
    <TypedLine config={config} text={caption} frame={frame} duration={typing} style={{
      ...body(config), position: 'absolute', left: g.textLeft, top: config.layout.captionHeight - 74,
      maxWidth: g.width - config.layout.grid.logoWidth - config.layout.gutter * 2,
    }} />
    <div style={{position: 'absolute', top: config.layout.captionHeight - 81, right: config.layout.margin}}>
      <Logo config={config} />
    </div>
  </div>;
};

const Baseline = ({
  config, progress, fromBottom = false,
}: TemplateProps<TerminalConfig> & {progress: number; fromBottom?: boolean}) => {
  const g = geometry(config);
  const y = g.top + (fromBottom ? g.height * (1 - progress) : g.height * progress);
  return <div style={{
    position: 'absolute', top: y, left: g.left, width: g.width,
    height: config.motion.baselineThickness, background: config.brand.colors.canvas,
  }}>
    <div style={{
      position: 'absolute', right: 0, bottom: 0,
      width: config.motion.caretWidth, height: 12, background: config.brand.colors.canvas,
    }} />
  </div>;
};

const ImageWindow = ({
  config, selection, progress = 1, children,
}: TemplateProps<TerminalConfig> & {selection: ImageSelection; progress?: number; children?: ReactNode}) => {
  const g = geometry(config);
  return <div style={{
    position: 'absolute', top: g.top, left: g.left, width: g.width, height: g.height,
    clipPath: `inset(0 0 ${(1 - progress) * 100}% 0)`,
    background: config.brand.colors.mediaMat,
  }}>
    <SourceImage {...selection} width={g.width} height={g.height} />
    {children}
  </div>;
};

const Opening = ({config, duration}: SceneProps) => {
  const frame = useCurrentFrame();
  const g = geometry(config);
  const transition = revealFrames(config.motion.baselineRevealFrames, duration);
  const reveal = smooth(phase(frame, duration - transition, transition));
  const typing = revealFrames(config.motion.typingFrames, duration);
  const benefitStart = Math.min(typing + config.motion.lineDelayFrames, duration * 0.4);
  const captionFrame = frame - (duration - transition);
  const opacity = 1 - phase(frame, duration - transition - 4, transition * 0.6);
  const settle = smooth(phase(frame, duration - transition - 12, 12));
  const initialBaseline = config.layout.grid.introTop + config.brand.typography.headingSize +
    config.brand.spacing.titleGap + 98;
  const baselineY = reveal > 0 ? g.top + g.height * reveal :
    initialBaseline + (g.top - initialBaseline) * settle;
  const baselineLeft = g.textLeft + (g.left - g.textLeft) * settle;
  const baselineWidth = (g.width - config.layout.grid.indexWidth * (1 - settle)) *
    smooth(phase(frame, benefitStart + 8, typing));
  return <AbsoluteFill>
    {reveal > 0 ? <>
      <ImageWindow config={config} selection={config.media.environment} progress={reveal} />
      <Header config={config} index={0} caption={config.copy.environment}
        frame={captionFrame} typing={Math.max(0, transition - 5)} />
    </> : null}
    <div style={{
      position: 'absolute', inset: 0, opacity,
      transform: `translateY(${-reveal * config.motion.lineTravel}px)`,
    }}>
      <div style={{...mono(config), position: 'absolute', left: g.textLeft, top: 54}}>
        {config.editorial.series} / {config.copy.featureName}
      </div>
      <div style={{position: 'absolute', right: g.left, top: 44}}><Logo config={config} /></div>
      <div style={{...mono(config), position: 'absolute', top: config.layout.grid.introTop + 32, left: g.left, opacity: 0.6}}>
        00
      </div>
      <TypedLine text={config.copy.opening} config={config} frame={frame + 1} duration={typing}
        style={{...title(config), position: 'absolute', top: config.layout.grid.introTop, left: g.textLeft,
          width: g.width - config.layout.grid.indexWidth}} />
      <div style={{
        ...body(config), position: 'absolute', left: g.textLeft,
        top: config.layout.grid.introTop + config.brand.typography.headingSize + config.brand.spacing.titleGap,
        width: 1320, opacity: phase(frame, benefitStart, 10),
      }}>{config.copy.benefit}</div>
      <div style={{...mono(config), position: 'absolute', left: g.textLeft, bottom: 120, opacity: 0.62}}>
        {config.editorial.openingLabel}
      </div>
    </div>
    <div style={{
      position: 'absolute', left: baselineLeft, top: baselineY, width: baselineWidth,
      height: config.motion.baselineThickness, background: config.brand.colors.canvas,
    }}>
      {settle > 0 ? <div style={{
        position: 'absolute', right: 0, bottom: 0, width: config.motion.caretWidth, height: 12,
        background: config.brand.colors.canvas, opacity: settle,
      }} /> : null}
    </div>
    <Footer config={config} source={config.copy.featureName} />
  </AbsoluteFill>;
};

const Product = ({
  config, duration, id, nextId,
}: SceneProps & {id: ProductId; nextId?: 'agent' | 'webQa'}) => {
  const frame = useCurrentFrame();
  const g = geometry(config);
  const order: ProductId[] = ['environment', 'agent', 'iphone', 'webQa', 'ipad'];
  const index = order.indexOf(id);
  const isVideo = id === 'agent' || id === 'webQa';
  const advance = revealFrames(config.motion.typingFrames, duration);
  const isPreparingNext = nextId !== undefined && frame >= duration - advance;
  const headerIndex = isPreparingNext ? index + 1 : index;
  const caption = config.copy[isPreparingNext && nextId ? nextId : id];
  const headerFrame = isPreparingNext ? frame - duration + advance : frame;
  const typing = isPreparingNext ? advance - 3 :
    (id === 'iphone' || id === 'ipad') ? advance : 0;
  const iphoneSecond = frame >= splitFrame(duration, config.motion.iphoneSplit);
  const selection = id === 'environment' ? config.media.environment :
    id === 'iphone' ? config.media.iphone[iphoneSecond ? 1 : 0] : config.media.ipad;
  const imageSource = id === 'environment' ? 'Hosted macOS · still' :
    `${config.editorial.imageLabel} · ${id === 'iphone' ? (iphoneSecond ? '02' : '01') : '03'}`;
  return <AbsoluteFill>
    <Header config={config} index={headerIndex} caption={caption} frame={headerFrame} typing={typing} />
    {isVideo ? <div style={{
      position: 'absolute', top: g.top, left: g.left, background: config.brand.colors.mediaMat,
    }}>
      <SourceVideo {...config.media[id]} width={g.width} height={g.height}
        durationInFrames={duration}
        labelHeight={48}
        labelStyle={{
          ...mono(config), fontSize: 24, color: config.brand.colors.white,
          background: config.brand.colors.ink, paddingLeft: config.layout.padding,
        }} />
    </div> : <ImageWindow config={config} selection={selection} />}
    <div style={{
      position: 'absolute', left: g.left, top: g.top - config.motion.baselineThickness,
      width: g.width, height: config.motion.baselineThickness, background: config.brand.colors.canvas,
    }} />
    <Footer config={config} index={index} source={isVideo ? config.editorial.videoLabel : imageSource} />
  </AbsoluteFill>;
};

const Closing = ({config, duration}: SceneProps) => {
  const frame = useCurrentFrame();
  const g = geometry(config);
  const resultHold = revealFrames(config.motion.closingResultFrames, duration);
  const collapseFrames = revealFrames(config.motion.baselineRevealFrames, duration);
  const collapse = smooth(phase(frame, resultHold, collapseFrames));
  const textStart = resultHold + collapseFrames;
  const typing = revealFrames(config.motion.typingFrames, duration);
  const textFrame = frame - textStart;
  return <AbsoluteFill>
    {collapse < 1 ? <>
      <Header config={config} index={4} caption={config.copy.ipad} />
      <ImageWindow config={config} selection={config.media.ipad} progress={1 - collapse} />
      <Baseline config={config} progress={collapse} fromBottom />
    </> : null}
    <div style={{opacity: phase(frame, textStart, 8)}}>
      <div style={{...mono(config), position: 'absolute', top: 54, left: g.textLeft, opacity: 0.65}}>
        {config.editorial.series} / {config.editorial.closingLabel}
      </div>
      <div style={{position: 'absolute', top: 44, right: g.left}}><Logo config={config} /></div>
      <div style={{...mono(config), position: 'absolute', top: 310, left: g.left, opacity: 0.65}}>06</div>
      <div style={{...title(config), position: 'absolute', top: 276, left: g.textLeft}}>{config.copy.featureName}</div>
      <TypedLine config={config} text={config.copy.closing} frame={textFrame}
        duration={typing} style={{
          ...body(config), position: 'absolute', left: g.textLeft,
          top: 276 + config.brand.typography.headingSize + config.brand.spacing.titleGap,
          maxWidth: g.width - config.layout.grid.indexWidth,
        }} />
      <div style={{
        position: 'absolute', left: g.textLeft, right: g.left, top: 570,
        height: config.motion.baselineThickness, background: config.brand.colors.canvas,
        transform: `scaleX(${smooth(phase(textFrame, typing, 12))})`, transformOrigin: 'left',
      }} />
      <div style={{
        position: 'absolute', top: 622, left: g.textLeft, right: g.left,
        opacity: phase(textFrame, typing + 5, 8),
      }}>
        <div style={{...body(config), fontSize: config.brand.typography.bodySize + 8}}>{config.copy.cta}</div>
        <div style={{...body(config), marginTop: config.layout.gutter, fontSize: 32, opacity: 0.7}}>
          {config.copy.url}
        </div>
        <div style={{
          position: 'absolute', right: 0, top: 5, width: config.motion.caretWidth * 2,
          height: 50, background: config.brand.colors.canvas,
        }} />
      </div>
    </div>
    <Footer config={config} source={config.copy.featureName} />
  </AbsoluteFill>;
};

export const Template = ({config}: TemplateProps<TerminalConfig>) => {
  const {fps} = useVideoConfig();
  const timeline = makeTimeline(config.durations, fps);
  return <AbsoluteFill style={{
    background: config.brand.colors.ink, color: config.brand.colors.canvas, fontWeight: 400,
  }}>
    {timeline.map((scene) => <Sequence key={scene.id} from={scene.from} durationInFrames={scene.durationInFrames}>
      {scene.id === 'opening' ? <Opening config={config} duration={scene.durationInFrames} /> :
        scene.id === 'closing' ? <Closing config={config} duration={scene.durationInFrames} /> :
          <Product config={config} duration={scene.durationInFrames} id={scene.id}
            nextId={scene.id === 'environment' ? 'agent' : scene.id === 'iphone' ? 'webQa' : undefined} />}
    </Sequence>)}
  </AbsoluteFill>;
};
