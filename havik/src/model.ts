export type Material = "oak" | "walnut" | "stone" | "linen" | "sage";
export type FurnitureKind =
  | "sofa"
  | "chair"
  | "table"
  | "bed"
  | "cabinet"
  | "plant"
  | "island"
  | "bath";
export interface Room {
  id: string;
  name: string;
  x: number;
  y: number;
  w: number;
  d: number;
  material: Material;
  ceiling: number;
}
export interface Wall {
  id: string;
  x: number;
  y: number;
  length: number;
  axis: "x" | "y";
  thickness: number;
  height: number;
}
export interface Opening {
  id: string;
  wall: string;
  offset: number;
  width: number;
  kind: "door" | "window";
  swing: boolean;
}
export interface Furniture {
  id: string;
  kind: FurnitureKind;
  name: string;
  x: number;
  y: number;
  w: number;
  d: number;
  rotation: number;
  material: Material;
}
export interface Project {
  version: 1;
  name: string;
  rooms: Room[];
  walls: Wall[];
  openings: Opening[];
  furniture: Furniture[];
}
export interface History {
  past: Project[];
  present: Project;
  future: Project[];
}
export type Selection = {
  type: "room" | "wall" | "opening" | "furniture";
  id: string;
} | null;
export type View = "plan" | "dollhouse" | "perspective";
export const STORAGE_KEY = "havik.project.v1";
export const materials: Record<Material, { label: string; color: string }> = {
  oak: { label: "Natural white oak", color: "#c6ae87" },
  walnut: { label: "Smoked walnut", color: "#80614c" },
  stone: { label: "Limestone", color: "#cecac0" },
  linen: { label: "Warm linen", color: "#e6e0d3" },
  sage: { label: "Sage green", color: "#829382" },
};
export const catalog: {
  kind: FurnitureKind;
  name: string;
  category: string;
  w: number;
  d: number;
  material: Material;
}[] = [
  {
    kind: "sofa",
    name: "Lowline sofa",
    category: "Furniture",
    w: 2.8,
    d: 1.05,
    material: "linen",
  },
  {
    kind: "chair",
    name: "Oak lounge chair",
    category: "Furniture",
    w: 0.85,
    d: 0.85,
    material: "oak",
  },
  {
    kind: "table",
    name: "Dining table",
    category: "Furniture",
    w: 2.4,
    d: 1.1,
    material: "walnut",
  },
  {
    kind: "bed",
    name: "Upholstered king bed",
    category: "Furniture",
    w: 2.05,
    d: 2.3,
    material: "linen",
  },
  {
    kind: "cabinet",
    name: "Shaker base cabinet",
    category: "Cabinets",
    w: 0.9,
    d: 0.62,
    material: "sage",
  },
  {
    kind: "island",
    name: "Waterfall island",
    category: "Cabinets",
    w: 2.8,
    d: 1.15,
    material: "stone",
  },
  {
    kind: "plant",
    name: "Fiddle-leaf fig",
    category: "Plants",
    w: 0.8,
    d: 0.8,
    material: "sage",
  },
  {
    kind: "bath",
    name: "Freestanding bathtub",
    category: "Fixtures",
    w: 1.7,
    d: 0.8,
    material: "linen",
  },
];
const f = (
  id: string,
  kind: FurnitureKind,
  x: number,
  y: number,
  w: number,
  d: number,
  rotation = 0,
  material: Material = "oak",
): Furniture => ({
  id,
  kind,
  x,
  y,
  w,
  d,
  rotation,
  material,
  name: catalog.find((c) => c.kind === kind)!.name,
});
export function createProject(): Project {
  return {
    version: 1,
    name: "Cedar Point Lake House",
    rooms: [
      {
        id: "living",
        name: "Great Room",
        x: 0,
        y: 0,
        w: 8,
        d: 7,
        material: "oak",
        ceiling: 3.2,
      },
      {
        id: "kitchen",
        name: "Kitchen & Dining",
        x: 8,
        y: 0,
        w: 5,
        d: 7,
        material: "oak",
        ceiling: 3.2,
      },
      {
        id: "primary",
        name: "Primary Suite",
        x: 13,
        y: 0,
        w: 7,
        d: 7,
        material: "oak",
        ceiling: 2.8,
      },
      {
        id: "studio",
        name: "Study",
        x: 0,
        y: 7,
        w: 5,
        d: 6,
        material: "oak",
        ceiling: 2.8,
      },
      {
        id: "entry",
        name: "Foyer",
        x: 5,
        y: 7,
        w: 4,
        d: 6,
        material: "stone",
        ceiling: 3.2,
      },
      {
        id: "guest",
        name: "Guest Bedroom",
        x: 9,
        y: 7,
        w: 6,
        d: 6,
        material: "oak",
        ceiling: 2.8,
      },
      {
        id: "bathroom",
        name: "Bath & Laundry",
        x: 15,
        y: 7,
        w: 5,
        d: 6,
        material: "stone",
        ceiling: 2.8,
      },
    ],
    walls: [
      {
        id: "north",
        x: 0,
        y: 0,
        length: 20,
        axis: "x",
        thickness: 0.24,
        height: 3.2,
      },
      {
        id: "south",
        x: 0,
        y: 13,
        length: 20,
        axis: "x",
        thickness: 0.24,
        height: 3.2,
      },
      {
        id: "west",
        x: 0,
        y: 0,
        length: 13,
        axis: "y",
        thickness: 0.24,
        height: 3.2,
      },
      {
        id: "east",
        x: 20,
        y: 0,
        length: 13,
        axis: "y",
        thickness: 0.24,
        height: 3.2,
      },
      {
        id: "hall",
        x: 0,
        y: 7,
        length: 20,
        axis: "x",
        thickness: 0.15,
        height: 2.8,
      },
      {
        id: "suite",
        x: 13,
        y: 0,
        length: 7,
        axis: "y",
        thickness: 0.15,
        height: 2.8,
      },
      {
        id: "study",
        x: 5,
        y: 7,
        length: 6,
        axis: "y",
        thickness: 0.15,
        height: 2.8,
      },
      {
        id: "guest",
        x: 9,
        y: 7,
        length: 6,
        axis: "y",
        thickness: 0.15,
        height: 2.8,
      },
      {
        id: "bath",
        x: 15,
        y: 7,
        length: 6,
        axis: "y",
        thickness: 0.15,
        height: 2.8,
      },
    ],
    openings: [
      {
        id: "glass-living",
        wall: "north",
        offset: 1,
        width: 6,
        kind: "window",
        swing: false,
      },
      {
        id: "glass-dining",
        wall: "north",
        offset: 8.2,
        width: 3.7,
        kind: "door",
        swing: false,
      },
      {
        id: "glass-suite",
        wall: "north",
        offset: 14.4,
        width: 4.3,
        kind: "window",
        swing: false,
      },
      {
        id: "entry-door",
        wall: "south",
        offset: 6.2,
        width: 1.6,
        kind: "door",
        swing: true,
      },
      {
        id: "study-window",
        wall: "south",
        offset: 1.1,
        width: 2.6,
        kind: "window",
        swing: false,
      },
      {
        id: "guest-window",
        wall: "south",
        offset: 10.2,
        width: 3.3,
        kind: "window",
        swing: false,
      },
      {
        id: "bath-window",
        wall: "east",
        offset: 9,
        width: 2.1,
        kind: "window",
        swing: false,
      },
      {
        id: "west-window",
        wall: "west",
        offset: 1.8,
        width: 3.4,
        kind: "window",
        swing: false,
      },
      {
        id: "suite-window",
        wall: "east",
        offset: 1.8,
        width: 3.4,
        kind: "window",
        swing: false,
      },
      {
        id: "foyer-opening",
        wall: "hall",
        offset: 5.6,
        width: 2.8,
        kind: "door",
        swing: false,
      },
      {
        id: "guest-door",
        wall: "hall",
        offset: 9.8,
        width: 0.9,
        kind: "door",
        swing: true,
      },
      {
        id: "study-door",
        wall: "hall",
        offset: 3.6,
        width: 0.9,
        kind: "door",
        swing: true,
      },
      {
        id: "suite-door",
        wall: "suite",
        offset: 5.6,
        width: 0.9,
        kind: "door",
        swing: true,
      },
      {
        id: "bath-door",
        wall: "bath",
        offset: 0.5,
        width: 0.9,
        kind: "door",
        swing: true,
      },
    ],
    furniture: [
      f("sofa-1", "sofa", 3.8, 4.1, 3.6, 1.1, 0, "linen"),
      f("lounge-1", "chair", 1.7, 2.35, 0.95, 0.95, 35, "sage"),
      f("lounge-2", "chair", 6.25, 2.3, 0.95, 0.95, -35, "sage"),
      f("coffee", "table", 3.9, 2.8, 1.8, 0.8, 0, "walnut"),
      f("plant-living", "plant", 0.75, 0.75, 0.8, 0.8),
      f("console", "cabinet", 3.3, 6.45, 3.5, 0.5, 0, "walnut"),
      f("island", "island", 10.2, 4.65, 3.1, 1.1, 0, "stone"),
      f("dining", "table", 10.25, 1.9, 2.7, 1.15, 0, "oak"),
      ...[8.65, 9.65, 10.65, 11.65].map((x, i) =>
        f(`kitchen-${i}`, "cabinet", x, 6.6, 0.96, 0.62, 0, "sage"),
      ),
      f("primary-bed", "bed", 16.5, 3.7, 2.2, 2.5, 0, "linen"),
      f("nightstand-1", "cabinet", 14.85, 4.6, 0.65, 0.6, 0, "walnut"),
      f("nightstand-2", "cabinet", 18.15, 4.6, 0.65, 0.6, 0, "walnut"),
      f("wardrobe", "cabinet", 19.55, 5.3, 2.7, 0.65, 90, "oak"),
      f("suite-plant", "plant", 19.1, 0.9, 0.85, 0.85),
      f("desk", "table", 2.4, 11.25, 2.4, 0.85, 0, "walnut"),
      f("desk-chair", "chair", 2.4, 10.25, 0.8, 0.8),
      f("bookcase", "cabinet", 0.45, 9.8, 2.7, 0.55, 90, "oak"),
      f("entry-console", "cabinet", 5.5, 10.2, 1.8, 0.5, 90, "walnut"),
      f("entry-plant", "plant", 8.2, 11.9, 0.75, 0.75),
      f("guest-bed", "bed", 12.25, 10.9, 2, 2.3, 0, "sage"),
      f("guest-side", "cabinet", 10.75, 11.7, 0.65, 0.6, 0, "oak"),
      f("guest-side-2", "cabinet", 13.75, 11.7, 0.65, 0.6, 0, "oak"),
      f("tub", "bath", 18.8, 9.9, 2, 0.9, 90, "linen"),
      f("vanity", "cabinet", 17, 12.5, 2.5, 0.65, 0, "oak"),
      f("deck-lounge-1", "chair", 3, -2.1, 0.95, 1.4, 0, "linen"),
      f("deck-lounge-2", "chair", 4.7, -2.1, 0.95, 1.4, 0, "linen"),
      f("deck-table", "table", 10, -2.1, 2.7, 1.1, 0, "oak"),
      f("deck-plant", "plant", 18.8, -2.65, 0.9, 0.9),
    ],
  };
}
export const area = (room: Room) => room.w * room.d;
export const totalArea = (project: Project) =>
  project.rooms.reduce((sum, r) => sum + area(r), 0);
