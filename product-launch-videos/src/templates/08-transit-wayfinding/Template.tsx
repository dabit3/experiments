import {AbsoluteFill, Freeze, Sequence, useCurrentFrame, useVideoConfig} from 'remotion';
import {
  SourceImage, SourceVideo, easeInOut, makeTimeline, mix, progress,
  type SceneTiming,
} from '../../shared';
import type {TransitConfig} from './config';

type Props = {config: TransitConfig};
type Point = {x: number; y: number};

const routePoints = (config: TransitConfig, width: number, height: number): Point[] =>
  config.route.stations.map((stop) => ({x: stop.x * width, y: stop.y * height}));

const Route = ({
  config, width, height, active, traced = active, compact = false,
}: Props & {
  width: number; height: number; active: number; traced?: number; compact?: boolean;
}) => {
  const {colors, typography} = config.brand;
  const points = routePoints(config, width, height);
  return <svg width={width} height={height} style={{overflow: 'visible'}}>
    {points.slice(1).map((point, i) => {
      const previous = points[i];
      const completed = progress(traced, i, 1);
      const path = `M ${previous.x} ${previous.y} H ${point.x} V ${point.y}`;
      return <g key={config.route.stations[i + 1].scene}>
        <path d={path} fill="none" stroke={colors.mediaMat} strokeWidth={config.motion.lineWidth} />
        <path d={path} fill="none" stroke={colors.ink} strokeWidth={config.motion.lineWidth}
          pathLength={1} strokeDasharray={1} strokeDashoffset={1 - completed} />
      </g>;
    })}
    {points.map((point, i) => {
      const isActive = i === active;
      const r = compact ? 7 : config.motion.markerRadius;
      return <g key={config.route.stations[i].scene}>
        {isActive && <circle cx={point.x} cy={point.y} r={r + 7}
          fill={colors.canvas} stroke={colors.ink} strokeWidth={2} />}
        <circle cx={point.x} cy={point.y} r={r}
          fill={i <= active ? colors.ink : colors.canvas}
          stroke={i <= active ? colors.ink : colors.secondaryInk} strokeWidth={2} />
        {!compact && <text x={point.x} y={point.y - 42} textAnchor="middle"
          fill={colors.secondaryInk} fontFamily={typography.monoFamily} fontSize={19}>
          {String(i + 1).padStart(2, '0')}
        </text>}
        <text x={point.x} y={point.y + (compact ? 31 : 54)} textAnchor="middle"
          fontSize={compact ? 22 : 34} fontFamily={typography.fontFamily}
          letterSpacing={typography.bodyTracking}
          fill={i <= active ? colors.ink : colors.secondaryInk}>
          {config.route.stations[i].name}
        </text>
      </g>;
    })}
  </svg>;
};

const Logo = ({config, width = 174, height = 52}: Props & {width?: number; height?: number}) =>
  <SourceImage {...config.media.logo} width={width} height={height} />;

