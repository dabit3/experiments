import { Config } from "@remotion/cli/config";

// Shared assets live two levels up; Remotion can only serve files from its public dir.
Config.setPublicDir("../../assets");
Config.setVideoImageFormat("jpeg");
Config.setCodec("h264");
Config.setOverwriteOutput(true);
