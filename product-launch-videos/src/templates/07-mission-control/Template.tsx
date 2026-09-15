import type {CSSProperties, ReactNode} from 'react';
import {AbsoluteFill, Sequence, useCurrentFrame, useVideoConfig} from 'remotion';
import {
  SourceImage, SourceVideo, easeInOut, makeTimeline, mix, progress,
  type SceneId, type SceneTiming,
} from '../../shared';
import type {MissionControlConfig} from './config';
import {EnvironmentSelector} from './EnvironmentSelector';

const mono = (config: MissionControlConfig): CSSProperties => ({
  fontFamily: config.brand.typography.monoFamily,
  fontSize: 18,
  letterSpacing: '0.035em',
  lineHeight: 1.2,
});

const Brackets = ({color}: {color: string}) => <AbsoluteFill style={{pointerEvents: 'none'}}>
  {[false, true].flatMap((bottom) => [false, true].map((right) =>
    <div key={`${bottom}-${right}`} style={{
      position: 'absolute', width: 16, height: 16,
      ...(bottom ? {bottom: -6} : {top: -6}),
      ...(right ? {right: -6} : {left: -6}),
      borderColor: color, borderStyle: 'solid',
      borderWidth: `${bottom ? 0 : 2}px ${right ? 2 : 0}px ${bottom ? 2 : 0}px ${right ? 0 : 2}px`,
    }} />,
  ))}
</AbsoluteFill>;

const Bay = ({
  config, index, scene, sceneFrame, frame,
}: {
  config: MissionControlConfig; index: number; scene: SceneId;
  sceneFrame: number; frame: number;
}) => {
  const bay = config.labels.bays[index];
  const active = bay.scenes.includes(scene);
  const enter = easeInOut(progress(
    frame, index * config.motion.bayStaggerFrames, config.motion.baySettleFrames,
  ));
  const emphasis = easeInOut(progress(sceneFrame, 0, config.motion.selectionFrames));
  const inset = 22;
  return <div style={{
    width: config.panels.railWidth, height: config.panels.bayHeight,
    boxSizing: 'border-box', position: 'relative',
    padding: inset, background: active ? config.status.activeFill : config.brand.colors.ink,
    border: `${config.status.outlineWidth}px solid ${active ? config.status.activeBorder : config.status.inactiveBorder}`,
    opacity: enter, transform: `translateX(${mix(config.motion.bayTravel, 0, enter)}px)`,
  }}>
    <div style={{...mono(config), display: 'flex', justifyContent: 'space-between',
      color: config.status.secondaryText}}>
      <span>{bay.number}</span>
      {config.status.showSelectionLabel
        ? <span style={{fontSize: 13, color: active ? config.brand.colors.white : config.status.secondaryText}}>
          {active ? config.labels.selected : config.labels.reference}
        </span> : null}
    </div>
    <div style={{fontSize: 32, letterSpacing: config.brand.typography.headingTracking, marginTop: 20}}>
      {bay.title}
    </div>
    <div style={{fontSize: 24, lineHeight: 1.3, whiteSpace: 'pre-line',
      color: config.status.secondaryText, marginTop: 12}}>
      {bay.detail}
    </div>
    <div style={{position: 'absolute', bottom: inset, left: inset, right: inset,
      fontSize: 18, color: config.status.secondaryText}}>
      {bay.sourceNote}
    </div>
    {active ? <div style={{position: 'absolute', left: -config.layout.gutter - 1,
      top: config.panels.bayHeight / 2, width: config.layout.gutter,
      height: config.status.outlineWidth, background: config.status.activeBorder,
      transform: `scaleX(${emphasis})`, transformOrigin: 'right'}} /> : null}
  </div>;
};

