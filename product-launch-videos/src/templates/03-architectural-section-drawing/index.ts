import {defineTemplate} from '../../shared';
import manifest from './manifest.json';
import {config} from './config';
import {Template} from './Template';

export const template = defineTemplate({
  ...manifest,
  schemaVersion: 1,
  Component: Template,
  defaultConfig: config,
  controls: [
    {path: 'motion.sectionRevealFrames', label: 'Section reveal', type: 'number', min: 0, max: 60, step: 1, description: 'Frames for still-plane expansion and section hairlines; bounded by scene duration.'},
    {path: 'motion.planeSeparation', label: 'Exploded plane gap', type: 'number', min: 0, max: 80, step: 1, description: 'Orthographic offset between overview planes.'},
    {path: 'motion.planeTravel', label: 'Plane travel', type: 'number', min: 0, max: 140, step: 1, description: 'Pixel travel during cover and still entrances. Recordings stay stationary.'},
    {path: 'motion.introResolveFraction', label: 'Assembly cue', type: 'number', min: 0.3, max: 0.75, step: 0.05, description: 'Fraction of cover duration at which separated planes align.'},
    {path: 'motion.annotationHoldFrames', label: 'Leader hold', type: 'number', min: 24, max: 90, step: 1, description: 'Local frame at which source-coordinate leaders begin fading.'},
    {path: 'motion.annotationFadeFrames', label: 'Leader fade', type: 'number', min: 1, max: 30, step: 1, description: 'Frames to remove explanatory leaders before the reading hold.'},
    {path: 'motion.iphoneSplit', label: 'iPhone still split', type: 'number', min: 0.25, max: 0.75, step: 0.05, description: 'Fraction of the iPhone scene occupied by Afterhours Maze.'},
    {path: 'drawing.gridSpacing', label: 'Drawing grid', type: 'number', min: 40, max: 160, step: 8, description: 'Spacing in pixels. Grid disappears during demonstrations.'},
    {path: 'drawing.gridOpacity', label: 'Grid ink', type: 'number', min: 0, max: 0.12, step: 0.01, description: 'Subtle grid visibility on explanatory sheets.'},
    {path: 'drawing.lineWidth', label: 'Hairline weight', type: 'number', min: 0.5, max: 3, step: 0.25, description: 'Drawing stroke width in pixels.'},
    {path: 'stages', label: 'Stage labels', type: 'string', description: 'Edit the typed array of stage IDs and labels in config.ts or complete props JSON.'},
    {path: 'connections', label: 'Diagram connections', type: 'string', description: 'Editorial sequence links by stage ID; no infrastructure dependencies.'},
    {path: 'annotations', label: 'Source anchors', type: 'string', description: 'Caption labels, original source-pixel x/y positions, edge and enabled flag for each still.'},
    {path: 'copy', label: 'Launch copy', type: 'string', description: 'Shared opening, benefit, captions, pricing, CTA and URL.'},
    {path: 'media', label: 'Source selections', type: 'string', description: 'Typed source assets, fit, source crop rectangles and anchor positions; video source offsets.'},
    {path: 'durations', label: 'Scene durations', type: 'string', description: 'Seven durations in seconds; composition metadata follows edits.'},
    {path: 'brand', label: 'Brand tokens', type: 'string', description: 'Color, font family, size, tracking, line height and title gap.'},
    {path: 'layout', label: 'Drawing geometry', type: 'string', description: 'Margin, gutter, mat padding, caption height, header/media/stage grid positions.'},
  ],
});
