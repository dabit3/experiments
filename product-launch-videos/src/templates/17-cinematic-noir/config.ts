import {defaultLaunchConfig, logos, type LaunchConfig} from '../../shared';

export type NoirConfig = LaunchConfig & {
  labels: {
    montage: string;
    still: string;
    recording: string;
  };
  motion: {
    shutterFrames: number;
    shutterAxis: 'horizontal' | 'vertical';
    slitSize: number;
    slitPhase: number;
    stillExitFrames: number;
    intertitleFrames: number;
    titleFadeFrames: number;
    resultHoldFrames: number;
    iphoneSplit: number;
    edgeLightOpacity: number;
    edgeLightLength: number;
    edgeLightTravel: number;
    lightingEnabled: boolean;
  };
};

export const config: NoirConfig = {
  ...structuredClone(defaultLaunchConfig),
  brand: {
    ...structuredClone(defaultLaunchConfig.brand),
    typography: {
      ...defaultLaunchConfig.brand.typography,
      headingSize: 128,
      bodySize: 44,
      bodyLineHeight: 1.2,
    },
  },
  media: {
    ...structuredClone(defaultLaunchConfig.media),
    logo: {
      asset: logos.white,
      framing: {fit: 'contain', anchorX: 0, anchorY: 0.5},
    },
    environment: {
      asset: 'devin-web-4.png',
      framing: {
        fit: 'contain', anchorX: 0.5, anchorY: 0.5,
        crop: {x: 560, y: 410, width: 1920, height: 1030},
      },
    },
  },
  layout: {
    margin: 64,
    gutter: 30,
    padding: 12,
    captionHeight: 90,
    grid: {
      titleLeft: 148,
      titleTop: 366,
      titleWidth: 1220,
      benefitWidth: 1040,
      logoWidth: 230,
      titleLineY: 862,
      footerSize: 22,
      captionSize: 44,
    },
  },
  labels: {
    montage: 'Separate session examples',
    still: 'Simulator still',
    recording: 'Source recording · 1×',
  },
  motion: {
    shutterFrames: 24,
    shutterAxis: 'horizontal',
    slitSize: 2,
    slitPhase: 0.3,
    stillExitFrames: 8,
    intertitleFrames: 18,
    titleFadeFrames: 12,
    resultHoldFrames: 30,
    iphoneSplit: 0.5,
    edgeLightOpacity: 0.32,
    edgeLightLength: 120,
    edgeLightTravel: 100,
    lightingEnabled: true,
  },
};
