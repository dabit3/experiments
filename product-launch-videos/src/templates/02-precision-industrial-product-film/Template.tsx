import type {CSSProperties, ReactNode} from 'react';
import {AbsoluteFill, Sequence, useCurrentFrame, useVideoConfig} from 'remotion';
import {
  assets, easeInOut, makeTimeline, mix, progress, SourceImage, SourceVideo,
  type Crop, type ImageSelection, type SceneTiming, type TemplateProps,
} from '../../shared';
import type {CameraBox, IndustrialConfig} from './config';

type Props = TemplateProps<IndustrialConfig>;

const blendBox = (a: CameraBox, b: CameraBox, p: number): CameraBox => ({
  x: mix(a.x, b.x, p), y: mix(a.y, b.y, p),
  width: mix(a.width, b.width, p), height: mix(a.height, b.height, p),
});

const blendCrop = (a: Crop, b: Crop, p: number): Crop => ({
  x: mix(a.x, b.x, p), y: mix(a.y, b.y, p),
  width: mix(a.width, b.width, p), height: mix(a.height, b.height, p),
});

const fittedBox = (box: CameraBox, aspect: number): CameraBox => {
  const width = Math.min(box.width, box.height * aspect);
  const height = width / aspect;
  return {x: box.x + (box.width - width) / 2, y: box.y + (box.height - height) / 2, width, height};
};

const stageBox = (config: IndustrialConfig): CameraBox => ({
  x: config.layout.margin,
  y: config.layout.margin + config.layout.captionHeight,
  width: 1920 - config.layout.margin * 2,
  height: 1080 - config.layout.margin - config.layout.captionHeight - 48,
});

const Studio = ({config}: Props) => {
  const {colors} = config.brand;
  const light = config.lighting;
  return <AbsoluteFill style={{backgroundColor: colors.canvas}}>
    <AbsoluteFill style={{
      opacity: light.keyStrength,
      background: `radial-gradient(ellipse at ${light.keyX}% ${light.keyY}%, ${colors.white} 0%, transparent 70%)`,
    }} />
    <AbsoluteFill style={{
      opacity: light.falloffStrength,
      background: `linear-gradient(135deg, transparent 30%, ${colors.ink} 150%)`,
    }} />
  </AbsoluteFill>;
};

const Plane = ({config, box, children, tilt = 0}: Props & {
  box: CameraBox;
  children: ReactNode;
  tilt?: number;
}) => {
  const {padding} = config.layout;
  const light = config.lighting;
  return <div style={{
    position: 'absolute', left: box.x - padding, top: box.y - padding,
    width: box.width, height: box.height, padding,
    backgroundColor: config.brand.colors.mediaMat, borderRadius: 2,
    transform: `perspective(${config.motion.perspective}px) rotateY(${tilt}deg)`,
    boxShadow: `0 ${light.shadowDrop}px ${light.shadowBlur}px rgba(25,25,25,${light.shadowOpacity}), 0 1px 2px rgba(25,25,25,0.12)`,
  }}>{children}</div>;
};

const Note = ({config, children}: Props & {children: ReactNode}) =>
  <div style={{
    position: 'absolute', left: config.layout.margin, right: config.layout.margin,
    top: config.layout.grid.noteY, display: 'flex', justifyContent: 'space-between',
    color: config.brand.colors.secondaryInk, fontSize: config.typography.noteSize,
    lineHeight: 1.2,
  }}><span>{children}</span><span>{config.labels.montage}</span></div>;

const Caption = ({config, text}: Props & {text: string}) => <div style={{
  position: 'absolute', left: config.layout.margin, right: config.layout.margin,
  top: config.layout.grid.captionY, display: 'flex', alignItems: 'center',
  justifyContent: 'space-between', gap: config.layout.gutter,
}}>
  <div style={{
    fontSize: config.typography.captionSize, lineHeight: 1.1,
    letterSpacing: config.brand.typography.headingTracking, maxWidth: 1490,
  }}>{text}</div>
  <div style={{flexShrink: 0, fontSize: 22, color: config.brand.colors.secondaryInk}}>
    {config.copy.featureName}
  </div>
