import { Config } from "@remotion/cli/config";

// All media lives in launch-videos/assets and is referenced via staticFile().
Config.setPublicDir("../../assets");
Config.setVideoImageFormat("jpeg");
Config.setOverwriteOutput(true);
// Silent film: drop the audio track entirely.
Config.setMuted(true);
Config.setEnforceAudioTrack(false);
