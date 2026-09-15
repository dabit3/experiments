import {defineTemplate, type ConfigControl} from '../../shared';
import {config} from './config';
import {Template} from './Template';
import manifest from './manifest.json';

const paperControls: ConfigControl[] = [
  {path: 'paper.layers', label: 'Paper layers', type: 'number', description: 'Number of matte backing sheets.', min: 1, max: 4, step: 1},
  {path: 'paper.layerOffsetX', label: 'Horizontal layer offset', type: 'number', description: 'Backing-sheet displacement in pixels.', min: 0, max: 16},
  {path: 'paper.layerOffsetY', label: 'Vertical layer offset', type: 'number', description: 'Backing-sheet displacement in pixels.', min: 0, max: 12},
  {path: 'paper.foldWidth', label: 'Folded margin', type: 'number', description: 'Width of the return flap outside the media.', min: 12, max: 48},
  {path: 'paper.shadowStrength', label: 'Shadow strength', type: 'number', description: 'Paper-only contact and lifted shadow opacity.', min: 0, max: 0.3, step: 0.01},
  {path: 'paper.textureOpacity', label: 'Matte texture', type: 'number', description: 'Subtle deterministic ruled grain, only on paper.', min: 0, max: 0.06, step: 0.005},
  {path: 'paper.titleWidth', label: 'Title width', type: 'number', description: 'Opening title line-wrap width in pixels.', min: 800, max: 1250},
  {path: 'paper.closingImageWidth', label: 'Final result width', type: 'number', description: 'Width of the flat result card beside the CTA.', min: 680, max: 950},
  {path: 'paper.captionSize', label: 'Caption size', type: 'number', description: 'Stable caption-strip text size.', min: 28, max: 46},
  {path: 'paper.labelSize', label: 'Secondary label size', type: 'number', description: 'Source context label size.', min: 20, max: 28},
  {path: 'motion.sleeveFrames', label: 'Sleeve motion', type: 'number', description: 'Frames to uncover still images; automatically capped for short scenes.', min: 0, max: 40},
  {path: 'motion.titleRevealFrames', label: 'Title slide', type: 'number', description: 'Final opening frames used to slide the title away.', min: 0, max: 45},
  {path: 'motion.dividerLift', label: 'Divider lift', type: 'number', description: 'Maximum pixel displacement of the margin-only divider.', min: 0, max: 28},
  {path: 'motion.foldAngle', label: 'Fold angle', type: 'number', description: 'Maximum rotation of blank presentation paper only.', min: 0, max: 80},
  {path: 'motion.iphoneSplit', label: 'iPhone still split', type: 'number', description: 'Proportion of iPhone scene allocated to its first still.', min: 0.3, max: 0.7, step: 0.05},
  {path: 'motion.sleeveDirection', label: 'Sleeve direction', type: 'string', description: 'left or right; controls the horizontal still-image sleeve.'},
];

export const template = defineTemplate({
  ...manifest,
  schemaVersion: 1,
  Component: Template,
  defaultConfig: config,
  controls: [
    ...paperControls,
    ...Object.keys(config.copy).map((key): ConfigControl => ({
      path: `copy.${key}`, label: `Copy: ${key}`, type: 'string', description: 'Editable launch copy.',
    })),
    ...Object.keys(config.durations).map((key): ConfigControl => ({
      path: `durations.${key}`, label: `Duration: ${key}`, type: 'number',
      description: 'Seconds; composition metadata updates automatically. Video scenes must fit their source.', min: 0.1, max: 60,
    })),
    ...Object.keys(config.paper.labels).map((key): ConfigControl => ({
      path: `paper.labels.${key}`, label: `Source label: ${key}`, type: 'string',
      description: 'Editorial context; keep stills and separate examples accurately labeled.',
    })),
    ...Object.keys(config.brand.colors).map((key): ConfigControl => ({
      path: `brand.colors.${key}`, label: `Color: ${key}`, type: 'color',
      description: 'Presentation material only; never recolors source UI.',
    })),
    {path: 'media', label: 'Media and crop anchors', type: 'string', description: 'Edit typed media selections, framing.anchorX/Y, fit, crop, and sourceStartSeconds in the complete config JSON.'},
    {path: 'brand.typography', label: 'Typography', type: 'string', description: 'Font family, sizes, line heights, and tracking in the typed config. Original bundled fonts are awaited.'},
    {path: 'layout', label: 'Layout', type: 'string', description: 'Margin, gutter, padding, captionHeight and grid positions in the typed config.'},
  ],
});
