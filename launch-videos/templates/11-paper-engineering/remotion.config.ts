import { Config } from "@remotion/cli/config";

// All media lives in launch-videos/assets and is referenced with staticFile().
Config.setPublicDir("../../assets");
Config.setVideoImageFormat("jpeg");
Config.setOverwriteOutput(true);
