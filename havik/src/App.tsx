import { useEffect, useRef, useState } from "react";
import {
  ArrowDownToLine,
  ArrowUpFromLine,
  BookOpen,
  Box,
  BrickWall,
  Camera,
  Check,
  ChevronDown,
  ChevronRight,
  CircleHelp,
  Columns3,
  Copy,
  DoorOpen,
  Download,
  Eye,
  EyeOff,
  FileImage,
  FileJson,
  Folder,
  FolderOpen,
  Grid2x2,
  Home,
  House,
  Layers,
  Leaf,
  Maximize,
  MousePointer2,
  PanelRight,
  PencilRuler,
  Redo2,
  RotateCcw,
  RotateCw,
  Ruler,
  Save,
  Search,
  Settings2,
  Sofa,
  Square,
  Sun,
  Trash2,
  Undo2,
  X,
  ZoomIn,
  ZoomOut,
} from "lucide-react";
import type { LucideIcon } from "lucide-react";
import Scene from "./Scene";
import { Plan, exportPlan, furnitureSvg } from "./plan";
import {
  STORAGE_KEY,
  area,
  catalog,
  createProject,
  materials,
  openingError,
  parseProject,
  placeFurniture,
  redo,
  serializeProject,
  totalArea,
  transact,
  undo,
} from "./model";
import type {
  Furniture,
  FurnitureKind,
  History,
  Opening,
  Project,
  Room,
  Selection,
  View,
  Wall,
} from "./model";

