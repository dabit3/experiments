import React from "react";
import type { Rect } from "../layout";
import type { Bay, BayStatus, Brand, MediaSlot, StatusLabels } from "../schema";
import { Media } from "./Media";
import { MonoLabel, Panel } from "./Panel";

export const BAY_HEADER = 40;

type Props = {
  bays: Bay[];
  rects: Rect[];
  statuses: BayStatus[];
  media: Record<string, MediaSlot>;
  brand: Brand;
  statusLabels: StatusLabels;
  radius: number;
  opacity: number;
  /** Per-bay entrance progress (0..1) for the opening scene. */
  entrances: number[];
};

const StatusChip: React.FC<{ status: BayStatus; brand: Brand; labels: StatusLabels }> = ({
  status,
  brand,
  labels,
}) => {
  const live = status === "live";
  return (
    <div
      style={{
        display: "flex",
        alignItems: "center",
        gap: 8,
        height: 22,
        padding: "0 10px",
        borderRadius: 8,
        background: live ? brand.accent : "transparent",
        boxShadow: live ? "none" : `inset 0 0 0 1px ${brand.consoleLine}`,
      }}
    >
      <MonoLabel
        brand={brand}
        size={11}
        color={live ? brand.white : status === "held" ? brand.inkMuted : brand.inkSubtle}
      >
        {labels[status]}
      </MonoLabel>
    </div>
  );
};

export const Bays: React.FC<Props> = ({
  bays,
  rects,
  statuses,
  media,
  brand,
  statusLabels,
  radius,
  opacity,
  entrances,
}) => {
  return (
    <>
      {bays.map((bay, i) => {
        const rect = rects[i];
        if (!rect) return null;
        const status = statuses[i] ?? "standby";
        const slot = media[bay.media];
        const e = entrances[i] ?? 1;
        const shifted: Rect = { ...rect, y: rect.y + (1 - e) * 12 };
        return (
          <Panel
            key={bay.id}
            rect={shifted}
            brand={brand}
            radius={radius}
            emphasis={status === "live"}
            opacity={opacity * e}
          >
            <div
              style={{
                position: "absolute",
                left: 0,
                top: 0,
                right: 0,
                height: BAY_HEADER,
                display: "flex",
                alignItems: "center",
                justifyContent: "space-between",
                padding: "0 12px 0 16px",
              }}
            >
              <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                <MonoLabel brand={brand} color={brand.inkMuted} size={12}>
                  {String(i + 1).padStart(2, "0")}
                </MonoLabel>
                <MonoLabel brand={brand} color={brand.white} size={12}>
                  {bay.label}
                </MonoLabel>
              </div>
              <StatusChip status={status} brand={brand} labels={statusLabels} />
            </div>
            <div
              style={{
                position: "absolute",
                left: 0,
                top: BAY_HEADER,
                right: 0,
                bottom: 0,
                overflow: "hidden",
                borderTop: `1px solid ${brand.consoleLine}`,
              }}
            >
              {slot ? (
                <Media
                  slot={slot}
                  width={rect.w}
                  height={rect.h - BAY_HEADER}
                  fit="cover"
                  background={brand.black}
                />
              ) : null}
            </div>
          </Panel>
        );
      })}
    </>
  );
};
