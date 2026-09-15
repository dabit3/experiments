import {defineTemplate, type ConfigControl} from '../../shared';
import {config} from './config';
import {Template} from './Template';
import manifest from './manifest.json';

const motionControls: ConfigControl[] = [
  {path: 'motion.typingFrames', label: 'Line entry', type: 'number', description: 'Frames to complete editorial text; capped at one quarter of the scene.', min: 0, max: 45, step: 1},
  {path: 'motion.lineDelayFrames', label: 'Line pause', type: 'number', description: 'Pause between the opening line and benefit.', min: 0, max: 45, step: 1},
  {path: 'motion.baselineRevealFrames', label: 'Baseline expansion', type: 'number', description: 'Caret baseline expands into the environment still and closes the final artifact.', min: 0, max: 45, step: 1},
  {path: 'motion.baselineThickness', label: 'Baseline thickness', type: 'number', description: 'Editorial rules in composition pixels.', min: 1, max: 6, step: 1},
  {path: 'motion.caretWidth', label: 'Caret width', type: 'number', description: 'Width of the text caret in pixels.', min: 2, max: 24, step: 1},
  {path: 'motion.caretBlinkFrames', label: 'Caret interval', type: 'number', description: 'Frames per blink state; zero gives a solid caret.', min: 0, max: 60, step: 1},
  {path: 'motion.blinkDuringHolds', label: 'Blink during holds', type: 'boolean', description: 'Off by default so captions and carets stay still over demonstrations.'},
  {path: 'motion.lineTravel', label: 'Line departure', type: 'number', description: 'Opening editorial line travel as the baseline opens.', min: 0, max: 80, step: 1},
  {path: 'motion.iphoneSplit', label: 'iPhone still split', type: 'number', description: 'Fraction of the iPhone section given to Afterhours Maze; remainder is Large Dispatch.', min: 0.2, max: 0.8, step: 0.05},
  {path: 'motion.closingResultFrames', label: 'Final artifact hold', type: 'number', description: 'Terra Table remains visible at the start of the closing scene.', min: 0, max: 45, step: 1},
];

export const template = defineTemplate({
  ...manifest,
  schemaVersion: 1,
  Component: Template,
  defaultConfig: config,
  controls: [
    ...motionControls,
    ...Object.keys(config.copy).map((key): ConfigControl => ({
      path: `copy.${key}`, label: key, type: 'string', description: 'Editable launch copy.',
    })),
    ...Object.keys(config.durations).map((key): ConfigControl => ({
      path: `durations.${key}`, label: `${key} duration`, type: 'number',
      description: 'Seconds; composition metadata derives from the sum. Video trims must fit their sources.',
      min: 1, max: 15, step: 0.1,
    })),
    {path: 'editorial.series', label: 'Editorial series', type: 'string', description: 'Small label identifying terminal-inspired text as editorial.'},
    {path: 'editorial.montage', label: 'Montage context', type: 'string', description: 'Persistent separate-session context.'},
    {path: 'layout.captionHeight', label: 'Caption position', type: 'number', description: 'Reserved top caption area; also positions product viewport.', min: 112, max: 180, step: 1},
    {path: 'layout.margin', label: 'Side margins', type: 'number', description: 'Shared left/right framing margin.', min: 24, max: 100, step: 1},
    {path: 'layout.grid.indexWidth', label: 'Editorial gutter', type: 'number', description: 'Distance between chapter index and text.', min: 40, max: 100, step: 1},
    {path: 'layout.grid.introTop', label: 'Opening baseline position', type: 'number', description: 'Y coordinate of opening statement.', min: 240, max: 480, step: 1},
    {path: 'brand.colors.ink', label: 'Dark presentation surface', type: 'color', description: 'Default verified #191919; source pixels are never recolored.'},
    {path: 'brand.colors.canvas', label: 'Editorial ink', type: 'color', description: 'Light text on the dark presentation surface.'},
    {path: 'brand.typography.headingSize', label: 'Statement size', type: 'number', description: 'Opening and closing title size.', min: 72, max: 128, step: 1},
    {path: 'brand.typography.bodySize', label: 'Caption size', type: 'number', description: 'Main caption size.', min: 30, max: 46, step: 1},
  ],
});
