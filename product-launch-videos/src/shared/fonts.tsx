import {useEffect, useState, type ReactNode} from 'react';
import {cancelRender, continueRender, delayRender} from 'remotion';
import {assetPath} from './assets';

let fontsReady: Promise<void> | undefined;

export const loadBrandFonts = (): Promise<void> => {
  fontsReady ??= Promise.all([
    new FontFace('nbInternationalPro',
      `url("${assetPath('NBInternationalPro-Regular.woff2')}")`,
      {weight: '400', style: 'normal'}).load(),
    new FontFace('nbInternationalPro Light',
      `url("${assetPath('NBInternationalPro-Light.woff2')}")`,
      {weight: '300', style: 'normal'}).load(),
    new FontFace('Geist Mono',
      `url("${assetPath('GeistMono-Regular.woff2')}")`,
      {weight: '400', style: 'normal'}).load(),
  ]).then((faces) => {
    for (const face of faces) document.fonts.add(face);
  });
  return fontsReady;
};

export const BrandFonts = ({children}: {children: ReactNode}) => {
  const [ready, setReady] = useState(false);
  const [handle] = useState(() => delayRender('Loading original Devin WOFF2 fonts'));
  useEffect(() => {
    loadBrandFonts().then(() => {
      setReady(true);
      continueRender(handle);
    }).catch((error: unknown) => {
      cancelRender(error instanceof Error ? error : new Error(String(error)));
    });
  }, [handle]);
  return ready ? children : null;
};
