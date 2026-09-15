import {useCurrentFrame} from 'remotion';
import {
  SourceImage, assets, contain, mediaGeometry, type Crop, type ImageSelection,
} from '../../shared';
import {selectorDefaults, selectorState} from './selector';

const asset = 'devin-web-4.png';
const fragments = [
  {x: 690, y: 1096, width: 232, height: 42},
  {x: 690, y: 1171, width: 210, height: 42},
  {x: 690, y: 1246, width: 275, height: 42},
];

const Fragment = ({
  crop, ubuntu = false, scale = 1,
}: {crop: Crop; ubuntu?: boolean; scale?: number}) =>
  <SourceImage asset={asset} framing={{...contain, crop}}
    width={crop.width * scale} height={crop.height * scale}
    style={{mixBlendMode: 'multiply', filter: ubuntu ? 'brightness(1.0625)' : undefined}} />;

export const EnvironmentSelector = ({
  selection, width, height, duration, background,
  settings = selectorDefaults,
}: {
  selection: ImageSelection;
  width: number;
  height: number;
  duration: number;
  background: string;
  settings?: typeof selectorDefaults;
}) => {
  const frame = useCurrentFrame();
  const {position, selected} = selectorState(frame, duration, settings);
  const source = assets[selection.asset];
  const geometry = mediaGeometry(source, {width, height}, selection.framing);
  const scale = geometry.mediaWidth / source.width;
  return <div style={{position: 'relative', width, height, overflow: 'hidden', background}}>
    <SourceImage {...selection} width={width} height={height} />
    {settings.enabled && selection.asset === asset ? <div style={{
      position: 'absolute', overflow: 'hidden',
      left: geometry.cropLeft, top: geometry.cropTop,
      width: geometry.cropWidth, height: geometry.cropHeight,
    }}>
      <div style={{
        position: 'absolute', left: geometry.mediaLeft, top: geometry.mediaTop,
        width: source.width, height: source.height,
        transform: `scale(${scale})`, transformOrigin: '0 0',
      }}>
        {selected === 'Ubuntu' ? <div style={{
          position: 'absolute', left: 660, top: 953, width: 204, height: 46,
          background: '#fcfcfc',
        }}>
          <div style={{position: 'absolute', left: 3, top: 5}}>
            <Fragment crop={{x: 690, y: 1096, width: 180, height: 42}} ubuntu scale={0.875} />
          </div>
          <svg width={24} height={24} viewBox="0 0 24 24"
            style={{position: 'absolute', left: 163, top: 11}}>
            <path d="m3 8 9 9 9-9" fill="none" stroke="#191919"
              strokeWidth={2.4} strokeLinecap="round" strokeLinejoin="round" />
          </svg>
        </div> : null}
        <div style={{
          position: 'absolute', left: 669, top: 1078,
          width: 531, height: 225, background: '#fff', boxShadow: '0 0 0 2px #fff',
        }}>
          <div style={{
            position: 'absolute', left: 0, top: position * 75,
            width: 531, height: 75, borderRadius: 16, background: '#f0f0f0',
          }} />
          {fragments.map((crop, index) => <div key={crop.y} style={{
            position: 'absolute', left: 21, top: index * 75 + 18,
          }}><Fragment crop={crop} ubuntu={index === 0} /></div>)}
          <div style={{
            position: 'absolute', left: 476, top: selected === 'macOS' ? 100 : 25,
          }}><Fragment crop={{x: 1145, y: 1178, width: 29, height: 30}} /></div>
        </div>
      </div>
    </div> : null}
  </div>;
};