</div>;

const Still = ({config, selection, box, tilt = 0}: Props & {
  selection: ImageSelection;
  box: CameraBox;
  tilt?: number;
}) => <Plane config={config} box={box} tilt={tilt}>
  <SourceImage {...selection} width={box.width} height={box.height} />
</Plane>;

const Opening = ({config, scene}: Props & {scene: SceneTiming}) => {
  const frame = useCurrentFrame();
  const motion = config.motion;
  const amount = easeInOut(progress(frame, scene.durationInFrames * motion.detailHoldFraction,
    scene.durationInFrames * Math.max(0.01, motion.pullbackEndFraction - motion.detailHoldFraction)));
  const crop = blendCrop(config.camera.detailCrop, config.camera.contextCrop, amount);
  const box = fittedBox(config.camera.opening, crop.width / crop.height);
  const type = config.brand.typography;
  return <>
    <div style={{position: 'absolute', left: config.layout.margin, top: 62}}>
      <SourceImage {...config.media.logo} width={236} height={82} />
    </div>
    <div style={{
      position: 'absolute', left: config.layout.margin + 12, top: 303,
      width: config.typography.openingTextWidth,
    }}>
      <div style={{
        fontSize: type.headingSize, lineHeight: type.headingLineHeight,
        letterSpacing: type.headingTracking,
      }}>{config.copy.opening}</div>
      <div style={{
        fontSize: type.bodySize, lineHeight: type.bodyLineHeight,
        marginTop: config.brand.spacing.titleGap, maxWidth: 580,
        color: config.brand.colors.secondaryInk,
      }}>{config.copy.benefit}</div>
    </div>
    <Still config={config} box={box}
      selection={{...config.media.environment, framing: {...config.media.environment.framing, crop}}} />
    <Note config={config}>{config.copy.featureName}</Note>
  </>;
};

const Environment = ({config, scene}: Props & {scene: SceneTiming}) => {
  const frame = useCurrentFrame();
  const amount = easeInOut(progress(frame, 0, Math.min(config.motion.settleFrames, scene.durationInFrames / 3)));
  const source = assets[config.media.environment.asset];
  const targetCrop = config.media.environment.framing.crop ??
    {x: 0, y: 0, width: source.width, height: source.height};
  const crop = blendCrop(config.camera.contextCrop, targetCrop, amount);
  const openingBox = fittedBox(config.camera.opening, config.camera.contextCrop.width / config.camera.contextCrop.height);
  const wideBox = fittedBox(stageBox(config), targetCrop.width / targetCrop.height);
  const box = blendBox(openingBox, wideBox, amount);
  const tilt = Math.sin(amount * Math.PI) * config.motion.transitionTiltDegrees;
  return <>
    <Caption config={config} text={config.copy.environment} />
    <Still config={config} box={box} tilt={tilt}
      selection={{...config.media.environment, framing: {...config.media.environment.framing, crop}}} />
    <Note config={config}>{config.labels.environment}</Note>
  </>;
};

