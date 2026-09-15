import {defineTemplate} from '../shared/contract';
import {defaultLaunchConfig} from '../shared/config';
import {Smoke} from './Smoke';

export const template = defineTemplate({
  schemaVersion: 1,
  slug: 'foundation-smoke',
  name: 'Foundation smoke',
  description: 'Infrastructure verification only; not one of the twenty design directions.',
  compositionId: 'FoundationSmoke',
  Component: Smoke,
  defaultConfig: defaultLaunchConfig,
  controls: [],
});
