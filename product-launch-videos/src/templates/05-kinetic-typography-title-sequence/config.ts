import {defaultLaunchConfig, type LaunchConfig} from '../../shared';

export type KineticConfig = LaunchConfig & {
  typography: {
    titleSize: number;
    titleMinSize: number;
    captionSize: number;
    captionMinSize: number;
    phraseSize: number;
    labelSize: number;
    titleMaxLines: number;
  };
  labels: {
    environment: string;
    agent: string;
    iphone: [string, string];
    webQa: string;
    ipad: string;
  };
  motion: {
    phraseDockFrames: number;
    titleRevealFrames: number;
    phraseTravel: number;
    titleTravel: number;
    titleLift: number;
    ruleThickness: number;
    iphoneSplit: number;
    endCardRevealFrames: number;
  };
};

export const config: KineticConfig = {
  ...structuredClone(defaultLaunchConfig),
  layout: {
    margin: 48,
    gutter: 24,
    padding: 0,
    captionHeight: 96,
    grid: {launchHeaderHeight: 220, labelHeight: 40, titleWidth: 1620, endCardHeight: 212},
  },
  typography: {
    titleSize: 208,
    titleMinSize: 72,
    captionSize: 48,
    captionMinSize: 30,
    phraseSize: 92,
    labelSize: 24,
    titleMaxLines: 3,
  },
  labels: {
    environment: 'Hosted environment',
    agent: 'Agent selection · 1×',
    iphone: ['iPhone Simulator · still 1 / 2', 'iPhone Simulator · still 2 / 2'],
    webQa: 'Test recording · 1×',
    ipad: 'iPad Simulator · still',
  },
  motion: {
    phraseDockFrames: 26,
    titleRevealFrames: 26,
    phraseTravel: 96,
    titleTravel: 120,
    titleLift: 32,
    ruleThickness: 2,
    iphoneSplit: 0.5,
    endCardRevealFrames: 24,
  },
};
