import React from "react";
import type { Brand } from "../schema";
import { type } from "../layout";

type Props = { brand: Brand; label: string; right: number; top: number };

/** Small mono chip shown only when footage is sped up. */
export const SpeedBadge: React.FC<Props> = ({ brand, label, right, top }) => (
  <div
    style={{
      position: "absolute",
      right,
      top,
      padding: "4px 10px",
      borderRadius: 8,
      background: brand.ink,
      color: brand.white,
      fontFamily: brand.monoFontFamily,
      ...type.label,
    }}
  >
    {label}
  </div>
);
