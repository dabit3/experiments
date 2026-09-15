import {AbsoluteFill} from 'remotion';
import {easeInOut, mix, progress} from '../../shared';
import type {PaperConfig} from './config';

type Environment = 'Ubuntu' | 'macOS' | 'Windows';

const EnvironmentIcon = ({name, color}: {name: Environment; color: string}) => {
  if (name === 'Windows') return <svg width="44" height="44" viewBox="0 0 44 44">
    <path fill="#f35325" d="M0 0h20v20H0z" />
    <path fill="#81bc06" d="M23 0h21v20H23z" />
    <path fill="#05a6f0" d="M0 23h20v21H0z" />
    <path fill="#ffba08" d="M23 23h21v21H23z" />
  </svg>;
  if (name === 'Ubuntu') return <svg width="44" height="44" viewBox="0 0 44 44">
    <circle cx="22" cy="22" r="14" fill="none" stroke="#e96829" strokeWidth="6" />
    {[0, 120, 240].map((angle) => <g key={angle} transform={`rotate(${angle} 22 22)`}>
      <path d="M7 22H13" stroke="#ffffff" strokeWidth="3" />
      <circle cx="4" cy="22" r="5.5" fill="#e96829" stroke="#ffffff" strokeWidth="2.5" />
    </g>)}
  </svg>;
  return <svg width="44" height="44" viewBox="0 0 44 44" fill={color}>
    <path d="M27.4 8.2c2.2-2.5 2-5.6 2-6.3-2.7.2-5.7 1.8-7.4 3.8-1.7 1.9-2.8 4.4-2.6 6.7 2.9.2 5.8-1.5 8-4.2Zm5.2 15.7c0-5.2 4.3-7.8 4.5-8-2.5-3.7-6.4-4.2-7.8-4.3-3.3-.4-6.5 2-8.2 2-1.8 0-4.5-1.9-7.4-1.8-3.8.1-7.3 2.2-9.2 5.6-4 6.8-1 17 2.8 22.5 1.8 2.6 3.9 5.4 6.7 5.2 2.7-.1 3.7-1.7 7-1.7 3.2 0 4.2 1.7 7 1.6 2.9-.1 4.7-2.6 6.5-5.2 2.1-3 2.9-5.9 3-6.1-.1 0-4.9-1.9-4.9-7.8Z"
      transform="translate(2 -1) scale(.91)" />
  </svg>;
};

const Check = ({opacity, color}: {opacity: number; color: string}) =>
  <svg width="36" height="36" viewBox="0 0 36 36" style={{opacity}}>
    <path d="m5 19 8 8L31 8" fill="none" stroke={color} strokeWidth="3"
      strokeLinecap="round" strokeLinejoin="round" />
  </svg>;

export const EnvironmentSelector = ({
  config, frame, durationInFrames, width, height,
}: {
  config: PaperConfig; frame: number; durationInFrames: number; width: number; height: number;
}) => {
  const settings = config.environmentSelector;
  const {colors} = config.brand;
  const duration = Math.max(1, durationInFrames - 1);
  const selectAt = Math.max(0.15, Math.min(0.85, settings.selectAt));
  const moveAt = Math.max(0, Math.min(selectAt - 0.1, settings.moveAt));
  const clickFrame = Math.round(duration * selectAt);
  const move = easeInOut(progress(frame, duration * moveAt, duration * (selectAt - moveAt - 0.04)));
  const selected = frame >= clickFrame;
  const leave = easeInOut(progress(frame, duration * (selectAt + 0.2), duration * 0.16));
  const hoverMac = move >= 0.5;
  const click = progress(frame, clickFrame, Math.max(1, duration * 0.08));
  const cursorX = mix(mix(430, 320, move), 778, leave);
  const cursorY = mix(mix(260, 354, move), 530, leave);
  const scale = Math.min(settings.width / 826, (width - 48) / 826, (height - 32) / 576);
  return <AbsoluteFill style={{background: colors.white, overflow: 'hidden'}}>
    <div style={{
      position: 'absolute', width: 826, height: 576,
      left: (width - 826 * scale) / 2, top: (height - 576 * scale) / 2,
      transform: `scale(${scale})`, transformOrigin: 'top left', color: colors.ink,
      fontSize: 44, lineHeight: 1, letterSpacing: '-0.02em',
    }}>
      <div style={{position: 'absolute', left: 66, top: 54, height: 48, display: 'flex', alignItems: 'center', gap: 14}}>
        <EnvironmentIcon name={selected ? 'macOS' : 'Ubuntu'} color={colors.ink} />
        <span>{selected ? 'macOS' : 'Ubuntu'}</span>
        <svg width="30" height="30" viewBox="0 0 30 30" style={{marginLeft: 8}}>
          <path d="m5 10 10 10 10-10" fill="none" stroke={colors.ink}
            strokeWidth="2.8" strokeLinecap="round" strokeLinejoin="round" />
        </svg>
      </div>
      <div style={{
        position: 'absolute', left: 60, top: 110, width: 702, height: 398,
        borderRadius: 34, border: '2px solid rgba(25,25,25,0.07)',
        background: colors.white,
        boxShadow: '0 20px 38px rgba(0,0,0,0.055), 0 1px 4px rgba(0,0,0,0.025)',
      }}>
        <div style={{position: 'absolute', left: 36, top: 35, fontSize: 40, color: colors.secondaryInk}}>Hosted</div>
        {(['Ubuntu', 'macOS', 'Windows'] as const).map((name, index) => <div key={name} style={{
          position: 'absolute', left: 12, right: 12, top: 96 + index * 96, height: 94,
          display: 'flex', alignItems: 'center', borderRadius: 19, padding: '0 26px', gap: 28,
          background: (index === 0 && !hoverMac) || (index === 1 && hoverMac && leave < 0.3)
            ? colors.mediaMat : 'transparent',
        }}>
          <EnvironmentIcon name={name} color={colors.secondaryInk} />
          <span>{name}</span>
          {name === 'Ubuntu' ? <svg width="40" height="40" viewBox="0 0 40 40" fill={colors.ink} style={{marginLeft: -4}}>
            <path d="m20 2 5.5 11.2 12.3 1.8-8.9 8.7L31 36 20 30.2 9 36l2.1-12.3L2.2 15l12.3-1.8Z"
              stroke={colors.ink} strokeWidth="2" strokeLinejoin="round" />
          </svg> : null}
          <div style={{position: 'absolute', right: 30, top: 28}}>
            <Check color={colors.secondaryInk} opacity={index === (selected ? 1 : 0) ? 1 : 0} />
          </div>
        </div>)}
      </div>
      {selected && click < 1 ? <div style={{
        position: 'absolute', left: 320, top: 354, width: 62, height: 62,
        border: `2px solid ${colors.secondaryInk}`, borderRadius: '50%',
        transform: `translate(-50%, -50%) scale(${mix(0.3, 1.3, click)})`,
        opacity: (1 - click) * 0.4,
      }} /> : null}
      <svg width="34" height="42" viewBox="0 0 34 42" style={{
        position: 'absolute', left: cursorX, top: cursorY,
        opacity: 1 - progress(leave, 0.65, 0.35),
        transform: `scale(${1 - Math.sin(click * Math.PI) * 0.13})`,
        transformOrigin: 'top left', filter: 'drop-shadow(0 2px 2px rgba(0,0,0,0.2))',
      }}>
        <path d="M3 2v30l8-8 7 15 6-3-7-14h12Z"
          fill={colors.ink} stroke={colors.white} strokeWidth="2.4" strokeLinejoin="round" />
      </svg>
    </div>
  </AbsoluteFill>;
};
