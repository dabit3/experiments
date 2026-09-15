// Brand type scale from brief/brand.md (1512px artboard) scaled x1.27 for 1920 video.
export const type = {
  display: { fontSize: 89, lineHeight: "92px", letterSpacing: "-3.4px", fontWeight: 500 },
  h2: { fontSize: 64, lineHeight: "72px", letterSpacing: "-2.3px", fontWeight: 500 },
  h3: { fontSize: 36, lineHeight: "44px", letterSpacing: "-0.6px", fontWeight: 500 },
  h5: { fontSize: 27, lineHeight: "38px", letterSpacing: "-0.4px", fontWeight: 400 },
  body: { fontSize: 20, lineHeight: "28px", letterSpacing: "-0.3px", fontWeight: 400 },
  label: { fontSize: 18, lineHeight: "25px", letterSpacing: "-0.2px", fontWeight: 400 },
  eyebrow: {
    fontSize: 14.5,
    lineHeight: "22px",
    letterSpacing: "0.9px",
    fontWeight: 500,
    textTransform: "uppercase" as const,
  },
} as const;

export const SAFE = 96;
export const VIEW_W = 1920;
export const VIEW_H = 1080;