export function transact(history: History, project: Project): History {
  if (JSON.stringify(project) === JSON.stringify(history.present))
    return history;
  return {
    past: [...history.past.slice(-49), history.present],
    present: project,
    future: [],
  };
}
export function undo(history: History): History {
  if (!history.past.length) return history;
  return {
    past: history.past.slice(0, -1),
    present: history.past.at(-1)!,
    future: [history.present, ...history.future],
  };
}
export function redo(history: History): History {
  if (!history.future.length) return history;
  return {
    past: [...history.past, history.present],
    present: history.future[0],
    future: history.future.slice(1),
  };
}
export function placeFurniture(
  project: Project,
  kind: FurnitureKind,
  x: number,
  y: number,
  id: string,
): Project {
  const item = catalog.find((c) => c.kind === kind)!;
  const object: Furniture = {
    id,
    kind,
    name: item.name,
    w: item.w,
    d: item.d,
    material: item.material,
    x: Math.round(x * 10) / 10,
    y: Math.round(y * 10) / 10,
    rotation: 0,
  };
  return { ...project, furniture: [...project.furniture, object] };
}
export function openingSegments(
  wall: Wall,
  openings: Opening[],
): { start: number; end: number; opening?: Opening }[] {
  const segments: { start: number; end: number; opening?: Opening }[] = [];
  let cursor = 0;
  for (const opening of openings
    .filter((o) => o.wall === wall.id)
    .sort((a, b) => a.offset - b.offset)) {
    if (opening.offset > cursor)
      segments.push({ start: cursor, end: opening.offset });
    segments.push({
      start: opening.offset,
      end: opening.offset + opening.width,
      opening,
    });
    cursor = opening.offset + opening.width;
  }
  if (cursor < wall.length) segments.push({ start: cursor, end: wall.length });
  return segments;
}
export function openingError(project: Project, opening: Opening): string {
  const wall = project.walls.find((w) => w.id === opening.wall);
  if (
    !wall ||
    opening.width < 0.4 ||
    opening.width > 8 ||
    opening.offset < 0.2 ||
    opening.offset + opening.width > wall.length - 0.2
  )
    return "Opening must fit within the wall, with 0.2 m clearance.";
  if (
    project.openings.some(
      (o) =>
        o.id !== opening.id &&
        o.wall === opening.wall &&
        opening.offset < o.offset + o.width + 0.1 &&
        opening.offset + opening.width + 0.1 > o.offset,
    )
  )
    return "This opening overlaps another door or window.";
  return "";
}
const object = (value: unknown): value is Record<string, unknown> =>
  typeof value === "object" && value !== null && !Array.isArray(value);
