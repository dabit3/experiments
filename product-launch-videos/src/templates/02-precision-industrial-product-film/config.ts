import {defaultLaunchConfig, type Crop, type LaunchConfig} from '../../shared';

export type CameraBox = {x: number; y: number; width: number; height: number};

export type IndustrialConfig = LaunchConfig & {
  camera: {
    opening: CameraBox;
    closing: CameraBox;
    detailCrop: Crop;
    contextCrop: Crop;
  };
  lighting: {
    keyX: number;
    keyY: number;
    keyStrength: number;
    falloffStrength: number;
    shadowOpacity: number;
    shadowBlur: number;
    shadowDrop: number;
  };
  typography: {
    captionSize: number;
    closingSize: number;
    ctaSize: number;
    noteSize: number;
    openingTextWidth: number;
    closingTextX: number;
    closingTextY: number;
    closingTextWidth: number;
  };
  labels: {
    montage: string;
    environment: string;
    agent: string;
    iphoneFirst: string;
    iphoneSecond: string;
    webQa: string;
    ipad: string;
    closing: string;
  };
  motion: {
    detailHoldFraction: number;
    pullbackEndFraction: number;
    settleFrames: number;
    transitionTiltDegrees: number;
    perspective: number;
    iphoneSplit: number;
    closingTravelFrames: number;
  };
};

export const config: IndustrialConfig = {
  ...structuredClone(defaultLaunchConfig),
  layout: {
    margin: 60,
    gutter: 40,
    padding: 2,
    captionHeight: 82,
    grid: {captionY: 39, noteY: 1046, closingHeadingY: 39, closingLogoY: 790},
  },
  camera: {
    opening: {x: 826, y: 270, width: 1028, height: 640},
    closing: {x: 72, y: 275, width: 1210, height: 660},
    detailCrop: {x: 600, y: 850, width: 1400, height: 760},
    contextCrop: {x: 400, y: 420, width: 2180, height: 1180},
  },
  lighting: {
    keyX: 32,
    keyY: 18,
    keyStrength: 0.88,
    falloffStrength: 0.065,
    shadowOpacity: 0.14,
    shadowBlur: 38,
    shadowDrop: 22,
  },
  typography: {
    captionSize: 46,
    closingSize: 56,
    ctaSize: 47,
    noteSize: 20,
    openingTextWidth: 660,
    closingTextX: 1374,
    closingTextY: 410,
    closingTextWidth: 470,
  },
  labels: {
    montage: 'A montage of separate sessions',
    environment: 'Hosted environment · interface detail',
    agent: 'Agent selection · recording',
    iphoneFirst: 'iPhone Simulator · still 01 / 02',
    iphoneSecond: 'iPhone Simulator · still 02 / 02',
    webQa: 'Recorded testing · separate web session',
    ipad: 'iPad Simulator · still',
    closing: 'iPad Simulator · stable result',
  },
  motion: {
    detailHoldFraction: 0.18,
    pullbackEndFraction: 1,
    settleFrames: 34,
    transitionTiltDegrees: 1.8,
    perspective: 2600,
    iphoneSplit: 0.5,
    closingTravelFrames: 28,
  },
};
