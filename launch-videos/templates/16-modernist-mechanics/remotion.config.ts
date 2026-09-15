import {Config} from '@remotion/cli/config';

// All footage lives in the shared launch-videos/assets folder.
Config.setPublicDir('../../assets');
Config.setVideoImageFormat('jpeg');
Config.setOverwriteOutput(true);
