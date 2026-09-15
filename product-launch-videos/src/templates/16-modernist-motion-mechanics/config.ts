import {defaultLaunchConfig, type LaunchConfig} from '../../shared';

export type ModernistConfig = LaunchConfig & {
  composition: {
    openingTitleWidth: number;
    openingShapeX: number;
    openingShapeY: number;
    openingShapeWidth: number;
    openingShapeHeight: number;
    closingTextWidth: number;
    closingMediaX: number;
    closingMediaY: number;
    closingMediaWidth: number;
    closingMediaHeight: number;
    titleSize: number;
    captionSize: number;
    labelSize: number;
    logoWidth: number;
  };
  geometry: {
    rectangleRole: 'frame' | 'plane';
    lineRole: 'progression' | 'rule';
    showTiles: boolean;
    frameThickness: number;
    lineThickness: number;
    tileSize: number;
  };
  labels: {
    stages: [string, string, string, string, string];
    montage: string;
    still: string;
    result: string;
  };
  motion: {
    revealFrames: number;
    transitionDistance: number;
    openingAssembleFrames: number;
    tileTravel: number;
    closingResolveFrames: number;
    iphoneSplit: number;
    revealAxis: 'x' | 'y';
  };
};

export const config: ModernistConfig = {
  ...structuredClone(defaultLaunchConfig),
  media: {
    ...structuredClone(defaultLaunchConfig.media),
    environment: {
      asset: 'devin-web-4.png',
      framing: {
        fit: 'contain', anchorX: 0.5, anchorY: 0.5,
        crop: {x: 550, y: 420, width: 1880, height: 980},
      },
    },
  },
  layout: {
    margin: 60, gutter: 28, padding: 18, captionHeight: 92,
    grid: {railWidth: 60, footerHeight: 28},
  },
  composition: {
    openingTitleWidth: 1150,
    openingShapeX: 1320,
    openingShapeY: 256,
    openingShapeWidth: 540,
    openingShapeHeight: 448,
    closingTextWidth: 700,
    closingMediaX: 842,
    closingMediaY: 228,
    closingMediaWidth: 1018,
    closingMediaHeight: 560,
    titleSize: 136,
    captionSize: 48,
    labelSize: 24,
    logoWidth: 172,
  },
  geometry: {
    rectangleRole: 'frame',
    lineRole: 'progression',
    showTiles: true,
    frameThickness: 2,
    lineThickness: 3,
    tileSize: 60,
  },
  labels: {
    stages: ['Environment', 'Agent', 'iPhone', 'Web QA', 'iPad'],
    montage: 'Examples from separate sessions',
    still: 'Simulator still',
    result: 'iPad Simulator · Still',
  },
  motion: {
    revealFrames: 18,
    transitionDistance: 160,
    openingAssembleFrames: 26,
    tileTravel: 44,
    closingResolveFrames: 24,
    iphoneSplit: 0.5,
    revealAxis: 'x',
  },
};
