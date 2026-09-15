import { Config } from "@remotion/cli/config";

// All footage lives in launch-videos/assets and is referenced via staticFile().
Config.setPublicDir("../../assets");
Config.setVideoImageFormat("jpeg");
Config.setOverwriteOutput(true);
