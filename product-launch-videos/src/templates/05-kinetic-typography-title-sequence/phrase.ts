export type PhraseLayout = {lines: string[]; fontSize: number; width: number};

export const fitPhrase = (
  text: string,
  width: number,
  maxSize: number,
  minSize: number,
  maxLines: number,
  measure: (text: string, size: number) => number,
): PhraseLayout => {
  const words = text.trim().split(/\s+/);
  for (let size = maxSize; size >= minSize; size -= 1) {
    const lines: string[] = [];
    let line = '';
    for (const word of words) {
      const candidate = line ? `${line} ${word}` : word;
      if (line && measure(candidate, size) > width) {
        lines.push(line);
        line = word;
      } else {
        line = candidate;
      }
    }
    lines.push(line);
    const widest = Math.max(...lines.map((value) => measure(value, size)));
    if (lines.length <= maxLines && widest <= width) {
      return {lines, fontSize: size, width: widest};
    }
  }
  throw new Error(`Phrase does not fit: shorten "${text}" or lower its minimum font size`);
};

export const boundedFrames = (requested: number, duration: number): number =>
  Math.max(0, Math.min(requested, Math.floor(duration / 3)));

export const iphoneCut = (duration: number, ratio: number): number =>
  Math.max(1, Math.min(duration - 1, Math.round(duration * ratio)));
