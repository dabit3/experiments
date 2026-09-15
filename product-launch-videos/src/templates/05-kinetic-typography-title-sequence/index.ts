import {defineTemplate, type ConfigControl} from '../../shared';
import {Template} from './Template';
import {config} from './config';
import manifest from './manifest.json';

const motionControls: ConfigControl[] = [
  {path: 'motion.phraseDockFrames', label: 'Phrase docking', type: 'number', min: 0, max: 60, step: 1,
    description: 'Frames for a complete action phrase to settle into its caption rail; bounded to a third of its scene.'},
  {path: 'motion.titleRevealFrames', label: 'Title reveal', type: 'number', min: 0, max: 60, step: 1,
    description: 'Opening whole-phrase reveal duration.'},
  {path: 'motion.phraseTravel', label: 'Phrase travel', type: 'number', min: 0, max: 160, step: 1,
    description: 'Horizontal travel in pixels before the caption becomes still.'},
  {path: 'motion.titleTravel', label: 'Title travel', type: 'number', min: 0, max: 240, step: 1,
    description: 'Vertical travel of complete title blocks behind rectangular type masks.'},
  {path: 'motion.titleLift', label: 'Title lift', type: 'number', min: 0, max: 80, step: 1,
    description: 'Final opening-title displacement as its baseline becomes a frame edge; also closing-pricing entrance travel.'},
  {path: 'motion.ruleThickness', label: 'Baseline thickness', type: 'number', min: 1, max: 8, step: 1,
    description: 'Thickness of the line connecting the phrase container to the media frame.'},
  {path: 'motion.iphoneSplit', label: 'iPhone still split', type: 'number', min: 0.2, max: 0.8, step: 0.05,
    description: 'Fraction of the iPhone scene devoted to the first authentic screenshot.'},
  {path: 'motion.endCardRevealFrames', label: 'End-card reveal', type: 'number', min: 0, max: 60, step: 1,
    description: 'Duration of the feature-name and CTA reveal, then a completely still end card.'},
];

export const template = defineTemplate({
  ...manifest,
  schemaVersion: 1,
  Component: Template,
  defaultConfig: config,
  controls: [
    ...motionControls,
    {path: 'typography.titleSize', label: 'Title maximum size', type: 'number', min: 72, max: 240, step: 1,
      description: 'Titles fit complete words into the configured width and line count.'},
    {path: 'typography.captionSize', label: 'Caption maximum size', type: 'number', min: 30, max: 64, step: 1,
      description: 'Stable action phrase size; automatically reduced for longer copy.'},
    {path: 'typography.phraseSize', label: 'Transition phrase size', type: 'number', min: 48, max: 120, step: 1,
      description: 'Initial phrase size before it becomes a caption; videos keep a fixed source viewport.'},
    {path: 'layout.grid.launchHeaderHeight', label: 'Initial phrase plane', type: 'number', min: 160, max: 280, step: 1,
      description: 'Still-scene phrase-plane height before docking frees the product frame.'},
    {path: 'layout.margin', label: 'Scene margin', type: 'number', min: 32, max: 80, step: 1,
      description: 'Outer composition inset; source pixels remain contained.'},
  ],
});
