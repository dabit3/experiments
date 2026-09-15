import type {CSSProperties} from 'react';
import {useCurrentFrame} from 'remotion';
import {assets, mediaGeometry, SourceImage, type Crop, type ImageSelection} from '../../shared';
import type {NoirConfig} from './config';
import {environmentSelectionState} from './motion';

const sourceAsset = 'devin-web-4.png';
const row = {x: 669, y: 1078, width: 530, height: 76};
const ubuntu = {x: 684, y: 1089, width: 235, height: 54};
const mac = {x: 684, y: 1165, width: 192, height: 54};
const check = {x: 1144, y: 1178, width: 34, height: 30};

const Sprite = ({
  crop, x = crop.x, y = crop.y, scale = 1, background = 255,
}: {crop: Crop; x?: number; y?: number; scale?: number; background?: number}) =>
  <div style={{
    position: 'absolute', left: x, top: y,
    transform: `scale(${scale})`, transformOrigin: 'top left',
    filter: `brightness(${255 / background})`, mixBlendMode: 'multiply',
  }}>
    <SourceImage asset={sourceAsset}
      framing={{fit: 'contain', anchorX: 0, anchorY: 0, crop}}
      width={crop.width} height={crop.height} />
  </div>;

export const EnvironmentSelection = ({
  config, selection, width, height, duration,
}: {
  config: NoirConfig; selection: ImageSelection;
  width: number; height: number; duration: number;
}) => {
  const frame = useCurrentFrame();
  const state = environmentSelectionState(frame, duration, config.motion);
  const geometry = mediaGeometry(assets[selection.asset], {width, height}, selection.framing);
  const overlay: CSSProperties = {
    position: 'absolute', width: assets[sourceAsset].width, height: assets[sourceAsset].height,
    left: geometry.mediaLeft, top: geometry.mediaTop,
    transform: `scale(${geometry.mediaWidth / assets[sourceAsset].width})`,
    transformOrigin: 'top left', isolation: 'isolate',
  };
  return <div style={{width, height, position: 'relative', overflow: 'hidden'}}>
    <SourceImage {...selection} width={width} height={height} />
    {selection.asset === sourceAsset ? <div style={{
      position: 'absolute', overflow: 'hidden',
      left: geometry.cropLeft, top: geometry.cropTop,
      width: geometry.cropWidth, height: geometry.cropHeight,
    }}>
      <div style={overlay}>
        <div style={{
          position: 'absolute', left: row.x, top: row.y,
          width: row.width, height: row.height * 2, background: '#ffffff',
        }} />
        <div style={{
          position: 'absolute', left: row.x, top: row.y + row.height * state.move,
          width: row.width, height: row.height, borderRadius: 16, background: '#f0f0f0',
        }} />
        <Sprite crop={ubuntu} background={240} />
        <Sprite crop={mac} />
        <Sprite crop={check} y={state.selectedMac ? check.y : check.y - row.height} />
        {!state.selectedMac ? <>
          <div style={{
            position: 'absolute', left: 657, top: 950, width: 195, height: 46,
            background: '#fdfdfd',
          }} />
          <Sprite crop={{x: 688, y: 1094, width: 42, height: 42}}
            x={661} y={957} scale={0.75} background={240} />
          <Sprite crop={{x: 746, y: 1091, width: 119, height: 48}}
            x={703} y={952} scale={0.86} background={240} />
          <Sprite crop={{x: 824, y: 963, width: 24, height: 26}} />
        </> : null}
        <svg width={38} height={46} viewBox="0 0 24 29" style={{
          position: 'absolute', left: 986, top: 1123 + row.height * state.move,
          opacity: state.cursorOpacity,
          transform: `scale(${1 - state.press * 0.12})`, transformOrigin: 'top left',
        }}>
          <path d="M2 2V23L8 17L13 27L17 25L12 15H21Z"
            fill="#191919" stroke="#ffffff" strokeWidth={1.5} strokeLinejoin="round" />
        </svg>
      </div>
    </div> : null}
  </div>;
};