const Bookend = ({
  config, closing, frame, width, height,
}: {
  config: MissionControlConfig; closing: boolean; frame: number; width: number; height: number;
}) => {
  const reveal = easeInOut(progress(frame, 0,
    closing ? config.motion.consolidationFrames : config.motion.apertureFrames));
  const inset = 58;
  const heading = closing ? config.copy.closing : config.copy.opening;
  return <div style={{width, height, position: 'relative', background: config.brand.colors.ink,
    overflow: 'hidden'}}>
    <div style={{position: 'absolute', top: 62, left: inset, right: inset,
      ...mono(config), color: config.status.secondaryText}}>
      {closing ? config.labels.closingNote : config.labels.openingNote}
    </div>
    <div style={{position: 'absolute', top: 154, left: inset, width: closing ? 1370 : 1130,
      clipPath: `inset(0 ${(1 - reveal) * 100}% 0 0)`}}>
      <div style={{
        fontSize: config.brand.typography.headingSize,
        lineHeight: config.brand.typography.headingLineHeight,
        letterSpacing: config.brand.typography.headingTracking,
        maxWidth: closing ? 1370 : 1080,
      }}>{heading}</div>
      <div style={{
        fontSize: config.brand.typography.bodySize * 0.8, lineHeight: 1.25,
        letterSpacing: config.brand.typography.bodyTracking,
        marginTop: config.brand.spacing.titleGap,
        maxWidth: closing ? 1400 : 1020, color: config.status.secondaryText,
      }}>{closing ? config.copy.cta : config.copy.benefit}</div>
    </div>
    <div style={{position: 'absolute', bottom: 60, left: inset, right: inset,
      borderTop: `1px solid ${config.status.inactiveBorder}`, paddingTop: 34,
      display: 'flex', alignItems: 'center', justifyContent: 'space-between'}}>
      <SourceImage {...config.media.logo} width={234} height={70} />
      <div style={{fontSize: 28, color: config.brand.colors.white}}>
        {closing ? config.copy.url : config.copy.featureName}
      </div>
    </div>
  </div>;
};

const Product = ({
  config, scene, width, height,
}: {
  config: MissionControlConfig; scene: SceneTiming; width: number; height: number;
}) => {
  const frame = useCurrentFrame();
  if (scene.id === 'environment') {
    return <EnvironmentSelector config={config} width={width} height={height}
      durationInFrames={scene.durationInFrames} />;
  }
  const selection = scene.id === 'ipad' ? config.media.ipad
    : config.media.iphone[frame < Math.round(scene.durationInFrames * config.motion.iphoneSplitRatio) ? 0 : 1];
  if (scene.id === 'agent' || scene.id === 'webQa') {
    return <SourceVideo
      {...config.media[scene.id]} width={width} height={height}
      durationInFrames={scene.durationInFrames}
      labelStyle={{background: config.brand.colors.ink, color: config.brand.colors.white,
        fontFamily: config.brand.typography.fontFamily, fontSize: 25}}
    />;
  }
  return <SourceImage {...selection} width={width} height={height} />;
};

