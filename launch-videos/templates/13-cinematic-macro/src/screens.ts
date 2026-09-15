/** Source screenshots (2x retina PNGs) and their pixel dimensions. */
export const SCREENS = {
  web1: { src: "screens/devin-web-1.png", w: 2990, h: 1624 },
  web4: { src: "screens/devin-web-4.png", w: 2988, h: 1622 },
  web9: { src: "screens/devin-web-9.png", w: 2988, h: 1628 },
  web10: { src: "screens/devin-web-10.png", w: 2990, h: 1624 },
  web13: { src: "screens/devin-web-13.png", w: 2982, h: 1620 },
  web17: { src: "screens/devin-web-17.png", w: 2978, h: 1620 },
  web19: { src: "screens/devin-web-19.png", w: 2982, h: 1626 },
  desktop9: { src: "screens/devin-desktop-9.png", w: 3024, h: 1898 },
} as const;

export type Screen = (typeof SCREENS)[keyof typeof SCREENS];
