import React from "react";
import type { Brand } from "../schema";

type Props = {
  text: string;
  visibleChars: number;
  accentWord?: string;
  brand: Brand;
};

export const TypedText: React.FC<Props> = ({ text, visibleChars, accentWord, brand }) => {
  const shown = text.slice(0, visibleChars);
  if (!accentWord) {
    return <>{shown}</>;
  }
  const idx = text.indexOf(accentWord);
  if (idx === -1) {
    return <>{shown}</>;
  }
  const before = shown.slice(0, idx);
  const word = shown.slice(idx, idx + accentWord.length);
  const after = shown.slice(idx + accentWord.length);
  return (
    <>
      {before}
      <span style={{ color: brand.accent }}>{word}</span>
      {after}
    </>
  );
};
