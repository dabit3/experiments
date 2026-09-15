import { useRef, useState } from "react";
import type { Furniture, Project, Selection } from "./model";
import { area, escapeXml, materials, openingSegments } from "./model";

const S = 40;
const line = (
  x1: number,
  y1: number,
  x2: number,
  y2: number,
  stroke = "#65675d",
  width = 1,
) =>
  `<line x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}" stroke="${stroke}" stroke-width="${width}"/>`;
const rect = (
  x: number,
  y: number,
  w: number,
  h: number,
  fill: string,
  stroke = "#716e61",
  radius = 0,
) =>
  `<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="${radius}" fill="${fill}" stroke="${stroke}" stroke-width="0.8"/>`;
const label = (
  x: number,
  y: number,
  text: string,
  size = 10,
  color = "#5d615a",
  weight = 400,
) =>
  `<text x="${x}" y="${y}" text-anchor="middle" font-family="Arial,sans-serif" font-size="${size}" fill="${color}" font-weight="${weight}">${escapeXml(text)}</text>`;
const circle = (
  x: number,
  y: number,
  r: number,
  fill: string,
  stroke = "#77766b",
) =>
  `<circle cx="${x}" cy="${y}" r="${r}" fill="${fill}" stroke="${stroke}" stroke-width="0.7"/>`;

