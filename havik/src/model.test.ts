import { describe, expect, it } from "vitest";
import {
  area,
  catalog,
  createProject,
  openingError,
  openingSegments,
  parseProject,
  placeFurniture,
  redo,
  serializeProject,
  totalArea,
  transact,
  undo,
} from "./model";
import type { History } from "./model";
import { exportPlan, planContents } from "./plan";

describe("architectural geometry", () => {
  it("partitions the 20 × 13 m interior into seven non-overlapping furnished rooms", () => {
    const p = createProject();
    expect(totalArea(p)).toBe(260);
    expect(area(p.rooms[0])).toBe(56);
    for (const r of p.rooms)
      for (const s of p.rooms.filter((s) => s.id !== r.id)) {
        const overlapX = Math.min(r.x + r.w, s.x + s.w) - Math.max(r.x, s.x);
        const overlapY = Math.min(r.y + r.d, s.y + s.d) - Math.max(r.y, s.y);
        expect(overlapX > 0 && overlapY > 0).toBe(false);
      }
    expect(p.furniture.length).toBeGreaterThan(30);
    expect(p.openings.every((o) => !openingError(p, o))).toBe(true);
  });
  it("splits every wall around its real door and window openings without losing length", () => {
    const p = createProject();
    for (const wall of p.walls) {
      const segments = openingSegments(wall, p.openings);
      expect(segments.reduce((sum, s) => sum + s.end - s.start, 0)).toBeCloseTo(
        wall.length,
        8,
      );
      expect(segments[0].start).toBe(0);
      expect(segments.at(-1)!.end).toBe(wall.length);
      segments.forEach((s, i) => {
        expect(s.end).toBeGreaterThan(s.start);
        if (i > 0) expect(s.start).toBeCloseTo(segments[i - 1].end, 8);
      });
    }
  });
  it("rejects wall overflow, nonexistent wall references, and collisions between openings", () => {
    const p = createProject(),
      o = p.openings[0];
    expect(openingError(p, { ...o, width: 25 })).toMatch(/within the wall/);
    expect(openingError(p, { ...o, wall: "unknown" })).toMatch(
      /within the wall/,
    );
    expect(openingError(p, { ...o, offset: 7, width: 3 })).toMatch(/overlaps/);
    expect(openingError(p, { ...o, width: 5.5 })).toBe("");
  });
});
describe("editing and history", () => {
  it("places every library type at snapped coordinates without mutating the prior state", () => {
    const p = createProject(),
      before = serializeProject(p);
    for (const c of catalog) {
      const next = placeFurniture(p, c.kind, 3.14, 2.76, `test-${c.kind}`);
      expect(next.furniture.at(-1)).toMatchObject({
        kind: c.kind,
        x: 3.1,
        y: 2.8,
        w: c.w,
        d: c.d,
      });
      expect(parseProject(serializeProject(next))).toEqual(next);
    }
    expect(serializeProject(p)).toBe(before);
  });
  it("restores edits, placement, and material changes exactly through undo/redo", () => {
    const p = createProject();
    let h: History = { past: [], present: p, future: [] };
    h = transact(h, {
      ...p,
      rooms: p.rooms.map((r) =>
        r.id === "living"
          ? { ...r, name: "Lake Lounge", material: "walnut" }
          : r,
      ),
    });
    const renamed = h.present;
    h = transact(h, placeFurniture(h.present, "chair", 5, 5, "new-chair"));
    const placed = h.present;
    h = undo(h);
    expect(h.present).toEqual(renamed);
    h = undo(h);
    expect(h.present).toEqual(p);
    h = redo(redo(h));
    expect(h.present).toEqual(placed);
    h = undo(h);
    h = transact(h, { ...h.present, name: "Alternate" });
    expect(h.future).toEqual([]);
  });
  it("bounds history, ignores identical writes, and safely handles empty history", () => {
    let h: History = { past: [], present: createProject(), future: [] };
    expect(undo(h)).toBe(h);
    expect(redo(h)).toBe(h);
    expect(transact(h, structuredClone(h.present))).toBe(h);
    for (let i = 0; i < 60; i++)
      h = transact(h, { ...h.present, name: `Revision ${i}` });
    expect(h.past).toHaveLength(50);
  });
});
describe("persistence validation", () => {
  it("round-trips the complete project and all edits without losing geometry", () => {
    const p = createProject();
    p.rooms[0].name = "Lake Lounge";
    p.rooms[0].material = "walnut";
    p.walls[0].thickness = 0.4;
    p.openings[0].width = 5.5;
    p.furniture[0].rotation = 45;
    expect(parseProject(serializeProject(p))).toEqual(p);
  });
  it.each([
    ["invalid JSON", "{oops"],
    ["unsupported version", JSON.stringify({ ...createProject(), version: 3 })],
    ["missing collections", JSON.stringify({ version: 1, name: "bad" })],
    ["null input", "null"],
    [
      "unknown material",
      JSON.stringify({
        ...createProject(),
        rooms: [{ ...createProject().rooms[0], material: "__proto__" }],
      }),
    ],
    [
      "non-finite value",
      JSON.stringify({
        ...createProject(),
        furniture: [{ ...createProject().furniture[0], x: Infinity }],
      }),
    ],
    [
      "negative wall length",
      JSON.stringify({
        ...createProject(),
        walls: [{ ...createProject().walls[0], length: -1 }],
      }),
    ],
    [
      "duplicate ids",
      JSON.stringify({
        ...createProject(),
        furniture: [createProject().furniture[0], createProject().furniture[0]],
      }),
    ],
    [
      "oversized collection",
      JSON.stringify({
        ...createProject(),
        furniture: Array.from({ length: 501 }, (_, i) => ({
          ...createProject().furniture[0],
          id: `${i}`,
        })),
      }),
    ],
  ])("rejects %s", (_name, raw) => expect(() => parseProject(raw)).toThrow());
  it("does not copy unrecognized input properties into the trusted model", () => {
    const raw = JSON.stringify({
      ...createProject(),
      trackingUrl: "https://example.com",
      rooms: createProject().rooms.map((r) => ({ ...r, script: "bad" })),
    });
    const p = parseProject(raw);
    expect(serializeProject(p)).not.toContain("trackingUrl");
    expect(serializeProject(p)).not.toContain("script");
  });
});
describe("real vector exports", () => {
  it("exports geometry, dimensions, door swings, furnishing outlines and edited labels", () => {
    const p = createProject();
    p.rooms[0].name = "Lake Lounge";
    const svg = exportPlan(p);
    expect(svg).toContain('xmlns="http://www.w3.org/2000/svg"');
    expect(svg).toContain("LAKE LOUNGE");
    expect(svg).toContain("20 000");
    expect(svg).toContain('data-type="furniture"');
    expect(svg).toContain("A 36 36");
    expect(svg).not.toContain("<image");
    expect(svg).not.toContain("data:image");
  });
  it("escapes imported labels, names and identifiers before generating SVG", () => {
    const p = createProject();
    p.name = "Home <script>alert(1)</script>";
    p.rooms[0].name = '<image onload="alert(1)">';
    p.furniture[0].id = 'x" onclick="bad';
    const svg = exportPlan(p);
    expect(svg).not.toContain("<script>");
    expect(svg).not.toContain("<image");
    expect(svg).toContain("&lt;script&gt;");
    expect(svg).toContain('data-id="x&quot; onclick=&quot;bad"');
  });
  it("renders current furniture positions, hidden plan labels, and selection separately", () => {
    const p = createProject();
    p.furniture[0].x = 8;
    const svg = planContents(
      p,
      { type: "furniture", id: p.furniture[0].id },
      false,
      false,
    );
    expect(svg).toContain("translate(320 164)");
    expect(svg).toContain('stroke="#297f79"');
    expect(svg).not.toContain("GREAT ROOM");
    expect(svg).not.toContain("20 000");
  });
});
