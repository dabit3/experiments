// Timing table (frames at 30fps). Edit here to retime the whole video.
export const FPS = 30;
const s = (seconds: number) => Math.round(seconds * FPS);

export const timing = {
  hook: s(3.5),
  context: s(5.5),
  // Bento scene, in order:
  gridBuild: s(2.5),
  feature: s(6.5), // each of the 4 feature moments
  featureExpand: s(0.7), // expand / collapse duration inside a feature
  summaryHold: s(1.5), // complete grid before it flips to outcomes
  outcomes: s(5),
  brandExpand: s(0.8), // brand tile grows into the end card
  endCard: s(3.5),
};

export const FEATURE_COUNT = 4;

const bentoDuration =
  timing.gridBuild +
  timing.feature * FEATURE_COUNT +
  timing.summaryHold +
  timing.outcomes +
  timing.brandExpand;

export const scenes = {
  hook: { from: 0, duration: timing.hook },
  context: { from: timing.hook, duration: timing.context },
  bento: { from: timing.hook + timing.context, duration: bentoDuration },
  endCard: {
    from: timing.hook + timing.context + bentoDuration,
    duration: timing.endCard,
  },
};

// Local (bento-relative) frame offsets.
export const bento = {
  featureStart: (i: number) => timing.gridBuild + i * timing.feature,
  summaryStart: timing.gridBuild + timing.feature * FEATURE_COUNT,
  outcomesStart: timing.gridBuild + timing.feature * FEATURE_COUNT + timing.summaryHold,
  brandExpandStart:
    timing.gridBuild + timing.feature * FEATURE_COUNT + timing.summaryHold + timing.outcomes,
};

export const TOTAL_FRAMES = scenes.endCard.from + scenes.endCard.duration;
