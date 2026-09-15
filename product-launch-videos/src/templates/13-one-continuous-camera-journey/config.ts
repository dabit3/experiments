import {defaultLaunchConfig, type LaunchConfig} from '../../shared';

export const stopIds = [
  'opening', 'environment', 'agent', 'iphoneFirst', 'iphoneSecond', 'webQa', 'ipad', 'closing',
] as const;
export type StopId = typeof stopIds[number];
export type Point = {x: number; y: number};
export type JourneyConfig = LaunchConfig & {
  canvas: {
    stops: Record<StopId, Point>;
    railY: number;
    titleSize: number;
    titleWidth: number;
    logoWidth: number;
    captionSize: number;
    labelSize: number;
    mediaTop: number;
    mediaBottom: number;
  };
  labels: {
    introduction: string;
    environment: string;
    agent: string;
    iphoneFirst: string;
    iphoneSecond: string;
    webQa: string;
    ipad: string;
    closing: string;
    montage: string;
  };
  motion: {
    travelSeconds: number;
    iphoneSplit: number;
    travelPullback: number;
    railWeight: number;
  };
};

export const config: JourneyConfig = {
  ...structuredClone(defaultLaunchConfig),
  layout: {margin: 60, gutter: 60, padding: 12, captionHeight: 100, grid: {}},
  media: {
    ...structuredClone(defaultLaunchConfig.media),
    environment: {
      asset: 'devin-web-4.png',
      framing: {
        fit: 'contain', anchorX: 0.5, anchorY: 0.5,
        crop: {x: 560, y: 440, width: 1920, height: 990},
      },
    },
  },
  canvas: {
    stops: {
      opening: {x: 0, y: 0},
      environment: {x: 2100, y: 0},
      agent: {x: 4200, y: 0},
      iphoneFirst: {x: 6300, y: 0},
      iphoneSecond: {x: 8400, y: 0},
      webQa: {x: 10500, y: 0},
      ipad: {x: 12600, y: 0},
      closing: {x: 14700, y: 0},
    },
    railY: 1054,
    titleSize: 164,
    titleWidth: 1380,
    logoWidth: 258,
    captionSize: 48,
    labelSize: 24,
    mediaTop: 155,
    mediaBottom: 104,
  },
  labels: {
    introduction: 'A new environment.',
    environment: 'Hosted environment',
    agent: 'Agent selection · 1×',
    iphoneFirst: 'iPhone · Afterhours Maze · still',
    iphoneSecond: 'iPhone · Large Dispatch · still',
    webQa: 'Recorded review · 1×',
    ipad: 'iPad · Terra Table · still',
    closing: 'Your next session.',
    montage: 'Separate sessions. One launch montage.',
  },
  motion: {
    travelSeconds: 0.6,
    iphoneSplit: 0.5,
    travelPullback: 0.025,
    railWeight: 2,
  },
};
