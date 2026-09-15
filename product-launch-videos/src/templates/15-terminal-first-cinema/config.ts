import {defaultLaunchConfig, logos, type LaunchConfig} from '../../shared';

export type TerminalConfig = LaunchConfig & {
  editorial: {
    series: string;
    montage: string;
    imageLabel: string;
    videoLabel: string;
    sectionNames: [string, string, string, string, string];
    openingLabel: string;
    closingLabel: string;
  };
  motion: {
    typingFrames: number;
    lineDelayFrames: number;
    baselineRevealFrames: number;
    baselineThickness: number;
    caretWidth: number;
    caretBlinkFrames: number;
    blinkDuringHolds: boolean;
    lineTravel: number;
    iphoneSplit: number;
    closingResultFrames: number;
  };
};

export const config: TerminalConfig = {
  ...structuredClone(defaultLaunchConfig),
  brand: {
    ...structuredClone(defaultLaunchConfig.brand),
    typography: {
      ...defaultLaunchConfig.brand.typography,
      headingSize: 112,
      bodySize: 40,
    },
  },
  media: {
    ...structuredClone(defaultLaunchConfig.media),
    logo: {asset: logos.white, framing: {fit: 'contain', anchorX: 1, anchorY: 0.5}},
    environment: {
      asset: 'devin-web-4.png',
      framing: {
        fit: 'contain', anchorX: 0.5, anchorY: 0.5,
        crop: {x: 560, y: 430, width: 1880, height: 960},
      },
    },
  },
  layout: {
    margin: 48,
    gutter: 32,
    padding: 16,
    captionHeight: 124,
    grid: {indexWidth: 56, footerHeight: 40, introTop: 356, logoWidth: 156, logoHeight: 50},
  },
  editorial: {
    series: 'LAUNCH NOTES',
    montage: 'Separate session examples',
    imageLabel: 'Simulator still',
    videoLabel: 'Recording · 1×',
    sectionNames: ['Hosted environment', 'Agent selection', 'iPhone Simulator', 'Test review', 'iPad Simulator'],
    openingLabel: 'SIMULATOR WORKFLOWS',
    closingLabel: 'START HERE',
  },
  motion: {
    typingFrames: 20,
    lineDelayFrames: 14,
    baselineRevealFrames: 18,
    baselineThickness: 2,
    caretWidth: 12,
    caretBlinkFrames: 15,
    blinkDuringHolds: false,
    lineTravel: 26,
    iphoneSplit: 0.5,
    closingResultFrames: 18,
  },
};