const TitleScene = ({config, closing = false}: Props & {closing?: boolean}) => {
  const frame = useCurrentFrame();
  const {width} = useVideoConfig();
  const {colors, typography} = config.brand;
  const m = config.layout.margin;
  const routeWidth = width - m * 4;
  const line = progress(frame, 15, config.motion.lineTraceFrames);
  const last = config.route.stations.length - 1;
  return <AbsoluteFill style={{background: colors.canvas}}>
    <div style={{position: 'absolute', left: m, top: 46}}><Logo config={config} /></div>
    <div style={{
      position: 'absolute', right: m, top: 48, display: 'flex', gap: 22, alignItems: 'center',
    }}>
      <span style={{fontSize: 26}}>{config.copy.featureName}</span>
      <div style={{
        width: 66, height: 66, background: colors.ink, color: colors.white,
        display: 'grid', placeItems: 'center', fontSize: 42,
      }}>{config.route.code}</div>
    </div>
    <div style={{position: 'absolute', left: m * 2, top: 215, width: config.layout.grid.titleWidth}}>
      <div style={{
        fontSize: closing ? typography.bodySize : 25,
        color: colors.secondaryInk, marginBottom: config.brand.spacing.titleGap,
      }}>
        {closing ? config.copy.closing : config.copy.featureName}
      </div>
      <div style={{
        fontSize: closing ? typography.headingSize : typography.headingSize * 1.42,
        lineHeight: typography.headingLineHeight,
        letterSpacing: typography.headingTracking, maxWidth: closing ? 1220 : 1120,
      }}>
        {closing ? config.copy.cta : config.copy.opening}
      </div>
      <div style={{
        fontSize: typography.bodySize, lineHeight: typography.bodyLineHeight,
        letterSpacing: typography.bodyTracking, marginTop: config.brand.spacing.titleGap,
        maxWidth: 1120,
      }}>
        {closing ? config.copy.url : config.copy.benefit}
      </div>
    </div>
    <div style={{position: 'absolute', left: m * 2, top: config.layout.grid.introMapY}}>
      <Route config={config} width={routeWidth} height={110}
        active={closing ? last : 0} traced={closing ? last : line} />
    </div>
    <div style={{
      position: 'absolute', left: m, right: m, bottom: 42, paddingTop: 21,
      borderTop: `1px solid ${colors.secondaryInk}`, display: 'flex', justifyContent: 'space-between',
      fontSize: 22, color: colors.secondaryInk,
    }}>
      <span>{config.route.legend}</span>
      <span>{closing ? config.route.destinationLabel : config.route.departureLabel}</span>
    </div>
  </AbsoluteFill>;
};

const StillPair = ({config, width, height, frames}: Props & {
  width: number; height: number; frames: number;
}) => {
  const frame = useCurrentFrame();
  const split = Math.max(1, Math.min(frames - 1, Math.round(frames * config.motion.iphoneSplit)));
  return <SourceImage {...config.media.iphone[frame < split ? 0 : 1]} width={width} height={height} />;
};

const Product = ({config, scene, width, height}: Props & {
  scene: SceneTiming; width: number; height: number;
}) => {
  if (scene.id === 'agent' || scene.id === 'webQa') {
    return <SourceVideo {...config.media[scene.id]} width={width} height={height}
      durationInFrames={scene.durationInFrames} labelHeight={48}
      labelStyle={{
        backgroundColor: config.brand.colors.ink, color: config.brand.colors.white,
        fontFamily: config.brand.typography.fontFamily, fontSize: 26,
      }} />;
  }
  if (scene.id === 'iphone') {
    return <StillPair config={config} width={width} height={height} frames={scene.durationInFrames} />;
  }
  if (scene.id === 'environment' || scene.id === 'ipad') {
    return <SourceImage {...config.media[scene.id]} width={width} height={height} />;
  }
  return null;
};

