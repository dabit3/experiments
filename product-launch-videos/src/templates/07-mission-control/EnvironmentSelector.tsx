import {useCurrentFrame} from 'remotion';
import {easeInOut, progress} from '../../shared';
import type {MissionControlConfig} from './config';

type Environment = 'ubuntu' | 'macos' | 'windows';

const EnvironmentIcon = ({environment, size}: {environment: Environment; size: number}) =>
  <svg width={size} height={size} viewBox="0 0 32 32" fill="none" aria-hidden>
    {environment === 'macos' ? <path fill="currentColor" d={
      'M22.9 1.6c.3 2.2-.7 4.2-2.1 5.6-1.4 1.4-3.3 2.2-5.2 2 ' +
      '-.3-2.1.7-4.2 2.1-5.6 1.4-1.4 3.4-2.2 5.2-2ZM26.7 24.5 ' +
      'c-1.1 2.4-2.7 5.5-5.4 5.5-1.8 0-2.5-1.1-4.7-1.1-2.2 0-3 1.1-4.7 1.1 ' +
      '-2.7 0-4.5-3.3-5.7-5.7-2.3-4.7-3.1-11.6 1.1-14.5 1.7-1.2 4.3-1.3 6.2-.5 ' +
      '1.3.5 2.3.9 3.2.9 1 0 2.2-.5 3.8-1 2.4-.8 5.2-.2 6.8 1.9 ' +
      '-5.2 2.9-4.5 9.7.8 11.7-.4.7-.8 1.3-1.4 1.7Z'
    } /> : environment === 'ubuntu' ? <g stroke="#e95420" strokeWidth="3.7">
      <circle cx="16" cy="16" r="9" strokeDasharray="13 5.85" transform="rotate(-40 16 16)" />
      {[[5, 16], [21.5, 6.5], [21.5, 25.5]].map(([cx, cy]) =>
        <circle key={cy} cx={cx} cy={cy} r="3.3" fill="#e95420" stroke="none" />)}
    </g> : <g>
      <path fill="#f25022" d="M2 2h13v13H2z" />
      <path fill="#7fba00" d="M17 2h13v13H17z" />
      <path fill="#00a4ef" d="M2 17h13v13H2z" />
      <path fill="#ffb900" d="M17 17h13v13H17z" />
    </g>}
  </svg>;

export const EnvironmentSelector = ({
  config, width, height, durationInFrames,
}: {
  config: MissionControlConfig; width: number; height: number; durationInFrames: number;
}) => {
  const frame = useCurrentFrame();
  const selector = config.environmentSelector;
  const start = Math.round((durationInFrames - 1) * selector.transitionStartRatio);
  const duration = Math.min(selector.transitionFrames, Math.max(0, durationInFrames - 1 - start));
  const selection = easeInOut(progress(frame, start, duration));
  const selected: Environment = selection < 0.5 ? 'ubuntu' : 'macos';
  const headerHeight = 68;
  const groupHeight = 76 + headerHeight + selector.rowHeight * 3 + 16;
  const scale = Math.min(1, (width - 96) / selector.width, (height - 96) / groupHeight);
  const environments: Environment[] = ['ubuntu', 'macos', 'windows'];
  return <div style={{
    width, height, position: 'relative', background: config.brand.colors.canvas,
    color: config.brand.colors.ink, fontFamily: config.brand.typography.fontFamily,
    fontSize: selector.labelSize, letterSpacing: config.brand.typography.bodyTracking,
  }}>
    <div style={{
      position: 'absolute', width: selector.width, height: groupHeight,
      left: (width - selector.width) / 2, top: (height - groupHeight) / 2,
      transform: `scale(${scale})`, transformOrigin: 'center',
    }}>
      <div style={{height: 56, display: 'flex', alignItems: 'center', gap: 18, paddingLeft: 32}}>
        <EnvironmentIcon environment={selected} size={40} />
        <span>{selector.labels[selected]}</span>
        <svg width="28" height="28" viewBox="0 0 24 24" fill="none">
          <path d="m5 9 7 7 7-7" stroke="currentColor" strokeWidth="2" />
        </svg>
      </div>
      <div style={{
        position: 'absolute', top: 76, width: selector.width,
        height: headerHeight + selector.rowHeight * 3 + 16,
        background: selector.surface, border: `2px solid ${selector.border}`,
        borderRadius: 24, boxSizing: 'border-box',
        boxShadow: '0 16px 32px rgba(25,25,25,0.06)',
      }}>
        <div style={{
          height: headerHeight, paddingLeft: 38, display: 'flex', alignItems: 'center',
          fontSize: selector.labelSize * 0.85, color: config.brand.colors.secondaryInk,
        }}>{selector.labels.hosted}</div>
        <div style={{
          position: 'absolute', left: 14, right: 14, top: headerHeight,
          height: selector.rowHeight, background: selector.highlight, borderRadius: 14,
          transform: `translateY(${selection * selector.rowHeight}px)`,
          display: 'flex', alignItems: 'center', justifyContent: 'flex-end', paddingRight: 34,
        }}>
          <svg width="34" height="34" viewBox="0 0 24 24" fill="none">
            <path d="m4 12 5 5L20 6" stroke="currentColor" strokeWidth="2"
              strokeLinecap="round" strokeLinejoin="round" />
          </svg>
        </div>
        {environments.map((environment) => <div key={environment} style={{
          position: 'relative', height: selector.rowHeight, padding: '0 38px',
          display: 'flex', alignItems: 'center', gap: 24,
        }}>
          <EnvironmentIcon environment={environment} size={44} />
          <span>{selector.labels[environment]}</span>
          {environment === 'ubuntu' ? <svg width="30" height="30" viewBox="0 0 24 24">
            <path fill="currentColor"
              d="m12 2 3.1 6.3 6.9 1-5 4.9 1.2 6.8L12 17.8 5.8 21 7 14.2 2 9.3l6.9-1Z" />
          </svg> : null}
        </div>)}
      </div>
    </div>
  </div>;
};