export function furnitureSvg(f: Furniture): string {
  const w = f.w * S,
    d = f.d * S,
    c = materials[f.material].color;
  let body = "";
  if (f.kind === "sofa") {
    body =
      rect(-w / 2, -d / 2, w, d, c, "#8b8578", 5) +
      rect(-w / 2 + 5, -d / 2 + 7, w - 10, d - 15, "#eee9de", "#aca697", 4);
    for (let i = 1; i < 3; i++)
      body += line(
        -w / 2 + (w * i) / 3,
        -d / 2 + 7,
        -w / 2 + (w * i) / 3,
        d / 2 - 7,
        "#b5ad9c",
      );
    body += rect(-w / 2 + 4, d / 2 - 10, w - 8, 8, c, "#9c9485", 2);
  } else if (f.kind === "chair") {
    body =
      rect(-w / 2, -d / 2, w, d, c, "#807d6d", 7) +
      rect(-w / 2 + 5, -d / 2 + 4, w - 10, d - 12, "#dfdfd0", "#989783", 6);
    body += rect(-w / 2 + 3, d / 2 - 9, w - 6, 8, c, "#8b8a76", 2);
  } else if (f.kind === "table") {
    if (f.w > 2)
      for (const x of [-w / 3, 0, w / 3])
        body +=
          rect(x - 10, -d / 2 - 18, 20, 20, "#dcd6c8", "#948977", 4) +
          rect(x - 10, d / 2 - 2, 20, 20, "#dcd6c8", "#948977", 4);
    body += rect(-w / 2, -d / 2, w, d, c, "#8a7761", Math.min(d / 2, 14));
    body += circle(0, 0, 6, "#a5aa83") + circle(3, -3, 3, "#e8e4d7");
  } else if (f.kind === "bed") {
    body = rect(
      -w / 2 - 7,
      -d / 2 - 8,
      w + 14,
      d + 16,
      "#e0dcd0",
      "#c3bcb0",
      2,
    );
    body +=
      rect(-w / 2, -d / 2, w, d, "#faf7ef", "#9c9385", 3) +
      rect(-w / 2, d / 2 - 7, w, 9, c, "#9c9385", 2);
    body += rect(-w / 2 + 5, -d / 2, w - 10, d * 0.58, c, "#bdb5a3", 2);
    for (const x of [-w / 4, w / 4])
      body += rect(x - w / 5, d / 2 - 27, w / 2.5, 17, "#fffdf6", "#c1b9ab", 4);
  } else if (f.kind === "cabinet" || f.kind === "island") {
    body =
      rect(-w / 2, -d / 2, w, d, c, "#787465", 1) +
      rect(
        -w / 2 + 2,
        -d / 2 + 2,
        w - 4,
        d - 4,
        f.kind === "island" ? "#e8e4db" : c,
        "#a5a08f",
      );
    for (let x = -w / 2 + 25; x < w / 2; x += 30)
      body += line(x, -d / 2 + 2, x, d / 2 - 2, "#a09882", 0.5);
    if (f.kind === "island") {
      body +=
        rect(-14, -12, 28, 24, "#b7c1ba", "#8a938e", 4) +
        line(0, -14, 0, -21, "#687875", 2);
      for (const x of [-40, 0, 40])
        body += circle(x, -d / 2 - 14, 9, "#c2ae8c");
    }
  } else if (f.kind === "bath") {
    body =
      rect(-w / 2, -d / 2, w, d, "#fefdf8", "#999b91", d / 2) +
      rect(-w / 2 + 6, -d / 2 + 5, w - 12, d - 10, "#e6eeee", "#bfc9c4", d / 2);
    body += circle(w / 2 - 15, 0, 2, "#8b9290");
  } else {
    body = circle(0, 0, w * 0.26, "#d1bc9b");
    for (let i = 0; i < 9; i++) {
      const a = i * 2.4;
      body += `<ellipse cx="${Math.cos(a) * w * 0.22}" cy="${Math.sin(a) * d * 0.22}" rx="${w * 0.2}" ry="${d * 0.12}" transform="rotate(${i * 137},${Math.cos(a) * w * 0.22},${Math.sin(a) * d * 0.22})" fill="${i % 2 ? "#748767" : "#91a17a"}" stroke="#647857" stroke-width="0.6"/>`;
    }
  }
  return body;
}
function dimension(x1: number, x2: number, y: number, text: string): string {
  return (
    line(x1, y, x2, y, "#888d81", 0.7) +
    line(x1, y - 8, x1, y + 12, "#888d81", 0.7) +
    line(x2, y - 8, x2, y + 12, "#888d81", 0.7) +
    line(x1 - 4, y + 4, x1 + 4, y - 4, "#656b60") +
    line(x2 - 4, y + 4, x2 + 4, y - 4, "#656b60") +
    label((x1 + x2) / 2, y - 5, text, 10)
  );
}
export function planContents(
  project: Project,
  selected: Selection = null,
  dimensions = true,
  labels = true,
): string {
  let svg = `<defs><pattern id="oak-hatch" width="48" height="9" patternUnits="userSpaceOnUse"><rect width="48" height="9" fill="#f0e9dc"/><path d="M0 0H48M0 0V9M24 0V4" stroke="#ded2be" stroke-width=".45"/></pattern><pattern id="deck-hatch" width="10" height="10" patternUnits="userSpaceOnUse"><rect width="10" height="10" fill="#d9c9ab"/><path d="M0 0V10" stroke="#baab8c" stroke-width=".65"/></pattern><pattern id="tile-hatch" width="26" height="26" patternUnits="userSpaceOnUse"><rect width="26" height="26" fill="#efeee7"/><path d="M0 0H26M0 0V26" stroke="#d6d7cd" stroke-width=".8"/></pattern></defs>`;
  svg += `<g opacity=".8">${rect(-20, -155, 840, 715, "#e9eddf", "#d4dcc9", 7)}</g>`;
  svg += rect(0, -140, 800, 140, "url(#deck-hatch)", "#9b8f78");
  svg += line(0, -137, 800, -137, "#7c816f", 2);
  for (let x = 0; x <= 800; x += 80)
    svg += rect(x - 2, -143, 4, 7, "#747b6b", "#747b6b");
  svg += label(400, -115, "LAKESIDE DECK", 10, "#726e5d", 600);
  for (const room of project.rooms) {
    const selectedRoom = selected?.type === "room" && selected.id === room.id;
    svg += `<g data-type="room" data-id="${escapeXml(room.id)}" class="plan-object">${rect(room.x * S, room.y * S, room.w * S, room.d * S, room.material === "oak" ? "url(#oak-hatch)" : room.material === "stone" ? "url(#tile-hatch)" : materials[room.material].color, "none")}`;
    if (selectedRoom)
      svg += `<rect x="${room.x * S + 6}" y="${room.y * S + 6}" width="${room.w * S - 12}" height="${room.d * S - 12}" fill="#4c8c8515" stroke="#337e78" stroke-width="1.5" stroke-dasharray="6 3"/>`;
    svg += "</g>";
  }
  svg +=
    rect(45, 40, 235, 152, "#dfdcd0", "#cfccbe", 3) +
    rect(51, 46, 223, 140, "#e9e5d9", "#d6d2c5", 2);
  svg += rect(404, 334, 176, 162, "#ded8ca", "#cec7b8", 2);
  for (const wall of project.walls) {
    const chosen = selected?.type === "wall" && selected.id === wall.id;
    svg += `<g data-type="wall" data-id="${escapeXml(wall.id)}" class="plan-object" transform="translate(${wall.x * S} ${wall.y * S}) rotate(${wall.axis === "y" ? 90 : 0})">`;
    for (const part of openingSegments(wall, project.openings)) {
      if (part.opening) continue;
      svg += rect(
        part.start * S,
        (-wall.thickness * S) / 2,
        (part.end - part.start) * S,
        wall.thickness * S,
        chosen ? "#47867d" : "#575d55",
        "#454b44",
      );
      svg += line(part.start * S, 0, part.end * S, 0, "#a9aaa0", 0.8);
    }
    svg += "</g>";
  }
  for (const o of project.openings) {
    const wall = project.walls.find((w) => w.id === o.wall)!;
    const w = o.width * S,
      t = wall.thickness * S;
    svg += `<g data-type="opening" data-id="${escapeXml(o.id)}" class="plan-object" transform="translate(${wall.x * S} ${wall.y * S}) rotate(${wall.axis === "y" ? 90 : 0}) translate(${o.offset * S} 0)">`;
    svg += `<rect x="-2" y="-8" width="${w + 4}" height="${Math.max(16, o.swing ? w + 12 : 16)}" fill="transparent"/>`;
    if (o.kind === "window" || !o.swing) {
      svg +=
        rect(0, -t / 2, w, t, "#dce9e4", "#6e8580") +
        line(0, -1.2, w, -1.2, "#799992", 0.7) +
        line(0, 1.2, w, 1.2, "#799992", 0.7);
      for (let x = 0; x <= w; x += w / Math.ceil(o.width / 1.5))
        svg += rect(x - 1.5, -t / 2, 3, t, "#5d756f", "#5d756f");
    } else {
      svg +=
        line(0, 0, 0, w, "#8a7760", 2) +
        `<path d="M ${w} 0 A ${w} ${w} 0 0 1 0 ${w}" fill="none" stroke="#9b9785" stroke-width=".8"/>`;
    }
    if (selected?.type === "opening" && selected.id === o.id)
      svg += `<rect x="-4" y="-9" width="${w + 8}" height="${o.swing ? w + 15 : 18}" fill="none" stroke="#287d79" stroke-width="2" stroke-dasharray="4 2"/>`;
    svg += "</g>";
  }
  for (const f of project.furniture) {
    svg += `<g data-type="furniture" data-id="${escapeXml(f.id)}" class="plan-object" transform="translate(${f.x * S} ${f.y * S}) rotate(${f.rotation})">${furnitureSvg(f)}`;
    if (selected?.type === "furniture" && selected.id === f.id) {
      svg += `<rect x="${-f.w * 20 - 5}" y="${-f.d * 20 - 5}" width="${f.w * 40 + 10}" height="${f.d * 40 + 10}" fill="none" stroke="#297f79" stroke-width="2" stroke-dasharray="4 2"/>`;
      for (const x of [-f.w * 20 - 5, f.w * 20 + 5])
        for (const y of [-f.d * 20 - 5, f.d * 20 + 5])
          svg += rect(x - 3, y - 3, 6, 6, "#fff", "#297f79");
    }
    svg += "</g>";
  }
  if (labels)
    for (const room of project.rooms) {
      const x = (room.x + room.w / 2) * S,
        y = (room.y + room.d - 0.75) * S;
      svg += `<g data-type="room" data-id="${escapeXml(room.id)}" class="plan-object">${rect(x - 62, y - 15, 124, 32, "#f7f4e9ed", "none", 2)}${label(x, y - 2, room.name.toUpperCase(), 9.5, "#535c52", 600)}${label(x, y + 11, `${room.w.toFixed(1)} × ${room.d.toFixed(1)} m  ·  ${area(room).toFixed(1)} m²`, 8, "#7a7f71")}</g>`;
    }
  if (dimensions) {
    svg += dimension(0, 800, -190, "20 000");
    svg +=
      dimension(0, 320, -164, "8 000") +
      dimension(320, 520, -164, "5 000") +
      dimension(520, 800, -164, "7 000");
    svg +=
      dimension(0, 200, 567, "5 000") +
      dimension(200, 360, 567, "4 000") +
      dimension(360, 600, 567, "6 000") +
      dimension(600, 800, 567, "5 000");
    svg += `<g transform="translate(-50 520) rotate(-90)">${dimension(0, 520, 0, "13 000")}${dimension(0, 240, 27, "6 000")}${dimension(240, 520, 27, "7 000")}</g>`;
    svg += `<g transform="translate(848 50)"><path d="M0 35V-12M-8 0L0-20 8 0Z" fill="#657468" stroke="#657468"/>${label(0, -28, "N", 11, "#4c5e51", 600)}</g>`;
  }
  return svg;
}
export function exportPlan(project: Project): string {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="1400" height="1120" viewBox="-110 -240 1040 835"><title>${escapeXml(project.name)} — Dimensioned floor plan</title><rect x="-110" y="-240" width="1040" height="835" fill="#fafaf5"/>${label(400, -222, project.name.toUpperCase(), 14, "#455f53", 600)}${planContents(project)}${label(400, 592, "HAVIK  /  LEVEL 1  /  DIMENSIONS IN MILLIMETRES  /  CONCEPT DESIGN", 8, "#777d72")}</svg>`;
}
interface Props {
  project: Project;
  selected: Selection;
  onSelect: (s: Selection) => void;
  onPlace: (x: number, y: number) => void;
  onMove: (id: string, x: number, y: number) => void;
  placing: boolean;
  dimensions: boolean;
  labels: boolean;
  zoom: number;
  miniature?: boolean;
}
export function Plan({
  project,
  selected,
  onSelect,
  onPlace,
  onMove,
  placing,
  dimensions,
  labels,
  zoom,
  miniature = false,
}: Props) {
  const svg = useRef<SVGSVGElement>(null);
  const start = useRef<{
    id: string;
    x: number;
    y: number;
    originalX: number;
    originalY: number;
  } | null>(null);
  const [drag, setDrag] = useState<{ id: string; x: number; y: number } | null>(
    null,
  );
  const point = (e: React.PointerEvent) => {
    const matrix = svg.current?.getScreenCTM()?.inverse();
    if (!matrix) return { x: 0, y: 0 };
    const p = new DOMPoint(e.clientX, e.clientY).matrixTransform(matrix);
    return { x: p.x / S, y: p.y / S };
  };
  const displayed = drag
    ? {
        ...project,
        furniture: project.furniture.map((f) =>
          f.id === drag.id ? { ...f, x: drag.x, y: drag.y } : f,
        ),
      }
    : project;
  return (
    <svg
      ref={svg}
      className={`floor-plan ${placing ? "placing" : ""}`}
      aria-label="Interactive floor plan"
      viewBox={`${400 - 500 / zoom} ${180 - 425 / zoom} ${1000 / zoom} ${850 / zoom}`}
      onPointerDown={(e) => {
        if (miniature) return;
        const p = point(e);
        if (placing) {
          onPlace(p.x, p.y);
          return;
        }
        const element = (e.target as Element).closest<SVGElement>(
          "[data-type]",
        );
        if (!element) {
          onSelect(null);
          return;
        }
        const type = element.dataset.type as NonNullable<Selection>["type"],
          id = element.dataset.id!;
        onSelect({ type, id });
        if (type === "furniture") {
          const f = project.furniture.find((f) => f.id === id)!;
          start.current = {
            id,
            x: p.x,
            y: p.y,
            originalX: f.x,
            originalY: f.y,
          };
          svg.current?.setPointerCapture(e.pointerId);
        }
      }}
      onPointerMove={(e) => {
        if (!start.current) return;
        const p = point(e),
          s = start.current;
        setDrag({
          id: s.id,
          x: Math.max(
            -5,
            Math.min(25, Math.round((s.originalX + p.x - s.x) * 10) / 10),
          ),
          y: Math.max(
            -5,
            Math.min(18, Math.round((s.originalY + p.y - s.y) * 10) / 10),
          ),
        });
      }}
      onPointerUp={() => {
        if (drag) onMove(drag.id, drag.x, drag.y);
        start.current = null;
        setDrag(null);
      }}
      onPointerCancel={() => {
        start.current = null;
        setDrag(null);
      }}
      dangerouslySetInnerHTML={{
        __html: planContents(displayed, selected, dimensions, labels),
      }}
    />
  );
}
