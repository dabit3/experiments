import { Config } from "@remotion/cli/config";

// Shared launch-video assets (screens/, brand/, tokens.json) live two levels up.
Config.setPublicDir("../../assets");
Config.setVideoImageFormat("jpeg");
Config.setCodec("h264");
Config.setOverwriteOutput(true);
