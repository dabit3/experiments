import type {CSSProperties, ReactNode} from 'react';
import {AbsoluteFill, Sequence, useCurrentFrame, useVideoConfig} from 'remotion';
import {
  SourceImage, SourceVideo, easeInOut, makeTimeline, mix, progress,
  type SceneId, type SceneTiming,
} from '../../shared';
import type {GalleryConfig} from './config';

type SceneProps = {config: GalleryConfig; scene: SceneTiming};
type ProductSceneId = Exclude<SceneId, 'opening' | 'closing'>;

const exhibitFor = (id: ProductSceneId): 0 | 1 | 2 =>
  id === 'environment' || id === 'agent' ? 0 : id === 'iphone' ? 1 : 2;

const captionStyle = (config: GalleryConfig): CSSProperties => ({
  fontFamily: config.brand.typography.fontFamily,
  fontWeight: 400,
  letterSpacing: config.brand.typography.bodyTracking,
  lineHeight: config.brand.typography.bodyLineHeight,
});

const Wall = ({config, offset = 0}: {config: GalleryConfig; offset?: number}) => {
  const {colors} = config.brand;
  return <AbsoluteFill style={{background: colors.canvas}}>
    <AbsoluteFill style={{
      background: `radial-gradient(ellipse at 62% 14%, ${colors.white}, transparent 70%)`,
      opacity: config.gallery.lightOpacity,
    }} />
    <div style={{
      position: 'absolute', top: 0, bottom: 0, left: 174 + offset,
      width: 1, background: config.gallery.seamColor,
    }} />
    <div style={{
      position: 'absolute', top: config.gallery.floorY, left: 0, right: 0,
      borderTop: `1px solid ${config.gallery.seamColor}`, height: 80,
      background: `linear-gradient(180deg, ${colors.mediaMat}, ${colors.canvas})`,
      opacity: 0.5,
    }} />
  </AbsoluteFill>;
};

const Colophon = ({config}: {config: GalleryConfig}) => <div style={{
  position: 'absolute', left: config.layout.margin, right: config.layout.margin,
  bottom: 14, display: 'flex', justifyContent: 'space-between',
  ...captionStyle(config), fontSize: 19, color: config.brand.colors.secondaryInk,
}}>
  <span>{config.copy.featureName}</span>
  <span>{config.exhibition.note}</span>
</div>;

const Display = ({
  config, children, scale = 1, x = 0, y = 0,
}: {
  config: GalleryConfig; children: ReactNode; scale?: number; x?: number; y?: number;
}) => {
  const {gallery: g, layout, brand} = config;
  return <div style={{
    position: 'absolute',
    left: g.displayX, top: g.displayY,
    width: g.displayWidth, height: g.displayHeight,
    transform: `translate(${x}px, ${y}px) scale(${scale})`,
    transformOrigin: '50% 50%',
    padding: layout.padding,
    boxSizing: 'border-box',
    background: brand.colors.mediaMat,
    boxShadow: `0 14px 28px rgba(25,25,25,${g.shadowOpacity}), 0 1px 0 ${brand.colors.white}`,
  }}>{children}</div>;
};

const ExhibitLabel = ({
  config, index, detail,
}: {config: GalleryConfig; index: 0 | 1 | 2; detail: string}) => {
  const exhibit = config.exhibition.exhibits[index];
  const {gallery: g, brand, layout} = config;
  return <div style={{
    position: 'absolute', top: g.displayY, left: layout.margin,
    width: g.railWidth, ...captionStyle(config), whiteSpace: 'pre-line',
  }}>
    <div style={{
      fontSize: g.indexSize, lineHeight: 1,
      letterSpacing: brand.typography.headingTracking, marginBottom: 30,
    }}>{exhibit.number}</div>
    <div style={{width: 30, height: 2, background: brand.colors.ink, marginBottom: 25}} />
    <div style={{fontSize: g.labelSize, lineHeight: 1.12}}>{exhibit.title}</div>
    <div style={{fontSize: 20, lineHeight: 1.35, marginTop: 22, color: brand.colors.secondaryInk}}>
      {exhibit.medium}
    </div>
    <div style={{
      fontSize: 19, lineHeight: 1.4, marginTop: 36,
      paddingTop: 14, borderTop: `1px solid ${g.seamColor}`,
      color: brand.colors.secondaryInk, overflowWrap: 'break-word',
    }}>{detail}</div>
  </div>;
};

