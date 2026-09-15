import {defaultLaunchConfig, type LaunchConfig} from '../../shared';

export type PureProductConfig = LaunchConfig & {
  motion: {
    environmentZoom: number;
    environmentAnchorX: number;
    environmentAnchorY: number;
    environmentContextSeconds: number;
    environmentMoveSeconds: number;
    iphoneFirstFraction: number;
  };
  labels: {
    montage: string;
    environment: string;
    agent: string;
    iphone: [string, string];
    webQa: string;
    ipad: string;
    speed: string;
  };
  typography: {
    captionSize: number;
    noteSize: number;
    ctaSize: number;
  };
  titleLayout: {
    inset: number;
    logoWidth: number;
    headingTop: number;
    headingWidth: number;
    urlGap: number;
  };
};

const base = structuredClone(defaultLaunchConfig);

export const config: PureProductConfig = {
  ...base,
  brand: {
    ...base.brand,
    typography: {
      ...base.brand.typography,
      headingSize: 126,
      headingLineHeight: 1.04,
      bodySize: 42,
    },
  },
  media: {
    ...base.media,
    environment: {
      ...base.media.environment,
      framing: {
        fit: 'contain', anchorX: 0.5, anchorY: 0.5,
        crop: {x: 350, y: 330, width: 2300, height: 1250},
      },
    },
    agent: {
      ...base.media.agent,
      framing: {
        fit: 'contain', anchorX: 0.5, anchorY: 0.5,
        crop: {x: 300, y: 65, width: 1440, height: 820},
      },
    },
  },
  layout: {
    margin: 36,
    gutter: 24,
    padding: 20,
    captionHeight: 122,
    grid: {footerHeight: 48, webQaLabelHeight: 44, captionInset: 72},
  },
  motion: {
    environmentZoom: 1.16,
    environmentAnchorX: 0.62,
    environmentAnchorY: 0.72,
    environmentContextSeconds: 0.8,
    environmentMoveSeconds: 0.6,
    iphoneFirstFraction: 0.5,
  },
  labels: {
    montage: 'Examples from separate sessions',
    environment: 'Hosted environment · screenshot',
    agent: 'Agent selection · original recording',
    iphone: [
      'Afterhours Maze · Simulator still',
      'Large Dispatch · Simulator still',
    ],
    webQa: 'Test review · original recording',
    ipad: 'Terra Table · Simulator still',
    speed: 'Playback',
  },
  typography: {captionSize: 44, noteSize: 24, ctaSize: 46},
  titleLayout: {
    inset: 108,
    logoWidth: 234,
    headingTop: 340,
    headingWidth: 1440,
    urlGap: 20,
  },
};
