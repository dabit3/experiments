import type {ComponentType} from 'react';
import {Composition} from 'remotion';
import type {LaunchConfig} from './config';
import {BrandFonts} from './fonts';
import {timelineDuration} from './timeline';
import {VIDEO} from './tokens';

export type TemplateManifest = {
  schemaVersion: 1;
  slug: string;
  name: string;
  description: string;
  compositionId: string;
};

export type ConfigControl = {
  path: string;
  label: string;
  type: 'number' | 'string' | 'boolean' | 'color';
  description: string;
  min?: number;
  max?: number;
  step?: number;
};

export type TemplateProps<C extends LaunchConfig = LaunchConfig> = {config: C};

export type GalleryDescriptor = TemplateManifest & {
  defaultConfig: LaunchConfig;
  controls: readonly ConfigControl[];
  metadata: {width: number; height: number; fps: number; durationInFrames: number};
  Preview: ComponentType;
  Root: ComponentType;
};

export type TemplateDefinition<C extends LaunchConfig> = TemplateManifest & {
  Component: ComponentType<TemplateProps<C>>;
  defaultConfig: C;
  controls: readonly ConfigControl[];
};

export const defineTemplate = <C extends LaunchConfig>(definition: TemplateDefinition<C>) => {
  const {Component, defaultConfig} = definition;
  const metadata = {...VIDEO, durationInFrames: timelineDuration(defaultConfig.durations, VIDEO.fps)};
  const WithFonts = (props: TemplateProps<C>) => <BrandFonts><Component {...props} /></BrandFonts>;
  const Preview = () => <WithFonts config={defaultConfig} />;
  const Root = () => <Composition
    id={definition.compositionId}
    component={WithFonts}
    defaultProps={{config: defaultConfig}}
    {...metadata}
    calculateMetadata={({props}) => ({
      ...VIDEO,
      durationInFrames: timelineDuration(props.config.durations, VIDEO.fps),
    })}
  />;
  return {...definition, metadata, Preview, Root};
};
