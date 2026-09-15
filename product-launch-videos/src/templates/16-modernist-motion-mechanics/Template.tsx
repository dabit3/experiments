import type {CSSProperties, ReactNode} from 'react';
import {AbsoluteFill, Sequence, useCurrentFrame, useVideoConfig} from 'remotion';
import {
  easeInOut, makeTimeline, mix, progress, SourceImage, SourceVideo,
  type SceneId, type SceneTiming,
} from '../../shared';
import type {ModernistConfig} from './config';

type Props = {config: ModernistConfig};
type SceneProps = Props & {scene: SceneTiming};

const Rect = ({style, children}: {style: CSSProperties; children?: ReactNode}) =>
  <div style={{position: 'absolute', boxSizing: 'border-box', ...style}}>{children}</div>;

const layoutFor = (config: ModernistConfig, width: number, height: number) => {
  const {margin, gutter, captionHeight, grid} = config.layout;
  const x = margin + grid.railWidth + gutter;
  const y = margin + captionHeight;
  return {x, y, width: width - x - margin, height: height - y - margin - grid.footerHeight};
};

const Logo = ({config, width}: Props & {width: number}) =>
  <SourceImage {...config.media.logo} width={width} height={width * 0.26} />;

const heading = (config: ModernistConfig): CSSProperties => ({
  fontWeight: 400,
  fontFamily: config.brand.typography.fontFamily,
  lineHeight: config.brand.typography.headingLineHeight,
  letterSpacing: config.brand.typography.headingTracking,
});

const StageTiles = ({config, active, frame, intro = false}: Props & {
  active: number; frame: number; intro?: boolean;
}) => {
  const {colors, typography} = config.brand;
  const {showTiles, tileSize} = config.geometry;
  const settle = easeInOut(progress(frame, 0, config.motion.revealFrames));
  if (!showTiles) return null;
  return <div style={{display: 'flex', gap: intro ? config.layout.gutter : 24, alignItems: 'center'}}>
    {config.labels.stages.map((label, index) => {
      const selected = active === index;
      return <div key={index} style={{
        display: 'flex', alignItems: 'center', gap: 12,
        transform: intro ? `translateY(${(1 - settle) * config.motion.tileTravel * (index % 2 ? -1 : 1)}px)` : undefined,
      }}>
        <div style={{
          width: intro ? tileSize : 10, height: intro ? tileSize : 10,
          background: selected || intro ? colors.ink : colors.mediaMat,
          color: colors.white, display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontFamily: typography.monoFamily, fontSize: config.composition.labelSize,
        }}>{intro ? String(index + 1).padStart(2, '0') : null}</div>
        <div style={{
          fontSize: config.composition.labelSize,
          color: selected || intro ? colors.ink : colors.secondaryInk,
        }}>{label}</div>
      </div>;
    })}
  </div>;
};

