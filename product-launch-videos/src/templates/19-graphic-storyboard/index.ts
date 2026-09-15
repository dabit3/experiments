import {defineTemplate} from '../../shared';
import {config} from './config';
import manifest from './manifest.json';
import {Template} from './Template';

export const template = defineTemplate({
  ...manifest,
  schemaVersion: 1,
  Component: Template,
  defaultConfig: config,
  controls: [
    {path: 'copy', label: 'Launch copy', type: 'string', description: 'Complete approved title, benefit, seven captions, CTA and URL strings.'},
    {path: 'media', label: 'Source selections', type: 'string', description: 'Source filenames, video offsets and per-source fit / crop / anchorX / anchorY.'},
    {path: 'durations', label: 'Scene durations', type: 'string', description: 'Seven seconds values. Metadata derives the total; clips must fit their source duration.'},
    {path: 'brand', label: 'Brand tokens', type: 'string', description: 'Neutral colors, original font families, type sizes, tracking, line heights and intro padding.'},
    {path: 'layout', label: 'Page geometry', type: 'string', description: 'Margins, gutter, source padding, caption height and grid top, context dimensions, border width, logo width.'},
    {path: 'storyboard.readingOrder', label: 'Reading direction', type: 'string', description: 'left-to-right or right-to-left mirrors panel placement and gutter movement without changing the narrative order.'},
    {path: 'storyboard.arrangements', label: 'Panel arrangements', type: 'string', description: 'Product scenes accept side, stack or full; intro and closing use their dedicated triptych/full compositions.'},
    {path: 'storyboard.introFractions', label: 'Intro panel proportions', type: 'string', description: 'Three positive proportional widths for identity, opening title and benefit panels.'},
    {path: 'storyboard.introLabels', label: 'Intro panel labels', type: 'string', description: 'Three editable labels within the introductory typographic panels.'},
    {path: 'storyboard.chapterNames', label: 'Panel names', type: 'string', description: 'Editorial names retained on the quiet previous-panel spines.'},
    {path: 'storyboard.edition', label: 'Edition heading', type: 'string', description: 'Small top-right margin heading.'},
    {path: 'storyboard.montageLabel', label: 'Montage disclosure', type: 'string', description: 'Persistent separate-session disclosure in the bottom margin.'},
    {path: 'storyboard.stillLabel', label: 'Still disclosure', type: 'string', description: 'Header label identifying authentic Simulator screenshots as stills.'},
    {path: 'storyboard.recordingLabel', label: 'Recording disclosure', type: 'string', description: 'Header label for unchanged-speed recordings; Web QA example is additionally enforced by the shared component.'},
    {path: 'storyboard.closingLogo', label: 'Closing logo', type: 'string', description: 'Original white transparent lockup and its aspect-preserving framing.'},
    {path: 'motion.gutterFrames', label: 'Gutter travel', type: 'number', description: 'Frames to collapse the previous panel and expand the active panel, capped to a quarter of each scene.', min: 0, max: 40, step: 1},
    {path: 'motion.stillEntryFraction', label: 'Still entry size', type: 'number', description: 'Initial active proportion before the boundary expands to its reading stop.', min: 0.5, max: 0.95, step: 0.01},
    {path: 'motion.videoEntryFraction', label: 'Recording entry size', type: 'number', description: 'Large initial viewport ensures actions remain visible at source speed during expansion.', min: 0.85, max: 0.95, step: 0.01},
    {path: 'motion.introStaggerFrames', label: 'Intro stagger', type: 'number', description: 'Frame offset between title-panel boundary reveals.', min: 0, max: 20, step: 1},
    {path: 'motion.iphoneSplit', label: 'iPhone still split', type: 'number', description: 'Fraction of the iPhone scene before the second separate-session still.', min: 0.3, max: 0.7, step: 0.01},
    {path: 'motion.stillBoundaryFrames', label: 'Still boundary', type: 'number', description: 'Frames for the clean gutter reveal between authentic iPhone stills.', min: 0, max: 30, step: 1},
    {path: 'motion.closingResultFraction', label: 'Closing result hold', type: 'number', description: 'Fraction of closing spent on the unchanged final iPad result before the CTA panel opens.', min: 0.2, max: 0.6, step: 0.01},
    {path: 'motion.closingBoundaryFrames', label: 'Closing reveal', type: 'number', description: 'Frames for the final full-panel CTA reveal.', min: 0, max: 40, step: 1},
    {path: 'motion.contextOpacity', label: 'Quiet panel type', type: 'number', description: 'Opacity of previous-panel spine labels.', min: 0.3, max: 1, step: 0.01},
  ],
});
