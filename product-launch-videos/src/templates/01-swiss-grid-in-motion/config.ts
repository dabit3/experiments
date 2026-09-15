import {defaultLaunchConfig, type LaunchConfig} from '../../shared';

export type SwissConfig = LaunchConfig & {
  layout: LaunchConfig['layout'] & {
    grid: {
      railWidth: number;
      headerHeight: number;
      footerHeight: number;
      titleWidth: number;
      titleTop: number;
      captionTop: number;
      ruleWidth: number;
    };
  };
  motion: {
    panelRevealFrames: number;
    panelTravel: number;
    typeRevealFrames: number;
    typeTravel: number;
    regionStartWidth: number;
    iphoneSplit: number;
  };
  editorial: {
    openingRail: string;
    closingRail: string;
    openingIndex: string;
    closingIndex: string;
    montageLabel: string;
    environmentLabel: string;
    agentLabel: string;
    iphoneLabels: [string, string];
    webQaLabel: string;
    ipadLabel: string;
  };
};

export const config: SwissConfig = {
  ...structuredClone(defaultLaunchConfig),
  brand: {
    ...structuredClone(defaultLaunchConfig.brand),
    typography: {
      ...defaultLaunchConfig.brand.typography,
      headingSize: 164,
      headingLineHeight: 1,
      bodySize: 46,
      bodyLineHeight: 1.08,
    },
  },
  media: {
    ...structuredClone(defaultLaunchConfig.media),
    environment: {
      asset: 'devin-web-4.png',
      framing: {
        fit: 'contain', anchorX: 0.5, anchorY: 0.5,
        crop: {x: 580, y: 465, width: 1830, height: 920},
      },
    },
  },
  layout: {
    margin: 60,
    gutter: 40,
    padding: 0,
    captionHeight: 400,
    grid: {
      railWidth: 240,
      headerHeight: 110,
      footerHeight: 32,
      titleWidth: 1380,
      titleTop: 280,
      captionTop: 350,
      ruleWidth: 1,
    },
  },
  motion: {
    panelRevealFrames: 18,
    panelTravel: 64,
    typeRevealFrames: 14,
    typeTravel: 42,
    regionStartWidth: 0.28,
    iphoneSplit: 0.5,
  },
  editorial: {
    openingRail: '01',
    closingRail: 'Mac',
    openingIndex: 'Launch / Mac',
    closingIndex: 'Devin on Mac',
    montageLabel: 'Examples from separate sessions',
    environmentLabel: 'Hosted environment · Source still',
    agentLabel: 'Agent selection · Recording · 1×',
    iphoneLabels: [
      'iPhone Simulator · Source still 01 / 02',
      'iPhone Simulator · Source still 02 / 02',
    ],
    webQaLabel: 'Recorded test review · 1×',
    ipadLabel: 'iPad Simulator · Source still',
  },
};
