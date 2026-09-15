import {defaultLaunchConfig, type LaunchConfig} from '../../shared';

export type CinemaConfig = LaunchConfig & {
  archive: {
    title: string;
    context: string;
    labels: [string, string, string, string, string, string];
    kinds: [string, string, string, string, string, string];
    agentIndexFrame: number;
    webQaIndexFrame: number;
    agentFreezeFrame: number;
    webQaFreezeFrame: number;
  };
  motion: {
    returnFrames: number;
    indexHoldFrames: number;
    expandFrames: number;
    openingExpandFrames: number;
    iphoneSplit: number;
    selectionStroke: number;
  };
};

export const config: CinemaConfig = {
  ...structuredClone(defaultLaunchConfig),
  media: {
    ...structuredClone(defaultLaunchConfig.media),
    environment: {
      asset: 'devin-web-4.png',
      framing: {
        fit: 'contain', anchorX: 0.5, anchorY: 0.5,
        crop: {x: 540, y: 410, width: 1900, height: 1080},
      },
    },
  },
  layout: {
    margin: 60,
    gutter: 40,
    padding: 4,
    captionHeight: 88,
    grid: {
      top: 358,
      rowGap: 66,
      tileHeight: 258,
      heroTop: 98,
      closingHeroTop: 126,
      closingHeroHeight: 704,
    },
  },
  archive: {
    title: 'Selected frames',
    context: 'A montage of separate sessions',
    labels: ['Mac environment', 'Agent selection', 'Afterhours Maze', 'Large Dispatch', 'Recorded web tests', 'Terra Table'],
    kinds: ['STILL', 'RECORDING', 'IPHONE STILL', 'IPHONE STILL', 'WEB QA EXAMPLE', 'IPAD STILL'],
    agentIndexFrame: 0,
    webQaIndexFrame: 0,
    agentFreezeFrame: -1,
    webQaFreezeFrame: -1,
  },
  motion: {
    returnFrames: 10,
    indexHoldFrames: 8,
    expandFrames: 14,
    openingExpandFrames: 32,
    iphoneSplit: 0.5,
    selectionStroke: 3,
  },
};
