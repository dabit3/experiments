import React from 'react';
import {Img, OffthreadVideo, staticFile} from 'remotion';
import type {MediaSlot} from '../schema';
import type {Rect} from '../geometry';

/**
 * Renders a media slot so that its crop region maps exactly onto `rest`
 * (pixel-preserving uniform scale; crop only trims). The element is anchored
 * at the top-left of its container, so a container that is still moving
 * simply reveals more or less of it — the UI itself is never distorted.
 */
export const Media: React.FC<{slot: MediaSlot; rest: Rect}> = ({slot, rest}) => {
  const crop = slot.crop ?? {x: 0, y: 0, w: 1, h: 1};
  const scale = rest.w / (crop.w * slot.width);
  const fullW = slot.width * scale;
  const fullH = slot.height * scale;
  const style: React.CSSProperties = {
    position: 'absolute',
    left: -crop.x * fullW,
    top: -crop.y * fullH,
    width: fullW,
    height: fullH,
    display: 'block',
  };
  const src = staticFile(slot.src);

  if (slot.kind === 'video') {
    return (
      <OffthreadVideo
        src={src}
        style={style}
        startFrom={slot.startFrom}
        playbackRate={slot.playbackRate ?? 1}
        muted
      />
    );
  }
  return <Img src={src} style={style} />;
};
