import {useEffect, useState} from 'react';
import {Img, cancelRender, continueRender, delayRender} from 'remotion';
import {SourceImage, assetPath, assets, mediaGeometry, type ImageSelection} from '../../shared';

const highlightedSources = new Map<string, Promise<string>>();

const highlightedSource = (source: string): Promise<string> => {
  const cached = highlightedSources.get(source);
  if (cached) return cached;
  const result = (async () => {
    const response = await fetch(source);
    if (!response.ok) throw new Error(`Cannot load environment image: ${response.status}`);
    const image = await createImageBitmap(await response.blob());
    const canvas = document.createElement('canvas');
    canvas.width = image.width;
    canvas.height = image.height;
    const context = canvas.getContext('2d');
    if (!context) throw new Error('Cannot create environment image canvas.');
    context.drawImage(image, 0, 0);
    image.close();
    const region = context.getImageData(669, 1078, 530, 150);
    for (let y = 0; y < region.height; y++) {
      for (let x = 0; x < region.width; x++) {
        const i = (y * region.width + x) * 4;
        const value = region.data[i];
        if (value < 230 || value !== region.data[i + 1] || value !== region.data[i + 2]) continue;
        if (y < 75) {
          region.data[i] = region.data[i + 1] = region.data[i + 2] = 255;
        } else {
          const dx = Math.max(16 - x - 0.5, x + 0.5 - (region.width - 16), 0);
          const dy = Math.max(16 - (y - 75) - 0.5, y - 75 + 0.5 - (75 - 16), 0);
          const coverage = Math.max(0, Math.min(1, 16.5 - Math.hypot(dx, dy)));
          const background = Math.round(value - 16 * coverage * (value - 230) / 25);
          region.data[i] = region.data[i + 1] = region.data[i + 2] = background;
        }
      }
    }
    context.putImageData(region, 669, 1078);
    const blob = await new Promise<Blob>((resolve, reject) => {
      canvas.toBlob((value) => value ? resolve(value) : reject(new Error('Cannot encode environment image.')));
    });
    return URL.createObjectURL(blob);
  })();
  highlightedSources.set(source, result);
  return result;
};

const HighlightedImage = ({asset, framing, width, height}: ImageSelection & {width: number; height: number}) => {
  const [source, setSource] = useState<string | null>(null);
  useEffect(() => {
    const handle = delayRender('Preparing macOS menu highlight');
    highlightedSource(assetPath(asset)).then((url) => {
      setSource(url);
      continueRender(handle);
    }).catch(cancelRender);
  }, [asset]);
  const geometry = mediaGeometry(assets[asset], {width, height}, framing);
  return <div style={{width, height, position: 'relative', overflow: 'hidden'}}>
    <div style={{
      position: 'absolute', overflow: 'hidden', left: geometry.cropLeft, top: geometry.cropTop,
      width: geometry.cropWidth, height: geometry.cropHeight,
    }}>
      {source ? <Img src={source} style={{
        position: 'absolute', maxWidth: 'none', left: geometry.mediaLeft, top: geometry.mediaTop,
        width: geometry.mediaWidth, height: geometry.mediaHeight,
      }} /> : null}
    </div>
  </div>;
};

export const EnvironmentImage = ({highlight, ...props}: ImageSelection & {
  width: number; height: number; highlight: boolean;
}) => highlight && props.asset === 'devin-web-4.png'
  ? <HighlightedImage {...props} />
  : <SourceImage {...props} />;
