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
    {path: 'motion.returnFrames', label: 'Return to index', type: 'number', min: 0, max: 60, step: 1,
      description: 'Frames for the frozen outgoing plate to contract into its archive cell.'},
    {path: 'motion.indexHoldFrames', label: 'Index pause', type: 'number', min: 0, max: 60, step: 1,
      description: 'Still contact-sheet hold before expanding the next indexed frame.'},
    {path: 'motion.expandFrames', label: 'Frame expansion', type: 'number', min: 0, max: 60, step: 1,
      description: 'Frames for the next selected plate to expand; short scenes proportionally cap transitions.'},
    {path: 'motion.openingExpandFrames', label: 'Opening selection', type: 'number', min: 0, max: 90, step: 1,
      description: 'Opening frames allocated to enlarging the authentic environment still.'},
    {path: 'motion.iphoneSplit', label: 'iPhone still split', type: 'number', min: 0.2, max: 0.8, step: 0.01,
      description: 'Fraction of the iPhone chapter assigned to Afterhours Maze before Large Dispatch.'},
    {path: 'motion.selectionStroke', label: 'Selected frame stroke', type: 'number', min: 0, max: 8, step: 1,
      description: 'Outer keyline width for the selected archive cell.'},
    {path: 'archive.agentIndexFrame', label: 'Agent index frame', type: 'number', min: 0, max: 119, step: 1,
      description: 'Frame inside the chosen agent clip used for its initial frozen contact-sheet entry.'},
    {path: 'archive.webQaIndexFrame', label: 'Web QA index frame', type: 'number', min: 0, max: 209, step: 1,
      description: 'Frame inside the chosen web clip used in the archive; always labeled Web QA example.'},
    {path: 'archive.agentFreezeFrame', label: 'Agent closing freeze', type: 'number', min: -1, max: 119, step: 1,
      description: '-1 selects the last frame of the configured clip; another value selects a specific freeze frame.'},
    {path: 'archive.webQaFreezeFrame', label: 'Web QA closing freeze', type: 'number', min: -1, max: 209, step: 1,
      description: '-1 selects the last frame of the configured clip; these holds never truncate the live recording.'},
    {path: 'archive.title', label: 'Archive title', type: 'string', description: 'Heading shown during index returns.'},
    {path: 'archive.context', label: 'Montage context', type: 'string', description: 'Persistent context explaining that these are separate sessions.'},
    {path: 'layout.grid.top', label: 'Archive top', type: 'number', min: 300, max: 400, step: 1, description: 'Top edge of the six-frame index.'},
    {path: 'layout.grid.tileHeight', label: 'Archive frame height', type: 'number', min: 200, max: 280, step: 1, description: 'Thumbnail viewport height; source aspect ratio is retained.'},
    {path: 'layout.grid.rowGap', label: 'Archive row gap', type: 'number', min: 45, max: 90, step: 1, description: 'Gap including the labels between index rows.'},
    {path: 'layout.grid.heroTop', label: 'Product frame top', type: 'number', min: 80, max: 130, step: 1, description: 'Top of the large reading view.'},
    {path: 'layout.grid.closingHeroTop', label: 'Final artifact top', type: 'number', min: 90, max: 160, step: 1, description: 'Position of the selected final iPad artifact.'},
    {path: 'layout.grid.closingHeroHeight', label: 'Final artifact height', type: 'number', min: 600, max: 720, step: 1, description: 'Final artifact viewport height above the pricing and CTA.'},
  ],
});