const ProductScene = ({config, scene}: SceneProps & {scene: SceneTiming & {id: ProductSceneId}}) => {
  const f = useCurrentFrame();
  const {gallery: g, motion, layout, exhibition} = config;
  const index = exhibitFor(scene.id);
  const exhibit = exhibition.exhibits[index];
  const isRecording = scene.id === 'agent' || scene.id === 'webQa';
  const arrivalFrames = Math.min(motion.approachFrames, scene.durationInFrames * 0.2);
  const arrival = isRecording ? 1 : easeInOut(progress(f, 0, arrivalFrames));
  const departure = scene.id === 'iphone'
    ? easeInOut(progress(f, scene.durationInFrames - motion.exitFrames, motion.exitFrames))
    : 0;
  const scale = mix(motion.arrivalScale, 1, arrival);
  const x = (1 - arrival) * motion.lateralTravel - departure * motion.lateralTravel + exhibit.cameraX;
  const width = g.displayWidth - layout.padding * 2;
  const height = g.displayHeight - layout.padding * 2;
  const iphoneIndex = f < Math.round(scene.durationInFrames * motion.iphoneSplit) ? 0 : 1;
  const detail = scene.id === 'environment' ? exhibition.environmentLabel
    : scene.id === 'agent' ? exhibition.agentLabel
      : scene.id === 'iphone' ? exhibition.iphoneLabels[iphoneIndex]
        : scene.id === 'webQa' ? exhibition.webQaLabel : exhibition.ipadLabel;
  let media: ReactNode;
  if (scene.id === 'agent' || scene.id === 'webQa') {
    media = <SourceVideo
      {...config.media[scene.id]}
      width={width} height={height} durationInFrames={scene.durationInFrames}
      labelHeight={48}
      labelStyle={{
        background: config.brand.colors.mediaMat, color: config.brand.colors.ink,
        fontFamily: config.brand.typography.fontFamily,
        fontSize: 28, letterSpacing: config.brand.typography.bodyTracking,
      }}
    />;
  } else {
    const selection = scene.id === 'iphone'
      ? config.media.iphone[iphoneIndex] : config.media[scene.id];
    media = <SourceImage {...selection} width={width} height={height} />;
  }
  return <AbsoluteFill>
    <Wall config={config} offset={(1 - arrival - departure) * motion.wallTravel} />
    <div style={{
      position: 'absolute', left: g.displayX, right: layout.margin,
      top: g.displayY - (layout.captionHeight + g.captionSize * 1.1) / 2,
      fontSize: g.captionSize, lineHeight: 1.1,
      letterSpacing: config.brand.typography.headingTracking,
    }}>{config.copy[scene.id]}</div>
    <ExhibitLabel config={config} index={index} detail={detail} />
    <Display config={config} scale={scale} x={x} y={exhibit.cameraY}>{media}</Display>
    <Colophon config={config} />
  </AbsoluteFill>;
};

