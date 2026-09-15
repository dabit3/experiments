import { Config } from "@remotion/cli/config";

Config.setPublicDir("../../assets");
Config.setVideoImageFormat("jpeg");
Config.setCodec("h264");
Config.setCrf(16);
Config.setOverwriteOutput(true);
