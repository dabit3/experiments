import {defaultLaunchConfig, type LaunchConfig} from '../../shared';

export type PaperConfig = LaunchConfig & {
  paper: {
    layers: number;
    layerOffsetX: number;
    layerOffsetY: number;
    foldWidth: number;
    shadowStrength: number;
    textureOpacity: number;
    captionSize: number;
    labelSize: number;
    titleWidth: number;
    closingImageWidth: number;
    labels: {
      opening: string;
      environment: string;
      agent: string;
      iphoneFirst: string;
      iphoneSecond: string;
      webQa: string;
      ipad: string;
      closing: string;
    };
  };
  motion: {
    sleeveFrames: number;
    titleRevealFrames: number;
    dividerLift: number;
    foldAngle: number;
    iphoneSplit: number;
    sleeveDirection: 'left' | 'right';
  };
};

export const config: PaperConfig = {
  ...structuredClone(defaultLaunchConfig),
  brand: {
    ...structuredClone(defaultLaunchConfig.brand),
    typography: {
      ...defaultLaunchConfig.brand.typography,
      headingSize: 140,
      bodySize: 40,
    },
  },
  layout: {
    margin: 44,
    gutter: 28,
    padding: 18,
    captionHeight: 126,
    grid: {mediaTop: 44, captionGap: 24, captionIndexWidth: 92},
  },
  media: {
    ...structuredClone(defaultLaunchConfig.media),
    environment: {
      asset: 'devin-web-4.png',
      framing: {
        fit: 'contain', anchorX: 0.5, anchorY: 0.5,
        crop: {x: 550, y: 430, width: 1900, height: 1000},
      },
    },
  },
  paper: {
    layers: 3,
    layerOffsetX: 9,
    layerOffsetY: 7,
    foldWidth: 34,
    shadowStrength: 0.13,
    textureOpacity: 0.028,
    captionSize: 40,
    labelSize: 24,
    titleWidth: 1140,
    closingImageWidth: 850,
    labels: {
      opening: 'Cloud environments',
      environment: 'Hosted environment',
      agent: 'Agent selection · 1× recording',
      iphoneFirst: 'Afterhours Maze · iPhone Simulator still',
      iphoneSecond: 'Large Dispatch · separate iPhone Simulator still',
      webQa: 'Recorded review · 1× playback',
      ipad: 'Terra Table · separate iPad Simulator still',
      closing: 'Large Dispatch · iPhone Simulator still',
    },
  },
  motion: {
    sleeveFrames: 20,
    titleRevealFrames: 24,
    dividerLift: 16,
    foldAngle: 66,
    iphoneSplit: 0.5,
    sleeveDirection: 'left',
  },
};