const Product = ({config, scene}: Props & {scene: SceneTiming}) => {
  const frame = useCurrentFrame();
  if (scene.id === 'agent' || scene.id === 'webQa') {
    const selection = config.media[scene.id];
    const source = assets[selection.asset];
    const stage = stageBox(config);
    const labelHeight = selection.asset === 'devin-testing-2.mp4' ? 48 : 0;
    const crop = selection.framing.crop ?? source;
    const content = fittedBox({...stage, height: stage.height - labelHeight}, crop.width / crop.height);
    const box = {...content, height: content.height + labelHeight};
    return <>
      <Caption config={config} text={config.copy[scene.id]} />
      <Plane config={config} box={box}>
        <SourceVideo {...selection} width={box.width} height={box.height}
          durationInFrames={scene.durationInFrames}
          labelStyle={{backgroundColor: config.brand.colors.ink, color: config.brand.colors.white}} />
      </Plane>
      <Note config={config}>{config.labels[scene.id]}</Note>
    </>;
  }
  const second = frame >= Math.round(scene.durationInFrames * config.motion.iphoneSplit);
  const selection = scene.id === 'iphone' ? config.media.iphone[second ? 1 : 0] : config.media.ipad;
  const source = selection.framing.crop ?? assets[selection.asset];
  const box = fittedBox(stageBox(config), source.width / source.height);
  const note = scene.id === 'iphone'
    ? config.labels[second ? 'iphoneSecond' : 'iphoneFirst'] : config.labels.ipad;
  return <>
    <Caption config={config} text={config.copy[scene.id]} />
    <Still config={config} selection={selection} box={box} />
    <Note config={config}>{note}</Note>
  </>;
};

const Closing = ({config, scene}: Props & {scene: SceneTiming}) => {
  const frame = useCurrentFrame();
  const selection = config.media.ipad;
  const source = selection.framing.crop ?? assets[selection.asset];
  const aspect = source.width / source.height;
  const travel = Math.min(config.motion.closingTravelFrames, scene.durationInFrames / 3);
  const amount = easeInOut(progress(frame, 0, travel));
  const captionOpacity = progress(frame, travel, Math.min(10, scene.durationInFrames / 8));
  const box = blendBox(fittedBox(stageBox(config), aspect), fittedBox(config.camera.closing, aspect), amount);
  const type = config.typography;
  const heading: CSSProperties = {
    letterSpacing: config.brand.typography.headingTracking,
    lineHeight: 1.08, fontWeight: 400,
  };
  return <>
    <Still config={config} selection={selection} box={box}
      tilt={Math.sin(amount * Math.PI) * -config.motion.transitionTiltDegrees} />
    <div style={{
      position: 'absolute', left: config.layout.margin, top: config.layout.grid.closingHeadingY,
      maxWidth: 1780, fontSize: type.closingSize, ...heading,
    }}>{config.copy.closing}</div>
    <div style={{
      position: 'absolute', left: type.closingTextX, top: type.closingTextY,
      width: type.closingTextWidth, opacity: captionOpacity,
    }}>
      <div style={{fontSize: 24, color: config.brand.colors.secondaryInk, marginBottom: 28}}>
        {config.copy.featureName}
      </div>
      <div style={{fontSize: type.ctaSize, ...heading}}>{config.copy.cta}</div>
      <div style={{
        fontSize: 27, marginTop: 40, paddingBottom: 12,
        borderBottom: `1px solid ${config.brand.colors.secondaryInk}`, display: 'inline-block',
      }}>{config.copy.url}</div>
    </div>
    <div style={{
      position: 'absolute', left: type.closingTextX, top: config.layout.grid.closingLogoY,
      opacity: captionOpacity,
    }}>
      <SourceImage {...config.media.logo} width={236} height={82} />
    </div>
    <Note config={config}>{config.labels.closing}</Note>
  </>;
};

export const Template = ({config}: Props) => {
  const {fps} = useVideoConfig();
  return <AbsoluteFill style={{
    color: config.brand.colors.ink,
    fontFamily: config.brand.typography.fontFamily,
    fontWeight: 400,
    letterSpacing: config.brand.typography.bodyTracking,
    overflow: 'hidden',
  }}>
    <Studio config={config} />
    {makeTimeline(config.durations, fps).map((scene) => <Sequence
      key={scene.id} from={scene.from} durationInFrames={scene.durationInFrames}>
      {scene.id === 'opening' ? <Opening config={config} scene={scene} /> :
        scene.id === 'environment' ? <Environment config={config} scene={scene} /> :
          scene.id === 'closing' ? <Closing config={config} scene={scene} /> :
            <Product config={config} scene={scene} />}
    </Sequence>)}
  </AbsoluteFill>;
};
