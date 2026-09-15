import { Easing, interpolate } from "remotion";
import type { Camera, Station } from "./schema";

export type StationTiming = {
  station: Station;
  index: number;
  /** First frame of the travel that leads into this station. */
  travelStart: number;
  /** Frame the camera comes to rest at this station. */
  arrive: number;
  /** Frame the camera starts to leave (== next station's travelStart). */
  leave: number;
};

export const buildTimeline = (stations: Station[]): StationTiming[] => {
  let cursor = 0;
  return stations.map((station, index) => {
    const travelStart = cursor;
    const arrive = travelStart + (index === 0 ? 0 : station.travelInFrames);
    const leave = arrive + station.holdFrames;
    cursor = leave;
    return { station, index, travelStart, arrive, leave };
  });
};

export const totalFrames = (stations: Station[]): number => {
  const timeline = buildTimeline(stations);
  return timeline.length === 0 ? 1 : timeline[timeline.length - 1].leave;
};

const easingFor = (camera: Camera) =>
  camera.easing === "inOutSine"
    ? Easing.inOut(Easing.sin)
    : Easing.inOut(Easing.cubic);

export type CameraState = { x: number; y: number; zoom: number };

export const cameraAt = (
  frame: number,
  timeline: StationTiming[],
  camera: Camera,
): CameraState => {
  const first = timeline[0];
  if (frame <= first.arrive) {
    return {
      x: first.station.x,
      y: first.station.y,
      zoom: first.station.zoom ?? 1,
    };
  }
  for (let i = 1; i < timeline.length; i++) {
    const t = timeline[i];
    const prev = timeline[i - 1].station;
    if (frame < t.arrive) {
      const p = interpolate(frame, [t.travelStart, t.arrive], [0, 1], {
        easing: easingFor(camera),
        extrapolateLeft: "clamp",
        extrapolateRight: "clamp",
      });
      return {
        x: prev.x + (t.station.x - prev.x) * p,
        y: prev.y + (t.station.y - prev.y) * p,
        zoom: (prev.zoom ?? 1) + ((t.station.zoom ?? 1) - (prev.zoom ?? 1)) * p,
      };
    }
    if (frame < t.leave) {
      return { x: t.station.x, y: t.station.y, zoom: t.station.zoom ?? 1 };
    }
  }
  const last = timeline[timeline.length - 1].station;
  return { x: last.x, y: last.y, zoom: last.zoom ?? 1 };
};

/** Fraction (0-1) of the total route the camera has covered, by station index. */
export const routeProgress = (
  frame: number,
  timeline: StationTiming[],
  camera: Camera,
): number => {
  if (timeline.length < 2) return 1;
  for (let i = 1; i < timeline.length; i++) {
    const t = timeline[i];
    if (frame < t.arrive) {
      const p = interpolate(frame, [t.travelStart, t.arrive], [0, 1], {
        easing: easingFor(camera),
        extrapolateLeft: "clamp",
        extrapolateRight: "clamp",
      });
      return (i - 1 + p) / (timeline.length - 1);
    }
    if (frame < t.leave) return i / (timeline.length - 1);
  }
  return 1;
};
