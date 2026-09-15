import { Zoom } from "./layout";

/**
 * Shared state at scene boundaries. Each scene ends in exactly the state the
 * next one starts in, so the hard cuts between <Sequence>s are invisible.
 */
export const HANDOFF = {
  /** idle pointer position on the empty home screen */
  idle: { x: 0.64, y: 0.66 },
  /** pointer resting on the prompt box after choosing macOS */
  promptBox: { x: 0.4, y: 0.42 },
  /** pointer parked out of the way on the session view */
  sessionIdle: { x: 0.82, y: 0.56 },
  /** end of prompt scene: pushed in on Devin's reply (web-13) */
  promptEnd: { scale: 1.12, x: 0.5, y: 0.62 } as Zoom,
  /** end of simulator scene: pushed in on the test list (web-10) */
  simulatorEnd: { scale: 1.3, x: 0.72, y: 0.45 } as Zoom,
  /** end of PR scene: pushed in on "Ready to merge" (web-9) */
  prEnd: { scale: 1.4, x: 0.77, y: 0.33 } as Zoom,
};
