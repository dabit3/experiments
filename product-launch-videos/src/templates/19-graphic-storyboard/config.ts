import {
  defaultLaunchConfig, logos, type ImageSelection, type LaunchConfig, type SceneId,
} from '../../shared';

export type Arrangement = 'side' | 'stack' | 'full';
export type StoryboardConfig = LaunchConfig & {
  storyboard: {
    readingOrder: 'left-to-right' | 'right-to-left';
    arrangements: Record<SceneId, Arrangement>;
    chapterNames: Record<SceneId, string>;
    edition: string;
    montageLabel: string;
    stillLabel: string;
    recordingLabel: string;
    closingLogo: ImageSelection;
    introFractions: [number, number, number];
    introLabels: [string, string, string];
  };
  motion: {
    gutterFrames: number;
    stillEntryFraction: number;
    videoEntryFraction: number;
    introStaggerFrames: number;
    iphoneSplit: number;
    stillBoundaryFrames: number;
    closingResultFraction: number;
    closingBoundaryFrames: number;
    contextOpacity: number;
  };
};

export const config: StoryboardConfig = {
  ...structuredClone(defaultLaunchConfig),
  layout: {
    margin: 48, gutter: 20, padding: 10, captionHeight: 132,
    grid: {top: 96, contextWidth: 82, contextHeight: 42, borderWidth: 1, logoWidth: 148},
  },
  storyboard: {
    readingOrder: 'left-to-right',
    arrangements: {
      opening: 'side', environment: 'side', agent: 'side', iphone: 'stack',
      webQa: 'side', ipad: 'full', closing: 'full',
    },
    chapterNames: {
      opening: 'Launch', environment: 'Environment', agent: 'Agent',
      iphone: 'iPhone', webQa: 'Review', ipad: 'Layouts', closing: 'Start',
    },
    edition: 'A launch in seven panels',
    montageLabel: 'Separate session examples',
    stillLabel: 'Simulator still',
    recordingLabel: 'Source recording · 1×',
    closingLogo: {
      asset: logos.white, framing: {fit: 'contain', anchorX: 0, anchorY: 0.5},
    },
    introFractions: [0.18, 0.59, 0.23],
    introLabels: ['Devin on Mac', 'Launch', 'iOS in the cloud'],
  },
  motion: {
    gutterFrames: 20,
    stillEntryFraction: 0.64,
    videoEntryFraction: 0.92,
    introStaggerFrames: 9,
    iphoneSplit: 0.5,
    stillBoundaryFrames: 12,
    closingResultFraction: 0.44,
    closingBoundaryFrames: 18,
    contextOpacity: 0.58,
  },
};
