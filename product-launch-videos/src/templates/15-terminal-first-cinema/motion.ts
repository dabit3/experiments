export const unit = (value: number) => Math.max(0, Math.min(1, value));
export const smooth = (value: number) => {
  const t = unit(value);
  return t * t * (3 - 2 * t);
};
export const phase = (frame: number, start: number, duration: number) =>
  duration <= 0 ? Number(frame >= start) : unit((frame - start) / duration);

export const revealFrames = (requested: number, sceneFrames: number) =>
  Math.max(0, Math.min(Math.round(requested), Math.floor(sceneFrames / 4)));

export const splitFrame = (duration: number, ratio: number) =>
  Math.max(1, Math.min(duration - 1, Math.round(duration * unit(ratio))));

export const typedLength = (text: string, frame: number, duration: number) =>
  Math.ceil(text.length * phase(frame, 0, duration));

export const cursorVisible = (
  frame: number, typingDuration: number, blinkFrames: number, blinkDuringHolds: boolean,
) => !blinkDuringHolds || frame < typingDuration || blinkFrames <= 0 ||
  Math.floor((frame - typingDuration) / blinkFrames) % 2 === 0;
