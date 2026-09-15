import React from "react";
import { Img, interpolate, staticFile, useCurrentFrame } from "remotion";
import { color, ease, FRAME_BORDER } from "../theme";

export type Focus = { x: number; y: number }; // 0..1 point of the image to keep centred

type Layer = {
  src: string;
  /** natural aspect ratio (w/h) of the screenshot */
  aspect: number;
  /** [frameIn, frameOut] for a cross-fade; omit for always visible */
  fadeIn?: [number, number];
  fadeOut?: [number, number];
};

type Props = {
  width: number;
  height: number;
  layers: Layer[];
  /** scale relative to "cover" at frame range */
  scale: { from: number; to: number; over: [number, number] };
  focus: { from: Focus; to: Focus; over: [number, number] };
  /** entrance of the whole frame */
  enterAt?: number;
  /** overlays; `map` converts normalised image coords (first layer) to px inside the frame */
  children?: (map: (p: Focus) => { x: number; y: number }) => React.ReactNode;
};

/**
 * Screenshot sitting inside a thick black frame. The image is clipped to the
 * frame and "covers" it; scale and focus animate a slow push-in / pan.
 */
export const Screenshot: React.FC<Props> = ({
  width,
  height,
  layers,
  scale,
  focus,
  enterAt = 0,
  children,
}) => {
  const frame = useCurrentFrame();
  const innerW = width - FRAME_BORDER * 2;
  const innerH = height - FRAME_BORDER * 2;

  const s = interpolate(frame, scale.over, [scale.from, scale.to], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: ease.inOut,
  });
  const fx = interpolate(frame, focus.over, [focus.from.x, focus.to.x], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: ease.inOut,
  });
  const fy = interpolate(frame, focus.over, [focus.from.y, focus.to.y], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: ease.inOut,
  });

  const enter = interpolate(frame, [enterAt, enterAt + 18], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: ease.out,
  });

  const geometry = (aspect: number) => {
    const coverW = Math.max(innerW, innerH * aspect);
    const imgW = coverW * s;
    const imgH = imgW / aspect;
    const left = Math.min(0, Math.max(innerW - imgW, innerW / 2 - imgW * fx));
    const top = Math.min(0, Math.max(innerH - imgH, innerH / 2 - imgH * fy));
    return { imgW, imgH, left, top };
  };

  const first = geometry(layers[0].aspect);
  const map = (p: Focus) => ({ x: first.left + p.x * first.imgW, y: first.top + p.y * first.imgH });

  return (
    <div
      style={{
        position: "absolute",
        width,
        height,
        background: color.ink,
        padding: FRAME_BORDER,
        boxSizing: "border-box",
        opacity: enter,
        transform: `translateY(${(1 - enter) * 24}px)`,
      }}
    >
      <div style={{ position: "relative", width: innerW, height: innerH, overflow: "hidden", background: color.white }}>
        {layers.map((layer, i) => {
          const { imgW, imgH, left, top } = geometry(layer.aspect);
          const fadeIn = layer.fadeIn
            ? interpolate(frame, layer.fadeIn, [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp", easing: ease.inOut })
            : 1;
          const fadeOut = layer.fadeOut
            ? interpolate(frame, layer.fadeOut, [1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp", easing: ease.inOut })
            : 1;
          return (
            <Img
              key={i}
              src={staticFile(layer.src)}
              style={{
                position: "absolute",
                left,
                top,
                width: imgW,
                height: imgH,
                opacity: fadeIn * fadeOut,
              }}
            />
          );
        })}
        {children?.(map)}
      </div>
    </div>
  );
};