type Tool = "select" | FurnitureKind | "wall" | "door" | "window";
function ToolButton({
  icon: Icon,
  label,
  active,
  disabled,
  onClick,
  color,
  text = false,
}: {
  icon: LucideIcon;
  label: string;
  active?: boolean;
  disabled?: boolean;
  onClick: () => void;
  color?: string;
  text?: boolean;
}) {
  return (
    <button
      className={`tool-button ${active ? "active" : ""} ${text ? "with-text" : ""}`}
      aria-label={label}
      title={label}
      aria-pressed={active}
      disabled={disabled}
      onClick={onClick}
    >
      <Icon size={19} strokeWidth={1.6} style={{ color }} />
      {text && <span>{label}</span>}
    </button>
  );
}
function download(blob: Blob, name: string) {
  const url = URL.createObjectURL(blob),
    a = document.createElement("a");
  a.href = url;
  a.download = name;
  a.click();
  setTimeout(() => URL.revokeObjectURL(url), 1500);
}
function initialHistory(): History {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    return {
      past: [],
      present: raw ? parseProject(raw) : createProject(),
      future: [],
    };
  } catch {
    return { past: [], present: createProject(), future: [] };
  }
}
function Properties({
  selection,
  project,
  onChange,
  onDelete,
}: {
  selection: Selection;
  project: Project;
  onChange: (p: Project) => void;
  onDelete: () => void;
}) {
  const item =
    selection?.type === "room"
      ? project.rooms.find((r) => r.id === selection.id)
      : selection?.type === "wall"
        ? project.walls.find((r) => r.id === selection.id)
        : selection?.type === "opening"
          ? project.openings.find((r) => r.id === selection.id)
          : project.furniture.find((r) => r.id === selection?.id);
  if (!item || !selection)
    return (
      <div className="no-selection">
        <MousePointer2 size={25} />
        <strong>Select an object</strong>
        <span>Click a room, wall or furnishing to open its specification.</span>
        <div className="project-metrics">
          <b>
            {totalArea(project).toFixed(0)}
            <small>m² LIVING AREA</small>
          </b>
          <b>
            {project.rooms.length}
            <small>ROOMS</small>
          </b>
        </div>
      </div>
    );
  return (
    <PropertyForm
      key={`${selection.type}-${JSON.stringify(item)}`}
      selection={selection}
      item={item}
      project={project}
      onChange={onChange}
      onDelete={onDelete}
    />
  );
}
function PropertyForm({
  selection,
  item,
  project,
  onChange,
  onDelete,
}: {
  selection: NonNullable<Selection>;
  item: Room | Wall | Opening | Furniture;
  project: Project;
  onChange: (p: Project) => void;
  onDelete: () => void;
}) {
  const [draft, setDraft] = useState(item);
  const [error, setError] = useState("");
  const update = (key: string, value: string | number | boolean) =>
    setDraft((d) => ({ ...d, [key]: value }));
  const numeric = (
    label: string,
    key: string,
    value: number,
    min: number,
    max: number,
    step = 0.1,
  ) => (
    <label>
      {label}
      <div className="unit-input">
        <input
          aria-label={label}
          type="number"
          value={Number.isNaN(value) ? "" : value}
          min={min}
          max={max}
          step={step}
          required
          onChange={(e) => update(key, e.target.valueAsNumber)}
        />
        <span>{key === "rotation" ? "°" : "m"}</span>
      </div>
    </label>
  );
  return (
    <form
      className="property-form"
      onSubmit={(e) => {
        e.preventDefault();
        setError("");
        let next = project;
        if (selection.type === "room")
          next = {
            ...project,
            rooms: project.rooms.map((r) =>
              r.id === item.id ? (draft as Room) : r,
            ),
          };
        if (selection.type === "wall")
          next = {
            ...project,
            walls: project.walls.map((r) =>
              r.id === item.id ? (draft as Wall) : r,
            ),
          };
        if (selection.type === "opening") {
          const error = openingError(project, draft as Opening);
          if (error) {
            setError(error);
            return;
          }
          next = {
            ...project,
            openings: project.openings.map((r) =>
              r.id === item.id ? (draft as Opening) : r,
            ),
          };
        }
        if (selection.type === "furniture")
          next = {
            ...project,
            furniture: project.furniture.map((r) =>
              r.id === item.id ? (draft as Furniture) : r,
            ),
          };
        try {
          onChange(parseProject(serializeProject(next)));
        } catch (e) {
          setError(e instanceof Error ? e.message : "Invalid object values.");
        }
      }}
    >
      <div className="property-heading">
        <span className="selection-dot" />
        <strong>
          {"name" in draft
            ? draft.name
            : selection.type === "wall"
              ? `${draft.id} wall`
              : (draft as Opening).kind === "door"
                ? "Door specification"
                : "Window specification"}
        </strong>
        <span>{selection.type.toUpperCase()}</span>
      </div>
      {"name" in draft && (
        <label className="full">
          Name
          <input
            aria-label="Object name"
            value={draft.name}
            maxLength={80}
            required
            onChange={(e) => update("name", e.target.value)}
          />
        </label>
      )}
      {selection.type === "room" && (
        <>
          <div className="readout">
            <span>Floor area</span>
            <strong>{area(draft as Room).toFixed(1)} m²</strong>
            <span>Interior dimensions</span>
            <strong>
              {(draft as Room).w.toFixed(1)} × {(draft as Room).d.toFixed(1)} m
            </strong>
          </div>
          {numeric("Ceiling height", "ceiling", (draft as Room).ceiling, 2, 6)}
        </>
      )}
      {selection.type === "wall" && (
        <>
          <div className="readout">
            <span>Wall length</span>
            <strong>{(draft as Wall).length.toFixed(2)} m</strong>
            <span>Wall type</span>
            <strong>
              {(draft as Wall).thickness > 0.2
                ? "Exterior / timber"
                : "Interior / partition"}
            </strong>
          </div>
          <div className="form-row">
            {numeric(
              "Wall thickness",
              "thickness",
              (draft as Wall).thickness,
              0.08,
              0.6,
              0.01,
            )}
            {numeric("Wall height", "height", (draft as Wall).height, 2, 6)}
          </div>
        </>
      )}
      {selection.type === "opening" && (
        <>
          <div className="form-row">
            {numeric(
              "Opening width",
              "width",
              (draft as Opening).width,
              0.4,
              8,
            )}
            {numeric(
              "Wall offset",
              "offset",
              (draft as Opening).offset,
              0.2,
              49,
            )}
          </div>
          {(draft as Opening).kind === "door" && (
            <label className="checkbox">
              <input
                type="checkbox"
                checked={(draft as Opening).swing}
                onChange={(e) => update("swing", e.target.checked)}
              />{" "}
              Hinged door / show swing
            </label>
          )}
        </>
      )}
      {selection.type === "furniture" && (
        <>
          <div className="form-row">
            {numeric("Position X", "x", (draft as Furniture).x, -50, 50)}
            {numeric("Position Y", "y", (draft as Furniture).y, -50, 50)}
          </div>
          <div className="form-row">
            {numeric("Width", "w", (draft as Furniture).w, 0.2, 10)}
            {numeric("Depth", "d", (draft as Furniture).d, 0.2, 10)}
          </div>
          {numeric(
            "Rotation",
            "rotation",
            (draft as Furniture).rotation,
            -360,
            360,
            15,
          )}
        </>
      )}
      {"material" in draft && (
        <label className="full">
          Material
          <select
            aria-label="Material"
            value={draft.material}
            onChange={(e) => update("material", e.target.value)}
          >
            {Object.entries(materials).map(([key, mat]) => (
              <option key={key} value={key}>
                {mat.label}
              </option>
            ))}
          </select>
          <div className="swatch-row">
            {Object.entries(materials).map(([key, mat]) => (
              <button
                type="button"
                key={key}
                aria-label={`Use ${mat.label}`}
                title={mat.label}
                className={draft.material === key ? "selected" : ""}
                style={{ background: mat.color }}
                onClick={() => update("material", key)}
              >
                {draft.material === key && <Check size={12} />}
              </button>
            ))}
          </div>
        </label>
      )}
      {error && (
        <div className="form-error" role="alert">
          {error}
        </div>
      )}
      <div className="form-actions">
        <button className="apply" type="submit">
          <Check size={14} />
          Apply changes
        </button>
        {selection.type !== "room" && (
          <button
            type="button"
            className="delete"
            title="Delete selected object"
            aria-label="Delete selected object"
            onClick={onDelete}
          >
            <Trash2 size={15} />
          </button>
        )}
      </div>
    </form>
  );
}
export default function App() {
  const [history, setHistory] = useState<History>(initialHistory);
  const project = history.present;
  const [selected, setSelected] = useState<Selection>({
    type: "room",
    id: "living",
  });
  const [view, setView] = useState<View>("dollhouse");
  const [tool, setTool] = useState<Tool>("select");
  const [roof, setRoof] = useState(false),
    [terrain, setTerrain] = useState(true),
    [level, setLevel] = useState(true);
  const [labels, setLabels] = useState(true),
    [dimensions, setDimensions] = useState(true);
  const [sidebar, setSidebar] = useState(true),
    [inset, setInset] = useState(true),
    [zoom, setZoom] = useState(1);
  const [preset, setPreset] = useState(0),
    [sideTab, setSideTab] = useState("Library Browser");
  const [category, setCategory] = useState("All Content"),
    [search, setSearch] = useState("");
  const [menu, setMenu] = useState<string | null>(null),
    [dialog, setDialog] = useState<"help" | "reset" | null>(null);
  const [message, setMessage] = useState(""),
    [saveError, setSaveError] = useState("");
  const [wallStart, setWallStart] = useState<{ x: number; y: number } | null>(
    null,
  );
  const fileInput = useRef<HTMLInputElement>(null);
  const exportRef = useRef<(() => Promise<Blob | null>) | null>(null);
  const change = (p: Project) => {
    try {
      const validated = parseProject(serializeProject(p));
      setHistory((h) => transact(h, validated));
    } catch (error) {
      setMessage(error instanceof Error ? error.message : "Invalid project edit.");
    }
  };
  const cameraPreset = (index: number) =>
    setPreset((p) => p + 3 - (p % 3) + index);
  useEffect(() => {
    try {
      localStorage.setItem(STORAGE_KEY, serializeProject(project));
      setSaveError("");
    } catch {
      setSaveError(
        "Local storage is unavailable. Export a project file to save your work.",
      );
    }
  }, [project]);
  useEffect(() => {
    if (!message) return;
    const id = setTimeout(() => setMessage(""), 5500);
    return () => clearTimeout(id);
  }, [message]);
  const doUndo = () => {
    setHistory(undo);
    setSelected(null);
  };
  const doRedo = () => {
    setHistory(redo);
    setSelected(null);
  };
  const remove = () => {
    if (!selected || selected.type === "room") return;
    if (selected.type === "furniture")
      change({
        ...project,
        furniture: project.furniture.filter((f) => f.id !== selected.id),
      });
    if (selected.type === "opening")
      change({
        ...project,
        openings: project.openings.filter((f) => f.id !== selected.id),
      });
    if (selected.type === "wall")
      change({
        ...project,
        walls: project.walls.filter((f) => f.id !== selected.id),
        openings: project.openings.filter((o) => o.wall !== selected.id),
      });
    setSelected(null);
  };
  const duplicate = () => {
    if (selected?.type !== "furniture") return;
    const f = project.furniture.find((f) => f.id === selected.id);
    if (!f) return;
    const id = crypto.randomUUID();
    change({
      ...project,
      furniture: [
        ...project.furniture,
        { ...f, id, x: f.x + 0.5, y: f.y + 0.5 },
      ],
    });
    setSelected({ type: "furniture", id });
  };
  const chooseTool = (t: Tool) => {
    setTool(t);
    setWallStart(null);
    if (t === "wall" || t === "door" || t === "window") setView("plan");
  };
  const save = () => {
    try {
      localStorage.setItem(STORAGE_KEY, serializeProject(project));
      setMessage("Project saved to this browser.");
      setSaveError("");
    } catch {
      setSaveError("Local save failed. Export a project file instead.");
    }
  };
  useEffect(() => {
    const key = (e: KeyboardEvent) => {
      if (e.key === "Escape") {
        chooseTool("select");
        setMenu(null);
        setDialog(null);
        return;
      }
      if (dialog) return;
      if (
        e.target instanceof HTMLElement &&
        (e.target.matches("input,textarea,select") ||
          e.target.isContentEditable)
      )
        return;
      if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === "z") {
        e.preventDefault();
        if (e.shiftKey) doRedo();
        else doUndo();
      }
      if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === "y") {
        e.preventDefault();
        doRedo();
      }
      if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === "s") {
        e.preventDefault();
        save();
      }
      if (e.key === "Delete" || e.key === "Backspace") {
        e.preventDefault();
        remove();
      }
      if (e.key === "1") setView("plan");
      if (e.key === "2") setView("dollhouse");
      if (e.key === "3") setView("perspective");
    };
    window.addEventListener("keydown", key);
    return () => window.removeEventListener("keydown", key);
  });
  const place = (x: number, y: number) => {
    if (x < -5 || x > 25 || y < -5 || y > 18) {
      setMessage("Place objects within the project site.");
      return;
    }
    const id = crypto.randomUUID();
    if (tool === "wall") {
      if (!wallStart) {
        setWallStart({
          x: Math.round(x * 10) / 10,
          y: Math.round(y * 10) / 10,
        });
        setMessage("Click the other end of your partition wall.");
        return;
      }
      const axis =
        Math.abs(x - wallStart.x) >= Math.abs(y - wallStart.y) ? "x" : "y";
      const length =
        Math.round(
          Math.abs(axis === "x" ? x - wallStart.x : y - wallStart.y) * 10,
        ) / 10;
      if (length < 0.5) {
        setMessage("A wall must be at least 0.5 m long.");
        return;
      }
      change({
        ...project,
        walls: [
          ...project.walls,
          {
            id,
            x: axis === "x" ? Math.min(x, wallStart.x) : wallStart.x,
            y: axis === "y" ? Math.min(y, wallStart.y) : wallStart.y,
            length,
            axis,
            thickness: 0.15,
            height: 2.8,
          },
        ],
      });
      setSelected({ type: "wall", id });
      chooseTool("select");
      return;
    }
    if (tool === "door" || tool === "window") {
      const distances = project.walls
        .map((w) => ({
          wall: w,
          distance: Math.hypot(
            x -
              (w.axis === "x"
                ? Math.max(w.x, Math.min(w.x + w.length, x))
                : w.x),
            y -
              (w.axis === "y"
                ? Math.max(w.y, Math.min(w.y + w.length, y))
                : w.y),
          ),
        }))
        .sort((a, b) => a.distance - b.distance);
      const nearest = distances[0];
      if (!nearest || nearest.distance > 1) {
        setMessage("Click close to a wall to place an opening.");
        return;
      }
      const w = nearest.wall,
        width = tool === "door" ? 0.9 : 1.4;
      const opening: Opening = {
        id,
        wall: w.id,
        offset:
          Math.round(
            Math.max(
              0.2,
              Math.min(
                w.length - width - 0.2,
                (w.axis === "x" ? x - w.x : y - w.y) - width / 2,
              ),
            ) * 10,
          ) / 10,
        width,
        kind: tool,
        swing: tool === "door",
      };
      const error = openingError(project, opening);
      if (error) {
        setMessage(error);
        return;
      }
      change({ ...project, openings: [...project.openings, opening] });
      setSelected({ type: "opening", id });
    } else if (tool !== "select") {
      if (project.furniture.length >= 500) {
        setMessage("Project limit: 500 furnishings.");
        return;
      }
      change(placeFurniture(project, tool, x, y, id));
      setSelected({ type: "furniture", id });
    }
    chooseTool("select");
  };
  const move = (id: string, x: number, y: number) =>
    change({
      ...project,
      furniture: project.furniture.map((f) =>
        f.id === id ? { ...f, x, y } : f,
      ),
    });
  const exportJson = () =>
    download(
      new Blob([serializeProject(project)], { type: "application/json" }),
      "cedar-point.havik.json",
    );
  const exportSvg = () =>
    download(
      new Blob([exportPlan(project)], { type: "image/svg+xml" }),
      "cedar-point-plan.svg",
    );
  const exportPng = async () => {
    if (view !== "plan" && exportRef.current) {
      const blob = await exportRef.current();
      if (blob) download(blob, "cedar-point-view.png");
      return;
    }
    const url = URL.createObjectURL(
      new Blob([exportPlan(project)], { type: "image/svg+xml" }),
    );
    const image = new Image();
    image.onload = () => {
      const canvas = document.createElement("canvas");
      canvas.width = 1800;
      canvas.height = 1440;
      canvas.getContext("2d")!.drawImage(image, 0, 0, 1800, 1440);
      canvas.toBlob((blob) => {
        if (blob) download(blob, "cedar-point-plan.png");
        URL.revokeObjectURL(url);
      });
    };
    image.onerror = () => {
      URL.revokeObjectURL(url);
      setMessage("Image export failed. Try the SVG plan export.");
    };
    image.src = url;
  };
  const menus: Record<
    string,
    {
      label: string;
      action: () => void;
      disabled?: boolean;
      shortcut?: string;
    }[]
  > = {
    File: [
      { label: "Save project locally", action: save, shortcut: "Ctrl+S" },
      {
        label: "Open Havik project…",
        action: () => fileInput.current?.click(),
      },
      { label: "Export project (.json)", action: exportJson },
      { label: "Export dimensioned plan (.svg)", action: exportSvg },
      { label: "Export current image (.png)", action: exportPng },
      { label: "Restore sample lake house…", action: () => setDialog("reset") },
    ],
    Edit: [
      {
        label: "Undo",
        action: doUndo,
        disabled: !history.past.length,
        shortcut: "Ctrl+Z",
      },
      {
        label: "Redo",
        action: doRedo,
        disabled: !history.future.length,
        shortcut: "Ctrl+Y",
      },
      {
        label: "Duplicate object",
        action: duplicate,
        disabled: selected?.type !== "furniture",
      },
      {
        label: "Delete object",
        action: remove,
        disabled: !selected || selected.type === "room",
        shortcut: "Delete",
      },
    ],
    Build: [
      { label: "Draw partition wall", action: () => chooseTool("wall") },
      { label: "Place hinged door", action: () => chooseTool("door") },
      { label: "Place window", action: () => chooseTool("window") },
      { label: "Place base cabinet", action: () => chooseTool("cabinet") },
    ],
    Terrain: [
      {
        label: `${terrain ? "Hide" : "Show"} landscaping`,
        action: () => setTerrain(!terrain),
      },
    ],
    Library: [
      {
        label: "Furniture catalog",
        action: () => {
          setSidebar(true);
          setSideTab("Library Browser");
          setCategory("Furniture");
        },
      },
      {
        label: "Cabinet catalog",
        action: () => {
          setSidebar(true);
          setSideTab("Library Browser");
          setCategory("Cabinets");
        },
      },
      {
        label: "Plant catalog",
        action: () => {
          setSidebar(true);
          setSideTab("Library Browser");
          setCategory("Plants");
        },
      },
    ],
    "3D": [
      {
        label: "Dollhouse overview",
        action: () => setView("dollhouse"),
        shortcut: "2",
      },
      {
        label: "Exterior perspective",
        action: () => setView("perspective"),
        shortcut: "3",
      },
      { label: "Next camera preset", action: () => setPreset((p) => p + 1) },
      {
        label: `${roof ? "Hide" : "Show"} roof planes`,
        action: () => setRoof(!roof),
      },
    ],
    CAD: [
      {
        label: `${dimensions ? "Hide" : "Show"} dimensions`,
        action: () => setDimensions(!dimensions),
      },
      {
        label: `${labels ? "Hide" : "Show"} room labels`,
        action: () => setLabels(!labels),
      },
    ],
    Tools: [
      { label: "Select objects", action: () => chooseTool("select") },
      { label: "Fit plan in window", action: () => setZoom(1) },
      {
        label: "Project specification",
        action: () => {
          setSidebar(true);
          setSideTab("Project Browser");
        },
      },
    ],
    View: [
      {
        label: "Working plan view",
        action: () => setView("plan"),
        shortcut: "1",
      },
      { label: "Library browser", action: () => setSidebar(!sidebar) },
      { label: "Plan navigator", action: () => setInset(!inset) },
    ],
    Help: [
      {
        label: "Havik controls & project information",
        action: () => setDialog("help"),
      },
    ],
  };
  const filtered = catalog.filter(
    (c) =>
      (category === "All Content" || category === c.category) &&
      `${c.name} ${c.category}`.toLowerCase().includes(search.toLowerCase()),
  );
  const selectedObject =
    selected?.type === "furniture"
      ? project.furniture.find((f) => f.id === selected.id)
      : null;
  const viewName =
    view === "plan"
      ? "Working Plan View"
      : view === "dollhouse"
        ? "Perspective Floor Overview"
        : "Full Camera · Lakeside";
  return (
    <div className="app">
      <header className="titlebar">
        <div className="brand">
          <span className="brand-mark">
            <House size={17} />
          </span>
          HAVIK<span className="edition">PREMIER</span>
        </div>
        <span className="title-separator" />
        <span className="project-title">{project.name}.plan</span>
        <span className="title-path">Residential / Concept Design</span>
        <div className="save-indicator">
          <span className={saveError ? "bad-dot" : ""} />
          {saveError ? "Save unavailable" : "Saved locally"}
        </div>
        <button
          className="help-icon"
          title="Help and shortcuts"
          onClick={() => setDialog("help")}
        >
          <CircleHelp size={15} />
        </button>
      </header>
      <nav className="menubar" aria-label="Application menus">
        {Object.keys(menus).map((name) => (
          <div key={name} className="menu-wrap">
            <button
              className={menu === name ? "open" : ""}
              onClick={() => setMenu(menu === name ? null : name)}
            >
              {name}
            </button>
            {menu === name && (
              <div className="menu-dropdown">
                {menus[name].map((item) => (
                  <button
                    key={item.label}
                    disabled={item.disabled}
                    onClick={() => {
                      item.action();
                      setMenu(null);
                    }}
                  >
                    <span>{item.label}</span>
                    <kbd>{item.shortcut}</kbd>
                  </button>
                ))}
              </div>
            )}
          </div>
        ))}
        <span className="workspace-name">
          Architectural workspace
          <ChevronDown size={11} />
        </span>
      </nav>
      {menu && <div className="menu-backdrop" onClick={() => setMenu(null)} />}
      <div className="primary-toolbar">
        <div className="tool-group">
          <ToolButton
            icon={FolderOpen}
            label="Open project"
            color="#ae8b36"
            onClick={() => fileInput.current?.click()}
          />
          <ToolButton
            icon={Save}
            label="Save project"
            color="#57758d"
            onClick={save}
          />
          <ToolButton
            icon={FileJson}
            label="Export project"
            color="#6a7d70"
            onClick={exportJson}
          />
        </div>
        <div className="tool-group">
          <ToolButton
            icon={Undo2}
            label="Undo"
            color="#507d88"
            disabled={!history.past.length}
            onClick={doUndo}
          />
          <ToolButton
            icon={Redo2}
            label="Redo"
            color="#507d88"
            disabled={!history.future.length}
            onClick={doRedo}
          />
        </div>
        <div className="tool-group plan-select">
          <House size={16} />
          <select
            aria-label="Active document"
            value={view}
            onChange={(e) => setView(e.target.value as View)}
          >
            <option value="plan">Working Plan View</option>
            <option value="dollhouse">Perspective Floor Overview</option>
            <option value="perspective">Full Camera · Lakeside</option>
          </select>
        </div>
        <div className="tool-group level-control">
          <Layers size={17} />
          <span>Floor</span>
          <select
            aria-label="Active floor"
            value={level ? "1" : "site"}
            onChange={(e) => setLevel(e.target.value === "1")}
          >
            <option value="1">1</option>
            <option value="site">Site</option>
          </select>
        </div>
        <div className="tool-group">
          <ToolButton
            icon={Home}
            label="Show roof"
            active={roof}
            color="#b87255"
            onClick={() => setRoof(!roof)}
          />
          <ToolButton
            icon={Leaf}
            label="Show landscaping"
            active={terrain}
            color="#648463"
            onClick={() => setTerrain(!terrain)}
          />
          <ToolButton
            icon={Ruler}
            label="Show dimensions"
            active={dimensions}
            color="#b6944c"
            onClick={() => setDimensions(!dimensions)}
          />
          <ToolButton
            icon={Sun}
            label="Next camera preset"
            color="#b6923e"
            onClick={() => setPreset((p) => p + 1)}
          />
        </div>
        <div className="toolbar-spacer" />
        <div className="tool-group export-group">
          <ToolButton
            icon={FileImage}
            label="Export image"
            text
            color="#557e74"
            onClick={exportPng}
          />
          <ToolButton
            icon={Download}
            label="Export plan"
            text
            color="#57758d"
            onClick={exportSvg}
          />
        </div>
      </div>
      <div className="build-toolbar">
        <div className="tool-group">
          <ToolButton
            icon={MousePointer2}
            label="Select"
            text
            active={tool === "select"}
            onClick={() => chooseTool("select")}
            color="#406b7f"
          />
          <ToolButton
            icon={BrickWall}
            label="Wall"
            text
            active={tool === "wall"}
            color="#ba786b"
            onClick={() => chooseTool("wall")}
          />
          <ToolButton
            icon={DoorOpen}
            label="Door"
            text
            active={tool === "door"}
            color="#b18e55"
            onClick={() => chooseTool("door")}
          />
          <ToolButton
            icon={Columns3}
            label="Window"
            text
            active={tool === "window"}
            color="#5d8997"
            onClick={() => chooseTool("window")}
          />
        </div>
        <div className="tool-group">
          <ToolButton
            icon={Columns3}
            label="Cabinet"
            text
            active={tool === "cabinet"}
            color="#9c855d"
            onClick={() => chooseTool("cabinet")}
          />
          <ToolButton
            icon={Sofa}
            label="Furniture"
            text
            active={tool === "sofa"}
            color="#6a827b"
            onClick={() => {
              chooseTool("sofa");
              setSideTab("Library Browser");
              setCategory("Furniture");
            }}
          />
          <ToolButton
            icon={Leaf}
            label="Plant"
            text
            active={tool === "plant"}
            color="#739264"
            onClick={() => chooseTool("plant")}
          />
        </div>
        <div className="tool-group">
          <ToolButton
            icon={PencilRuler}
            label="Room labels"
            active={labels}
            color="#9b6553"
            onClick={() => setLabels(!labels)}
          />
          <ToolButton
            icon={Copy}
            label="Duplicate selected furniture"
            color="#607d8d"
            disabled={selected?.type !== "furniture"}
            onClick={duplicate}
          />
          <ToolButton
            icon={RotateCw}
            label="Rotate selected furniture"
            color="#608388"
            disabled={!selectedObject}
            onClick={() =>
              selectedObject &&
              change({
                ...project,
                furniture: project.furniture.map((f) =>
                  f.id === selectedObject.id
                    ? { ...f, rotation: (f.rotation + 90) % 360 }
                    : f,
                ),
              })
            }
          />
        </div>
        <div className="toolbar-spacer" />
        <button className="plain-control" onClick={() => setSidebar(!sidebar)}>
          <PanelRight size={16} />
          Browsers
        </button>
      </div>
      <div className="documents">
        <button
          className={view === "plan" ? "active" : ""}
          onClick={() => setView("plan")}
        >
          <PencilRuler size={15} />
          Cedar Point : Floor Plan<span>1</span>
        </button>
        <button
          className={view === "dollhouse" ? "active" : ""}
          onClick={() => setView("dollhouse")}
        >
          <House size={15} />
          Dollhouse Overview<span>2</span>
        </button>
        <button
          className={view === "perspective" ? "active" : ""}
          onClick={() => setView("perspective")}
        >
          <Camera size={15} />
          Lakeside Camera<span>3</span>
        </button>
        <div className="document-right">
          <span className="live-dot" />
          Linked model
        </div>
      </div>
      <main>
        <aside className="left-tools" aria-label="View tools">
          <ToolButton
            icon={MousePointer2}
            label="Select objects"
            active={tool === "select"}
            onClick={() => chooseTool("select")}
          />
          <span className="rail-divider" />
          <ToolButton
            icon={ZoomIn}
            label="Zoom in plan"
            disabled={view !== "plan"}
            onClick={() => setZoom((z) => Math.min(2.5, z + 0.15))}
          />
          <ToolButton
            icon={ZoomOut}
            label="Zoom out plan"
            disabled={view !== "plan"}
            onClick={() => setZoom((z) => Math.max(0.6, z - 0.15))}
          />
          <ToolButton
            icon={Maximize}
            label="Fill window"
            onClick={() => {
              setZoom(1);
              cameraPreset(0);
            }}
          />
          <ToolButton
            icon={RotateCcw}
            label="Orbit camera preset"
            disabled={view === "plan"}
            onClick={() => setPreset((p) => p + 1)}
          />
          <span className="rail-divider" />
          <ToolButton
            icon={Grid2x2}
            label="Floor plan"
            active={view === "plan"}
            onClick={() => setView("plan")}
          />
          <ToolButton
            icon={Box}
            label="Dollhouse view"
            active={view === "dollhouse"}
            onClick={() => setView("dollhouse")}
          />
          <ToolButton
            icon={Camera}
            label="Perspective camera"
            active={view === "perspective"}
            onClick={() => setView("perspective")}
          />
          <span className="rail-divider" />
          <ToolButton
            icon={Layers}
            label="Layer display options"
            onClick={() => {
              setSidebar(true);
              setSideTab("Layers");
            }}
          />
          <ToolButton
            icon={BookOpen}
            label="Library catalog"
            onClick={() => {
              setSidebar(true);
              setSideTab("Library Browser");
            }}
          />
          <div className="rail-spacer" />
          <ToolButton
            icon={Settings2}
            label="Project information"
            onClick={() => setDialog("help")}
          />
        </aside>
        <section className={`viewport ${view === "plan" ? "plan-mode" : ""}`}>
          <div className="viewport-topline">
            <span>
              <span className="view-dot" />
              {viewName}
            </span>
            <span>
              {view === "plan"
                ? "DIMENSIONED · 1:100"
                : "STANDARD · AMBIENT SHADOWS"}
            </span>
          </div>
          {view === "plan" ? (
            <Plan
              project={project}
              selected={selected}
              onSelect={setSelected}
              onPlace={place}
              onMove={move}
              placing={tool !== "select"}
              dimensions={dimensions}
              labels={labels}
              zoom={zoom}
            />
          ) : (
            <Scene
              project={project}
              selected={selected}
              onSelect={setSelected}
              onPlace={place}
              placing={tool !== "select"}
              view={view}
              roof={roof}
              terrain={terrain}
              level={level}
              preset={preset}
              exportRef={exportRef}
            />
          )}
          <div className="project-caption">
            <span>CEDAR POINT</span>
            <h1>Lake House</h1>
            <p>48° 29′ N / PACIFIC NORTHWEST</p>
            <div className="caption-rule" />
            <small>
              {totalArea(project).toFixed(0)} m² &nbsp; / &nbsp; LEVEL 01 &nbsp;
              / &nbsp; CONCEPT A
            </small>
          </div>
          {view !== "plan" && (
            <div className="camera-cube">
              <button onClick={() => cameraPreset(2)} aria-label="Top camera">
                TOP
              </button>
              <div>
                <button onClick={() => cameraPreset(1)} aria-label="Front camera">
                  FRONT
                </button>
                <button onClick={() => cameraPreset(0)} aria-label="Home camera">
                  RIGHT
                </button>
              </div>
              <span>N</span>
            </div>
          )}
          {view !== "plan" && inset && (
            <div className="plan-inset">
              <div>
                <span>
                  <PencilRuler size={12} />
                  FLOOR 1 · NAVIGATOR
                </span>
                <button
                  aria-label="Hide plan navigator"
                  onClick={() => setInset(false)}
                >
                  <X size={12} />
                </button>
              </div>
              <button
                className="inset-plan"
                aria-label="Open full floor plan"
                onClick={() => setView("plan")}
              >
                <svg
                  viewBox="-45 -155 890 735"
                  dangerouslySetInnerHTML={{
                    __html: exportPlan(project)
                      .replace(/^.*?<defs>/s, "<defs>")
                      .replace(/<\/svg>$/, ""),
                  }}
                />
              </button>
            </div>
          )}
          <div className="viewport-bottom">
            <div className="axis">
              <span>Y</span>
              <i />
              <b>X</b>
              <em>Z</em>
            </div>
            <span>
              {view === "plan"
                ? "Click to select · Drag furniture to move"
                : "Drag to orbit · Scroll to zoom · Right-drag to pan"}
            </span>
            <button
              onClick={() => (view === "plan" ? setZoom(1) : cameraPreset(0))}
            >
              <Maximize size={12} />
              {view === "plan" ? `${Math.round(zoom * 100)}%` : "Fit view"}
            </button>
          </div>
          {tool !== "select" && (
            <div className="placement-banner">
              <MousePointer2 size={15} />
              {tool === "wall"
                ? wallStart
                  ? "Click wall end point · Orthogonal snap"
                  : "Click the start of a partition wall"
                : `Click to place ${catalog.find((c) => c.kind === tool)?.name ?? tool}`}
              <button onClick={() => chooseTool("select")}>
                Cancel <kbd>Esc</kbd>
              </button>
            </div>
          )}
          {(message || saveError) && (
            <div
              role="status"
              className={`notification ${saveError ? "error" : ""}`}
            >
              {saveError || message}
              <button
                onClick={() => {
                  setMessage("");
                  setSaveError("");
                }}
                aria-label="Dismiss notification"
              >
                <X size={13} />
              </button>
            </div>
          )}
        </section>
        {sidebar && (
          <aside className="right-sidebar">
            <div className="browser-tabs">
              {["Project Browser", "Library Browser", "Layers"].map((tab) => (
                <button
                  key={tab}
                  className={sideTab === tab ? "active" : ""}
                  onClick={() => setSideTab(tab)}
                >
                  {tab === "Project Browser"
                    ? "Project"
                    : tab === "Library Browser"
                      ? "Library"
                      : "Layers"}
                </button>
              ))}
            </div>
            <div className="panel-heading">
              <strong>{sideTab}</strong>
              <span>
                <PanelRight size={12} />
                <button
                  aria-label="Close browser"
                  onClick={() => setSidebar(false)}
                >
                  <X size={13} />
                </button>
              </span>
            </div>
            <div className="browser-content">
              {sideTab === "Library Browser" && (
                <>
                  <div className="library-search">
                    <Search size={15} />
                    <input
                      aria-label="Search library"
                      placeholder="Search library…"
                      value={search}
                      onChange={(e) => setSearch(e.target.value)}
                    />
                    {search && (
                      <button
                        aria-label="Clear search"
                        onClick={() => setSearch("")}
                      >
                        <X size={12} />
                      </button>
                    )}
                  </div>
                  <div className="filter-line">
                    <span>Active filter:</span>
                    <select
                      aria-label="Library filter"
                      value={category}
                      onChange={(e) => setCategory(e.target.value)}
                    >
                      {[
                        "All Content",
                        "Furniture",
                        "Cabinets",
                        "Plants",
                        "Fixtures",
                      ].map((c) => (
                        <option key={c}>{c}</option>
                      ))}
                    </select>
                  </div>
                  <div className="catalog-tree">
                    <div className="tree-root">
                      <ChevronDown size={13} />
                      <BookOpen size={15} />
                      Havik Core Catalogs
                    </div>
                    {[
                      "All Content",
                      "Furniture",
                      "Cabinets",
                      "Plants",
                      "Fixtures",
                    ].map((c) => (
                      <button
                        key={c}
                        className={category === c ? "active" : ""}
                        onClick={() => setCategory(c)}
                      >
                        <ChevronRight size={11} />
                        <Folder size={14} />
                        {c}
                        <span>
                          {c === "All Content"
                            ? catalog.length
                            : catalog.filter((item) => item.category === c)
                                .length}
                        </span>
                      </button>
                    ))}
                  </div>
                  <div className="subpanel-heading">
                    Filter Results <span>({filtered.length})</span>
                    <Grid2x2 size={13} />
                  </div>
                  <div className="library-grid">
                    {filtered.map((c) => (
                      <button
                        key={c.kind}
                        className={tool === c.kind ? "active" : ""}
                        onClick={() => chooseTool(c.kind)}
                        aria-label={`Place ${c.name}`}
                      >
                        <div className="library-thumbnail">
                          <svg viewBox="-90 -70 180 140" aria-hidden="true">
                            <ellipse
                              cx="4"
                              cy="20"
                              rx="52"
                              ry="17"
                              fill="#4f493910"
                            />
                            <g
                              transform="translate(0 0) rotate(-25) scale(.85 .75)"
                              dangerouslySetInnerHTML={{
                                __html: furnitureSvg({
                                  ...c,
                                  id: "",
                                  x: 0,
                                  y: 0,
                                  rotation: 0,
                                }),
                              }}
                            />
                          </svg>
                        </div>
                        <span>{c.name}</span>
                        <small>
                          {c.w.toFixed(2)} × {c.d.toFixed(2)} m
                        </small>
                      </button>
                    ))}
                    {!filtered.length && (
                      <div className="empty-search">
                        <Search size={24} />
                        <b>No matching objects</b>
                        <span>Try “sofa”, “oak”, or another category.</span>
                      </div>
                    )}
                  </div>
                  <div className="library-hint">
                    <MousePointer2 size={12} />
                    Select a symbol, then click in the model to place.
                  </div>
                </>
              )}
              {sideTab === "Project Browser" && (
                <div className="project-browser">
                  <div className="tree-root">
                    <ChevronDown size={13} />
                    <House size={15} />
                    {project.name}
                  </div>
                  <h3>Saved views</h3>
                  {(["plan", "dollhouse", "perspective"] as View[]).map((v) => (
                    <button
                      key={v}
                      onClick={() => setView(v)}
                      className={view === v ? "active" : ""}
                    >
                      <Camera size={14} />
                      {v === "plan"
                        ? "Floor 1 · Working Plan"
                        : v === "dollhouse"
                          ? "Dollhouse Overview"
                          : "Camera 1 · Lakeside"}
                    </button>
                  ))}
                  <h3>Rooms · Floor 1</h3>
                  {project.rooms.map((room) => (
                    <button
                      key={room.id}
                      className={
                        selected?.id === room.id && selected.type === "room"
                          ? "active"
                          : ""
                      }
                      onClick={() => setSelected({ type: "room", id: room.id })}
                    >
                      <Square size={13} />
                      {room.name}
                      <span>{area(room).toFixed(0)} m²</span>
                    </button>
                  ))}
                  <h3>Model</h3>
                  <div className="model-count">
                    {project.walls.length} walls &nbsp; · &nbsp;{" "}
                    {project.openings.length} openings
                    <br />
                    {project.furniture.length} furnishings
                  </div>
                </div>
              )}
              {sideTab === "Layers" && (
                <div className="layer-panel">
                  <p>Active Layer Display Options</p>
                  {[
                    {
                      label: "Floor 1 · Rooms & furnishings",
                      checked: level,
                      fn: setLevel,
                    },
                    { label: "Roof planes", checked: roof, fn: setRoof },
                    {
                      label: "Terrain, trees & lake",
                      checked: terrain,
                      fn: setTerrain,
                    },
                    {
                      label: "Room labels (plan)",
                      checked: labels,
                      fn: setLabels,
                    },
                    {
                      label: "Dimensions (plan)",
                      checked: dimensions,
                      fn: setDimensions,
                    },
                    {
                      label: "Plan navigator (3D)",
                      checked: inset,
                      fn: setInset,
                    },
                  ].map((row) => (
                    <label key={row.label}>
                      <input
                        type="checkbox"
                        checked={row.checked}
                        onChange={(e) => row.fn(e.target.checked)}
                      />
                      {row.checked ? <Eye size={15} /> : <EyeOff size={15} />}
                      <span>{row.label}</span>
                    </label>
                  ))}
                  <p className="layer-note">
                    Display settings affect the working view. Exported plans
                    include all model objects and dimensions.
                  </p>
                </div>
              )}
            </div>
            <div className="specification">
              <div className="panel-heading">
                <strong>
                  {selected?.type === "room"
                    ? "Room Specification"
                    : selected?.type === "wall"
                      ? "Wall Specification"
                      : selected?.type === "opening"
                        ? "Opening Specification"
                        : "Object Specification"}
                </strong>
                <Settings2 size={13} />
              </div>
              <Properties
                project={project}
                selection={selected}
                onChange={change}
                onDelete={remove}
              />
            </div>
          </aside>
        )}
      </main>
      <div className="edit-toolbar">
        <span className="edit-label">EDIT</span>
        <ToolButton
          icon={MousePointer2}
          label="Select tool"
          onClick={() => chooseTool("select")}
        />
        <ToolButton
          icon={Copy}
          label="Duplicate object"
          disabled={selected?.type !== "furniture"}
          onClick={duplicate}
        />
        <ToolButton
          icon={Trash2}
          label="Delete object"
          disabled={!selected || selected.type === "room"}
          onClick={remove}
        />
        <span className="edit-separator" />
        <ToolButton
          icon={ArrowDownToLine}
          label="Export SVG drawing"
          onClick={exportSvg}
        />
        <ToolButton
          icon={ArrowUpFromLine}
          label="Import project file"
          onClick={() => fileInput.current?.click()}
        />
        <div className="toolbar-spacer" />
        <span className="snap-state">
          <Check size={12} />
          Object snaps
        </span>
        <span className="snap-state">
          <Check size={12} />
          0.10 m grid
        </span>
        <span className="scale">Scale 1 : 100</span>
      </div>
      <footer>
        <span>
          {selected
            ? `Selected: ${selectedObject?.name ?? (selected.type === "room" ? project.rooms.find((r) => r.id === selected.id)?.name : selected.type)}`
            : "Ready · Select an object to edit its specification"}
        </span>
        <span>Floor: {level ? "1" : "Site"}</span>
        <span>Layer: {selected?.type ?? "Architectural"}</span>
        <span className="coordinates">
          X: {selectedObject?.x.toFixed(2) ?? "0.00"} m &nbsp; Y:{" "}
          {selectedObject?.y.toFixed(2) ?? "0.00"} m &nbsp; Z: 0.00 m
        </span>
        <span>METRIC</span>
      </footer>
      <input
        type="file"
        accept=".json,application/json"
        ref={fileInput}
        className="hidden"
        onChange={async (e) => {
          const file = e.target.files?.[0];
          if (!file) return;
          try {
            if (file.size > 2_000_000)
              throw new Error("Project file is too large (maximum 2 MB).");
            const loaded = parseProject(await file.text());
            change(loaded);
            setSelected(null);
            chooseTool("select");
            setMessage(`Opened ${loaded.name}.`);
          } catch (e) {
            setMessage(
              e instanceof Error ? e.message : "Unable to import the project.",
            );
          } finally {
            if (fileInput.current) fileInput.current.value = "";
          }
        }}
      />
      {dialog && (
        <div className="modal-backdrop" onClick={() => setDialog(null)}>
          <div
            className="modal"
            role="dialog"
            aria-modal="true"
            aria-label={
              dialog === "reset"
                ? "Restore sample project"
                : "Havik project information"
            }
            onClick={(e) => e.stopPropagation()}
          >
            <div className="panel-heading">
              <strong>
                {dialog === "reset"
                  ? "Restore sample project"
                  : "About Havik Premier"}
              </strong>
              <button aria-label="Close dialog" onClick={() => setDialog(null)}>
                <X size={16} />
              </button>
            </div>
            {dialog === "reset" ? (
              <div className="modal-body">
                <h2>Return to Cedar Point?</h2>
                <p>
                  This restores the furnished lake house. You can undo the reset
                  or export your current project first.
                </p>
                <div className="modal-actions">
                  <button onClick={exportJson}>Export current project</button>
                  <button
                    className="apply"
                    autoFocus
                    onClick={() => {
                      change(createProject());
                      setSelected({ type: "room", id: "living" });
                      chooseTool("select");
                      setDialog(null);
                      setMessage("Sample project restored. Undo is available.");
                    }}
                  >
                    Restore sample
                  </button>
                </div>
              </div>
            ) : (
              <div className="modal-body">
                <div className="about-brand">
                  <House size={32} />
                  <div>
                    <h2>HAVIK</h2>
                    <span>Residential design studio · Browser V1</span>
                  </div>
                </div>
                <p>
                  A locally editable Cedar Point lake house, inspired by Chief
                  Architect Premier X16’s desktop workspace. All geometry,
                  furnishings and illustrations are generated locally.
                </p>
                <h3>Working with the model</h3>
                <p>
                  Select a room, wall, opening or furnishing, edit its
                  specification and choose <b>Apply changes</b>. Place library
                  objects by choosing a symbol and clicking the model. Drag
                  furniture in Floor Plan view.
                </p>
                <div className="shortcuts">
                  <span>Plan / Dollhouse / Camera</span>
                  <kbd>1 / 2 / 3</kbd>
                  <span>Undo / Redo</span>
                  <kbd>Ctrl Z / Ctrl Y</kbd>
                  <span>Save / Cancel tool</span>
                  <kbd>Ctrl S / Esc</kbd>
                  <span>Remove selected object</span>
                  <kbd>Delete</kbd>
                </div>
                <h3>Scope</h3>
                <p>
                  Concept visualization only. Single floor; new partitions do
                  not automatically redefine room boundaries. No structural
                  calculations, BIM interchange, native .plan compatibility or
                  commercial render engine. SVG, PNG and Havik JSON exports are
                  supported.
                </p>
                <a
                  href="https://cloud.chiefarchitect.com/1/pdf/documentation/chief-architect-x16-reference-manual.pdf"
                  target="_blank"
                  rel="noreferrer"
                >
                  Source reference: Chief Architect Premier X16 manual ↗
                </a>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
