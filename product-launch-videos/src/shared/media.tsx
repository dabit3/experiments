import type {CSSProperties, ReactNode} from 'react';
import {Img, OffthreadVideo, Sequence, useVideoConfig} from 'remotion';
import {assetPath, assets, type ImageAssetId, type VideoAssetId} from './assets';
import {contain, mediaGeometry, type Framing} from './geometry';
import {videoTrim, type VideoTiming} from './video-timing';
import {brand} from './tokens';

type Viewport = {
  width: number;
  height: number;
  framing?: Framing;
  style?: CSSProperties;
};

const SourceViewport = ({
  width, height, framing = contain, source, children, style,
}: Viewport & {
  source: {width: number; height: number};
  children: (style: CSSProperties) => ReactNode;
}) => {
  const geometry = mediaGeometry(source, {width, height}, framing);
  return <div style={{...style, width, height, position: 'relative', overflow: 'hidden'}}>
    <div style={{
      position: 'absolute', overflow: 'hidden',
      left: geometry.cropLeft, top: geometry.cropTop,
      width: geometry.cropWidth, height: geometry.cropHeight,
    }}>
      {children({
        position: 'absolute', maxWidth: 'none',
        width: geometry.mediaWidth, height: geometry.mediaHeight,
        left: geometry.mediaLeft, top: geometry.mediaTop,
      })}
    </div>
  </div>;
};

export const SourceImage = ({asset, ...viewport}: Viewport & {asset: ImageAssetId}) =>
  <SourceViewport {...viewport} source={assets[asset]}>
    {(style) => <Img src={assetPath(asset)} style={style} />}
  </SourceViewport>;

export const SourceVideo = ({
  asset, sourceStartSeconds, durationInFrames, width, height,
  labelHeight = 48, labelStyle, ...viewport
}: Viewport & VideoTiming & {
  asset: VideoAssetId;
  labelHeight?: number;
  labelStyle?: CSSProperties;
}) => {
  const {fps} = useVideoConfig();
  const trim = videoTrim({sourceStartSeconds, durationInFrames}, fps, assets[asset].durationSeconds);
  const isWebQa = asset === 'devin-testing-2.mp4';
  const footerHeight = isWebQa ? Math.max(40, labelHeight) : 0;
  return <Sequence durationInFrames={durationInFrames} layout="none">
    <div style={{width, height, position: 'relative'}}>
      <SourceViewport {...viewport} width={width} height={height - footerHeight} source={assets[asset]}>
        {(style) => <OffthreadVideo
          src={assetPath(asset)} {...trim}
          playbackRate={1} muted style={style}
          onError={(error) => {throw new Error(`Cannot load ${asset}: ${error}`);}}
        />}
      </SourceViewport>
      {isWebQa ? <div style={{
        backgroundColor: brand.colors.ink, color: brand.colors.white,
        fontFamily: brand.typography.fontFamily, fontSize: 28,
        ...labelStyle,
        position: 'absolute', left: 0, right: 0, bottom: 0,
        height: footerHeight, display: 'flex', alignItems: 'center', padding: '0 20px',
      }}>Web QA example</div> : null}
    </div>
  </Sequence>;
};