const StationScene = ({config, scene, preRoll}: Props & {scene: SceneTiming; preRoll: number}) => {
  const frame = useCurrentFrame();
  const {width, height} = useVideoConfig();
  const {colors, typography} = config.brand;
  const m = config.layout.margin;
  const viewportWidth = width - 2 * m;
  const viewportHeight = height - config.layout.captionHeight - config.layout.grid.routeFooterHeight;
  const mediaWidth = viewportWidth - 2 * config.layout.padding;
  const mediaHeight = viewportHeight - 2 * config.layout.padding;
  const active = config.route.stations.findIndex((station) => station.scene === scene.id);
  const stop = config.route.stations[active];
  const available = preRoll > 0 ? preRoll : scene.durationInFrames;
  const hold = Math.max(0, Math.min(config.motion.mapHoldFrames, Math.floor(available / 4)));
  const revealLength = Math.max(0, Math.min(config.motion.arrivalFrames, available - hold));
  const reveal = easeInOut(progress(frame, hold, revealLength));
  const points = routePoints(config, viewportWidth, viewportHeight);
  const origin = points[active];
  const inset = [
    mix(origin.y, 0, reveal),
    mix(viewportWidth - origin.x, 0, reveal),
    mix(viewportHeight - origin.y, 0, reveal),
    mix(origin.x, 0, reveal),
  ].map((value) => `${value}px`).join(' ');
  const video = scene.id === 'agent' || scene.id === 'webQa';
  const native = scene.id === 'iphone' || scene.id === 'ipad';
  return <AbsoluteFill style={{background: colors.canvas}}>
    <div style={{
      position: 'absolute', left: m, top: 40, width: 58, height: 58,
      background: colors.ink, color: colors.white, display: 'grid', placeItems: 'center',
      fontSize: 30, fontFamily: typography.monoFamily,
    }}>{String(active + 1).padStart(2, '0')}</div>
    <div style={{position: 'absolute', left: m + 58 + config.layout.gutter, top: 25}}>
      <div style={{fontSize: 21, color: colors.secondaryInk, marginBottom: 10}}>
        {config.route.code} / {stop.name}
        {native ? ` · ${config.route.stillLabel}` : ' · Separate example'}
      </div>
      <div style={{
        fontSize: typography.headingSize / 2, lineHeight: typography.headingLineHeight,
        letterSpacing: typography.headingTracking, maxWidth: width - 400,
      }}>{config.copy[scene.id]}</div>
    </div>
    <div style={{position: 'absolute', top: 50, right: m}}><Logo config={config} /></div>
    <div style={{
      position: 'absolute', left: m, top: config.layout.captionHeight,
      width: viewportWidth, height: viewportHeight,
    }}>
      {reveal < 1 && <div style={{
        position: 'absolute', inset: 0, overflow: 'hidden',
        opacity: 1 - progress(reveal, 0.1, 0.35),
      }}>
        <Route config={config} width={viewportWidth} height={viewportHeight}
          active={active} traced={Math.max(0, active - 1) + progress(frame, 0, hold + revealLength)} />
      </div>}
      <div style={{
        position: 'absolute', inset: 0, background: colors.mediaMat, clipPath: `inset(${inset})`,
        padding: config.layout.padding,
      }}>
        {video && preRoll > 0 ? <>
          <Sequence durationInFrames={preRoll} layout="none">
            <Freeze frame={0}><Product config={config} scene={scene} width={mediaWidth} height={mediaHeight} /></Freeze>
          </Sequence>
          <Sequence from={preRoll} durationInFrames={scene.durationInFrames} layout="none">
            <Product config={config} scene={scene} width={mediaWidth} height={mediaHeight} />
          </Sequence>
        </> : <Product config={config} scene={scene} width={mediaWidth} height={mediaHeight} />}
      </div>
    </div>
    <div style={{
      position: 'absolute', left: m * 2, top: height - config.layout.grid.routeFooterHeight + 12,
    }}>
      <Route config={config} width={width - m * 4} height={18} active={active} compact />
    </div>
  </AbsoluteFill>;
};

export const Template = ({config}: Props) => {
  const {fps} = useVideoConfig();
  const timeline = makeTimeline(config.durations, fps);
  return <AbsoluteFill style={{
    background: config.brand.colors.canvas, color: config.brand.colors.ink,
    fontFamily: config.brand.typography.fontFamily,
  }}>
    {timeline.map((scene, index) => {
      const isVideo = scene.id === 'agent' || scene.id === 'webQa';
      const preRoll = isVideo ? Math.max(0, Math.min(
        config.motion.arrivalFrames + config.motion.mapHoldFrames,
        Math.floor(timeline[index - 1].durationInFrames / 4),
      )) : 0;
      return <Sequence key={scene.id} from={scene.from - preRoll}
        durationInFrames={scene.durationInFrames + preRoll}>
        {scene.id === 'opening' || scene.id === 'closing'
          ? <TitleScene config={config} closing={scene.id === 'closing'} />
          : <StationScene config={config} scene={scene} preRoll={preRoll} />}
      </Sequence>;
    })}
  </AbsoluteFill>;
};
