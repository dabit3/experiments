import {makeTimeline, mix, type SceneId} from '../../shared';
import {stopIds, type JourneyConfig, type Point, type StopId} from './config';

export type Stop = {id: StopId; arrival: number; departure: number; position: Point};
export type Camera = Point & {scale: number};

export const planJourney = (config: JourneyConfig, fps: number) => {
  const scenes = makeTimeline(config.durations, fps);
  const scene = (id: SceneId) => {
    const result = scenes.find((item) => item.id === id);
    if (!result) throw new Error(`Missing scene ${id}`);
    return result;
  };
  const {travelSeconds, iphoneSplit, travelPullback} = config.motion;
  if (!Number.isFinite(travelSeconds) || travelSeconds <= 0 ||
    !Number.isFinite(iphoneSplit) || iphoneSplit < 0.25 || iphoneSplit > 0.75 ||
    !Number.isFinite(travelPullback) || travelPullback < 0 || travelPullback > 0.1) {
    throw new Error('Use positive travelSeconds, iphoneSplit 0.25–0.75 and travelPullback 0–0.1');
  }
  const travel = Math.max(0.25, Math.min(
    travelSeconds * fps,
    ...scenes.map((item) => item.durationInFrames * 0.18),
  ));
  const iphone = scene('iphone');
  const secondIphone = iphone.from + iphone.durationInFrames * iphoneSplit;
  const last = scene('closing');
  const boundaries: Record<StopId, [number, number]> = {
    opening: [0, scene('environment').from - travel],
    environment: [scene('environment').from, scene('agent').from - travel],
    agent: [scene('agent').from, iphone.from],
    iphoneFirst: [iphone.from + travel, secondIphone - travel],
    iphoneSecond: [secondIphone, scene('webQa').from - travel],
    webQa: [scene('webQa').from, scene('ipad').from],
    ipad: [scene('ipad').from + travel, last.from - travel],
    closing: [last.from, last.from + last.durationInFrames],
  };
  const stops: Stop[] = stopIds.map((id, index) => {
    const position = config.canvas.stops[id];
    if (!Number.isFinite(position.x) || !Number.isFinite(position.y)) {
      throw new Error(`Invalid canvas coordinates at ${id}`);
    }
    if (index > 0 && position.x - config.canvas.stops[stopIds[index - 1]].x < 1980) {
      throw new Error('Keep canvas stops at least 1980 pixels apart, moving left to right');
    }
    const [arrival, departure] = boundaries[id];
    if (departure < arrival) throw new Error(`Not enough hold time at ${id}`);
    return {id, arrival, departure, position};
  });
  return {stops, scene, totalFrames: last.from + last.durationInFrames};
};

export const cameraAt = (frame: number, stops: Stop[], pullback: number): Camera => {
  for (let index = 0; index < stops.length; index++) {
    const stop = stops[index];
    const next = stops[index + 1];
    if (frame <= stop.departure || !next) return {...stop.position, scale: 1};
    if (frame < next.arrival) {
      const t = (frame - stop.departure) / (next.arrival - stop.departure);
      const eased = t * t * t * (t * (t * 6 - 15) + 10);
      return {
        x: mix(stop.position.x, next.position.x, eased),
        y: mix(stop.position.y, next.position.y, eased),
        scale: 1 - Math.sin(Math.PI * t) ** 2 * pullback,
      };
    }
  }
  throw new Error('Journey needs at least one stop');
};
