import {interpolate} from 'remotion';
import type {JourneyConfig} from './config';

type Platform = 'ubuntu' | 'macos' | 'windows';

const PlatformIcon = ({platform, size}: {platform: Platform; size: number}) =>
  <svg width={size} height={size} viewBox="0 0 48 48" style={{flexShrink: 0}}>
    {platform === 'ubuntu' ? <g stroke="#ed7137" fill="#ed7137">
      <circle cx="24" cy="24" r="14" fill="none" strokeWidth="5" />
      {[[8, 24], [32, 10], [32, 38]].map(([cx, cy]) =>
        <circle key={cy} cx={cx} cy={cy} r="5" stroke="white" strokeWidth="3" />)}
    </g> : platform === 'macos' ? <g fill="#888888">
      <path d="M32 3c0 7-4 11-10 11 0-6 4-10 10-11Z" />
      <path d="M24 17c-5 0-6-3-11-1C0 21 9 43 15 45c3 1 6-2 9-2s6 3 9 2c3-1 6-5 8-10-8-3-9-12-2-16-4-6-10-5-15-2Z" />
    </g> : <g>
      <path fill="#f35325" d="M4 4h18v18H4z" />
      <path fill="#81bc06" d="M26 4h18v18H26z" />
      <path fill="#05a6f0" d="M4 26h18v18H4z" />
      <path fill="#ffba08" d="M26 26h18v18H26z" />
    </g>}
  </svg>;

const Check = ({size, color}: {size: number; color: string}) =>
  <svg width={size} height={size} viewBox="0 0 48 48">
    <path d="m9 25 10 10L39 13" fill="none" stroke={color} strokeWidth="3"
      strokeLinecap="round" strokeLinejoin="round" />
  </svg>;

export const EnvironmentMenu = ({
  config, frame, durationInFrames, width, height,
}: {
  config: JourneyConfig;
  frame: number;
  durationInFrames: number;
  width: number;
  height: number;
}) => {
  const menu = config.environmentMenu;
  if (!Number.isFinite(menu.moveStart) || !Number.isFinite(menu.selectAt) ||
      menu.moveStart < 0 || menu.selectAt <= menu.moveStart || menu.selectAt > 0.75) {
    throw new Error('Environment menu timing needs 0 ≤ moveStart < selectAt ≤ 0.75');
  }
  const {colors} = config.brand;
  const progress = frame / durationInFrames;
  const travel = interpolate(progress, [menu.moveStart, menu.selectAt], [0, 1],
    {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
  const eased = travel * travel * (3 - 2 * travel);
  const selected: Platform = progress >= menu.selectAt ? 'macos' : 'ubuntu';
  const headerHeight = 104;
  const menuTop = 110;
  const cardHeight = headerHeight + menu.rowHeight * 3 + 20;
  const totalHeight = menuTop + cardHeight;
  const scale = Math.min(1, (width - 120) / menu.width, (height - 110) / totalHeight);
  const cursorX = menu.width * 0.71;
  const cursorY = menuTop + headerHeight + menu.rowHeight * (0.5 + eased);
  const click = interpolate(progress, [menu.selectAt, menu.selectAt + 0.08], [0, 1],
    {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
  const cursorOpacity = interpolate(progress, [menu.selectAt + 0.12, menu.selectAt + 0.22], [1, 0],
    {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
  const iconSize = menu.fontSize * 1.12;
  const platforms: Platform[] = ['ubuntu', 'macos', 'windows'];
  return <div style={{
    width, height, position: 'relative', backgroundColor: colors.white, overflow: 'hidden',
  }}>
    <div style={{
      position: 'absolute', left: (width - menu.width * scale) / 2,
      top: (height - totalHeight * scale) / 2, width: menu.width, height: totalHeight,
      transform: `scale(${scale})`, transformOrigin: 'top left', fontSize: menu.fontSize,
      letterSpacing: '-0.02em', lineHeight: 1.2,
    }}>
      <div style={{display: 'flex', alignItems: 'center', gap: 20, height: 72, paddingLeft: 32}}>
        <PlatformIcon platform={selected} size={iconSize} />
        <span>{menu[selected]}</span>
        <svg width="32" height="32" viewBox="0 0 32 32" style={{marginLeft: 8}}>
          <path d="m6 12 10 10 10-10" fill="none" stroke={colors.ink}
            strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" />
        </svg>
      </div>
      <div style={{
        position: 'absolute', top: menuTop, width: menu.width, height: cardHeight,
        border: `2px solid ${colors.mediaMat}`, borderRadius: 30, boxSizing: 'border-box',
        backgroundColor: colors.white, boxShadow: '0 18px 45px rgba(0,0,0,0.055)',
      }}>
        <div style={{
          height: headerHeight, display: 'flex', alignItems: 'center',
          paddingLeft: 38, fontSize: menu.fontSize * 0.85, color: colors.secondaryInk,
        }}>{menu.heading}</div>
        <div style={{
          position: 'absolute', left: 16, right: 16, top: headerHeight,
          height: menu.rowHeight, borderRadius: 20, backgroundColor: colors.mediaMat,
          transform: `translateY(${eased * menu.rowHeight}px)`,
        }} />
        {platforms.map((platform) => <div key={platform} style={{
          height: menu.rowHeight, padding: '0 38px', position: 'relative',
          display: 'flex', alignItems: 'center', gap: 24,
        }}>
          <PlatformIcon platform={platform} size={iconSize} />
          <span>{menu[platform]}</span>
          {platform === 'ubuntu' ? <svg width="40" height="40" viewBox="0 0 40 40"
            style={{marginLeft: 4}}>
            <path d="m20 2 5.5 11.2 12.4 1.8-9 8.7L31 36l-11-5.8L9 36l2.1-12.3-9-8.7 12.4-1.8Z"
              fill={colors.ink} />
          </svg> : null}
          {selected === platform ? <div style={{marginLeft: 'auto', display: 'flex'}}>
            <Check size={44} color={colors.secondaryInk} />
          </div> : null}
        </div>)}
      </div>
      {progress >= menu.selectAt && click < 1 ? <div style={{
        position: 'absolute', left: cursorX - 28, top: cursorY - 28,
        width: 56, height: 56, border: `2px solid ${colors.ink}`, borderRadius: '50%',
        transform: `scale(${0.4 + click})`, opacity: (1 - click) * 0.35,
      }} /> : null}
      <svg width="35" height="43" viewBox="0 0 35 43" style={{
        position: 'absolute', left: cursorX, top: cursorY, opacity: cursorOpacity,
        transform: `scale(${click > 0 && click < 0.5 ? 0.9 : 1})`,
        transformOrigin: 'top left', filter: 'drop-shadow(0 2px 2px rgba(0,0,0,0.2))',
      }}>
        <path d="M2 2v31l8-8 7 15 7-3-7-14h13Z"
          fill={colors.ink} stroke={colors.white} strokeWidth="2" strokeLinejoin="round" />
      </svg>
    </div>
  </div>;
};