export const Template = ({config}: {config: MissionControlConfig}) => {
  const frame = useCurrentFrame();
  const {fps, width} = useVideoConfig();
  const timeline = makeTimeline(config.durations, fps);
  const scene = timeline.find((item) => frame >= item.from && frame < item.from + item.durationInFrames)
    ?? timeline[timeline.length - 1];
  const localFrame = frame - scene.from;
  const opening = scene.id === 'opening';
  const closing = scene.id === 'closing';
  const consolidation = closing
    ? easeInOut(progress(localFrame, 0, config.motion.consolidationFrames)) : 0;
  const aperture = opening ? easeInOut(progress(frame, 0, config.motion.apertureFrames)) : 1;
  const displayWidth = mix(
    config.panels.primaryWidth * mix(config.motion.openingWidthRatio, 1, aperture),
    width - config.layout.margin * 2,
    consolidation,
  );
  const productWidth = config.panels.primaryWidth - config.layout.padding * 2;
  const productHeight = config.panels.displayHeight - config.panels.headerHeight - config.layout.padding * 2;
  const caption = opening || closing ? config.copy.featureName : config.copy[scene.id];
  const letterStyle: CSSProperties = {
    fontFamily: config.brand.typography.fontFamily, fontWeight: 400,
    color: config.brand.colors.white,
  };
  const content: ReactNode = opening || closing
    ? <Bookend config={config} closing={closing} frame={localFrame}
      width={displayWidth - config.layout.padding * 2} height={productHeight} />
    : <Sequence from={scene.from} durationInFrames={scene.durationInFrames} layout="none">
      <Product config={config} scene={scene} width={productWidth} height={productHeight} />
    </Sequence>;
  return <AbsoluteFill style={{...letterStyle, background: config.brand.colors.ink}}>
    <div style={{position: 'absolute', left: config.layout.margin, top: 22,
      right: config.layout.margin, display: 'flex', alignItems: 'center',
      justifyContent: 'space-between', height: 34}}>
      <SourceImage {...config.media.logo} width={config.panels.logoWidth} height={34} />
      <div style={{...mono(config), color: config.status.secondaryText}}>{config.labels.edition}</div>
    </div>
    <div style={{
      position: 'absolute', left: config.layout.margin, top: config.layout.grid.captionTop,
      width: config.panels.primaryWidth, height: config.layout.captionHeight,
      fontSize: config.brand.typography.bodySize, lineHeight: config.brand.typography.bodyLineHeight,
      letterSpacing: config.brand.typography.bodyTracking,
    }}>{caption}</div>
    <div style={{
      position: 'absolute', left: config.layout.margin + config.panels.primaryWidth + config.layout.gutter,
      top: config.panels.displayTop, width: config.panels.railWidth,
      opacity: 1 - consolidation,
      transform: `translateX(${consolidation * config.motion.bayTravel}px)`,
    }}>
      <div style={{...mono(config), height: config.panels.headerHeight,
        display: 'flex', alignItems: 'center', color: config.status.secondaryText}}>
        {config.labels.index}
      </div>
      <div style={{display: 'flex', flexDirection: 'column', gap: config.panels.bayGap}}>
        {config.labels.bays.map((bay, index) => <Bay key={bay.number}
          config={config} index={index} scene={scene.id} sceneFrame={localFrame} frame={frame} />)}
      </div>
      <div style={{fontSize: 21, lineHeight: 1.25, marginTop: 22, maxWidth: 245,
        color: config.status.secondaryText}}>{config.labels.separateExamples}</div>
    </div>
    <div style={{
      position: 'absolute', left: config.layout.margin, top: config.panels.displayTop,
      width: displayWidth, height: config.panels.displayHeight, boxSizing: 'border-box',
      border: `1px solid ${config.status.inactiveBorder}`, background: config.brand.colors.ink,
    }}>
      <Brackets color={config.status.activeBorder} />
      <div style={{
        height: config.panels.headerHeight, padding: '0 16px',
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        ...mono(config), color: config.status.secondaryText,
        borderBottom: `1px solid ${config.status.inactiveBorder}`, boxSizing: 'border-box',
      }}>
        <span>{config.labels.primary}</span>
        <span>{config.labels.sceneSources[scene.id]}</span>
      </div>
      <div style={{position: 'absolute', left: config.layout.padding,
        top: config.panels.headerHeight + config.layout.padding,
        background: opening || closing ? config.brand.colors.ink : config.brand.colors.mediaMat,
        width: displayWidth - config.layout.padding * 2, height: productHeight,
        overflow: 'hidden'}}>
        {content}
      </div>
    </div>
    <div style={{position: 'absolute', left: config.layout.margin,
      top: config.layout.grid.footerTop, right: config.layout.margin,
      display: 'flex', justifyContent: 'space-between', ...mono(config),
      color: config.status.secondaryText, fontSize: 16}}>
      <span>{config.copy.featureName}</span>
      <span>{config.labels.separateExamples}</span>
    </div>
  </AbsoluteFill>;
};
