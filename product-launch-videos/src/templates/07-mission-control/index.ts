import {defineTemplate, type ConfigControl} from '../../shared';
import manifest from './manifest.json';
import {config} from './config';
import {Template} from './Template';

const motionControls: ConfigControl[] = [
  {path: 'motion.apertureFrames', label: 'Opening aperture', type: 'number', min: 0, max: 60, step: 1,
    description: 'Frames for the main display and title mask to open.'},
  {path: 'motion.baySettleFrames', label: 'Bay settle', type: 'number', min: 0, max: 60, step: 1,
    description: 'Frames for the contextual bays to settle on the fixed rail.'},
  {path: 'motion.bayStaggerFrames', label: 'Bay stagger', type: 'number', min: 0, max: 20, step: 1,
    description: 'Delay in frames between source-index bay arrivals.'},
  {path: 'motion.bayTravel', label: 'Bay travel', type: 'number', min: 0, max: 120, step: 1,
    description: 'Horizontal pixels used for rail arrival and final consolidation.'},
  {path: 'motion.selectionFrames', label: 'Selection rule', type: 'number', min: 0, max: 45, step: 1,
    description: 'Frames for the short rule linking the selected bay to the main view.'},
  {path: 'motion.consolidationFrames', label: 'Closing consolidation', type: 'number', min: 0, max: 60, step: 1,
    description: 'Frames for the primary display to expand into the final hero.'},
  {path: 'motion.openingWidthRatio', label: 'Opening display width', type: 'number', min: 0.6, max: 1, step: 0.01,
    description: 'Initial aperture width relative to the resting primary display.'},
  {path: 'motion.iphoneSplitRatio', label: 'iPhone still split', type: 'number', min: 0.2, max: 0.8, step: 0.01,
    description: 'Fraction of the iPhone scene reserved for Afterhours Maze, then Large Dispatch.'},
];

export const template = defineTemplate({
  ...manifest,
  schemaVersion: 1,
  Component: Template,
  defaultConfig: config,
  controls: [
    ...motionControls,
    ...Object.keys(config.panels).map((key): ConfigControl => ({
      path: `panels.${key}`, label: key, type: 'number',
      description: 'Display geometry in 1920 × 1080 composition pixels.',
    })),
    {path: 'status.activeBorder', label: 'Selected bay outline', type: 'color',
      description: 'Editorial selection treatment, never an execution status.'},
    {path: 'status.inactiveBorder', label: 'Reference bay outline', type: 'string',
      description: 'CSS color for fixed reference surfaces.'},
    {path: 'status.activeFill', label: 'Selected bay surface', type: 'string',
      description: 'CSS fill for the source currently on the main display.'},
    {path: 'status.secondaryText', label: 'Secondary text', type: 'string',
      description: 'Secondary caption and index color.'},
    {path: 'status.outlineWidth', label: 'Bay outline width', type: 'number',
      min: 1, max: 4, step: 1, description: 'Bay outline width in pixels.'},
    {path: 'status.showSelectionLabel', label: 'Show selection labels', type: 'boolean',
      description: 'Show ON MAIN DISPLAY or REFERENCE in each source bay.'},
  ],
});
