import type {CSSProperties, ReactNode} from 'react';
import {AbsoluteFill, Sequence, useCurrentFrame, useVideoConfig} from 'remotion';
import {SourceImage, SourceVideo, type SceneTiming} from '../../shared';
import type {PureProductConfig} from './config';
import {editTimeline, environmentFraming, iphoneSplit} from './edit';

type Props = {config: PureProductConfig};

const Title = ({config, closing = false}: Props & {closing?: boolean}) => {
  const {copy, brand, titleLayout} = config;
  const {inset, logoWidth, headingTop, headingWidth, urlGap} = titleLayout;
  return <AbsoluteFill>
    <div style={{position: 'absolute', top: inset, left: inset}}>
      <SourceImage {...config.media.logo} width={logoWidth} height={logoWidth / 2.914} />
    </div>
    <div style={{
      position: 'absolute', top: inset + 24, right: inset,
      fontSize: config.typography.noteSize, color: brand.colors.secondaryInk,
    }}>{copy.featureName}</div>
    <div style={{position: 'absolute', left: inset, top: headingTop, width: headingWidth}}>
      <div style={{
        fontSize: brand.typography.headingSize,
        lineHeight: brand.typography.headingLineHeight,
        letterSpacing: brand.typography.headingTracking,
        textWrap: 'balance',
      }}>{closing ? copy.closing : copy.opening}</div>
      <div style={{
        marginTop: brand.spacing.titleGap * 1.5,
        fontSize: closing ? config.typography.ctaSize : brand.typography.bodySize,
        lineHeight: brand.typography.bodyLineHeight,
        letterSpacing: brand.typography.bodyTracking,
      }}>{closing ? copy.cta : copy.benefit}</div>
      {closing ? <div style={{
        marginTop: urlGap, fontSize: brand.typography.bodySize,
        color: brand.colors.secondaryInk,
      }}>{copy.url}</div> : null}
    </div>
    {!closing ? <div style={{
      position: 'absolute', left: inset, bottom: inset,
      fontSize: config.typography.noteSize, color: brand.colors.secondaryInk,
    }}>{config.labels.montage}</div> : null}
  </AbsoluteFill>;
};

const ProductView = ({config, caption, note, recording = false, children}: Props & {
  caption: string;
  note: string;
  recording?: boolean;
  children: (box: {width: number; height: number}) => ReactNode;
}) => {
  const {width, height} = useVideoConfig();
  const {layout, typography, brand} = config;
  const captionX = layout.grid.captionInset ?? layout.margin;
  const footer = layout.grid.footerHeight ?? 48;
  const viewport = {
    width: width - 2 * layout.margin,
    height: height - layout.captionHeight - footer - layout.padding,
  };
  const smallText: CSSProperties = {
    fontSize: typography.noteSize,
    lineHeight: 1.2,
    color: brand.colors.secondaryInk,
    letterSpacing: brand.typography.bodyTracking,
  };
  if (viewport.width <= 0 || viewport.height <= 0) {
    throw new Error('The caption, footer and margins must leave a positive product viewport.');
  }
  return <AbsoluteFill>
    <div style={{
      position: 'absolute', top: 0, height: layout.captionHeight,
      left: captionX, right: captionX, display: 'flex', alignItems: 'center',
      fontSize: typography.captionSize, lineHeight: 1.15,
      letterSpacing: brand.typography.headingTracking,
    }}>{caption}</div>
    <div style={{
      position: 'absolute', left: layout.margin, top: layout.captionHeight,
      width: viewport.width, height: viewport.height,
    }}>{children(viewport)}</div>
    <div style={{
      ...smallText, position: 'absolute', bottom: 0, height: footer,
      left: captionX, right: captionX, display: 'flex',
      gap: layout.gutter, justifyContent: 'space-between', alignItems: 'center',
    }}>
      <span>{note}</span>
      <span>{recording ? `${config.labels.speed} 1×` : config.labels.montage}</span>
    </div>
  </AbsoluteFill>;
};

const ProductScene = ({config, scene}: Props & {scene: SceneTiming}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const {id, durationInFrames} = scene;
  if (id === 'opening' || id === 'closing') {
    return <Title config={config} closing={id === 'closing'} />;
  }
  if (id === 'environment') {
    return <ProductView config={config} caption={config.copy.environment} note={config.labels.environment}>
      {(box) => <SourceImage {...config.media.environment} {...box}
        framing={environmentFraming(config, frame, durationInFrames, fps)} />}
    </ProductView>;
  }
  if (id === 'agent' || id === 'webQa') {
    return <ProductView config={config} caption={config.copy[id]} note={config.labels[id]} recording>
      {(box) => <SourceVideo {...config.media[id]} {...box}
        durationInFrames={durationInFrames}
        labelHeight={config.layout.grid.webQaLabelHeight ?? 44}
        labelStyle={{
          backgroundColor: config.brand.colors.canvas,
          color: config.brand.colors.ink,
          fontFamily: config.brand.typography.fontFamily,
          fontSize: config.typography.noteSize,
          padding: 0,
          justifyContent: 'center',
        }} />}
    </ProductView>;
  }
  if (id === 'iphone') {
    const second = frame >= iphoneSplit(durationInFrames, config.motion.iphoneFirstFraction);
    const index = second ? 1 : 0;
    return <ProductView config={config} caption={config.copy.iphone} note={config.labels.iphone[index]}>
      {(box) => <SourceImage {...config.media.iphone[index]} {...box} />}
    </ProductView>;
  }
  return <ProductView config={config} caption={config.copy.ipad} note={config.labels.ipad}>
    {(box) => <SourceImage {...config.media.ipad} {...box} />}
  </ProductView>;
};

export const Template = ({config}: Props) => {
  const {fps} = useVideoConfig();
  return <AbsoluteFill style={{
    backgroundColor: config.brand.colors.canvas,
    color: config.brand.colors.ink,
    fontFamily: config.brand.typography.fontFamily,
    fontWeight: 400,
  }}>
    {editTimeline(config, fps).map((scene) => <Sequence key={scene.id}
      from={scene.from} durationInFrames={scene.durationInFrames}>
      <ProductScene config={config} scene={scene} />
    </Sequence>)}
  </AbsoluteFill>;
};