const number = (value: unknown, min: number, max: number): value is number =>
  typeof value === "number" &&
  Number.isFinite(value) &&
  value >= min &&
  value <= max;
const text = (value: unknown): value is string =>
  typeof value === "string" && value.length > 0 && value.length <= 100;
const material = (value: unknown): value is Material =>
  typeof value === "string" && Object.hasOwn(materials, value);
export function parseProject(raw: string): Project {
  const p: unknown = JSON.parse(raw);
  if (
    !object(p) ||
    p.version !== 1 ||
    !text(p.name) ||
    !Array.isArray(p.rooms) ||
    !Array.isArray(p.walls) ||
    !Array.isArray(p.openings) ||
    !Array.isArray(p.furniture)
  )
    throw new Error("Not a Havik version 1 project.");
  if (
    p.rooms.length < 1 ||
    p.rooms.length > 100 ||
    p.walls.length > 200 ||
    p.furniture.length > 500 ||
    p.openings.length > 200
  )
    throw new Error("Project exceeds supported object limits.");
  const rooms: Room[] = p.rooms.map((r: unknown) => {
    if (
      !object(r) ||
      !text(r.id) ||
      !text(r.name) ||
      !number(r.x, -50, 50) ||
      !number(r.y, -50, 50) ||
      !number(r.w, 0.5, 50) ||
      !number(r.d, 0.5, 50) ||
      !number(r.ceiling, 2, 6) ||
      !material(r.material)
    )
      throw new Error("Invalid room data.");
    return {
      id: r.id,
      name: r.name,
      x: r.x,
      y: r.y,
      w: r.w,
      d: r.d,
      ceiling: r.ceiling,
      material: r.material,
    };
  });
  const walls: Wall[] = p.walls.map((w: unknown) => {
    if (
      !object(w) ||
      !text(w.id) ||
      !number(w.x, -50, 50) ||
      !number(w.y, -50, 50) ||
      !number(w.length, 0.5, 50) ||
      !number(w.thickness, 0.08, 0.6) ||
      !number(w.height, 2, 6) ||
      (w.axis !== "x" && w.axis !== "y")
    )
      throw new Error("Invalid wall data.");
    return {
      id: w.id,
      x: w.x,
      y: w.y,
      length: w.length,
      thickness: w.thickness,
      height: w.height,
      axis: w.axis,
    };
  });
  const openings: Opening[] = p.openings.map((o: unknown) => {
    if (
      !object(o) ||
      !text(o.id) ||
      !text(o.wall) ||
      !number(o.offset, 0, 50) ||
      !number(o.width, 0.4, 8) ||
      (o.kind !== "door" && o.kind !== "window") ||
      typeof o.swing !== "boolean"
    )
      throw new Error("Invalid opening data.");
    return {
      id: o.id,
      wall: o.wall,
      offset: o.offset,
      width: o.width,
      kind: o.kind,
      swing: o.swing,
    };
  });
  const furniture: Furniture[] = p.furniture.map((f: unknown) => {
    if (
      !object(f) ||
      !text(f.id) ||
      !text(f.name) ||
      !number(f.x, -50, 50) ||
      !number(f.y, -50, 50) ||
      !number(f.w, 0.2, 10) ||
      !number(f.d, 0.2, 10) ||
      !number(f.rotation, -360, 360) ||
      !material(f.material) ||
      !catalog.some((c) => c.kind === f.kind)
    )
      throw new Error("Invalid furniture data.");
    return {
      id: f.id,
      name: f.name,
      kind: f.kind as FurnitureKind,
      x: f.x,
      y: f.y,
      w: f.w,
      d: f.d,
      rotation: f.rotation,
      material: f.material,
    };
  });
  const result: Project = {
    version: 1,
    name: p.name,
    rooms,
    walls,
    openings,
    furniture,
  };
  for (const collection of [rooms, walls, openings, furniture]) {
    if (new Set(collection.map((item) => item.id)).size !== collection.length)
      throw new Error("Duplicate object identifiers.");
  }
  if (openings.some((o) => openingError(result, o)))
    throw new Error("Invalid or overlapping openings.");
  return result;
}
export const serializeProject = (project: Project) =>
  JSON.stringify(project, null, 2);
export const escapeXml = (value: string) =>
  value.replace(
    /[&<>"']/g,
    (char) =>
      ({
        "&": "&amp;",
        "<": "&lt;",
        ">": "&gt;",
        '"': "&quot;",
        "'": "&apos;",
      })[char]!,
  );
