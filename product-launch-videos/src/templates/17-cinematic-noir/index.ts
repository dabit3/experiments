import {defineTemplate, type ConfigControl} from '../../shared';
import manifest from './manifest.json';
import {config} from './config';
import {Template} from './Template';

const motionControls: ConfigControl[] = [
  {path: 'motion.shutterFrames', label: 'Shutter reveal', type: 'number', min: 0, max: 60, step: 1,
    description: 'Two-stage aperture duration in frames; automatically bounded to one quarter of the still hold.'},
  {path: 'motion.shutterAxis', label: 'Shutter axis', type: 'string',
    description: 'horizontal or vertical: the direction of the first narrow slit.'},
  {path: 'motion.slitSize', label: 'Slit size', type: 'number', min: 1, max: 20, step: 1,
    description: 'Initial aperture thickness in composition pixels.'},
  {path: 'motion.slitPhase', label: 'Slit phase', type: 'number', min: 0.05, max: 0.9, step: 0.05,
    description: 'Fraction of reveal devoted to extending the narrow slit before opening across the interface.'},
  {path: 'motion.stillExitFrames', label: 'Still shutter close', type: 'number', min: 0, max: 30, step: 1,
    description: 'Closing shutter between separate iPhone still examples. Recordings are never masked.'},
  {path: 'motion.intertitleFrames', label: 'Quiet iPhone title', type: 'number', min: 0, max: 60, step: 1,
    description: 'Brief title composition at the beginning of the iPhone scene, within its configured duration.'},
  {path: 'motion.titleFadeFrames', label: 'Title fade', type: 'number', min: 0, max: 30, step: 1,
    description: 'Opacity arrival for stationary titles; product captions stay still and fully opaque.'},
  {path: 'motion.resultHoldFrames', label: 'Closing result hold', type: 'number', min: 0, max: 90, step: 1,
    description: 'Carry the unchanged iPad result into the closing scene before shuttering to the CTA.'},
  {path: 'motion.iphoneSplit', label: 'iPhone still split', type: 'number', min: 0.2, max: 0.8, step: 0.05,
    description: 'Share of iPhone media time assigned to the first example after the quiet title.'},
  {path: 'motion.edgeLightOpacity', label: 'Exterior highlight strength', type: 'number', min: 0, max: 1, step: 0.05,
    description: 'Opacity of narrow white highlights outside the source image.'},
  {path: 'motion.edgeLightLength', label: 'Exterior highlight length', type: 'number', min: 10, max: 300, step: 10,
    description: 'Length in composition pixels of the two exterior light strips.'},
  {path: 'motion.edgeLightTravel', label: 'Exterior highlight travel', type: 'number', min: 0, max: 400, step: 10,
    description: 'Vertical travel of the exterior rail while the still shutter opens.'},
  {path: 'motion.lightingEnabled', label: 'Exterior lighting', type: 'boolean',
    description: 'Enable the thin exterior border and highlights; never affects source pixels.'},
];

export const template = defineTemplate({
  ...manifest,
  schemaVersion: 1,
  Component: Template,
  defaultConfig: config,
  controls: [
    ...motionControls,
    {path: 'copy.opening', label: 'Opening statement', type: 'string', description: 'Main stationary opening phrase.'},
    {path: 'copy.cta', label: 'CTA', type: 'string', description: 'Closing title with URL and pricing held below.'},
    {path: 'brand.colors.ink', label: 'Dark surface', type: 'color', description: 'Exterior canvas only.'},
    {path: 'brand.colors.white', label: 'Title and highlight color', type: 'color', description: 'Does not recolor source media.'},
    {path: 'brand.typography.headingSize', label: 'Title size', type: 'number', min: 48, max: 150, step: 2,
      description: 'Title size in composition pixels; font family, tracking and line height remain editable in config.'},
    {path: 'layout.margin', label: 'Scene margin', type: 'number', min: 32, max: 120, step: 2,
      description: 'Reserved outer space for captions and contained media.'},
    {path: 'layout.grid.captionSize', label: 'Product caption size', type: 'number', min: 24, max: 60, step: 2,
      description: 'Stable header above the product; edit captionHeight for multi-line text.'},
    {path: 'layout.captionHeight', label: 'Caption reserve', type: 'number', min: 70, max: 220, step: 2,
      description: 'Space above source media; expand when using longer copy.'},
    {path: 'durations.iphone', label: 'iPhone scene hold', type: 'number', min: 2, max: 30, step: 0.5,
      description: 'Seconds. All seven scene durations in config determine actual composition length.'},
    {path: 'media.environment.framing.anchorX', label: 'Environment crop anchor', type: 'number', min: 0, max: 1, step: 0.05,
      description: 'Normalized anchor. Crop rectangles in config always use original-source pixel coordinates.'},
  ],
});
