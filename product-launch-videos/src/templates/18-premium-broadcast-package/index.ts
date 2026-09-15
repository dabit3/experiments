import {defineTemplate, type ConfigControl} from '../../shared';
import {config} from './config';
import {Template} from './Template';
import manifest from './manifest.json';

const controls: ConfigControl[] = [
  {path: 'motion.wipeFrames', label: 'Still wipe', type: 'number', min: 0, max: 30, step: 1, description: 'Crisp uncover duration for stills; never masks moving footage.'},
  {path: 'motion.stingFrames', label: 'Chapter sting', type: 'number', min: 0, max: 30, step: 1, description: 'Number-tile entrance duration in reserved lower-third space.'},
  {path: 'motion.panelTravel', label: 'Aligned panel travel', type: 'number', min: 0, max: 128, step: 1, description: 'Vertical entrance distance of the numbered lower-third tile.'},
  {path: 'motion.titleRevealFrames', label: 'Title ident reveal', type: 'number', min: 0, max: 45, step: 1, description: 'Horizontal split-panel reveal; title copy remains still.'},
  {path: 'motion.iphoneSplit', label: 'iPhone still split', type: 'number', min: 0.2, max: 0.8, step: 0.05, description: 'Fraction of the iPhone chapter assigned to Afterhours Maze.'},
  {path: 'broadcast.titlePanelFraction', label: 'Title product panel', type: 'number', min: 0.45, max: 0.6, step: 0.01, description: 'Fraction of canvas width reserved for the opening product view.'},
  {path: 'broadcast.captionSize', label: 'Lower-third size', type: 'number', min: 28, max: 54, step: 1, description: 'Stable caption text size in pixels.'},
  {path: 'broadcast.markerSize', label: 'Chapter marker size', type: 'number', min: 18, max: 30, step: 1, description: 'Small stable marker and supporting source labels.'},
  {path: 'broadcast.logoWidth', label: 'Lockup width', type: 'number', min: 160, max: 400, step: 1, description: 'Original transparent lockup width; aspect ratio is preserved.'},
  {path: 'broadcast.montageLabel', label: 'Montage context', type: 'string', description: 'Outside-UI explanation that examples come from separate sessions.'},
  {path: 'layout.margin', label: 'Safe margin', type: 'number', min: 32, max: 80, step: 1, description: 'Outer safe margin in pixels.'},
  {path: 'layout.captionHeight', label: 'Caption reservation', type: 'number', min: 120, max: 180, step: 1, description: 'Reserved lower-third height; product bay resizes automatically.'},
  {path: 'layout.grid.mediaTop', label: 'Product bay top', type: 'number', min: 76, max: 140, step: 1, description: 'Product-bay top edge, below the chapter markers.'},
  ...Object.keys(config.copy).map((key): ConfigControl => ({
    path: `copy.${key}`, label: key, type: 'string', description: 'Editable launch copy; keep supported claims.',
  })),
  ...Object.keys(config.durations).map((key): ConfigControl => ({
    path: `durations.${key}`, label: `${key} seconds`, type: 'number', min: 1, max: key === 'agent' ? 9 : key === 'webQa' ? 59 : 30, step: 0.1,
    description: 'Scene duration drives composition metadata; video trims must remain inside the source.',
  })),
  ...Object.keys(config.brand.colors).map((key): ConfigControl => ({
    path: `brand.colors.${key}`, label: key, type: 'color', description: 'Presentation color; source pixels are never recolored.',
  })),
];

export const template = defineTemplate({
  ...manifest, schemaVersion: 1, Component: Template, defaultConfig: config, controls,
});
