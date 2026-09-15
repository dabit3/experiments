export type Crop = {x: number; y: number; width: number; height: number};
export type Framing = {
  fit: 'contain' | 'cover';
  anchorX: number;
  anchorY: number;
  crop?: Crop;
};
export const contain: Framing = {fit: 'contain', anchorX: 0.5, anchorY: 0.5};

export const mediaGeometry = (
  source: {width: number; height: number},
  viewport: {width: number; height: number},
  framing: Framing = contain,
) => {
  const crop = framing.crop ?? {x: 0, y: 0, ...source};
  const numbers = [source.width, source.height, viewport.width, viewport.height,
    crop.width, crop.height];
  if (numbers.some((n) => !Number.isFinite(n) || n <= 0) ||
    !Number.isFinite(crop.x) || !Number.isFinite(crop.y) ||
    crop.x < 0 || crop.y < 0 || crop.x + crop.width > source.width ||
    crop.y + crop.height > source.height) {
    throw new Error('Crop and viewport must fit positive source dimensions');
  }
  if ([framing.anchorX, framing.anchorY].some((n) => !Number.isFinite(n) || n < 0 || n > 1)) {
    throw new Error('Crop anchors must be between 0 and 1');
  }
  const scale = (framing.fit === 'contain' ? Math.min : Math.max)(
    viewport.width / crop.width, viewport.height / crop.height,
  );
  const cropWidth = crop.width * scale;
  const cropHeight = crop.height * scale;
  return {
    cropWidth, cropHeight,
    cropLeft: (viewport.width - cropWidth) * framing.anchorX,
    cropTop: (viewport.height - cropHeight) * framing.anchorY,
    mediaWidth: source.width * scale,
    mediaHeight: source.height * scale,
    mediaLeft: 0 - crop.x * scale,
    mediaTop: 0 - crop.y * scale,
  };
};