const Opening = ({config, scene}: SceneProps) => {
  const frame = useCurrentFrame();
  const {width, height} = useVideoConfig();
  const {colors, typography, spacing} = config.brand;
  const {margin, padding} = config.layout;
  const c = config.composition;
  const assembleFrames = Math.min(config.motion.openingAssembleFrames, scene.durationInFrames / 3);
  const assembled = easeInOut(progress(frame, 0, assembleFrames));
  const travel = (1 - assembled) * config.motion.transitionDistance;
  const cut = c.openingShapeHeight * 0.28;
  const frameMode = config.geometry.rectangleRole === 'frame';
  return <AbsoluteFill>
    <Rect style={{left: margin, top: margin}}><Logo config={config} width={c.logoWidth} /></Rect>
    <Rect style={{right: margin, top: margin, fontSize: c.labelSize}}>{config.copy.featureName}</Rect>
    <Rect style={{
      left: margin, top: 266, width: c.openingTitleWidth,
      fontSize: c.titleSize, ...heading(config),
    }}>{config.copy.opening}</Rect>
    <Rect style={{
      left: margin, top: 614, width: 850,
      fontSize: typography.bodySize + 6, lineHeight: typography.bodyLineHeight,
      letterSpacing: typography.bodyTracking,
    }}>{config.copy.benefit}</Rect>
    <Rect style={{
      left: c.openingShapeX + travel, top: c.openingShapeY,
      width: c.openingShapeWidth, height: cut, background: colors.ink,
    }} />
    <Rect style={{
      left: c.openingShapeX, top: c.openingShapeY + cut + padding + travel,
      width: c.openingShapeWidth, height: c.openingShapeHeight - cut - padding,
      background: colors.ink,
    }}>
      <Rect style={{
        left: padding, right: padding, top: padding, bottom: padding,
        background: colors.canvas,
        clipPath: frameMode ? `inset(0 ${(1 - assembled) * 100}% 0 0)` : undefined,
      }}>
        <div style={{
          height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}><Logo config={config} width={c.openingShapeWidth * 0.53} /></div>
      </Rect>
    </Rect>
    <Rect style={{
      left: c.openingShapeX, top: c.openingShapeY + c.openingShapeHeight + spacing.titleGap,
      width: c.openingShapeWidth * assembled, height: config.geometry.lineThickness,
      background: colors.ink,
    }} />
    <Rect style={{left: margin, bottom: 130, width: width - margin * 2}}>
      <StageTiles config={config} frame={frame} active={-1} intro />
    </Rect>
    <Rect style={{
      left: margin, top: height - margin, color: colors.secondaryInk, fontSize: c.labelSize,
    }}>{config.labels.montage}</Rect>
  </AbsoluteFill>;
};

const Reveal = ({config, frame, duration}: Props & {frame: number; duration: number}) => {
  const {revealFrames, revealAxis} = config.motion;
  const p = easeInOut(progress(frame, 0, Math.min(revealFrames, duration / 4)));
  const remaining = (1 - p) * 50;
  if (p >= 1) return null;
  const horizontal = revealAxis === 'x';
  return <>
    <Rect style={{
      background: config.brand.colors.mediaMat,
      left: 0, top: 0, width: horizontal ? `${remaining}%` : '100%',
      height: horizontal ? '100%' : `${remaining}%`,
    }} />
    <Rect style={{
      background: config.brand.colors.mediaMat,
      right: 0, bottom: 0, width: horizontal ? `${remaining}%` : '100%',
      height: horizontal ? '100%' : `${remaining}%`,
    }} />
  </>;
};

const Product = ({config, scene}: SceneProps) => {
  const frame = useCurrentFrame();
  const {width, height} = useVideoConfig();
  const box = layoutFor(config, width, height);
  const {margin, grid, padding} = config.layout;
  const {colors, typography} = config.brand;
  const {lineThickness, tileSize, frameThickness, rectangleRole, lineRole} = config.geometry;
  const p = easeInOut(progress(frame, 0, Math.min(config.motion.revealFrames, scene.durationInFrames / 4)));
  const index = ['environment', 'agent', 'iphone', 'webQa', 'ipad'].indexOf(scene.id);
  const split = Math.max(1, Math.min(scene.durationInFrames - 1,
    Math.round(scene.durationInFrames * config.motion.iphoneSplit)));
  const secondIphone = frame >= split;
  const isVideo = scene.id === 'agent' || scene.id === 'webQa';
  const isStill = scene.id === 'iphone' || scene.id === 'ipad';
  const caption = config.copy[scene.id];
  const image = scene.id === 'environment' ? config.media.environment :
    scene.id === 'ipad' ? config.media.ipad : config.media.iphone[secondIphone ? 1 : 0];
  const previous = Math.max(0, index - 1);
  const lineLength = lineRole === 'rule' ? box.height - tileSize - padding :
    (box.height - tileSize - padding) * mix(previous / 4, index / 4, p);
  return <AbsoluteFill>
    <Rect style={{
      left: box.x, top: margin - 4, right: margin + 230,
      fontSize: config.composition.captionSize, ...heading(config),
    }}>{caption}</Rect>
    <Rect style={{right: margin, top: margin - 2}}>
      <Logo config={config} width={config.composition.logoWidth} />
    </Rect>
    <Rect style={{
      left: margin, top: box.y, width: tileSize, height: tileSize, background: colors.ink,
      color: colors.white, display: 'flex', alignItems: 'center', justifyContent: 'center',
      fontFamily: typography.monoFamily, fontSize: 26,
      transform: `translateY(${-(1 - p) * config.motion.tileTravel}px)`,
    }}>{String(index + 1).padStart(2, '0')}</Rect>
    <Rect style={{
      left: margin + grid.railWidth / 2 - lineThickness / 2,
      top: box.y + tileSize + padding, height: box.height - tileSize - padding,
      width: lineThickness, background: colors.mediaMat,
    }} />
    <Rect style={{
      left: margin + grid.railWidth / 2 - lineThickness / 2,
      top: box.y + tileSize + padding, height: lineLength,
      width: lineThickness, background: colors.ink,
    }} />
    <Rect style={{
      left: box.x - frameThickness, top: box.y - frameThickness,
      width: box.width + frameThickness * 2, height: box.height + frameThickness * 2,
      border: rectangleRole === 'frame' ? `${frameThickness}px solid ${colors.ink}` : undefined,
      background: colors.mediaMat,
    }} />
    <Rect style={{left: box.x, top: box.y, width: box.width, height: box.height}}>
      {isVideo ? <SourceVideo
        {...(scene.id === 'agent' ? config.media.agent : config.media.webQa)}
        width={box.width} height={box.height} durationInFrames={scene.durationInFrames}
        labelHeight={48}
        labelStyle={{
          backgroundColor: colors.ink, color: colors.white,
          fontFamily: typography.fontFamily, fontSize: 26, paddingLeft: 22,
        }}
      /> : <SourceImage {...image} width={box.width} height={box.height} />}
      {!isVideo ? <Reveal
        config={config} frame={secondIphone && scene.id === 'iphone' ? frame - split : frame}
        duration={scene.id === 'iphone' ? (secondIphone ? scene.durationInFrames - split : split) : scene.durationInFrames}
      /> : null}
    </Rect>
    <Rect style={{
      left: box.x, top: box.y - padding, height: lineThickness,
      width: box.width * p, background: colors.ink,
    }} />
    <Rect style={{left: box.x, bottom: 30}}>
      <StageTiles config={config} active={index} frame={frame} />
    </Rect>
    <Rect style={{
      right: margin, bottom: 29, fontSize: config.composition.labelSize,
      color: colors.secondaryInk,
    }}>{isStill ? config.labels.still : config.labels.montage}</Rect>
  </AbsoluteFill>;
};

const Closing = ({config, scene}: SceneProps) => {
  const frame = useCurrentFrame();
  const {width, height} = useVideoConfig();
  const {colors, typography, spacing} = config.brand;
  const {margin, padding} = config.layout;
  const c = config.composition;
  const g = config.geometry;
  const box = layoutFor(config, width, height);
  const resolveFrames = Math.min(config.motion.closingResolveFrames, scene.durationInFrames / 3);
  const p = easeInOut(progress(frame, 0, resolveFrames));
  const copyOpacity = progress(frame, resolveFrames, Math.min(8, scene.durationInFrames / 6));
  const result = {
    x: mix(box.x, c.closingMediaX, p),
    y: mix(box.y, c.closingMediaY, p),
    width: mix(box.width, c.closingMediaWidth, p),
    height: mix(box.height, c.closingMediaHeight, p),
  };
  return <AbsoluteFill>
    <Rect style={{left: margin, top: margin}}><Logo config={config} width={c.logoWidth} /></Rect>
    <Rect style={{right: margin, top: margin, fontSize: c.labelSize}}>{config.copy.featureName}</Rect>
    <Rect style={{
      left: margin, top: 242, width: c.closingTextWidth, fontSize: typography.headingSize,
      ...heading(config), opacity: copyOpacity,
    }}>{config.copy.closing}</Rect>
    <Rect style={{
      left: margin, top: 650, width: c.closingTextWidth, fontSize: typography.bodySize + 4,
      lineHeight: typography.bodyLineHeight, opacity: copyOpacity,
    }}>{config.copy.cta}</Rect>
    <Rect style={{
      left: margin, top: 790, fontSize: typography.bodySize,
      letterSpacing: typography.bodyTracking, opacity: copyOpacity,
      borderBottom: `${g.lineThickness}px solid ${colors.ink}`, paddingBottom: padding,
    }}>{config.copy.url}</Rect>
    <Rect style={{
      left: result.x - padding, top: result.y - padding,
      width: result.width + padding * 2, height: result.height + padding * 2,
      background: colors.mediaMat,
      border: g.rectangleRole === 'frame' ? `${g.frameThickness}px solid ${colors.ink}` : undefined,
    }} />
    <Rect style={{left: result.x, top: result.y}}>
      <SourceImage {...config.media.ipad} width={result.width} height={result.height} />
    </Rect>
    <Rect style={{
      left: c.closingMediaX, top: c.closingMediaY + c.closingMediaHeight + spacing.titleGap,
      fontSize: c.labelSize, opacity: copyOpacity, color: colors.secondaryInk,
    }}>{config.labels.result}</Rect>
    <Rect style={{
      right: margin, bottom: 130, display: 'flex', gap: 10, opacity: copyOpacity,
    }}>{g.showTiles ? config.labels.stages.map((_, index) => <div key={index} style={{
      width: g.tileSize, height: 18, background: colors.ink,
      transform: `translateX(${(1 - easeInOut(copyOpacity)) * config.motion.transitionDistance * (index + 1) / 5}px)`,
    }} />) : null}</Rect>
    <Rect style={{
      left: margin, right: margin, bottom: 90, height: g.lineThickness, background: colors.ink,
    }} />
    <Rect style={{left: margin, bottom: 35, fontSize: c.labelSize, color: colors.secondaryInk}}>
      {config.labels.montage}
    </Rect>
  </AbsoluteFill>;
};

const Scene = ({config, scene}: SceneProps) => {
  const id: SceneId = scene.id;
  if (id === 'opening') return <Opening config={config} scene={scene} />;
  if (id === 'closing') return <Closing config={config} scene={scene} />;
  return <Product config={config} scene={scene} />;
};

export const Template = ({config}: Props) => {
  const {fps} = useVideoConfig();
  const timeline = makeTimeline(config.durations, fps);
  return <AbsoluteFill style={{
    background: config.brand.colors.canvas,
    color: config.brand.colors.ink,
    fontFamily: config.brand.typography.fontFamily,
    fontWeight: 400,
    overflow: 'hidden',
  }}>
    {timeline.map((scene) => <Sequence
      key={scene.id} from={scene.from} durationInFrames={scene.durationInFrames}
    ><Scene config={config} scene={scene} /></Sequence>)}
  </AbsoluteFill>;
};
