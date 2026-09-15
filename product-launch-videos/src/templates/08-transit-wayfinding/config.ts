import {defaultLaunchConfig, type LaunchConfig, type SceneId} from '../../shared';

export type StopId = Exclude<SceneId, 'opening'>;
export type TransitConfig = LaunchConfig & {
  route: {
    code: string;
    legend: string;
    stillLabel: string;
    departureLabel: string;
    destinationLabel: string;
    stations: {scene: StopId; name: string; x: number; y: number}[];
  };
  motion: {
    arrivalFrames: number;
    mapHoldFrames: number;
    lineTraceFrames: number;
    lineWidth: number;
    markerRadius: number;
    iphoneSplit: number;
  };
};

export const config: TransitConfig = {
  ...structuredClone(defaultLaunchConfig),
  media: {
    ...structuredClone(defaultLaunchConfig.media),
    environment: {
      asset: 'devin-web-4.png',
      framing: {
        fit: 'contain', anchorX: 0.5, anchorY: 0.5,
        crop: {x: 550, y: 400, width: 1900, height: 1040},
      },
    },
  },
  layout: {
    margin: 48,
    gutter: 20,
    padding: 12,
    captionHeight: 132,
    grid: {routeFooterHeight: 72, titleWidth: 1400, introMapY: 735},
  },
  route: {
    code: 'M',
    legend: 'Launch route · examples from separate sessions',
    stillLabel: 'Simulator screenshot · separate session',
    departureLabel: 'Departure / Mac environments',
    destinationLabel: 'Destination / Devin on Mac',
    stations: [
      {scene: 'environment', name: 'Mac', x: 0.05, y: 0.5},
      {scene: 'agent', name: 'Agent', x: 0.23, y: 0.5},
      {scene: 'iphone', name: 'iPhone', x: 0.41, y: 0.5},
      {scene: 'webQa', name: 'Web QA', x: 0.59, y: 0.5},
      {scene: 'ipad', name: 'iPad', x: 0.77, y: 0.5},
      {scene: 'closing', name: 'Devin on Mac', x: 0.95, y: 0.5},
    ],
  },
  motion: {
    arrivalFrames: 16,
    mapHoldFrames: 3,
    lineTraceFrames: 46,
    lineWidth: 5,
    markerRadius: 11,
    iphoneSplit: 0.5,
  },
};
