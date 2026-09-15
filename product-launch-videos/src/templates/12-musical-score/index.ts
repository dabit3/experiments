import {defineTemplate, type ConfigControl} from '../../shared';
import {config} from './config';
import {Template} from './Template';
import manifest from './manifest.json';

const numberControl = (path: string, label: string, description: string, min: number, max: number, step = 1): ConfigControl =>
  ({path, label, description, type: 'number', min, max, step});

export const template = defineTemplate({
  ...manifest,
  schemaVersion: 1,
  Component: Template,
  defaultConfig: config,
  controls: [
    numberControl('motion.entranceFrames', 'Opening entrance', 'Frames for the score rules and introductory type to settle.', 0, 90),
    numberControl('motion.playheadTravelFrames', 'Chapter travel', 'Playhead travels once, then parks; it is not a clock.', 0, 60),
    numberControl('motion.cueAccentFrames', 'Cue decay', 'Frames for the square editorial accent to decay.', 0, 60),
    numberControl('motion.cueAccentSize', 'Cue square', 'Size in pixels of the cue on the active track.', 4, 24),
    numberControl('motion.resolveFrames', 'Closing resolution', 'Frames for separate tracks to converge at the final bar.', 0, 90),
    numberControl('motion.iphoneSplit', 'iPhone still split', 'Fraction of the iPhone scene given to Afterhours Maze.', 0.1, 0.9, 0.01),
    numberControl('score.rowHeight', 'Track spacing', 'Pixels between the three narrative tracks.', 20, 40),
    numberControl('score.labelWidth', 'Track label column', 'Width reserved for the editable track names.', 160, 360),
    numberControl('score.fontSize', 'Track typography', 'Size of labels and chapter indices.', 18, 28),
    numberControl('score.barInset', 'Chapter pause', 'Empty space before and after each chapter bar.', 8, 40),
    numberControl('score.ruleOpacity', 'Score rule strength', 'Opacity of the neutral baseline rules.', 0.05, 0.5, 0.01),
    {path: 'score.label', label: 'Score heading', type: 'string', description: 'Persistent label identifying editorial progression.'},
    {path: 'score.context', label: 'Context', type: 'string', description: 'Keep separate-example and narrative-order context explicit.'},
    {path: 'score.tracks', label: 'Track labels', type: 'string', description: 'Three editable strings in config.ts or complete props JSON.'},
    {path: 'score.chapters', label: 'Chapters', type: 'string', description: 'Scene-keyed labels and track indices (0–2).'},
    {path: 'score.cues', label: 'Event cues', type: 'string', description: 'Editable scene, local atSeconds, and observed-event label records.'},
    {path: 'score.introIndex', label: 'Opening index', type: 'string', description: 'Prelude text.'},
    {path: 'score.closingIndex', label: 'Closing index', type: 'string', description: 'Resolution text.'},
    {path: 'copy', label: 'Launch copy', type: 'string', description: 'All headlines, captions, benefit, CTA and URL in complete config.'},
    {path: 'media', label: 'Original media / framing', type: 'string', description: 'Source assets, video offsets, fit modes, source-pixel crops and anchors.'},
    {path: 'durations', label: 'Scene durations', type: 'string', description: 'Seven seconds values; composition duration and cue positions recalculate.'},
    {path: 'brand', label: 'Brand tokens', type: 'string', description: 'Neutral colors, font families, sizes, line heights, tracking and title gap.'},
    {path: 'layout', label: 'Layout geometry', type: 'string', description: 'Margin, gutter, caption height; grid.mediaTop, mediaHeight and scoreTop.'},
    {path: 'sound.enabled', label: 'Optional audio', type: 'boolean', description: 'Off by default. Use the documented unmuted CLI for sound accents.'},
    {path: 'sound.asset', label: 'Accent file', type: 'string', description: 'Local public-relative path to a user-supplied optional sound.'},
    numberControl('sound.volume', 'Accent volume', 'Optional accent gain.', 0, 1, 0.01),
    numberControl('sound.durationSeconds', 'Accent length', 'Length of each optional local sound cue in seconds.', 0.04, 2, 0.01),
  ],
});
