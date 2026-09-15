import React from 'react';
import {Composition} from 'remotion';
import {Launch} from './Launch';
import {launchPropsSchema} from './schema';
import {defaultProps} from './defaults';
import {totalDuration} from './geometry';

export const RemotionRoot: React.FC = () => {
  return (
    <Composition
      id="Launch"
      component={Launch}
      width={1920}
      height={1080}
      fps={30}
      durationInFrames={totalDuration(defaultProps.scenes)}
      schema={launchPropsSchema}
      defaultProps={defaultProps}
      calculateMetadata={({props}) => ({
        durationInFrames: totalDuration(props.scenes),
      })}
    />
  );
};