const Opening = ({config, scene}: SceneProps) => {
  const f = useCurrentFrame();
  const reveal = easeInOut(progress(f, 0, Math.min(config.motion.titleRevealFrames, scene.durationInFrames * 0.2)));
  const {brand, gallery: g, layout} = config;
  return <AbsoluteFill>
    <Wall config={config} offset={mix(50, 0, reveal)} />
    <div style={{position: 'absolute', top: 58, left: g.displayX}}>
      <SourceImage {...config.media.logo} width={184} height={68} />
    </div>
    <div style={{
      position: 'absolute', right: layout.margin, top: 77,
      fontSize: 24, color: brand.colors.secondaryInk,
    }}>{config.exhibition.title}</div>
    <div style={{
      position: 'absolute', left: g.displayX, top: 300,
      width: 1370, opacity: mix(0.3, 1, reveal),
      clipPath: `inset(0 ${mix(9, 0, reveal)}% 0 0)`,
    }}>
      <div style={{
        fontSize: brand.typography.headingSize * 1.3,
        lineHeight: brand.typography.headingLineHeight,
        letterSpacing: brand.typography.headingTracking,
        maxWidth: 1180, textWrap: 'balance',
      }}>{config.copy.opening}</div>
      <div style={{
        fontSize: brand.typography.bodySize * 1.22,
        lineHeight: brand.typography.bodyLineHeight,
        letterSpacing: brand.typography.bodyTracking,
        color: brand.colors.secondaryInk, marginTop: brand.spacing.titleGap,
        maxWidth: 1080,
      }}>{config.copy.benefit}</div>
    </div>
    <div style={{
      position: 'absolute', left: g.displayX, right: layout.margin, top: 827,
      display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: layout.gutter,
    }}>
      {config.exhibition.exhibits.map((exhibit) => <div key={exhibit.number} style={{
        borderTop: `1px solid ${g.seamColor}`, paddingTop: 22,
        display: 'flex', gap: 28, alignItems: 'baseline',
      }}>
        <span style={{fontSize: 22, color: brand.colors.secondaryInk}}>{exhibit.number}</span>
        <span style={{fontSize: 32, whiteSpace: 'pre-line'}}>{exhibit.title.replace('\n', ' ')}</span>
      </div>)}
    </div>
    <Colophon config={config} />
  </AbsoluteFill>;
};

const Closing = ({config}: {config: GalleryConfig}) => {
  const f = useCurrentFrame();
  const {brand, gallery: g, layout} = config;
  const reveal = easeInOut(progress(f, 0, config.motion.titleRevealFrames));
  return <AbsoluteFill>
    <Wall config={config} />
    <div style={{position: 'absolute', left: g.displayX, top: 100}}>
      <SourceImage {...config.media.logo} width={210} height={80} />
    </div>
    <div style={{
      position: 'absolute', left: g.displayX, right: layout.margin, top: 322,
      opacity: mix(0.55, 1, reveal),
    }}>
      <div style={{
        fontSize: brand.typography.headingSize,
        lineHeight: brand.typography.headingLineHeight * 1.06,
        letterSpacing: brand.typography.headingTracking,
        maxWidth: 1360, textWrap: 'balance',
      }}>{config.copy.closing}</div>
      <div style={{
        marginTop: 58, paddingTop: 28,
        borderTop: `1px solid ${g.seamColor}`, maxWidth: 1360,
        display: 'flex', gap: layout.gutter, alignItems: 'baseline',
      }}>
        <div style={{
          fontSize: brand.typography.bodySize * 1.2,
          letterSpacing: brand.typography.bodyTracking, flex: 1,
        }}>{config.copy.cta}</div>
        <div style={{fontSize: 30, whiteSpace: 'nowrap'}}>{config.copy.url}</div>
      </div>
    </div>
    <div style={{
      position: 'absolute', left: g.displayX, bottom: 154,
      fontSize: 24, color: brand.colors.secondaryInk,
    }}>{config.copy.featureName}</div>
    <Colophon config={config} />
  </AbsoluteFill>;
};

export const Template = ({config}: {config: GalleryConfig}) => {
  const {fps} = useVideoConfig();
  const timeline = makeTimeline(config.durations, fps);
  return <AbsoluteFill style={{
    ...captionStyle(config), color: config.brand.colors.ink,
    background: config.brand.colors.canvas,
  }}>
    {timeline.map((scene) => <Sequence
      key={scene.id} from={scene.from} durationInFrames={scene.durationInFrames}
    >
      {scene.id === 'opening' ? <Opening config={config} scene={scene} />
        : scene.id === 'closing' ? <Closing config={config} />
          : <ProductScene config={config} scene={{...scene, id: scene.id}} />}
    </Sequence>)}
  </AbsoluteFill>;
};
