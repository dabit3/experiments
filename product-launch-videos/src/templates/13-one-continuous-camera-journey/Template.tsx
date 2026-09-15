import type {CSSProperties, ReactNode} from 'react';
import {AbsoluteFill, Freeze, useCurrentFrame, useVideoConfig} from 'remotion';
import {SourceImage, SourceVideo, type SceneTiming} from '../../shared';
import {stopIds, type JourneyConfig, type StopId} from './config';
import {EnvironmentMenu} from './EnvironmentMenu';
import {cameraAt, planJourney} from './journey';

const VideoAt = ({
  config, kind, scene, frame, width, height,
}: {
  config: JourneyConfig; kind: 'agent' | 'webQa'; scene: SceneTiming;
  frame: number; width: number; height: number;
}) => <Freeze frame={Math.max(0, Math.min(scene.durationInFrames - 1, frame - scene.from))}>
  <SourceVideo
    {...config.media[kind]} width={width} height={height}
    durationInFrames={scene.durationInFrames}
    labelStyle={{
      fontFamily: config.brand.typography.fontFamily,
      backgroundColor: config.brand.colors.ink,
      color: config.brand.colors.white,
    }}
  />
</Freeze>;

export const Template = ({config}: {config: JourneyConfig}) => {
  const frame = useCurrentFrame();
  const {fps, width, height} = useVideoConfig();
  const {stops, scene} = planJourney(config, fps);
  const camera = cameraAt(frame, stops, config.motion.travelPullback);
  const {colors, typography} = config.brand;
  const {margin, padding} = config.layout;
  const {canvas, labels} = config;
  const mediaWidth = width - 2 * margin;
  const mediaHeight = height - canvas.mediaTop - canvas.mediaBottom;
  const imageWidth = mediaWidth - 2 * padding;
  const imageHeight = mediaHeight - 2 * padding;
  const type: CSSProperties = {
    fontFamily: typography.fontFamily, fontWeight: 400,
    letterSpacing: typography.bodyTracking, lineHeight: typography.bodyLineHeight,
  };
  const captions: Record<StopId, string> = {
    opening: config.copy.opening,
    environment: config.copy.environment,
    agent: config.copy.agent,
    iphoneFirst: config.copy.iphone,
    iphoneSecond: config.copy.iphone,
    webQa: config.copy.webQa,
    ipad: config.copy.ipad,
    closing: config.copy.closing,
  };
  const mediaFor = (id: StopId): ReactNode => {
    if (id === 'environment' && config.environmentMenu.enabled) return <EnvironmentMenu
      config={config} frame={frame - scene('environment').from}
      durationInFrames={scene('environment').durationInFrames}
      width={imageWidth} height={imageHeight}
    />;
    if (id === 'agent' || id === 'webQa') return <VideoAt
      config={config} kind={id} scene={scene(id)} frame={frame}
      width={imageWidth} height={imageHeight}
    />;
    const selection = id === 'environment' ? config.media.environment
      : id === 'iphoneFirst' ? config.media.iphone[0]
        : id === 'iphoneSecond' ? config.media.iphone[1] : config.media.ipad;
    return <SourceImage {...selection} width={imageWidth} height={imageHeight} />;
  };
  const indexStyle: CSSProperties = {
    fontFamily: typography.monoFamily, fontSize: canvas.labelSize,
    letterSpacing: '-0.02em', lineHeight: 1.2,
  };
  return <AbsoluteFill style={{...type, backgroundColor: colors.canvas, color: colors.ink, overflow: 'hidden'}}>
    <div style={{
      position: 'absolute', width, height, transformOrigin: '50% 50%',
      transform: `scale(${camera.scale})`,
    }}>
      <div style={{
        position: 'absolute', width, height,
        transform: `translate(${-camera.x}px, ${-camera.y}px)`,
      }}>
        <svg width={config.canvas.stops.closing.x + width} height={height + 1000}
          style={{position: 'absolute', overflow: 'visible'}}>
          <polyline
            points={stops.map((stop) => `${stop.position.x + margin},${stop.position.y + canvas.railY}`).join(' ')}
            stroke={colors.ink} strokeWidth={config.motion.railWeight} fill="none" opacity={0.3}
          />
        </svg>
        {stops.map((stop, index) => {
          if (Math.abs(stop.position.x - camera.x) > width * 1.3) return null;
          const terminal = stop.id === 'opening' || stop.id === 'closing';
          return <div key={stop.id} style={{
            position: 'absolute', width, height,
            left: stop.position.x, top: stop.position.y,
          }}>
            <div style={{
              position: 'absolute', left: margin, top: canvas.railY - 12,
              width: 2, height: 24, backgroundColor: colors.ink,
            }} />
            {terminal ? <>
              <div style={{position: 'absolute', left: margin, top: 72}}>
                <SourceImage {...config.media.logo} width={canvas.logoWidth} height={90} />
              </div>
              <div style={{position: 'absolute', right: margin, top: 92, ...indexStyle}}>
                {config.copy.featureName}
              </div>
              <div style={{
                position: 'absolute', left: margin, top: 250, width: canvas.titleWidth,
              }}>
                <div style={{...indexStyle, color: colors.secondaryInk, marginBottom: 38}}>
                  {stop.id === 'opening' ? labels.introduction : labels.closing}
                </div>
                <div style={{
                  fontSize: stop.id === 'opening' ? canvas.titleSize : typography.headingSize * 1.25,
                  letterSpacing: typography.headingTracking,
                  lineHeight: typography.headingLineHeight,
                  maxWidth: stop.id === 'opening' ? 1360 : canvas.titleWidth,
                }}>{captions[stop.id]}</div>
                <div style={{
                  marginTop: config.brand.spacing.titleGap + 18,
                  fontSize: typography.bodySize + 8, maxWidth: 1050,
                }}>{stop.id === 'opening' ? config.copy.benefit : config.copy.cta}</div>
                {stop.id === 'closing' ? <div style={{
                  marginTop: 34, fontSize: typography.bodySize,
                  display: 'inline-block', borderBottom: `2px solid ${colors.ink}`, paddingBottom: 8,
                }}>{config.copy.url}</div> : null}
              </div>
              <div style={{position: 'absolute', right: margin, bottom: 114,
                fontSize: 108, fontFamily: typography.fontFamily, lineHeight: 1}}>
                {stop.id === 'opening' ? '→' : '—'}
              </div>
              <div style={{
                ...indexStyle, position: 'absolute', left: margin, bottom: 78,
                color: colors.secondaryInk,
              }}>{stop.id === 'opening' ? labels.montage : config.copy.featureName}</div>
            </> : <>
              <div style={{
                position: 'absolute', left: margin, top: 50,
                height: config.layout.captionHeight, right: margin,
                display: 'flex', alignItems: 'center', gap: config.layout.gutter,
              }}>
                <div style={{...indexStyle, color: colors.secondaryInk, width: 54}}>
                  {String(index).padStart(2, '0')}
                </div>
                <div style={{
                  fontSize: canvas.captionSize, letterSpacing: typography.headingTracking,
                  lineHeight: typography.headingLineHeight,
                }}>{captions[stop.id]}</div>
              </div>
              <div style={{
                position: 'absolute', top: canvas.mediaTop, left: margin,
                width: mediaWidth, height: mediaHeight,
                padding, boxSizing: 'border-box', backgroundColor: colors.mediaMat,
              }}>{mediaFor(stop.id)}</div>
              <div style={{
                ...indexStyle, position: 'absolute', left: margin, right: margin, bottom: 57,
                display: 'flex', justifyContent: 'space-between', color: colors.secondaryInk,
              }}>
                <span>{stop.id === 'opening' ? labels.introduction : labels[stop.id]}</span>
                <span>{config.copy.featureName} <span style={{marginLeft: 36}}>→</span></span>
              </div>
            </>}
            <div style={{position: 'absolute', left: margin + 18, top: canvas.railY - 10,
              ...indexStyle, fontSize: 16, backgroundColor: colors.canvas, padding: '0 12px'}}>
              {String(index + 1).padStart(2, '0')} / {String(stopIds.length).padStart(2, '0')}
            </div>
          </div>;
        })}
      </div>
    </div>
  </AbsoluteFill>;
};
