import { useEffect, useRef, useState } from "react";
import * as THREE from "three";
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls.js";
import { RoundedBoxGeometry } from "three/examples/jsm/geometries/RoundedBoxGeometry.js";
import type { Furniture, Project, Selection, View } from "./model";
import { materials, openingSegments } from "./model";

interface Props {
  project: Project;
  selected: Selection;
  onSelect: (s: Selection) => void;
  onPlace: (x: number, y: number) => void;
  placing: boolean;
  view: View;
  roof: boolean;
  terrain: boolean;
  level: boolean;
  preset: number;
  exportRef: React.MutableRefObject<(() => Promise<Blob | null>) | null>;
}
function dispose(root: THREE.Object3D) {
  const textures = new Set<THREE.Texture>();
  root.traverse((o) => {
    if (o instanceof THREE.Mesh) {
      o.geometry.dispose();
      for (const m of Array.isArray(o.material) ? o.material : [o.material]) {
        if (m instanceof THREE.MeshStandardMaterial && m.map)
          textures.add(m.map);
        m.dispose();
      }
    }
  });
  textures.forEach((t) => t.dispose());
}
function woodTexture(): THREE.CanvasTexture {
  const canvas = document.createElement("canvas");
  canvas.width = 256;
  canvas.height = 256;
  const c = canvas.getContext("2d")!;
  c.fillStyle = "#f4ebdc";
  c.fillRect(0, 0, 256, 256);
  for (let i = 0; i < 160; i++) {
    c.strokeStyle = `rgba(110,82,44,${0.015 + (i % 7) * 0.006})`;
    c.beginPath();
    c.moveTo(i * 1.63, 0);
    c.bezierCurveTo(
      i * 1.63 + Math.sin(i) * 2,
      70,
      i * 1.63 - 2,
      160,
      i * 1.63,
      256,
    );
    c.stroke();
  }
  for (let x = 0; x < 256; x += 32) {
    c.fillStyle = "#8d795828";
    c.fillRect(x, 0, 1, 256);
    c.fillRect(x, (x * 3) % 210, 32, 1);
  }
  const texture = new THREE.CanvasTexture(canvas);
  texture.colorSpace = THREE.SRGBColorSpace;
  texture.wrapS = texture.wrapT = THREE.RepeatWrapping;
  texture.repeat.set(2, 3);
  texture.anisotropy = 8;
  return texture;
}
export function makeHouse(
  project: Project,
  view: View,
  roof: boolean,
  terrain: boolean,
  level: boolean,
  selected: Selection,
) {
  const root = new THREE.Group();
  const wood = woodTexture();
  const mat = (color: string, roughness = 0.85) =>
    new THREE.MeshStandardMaterial({ color, roughness });
  const white = mat("#f5f1e7"),
    oak = new THREE.MeshStandardMaterial({
      color: "#c6a77f",
      roughness: 0.7,
      map: wood,
    }),
    dark = mat("#4d524c");
  const box = (
    parent: THREE.Object3D,
    x: number,
    y: number,
    z: number,
    w: number,
    h: number,
    d: number,
    material: THREE.Material,
    round = false,
  ) => {
    const mesh = new THREE.Mesh(
      round
        ? new RoundedBoxGeometry(w, h, d, 2, Math.min(w, h, d) * 0.13)
        : new THREE.BoxGeometry(w, h, d),
      material,
    );
    mesh.position.set(x, y, z);
    mesh.castShadow = mesh.receiveShadow = true;
    parent.add(mesh);
    return mesh;
  };
  const cyl = (
    parent: THREE.Object3D,
    x: number,
    y: number,
    z: number,
    radius: number,
    height: number,
    material: THREE.Material,
    top?: number,
  ) => {
    const mesh = new THREE.Mesh(
      new THREE.CylinderGeometry(top ?? radius, radius, height, 16),
      material,
    );
    mesh.position.set(x, y, z);
    mesh.castShadow = mesh.receiveShadow = true;
    parent.add(mesh);
    return mesh;
  };
  const foliage = [
    mat("#748a58"),
    mat("#849969"),
    mat("#536f49"),
    mat("#9aaa75"),
  ];
  const plant = (
    parent: THREE.Object3D,
    x: number,
    z: number,
    scale: number,
    outdoor = false,
  ) => {
    const group = new THREE.Group();
    parent.add(group);
    group.position.set(x, 0.1, z);
    group.scale.setScalar(scale);
    cyl(
      group,
      0,
      0.24,
      0,
      0.22,
      0.48,
      mat(outdoor ? "#a6a496" : "#d2c4b0"),
      0.29,
    );
    cyl(group, 0, 0.8, 0, 0.025, 1.25, oak);
    for (let i = 0; i < 11; i++) {
      const angle = i * 2.4,
        y = 0.7 + i * 0.07,
        r = i < 8 ? 0.22 : 0.12;
      const leaf = new THREE.Mesh(
        new THREE.SphereGeometry(0.22, 7, 6),
        foliage[i % 4],
      );
      leaf.position.set(Math.cos(angle) * r, y, Math.sin(angle) * r);
      leaf.scale.set(0.7, 0.35, 1.5);
      leaf.rotation.set(0.2, -angle, 0.4);
      leaf.castShadow = true;
      group.add(leaf);
    }
  };
  box(root, 10, -0.7, 4.6, 29, 0.9, 24, mat("#d8d4bf"));
  box(root, 10, -0.22, 4.6, 29, 0.13, 24, mat(terrain ? "#bbc5a1" : "#e4e3d9"));
  if (terrain) {
    const lake = new THREE.Mesh(
      new THREE.PlaneGeometry(75, 42),
      new THREE.MeshStandardMaterial({
        color: "#799e9d",
        roughness: 0.4,
        metalness: 0.2,
      }),
    );
    lake.rotation.x = -Math.PI / 2;
    lake.position.set(10, -0.29, -27);
    lake.receiveShadow = true;
    root.add(lake);
    for (let i = 0; i < 65; i++) {
      const x = -19 + ((i * 13.71) % 63),
        z = -9 - ((i * 7.33) % 31);
      box(
        root,
        x,
        -0.275,
        z,
        0.5 + (i % 5) * 0.6,
        0.002,
        0.018,
        mat("#bdccbe"),
      );
    }
    for (const [x, z, scale] of [
      [-2.8, 1, 1.1],
      [-2, 7, 0.8],
      [22.6, 2, 1.3],
      [23, 12, 1],
      [-2, 13, 1.1],
      [21.5, -4.5, 0.9],
    ]) {
      cyl(root, x, 1.1 * scale, z, 0.12 * scale, 2.4 * scale, mat("#786d58"));
      for (let i = 0; i < 5; i++) {
        const crown = new THREE.Mesh(
          new THREE.IcosahedronGeometry((1.0 + (i % 2) * 0.3) * scale, 2),
          foliage[i % 4],
        );
        crown.position.set(
          x + Math.sin(i * 2.4) * 0.6,
          (2.2 + i * 0.28) * scale,
          z + Math.cos(i * 2.4) * 0.5,
        );
        crown.castShadow = true;
        root.add(crown);
      }
    }
    for (let i = 0; i < 17; i++) {
      const x = -3 + i * 1.7,
        z = i % 2 ? -5.3 : 15.9;
      const rock = new THREE.Mesh(
        new THREE.DodecahedronGeometry(0.3 + (i % 3) * 0.1),
        mat("#babaae"),
      );
      rock.position.set(x, 0, z);
      rock.scale.set(1.5, 0.7, 1);
      rock.castShadow = true;
      root.add(rock);
      if (i % 2) plant(root, x + 0.4, z, 0.65, true);
    }
    for (let i = 0; i < 5; i++)
      box(root, 7, -0.05, 13.9 + i * 0.7, 2.5, 0.12, 0.53, mat("#d9d8cc"));
  }
  box(root, 10, -0.08, 6.5, 20.4, 0.35, 13.4, mat("#c3bdaa"));
  box(root, 10, 0.02, -1.8, 20.4, 0.3, 3.6, oak);
  for (let x = -0.2; x < 20.3; x += 0.18)
    box(root, x, 0.177, -1.8, 0.012, 0.005, 3.6, mat("#9d896b"));
  const glass = new THREE.MeshStandardMaterial({
    color: "#b5d5ce",
    transparent: true,
    opacity: 0.22,
    roughness: 0.12,
    metalness: 0.15,
    depthWrite: false,
  });
  for (let x = 0; x < 20; x += 2) {
    box(root, x, 0.67, -3.55, 0.04, 1.0, 0.04, dark);
    box(root, x + 1, 0.66, -3.55, 1.9, 0.8, 0.025, glass);
  }
  box(root, 10, 1.17, -3.55, 20, 0.04, 0.055, dark);
  if (!level) return root;
  for (const room of project.rooms) {
    const floorMat = new THREE.MeshStandardMaterial({
      color: materials[room.material].color,
      map: room.material === "oak" || room.material === "walnut" ? wood : null,
      roughness: 0.75,
    });
    const floor = box(
      root,
      room.x + room.w / 2,
      0.13,
      room.y + room.d / 2,
      room.w,
      0.1,
      room.d,
      floorMat,
    );
    floor.userData.selection = { type: "room", id: room.id };
    if (selected?.type === "room" && selected.id === room.id) {
      floorMat.emissive.set("#3b7363");
      floorMat.emissiveIntensity = 0.16;
    }
    if (room.material === "stone") {
      for (let x = room.x; x < room.x + room.w; x += 0.8)
        box(
          root,
          x,
          0.183,
          room.y + room.d / 2,
          0.008,
          0.003,
          room.d,
          mat("#b4b9ad"),
        );
      for (let z = room.y; z < room.y + room.d; z += 0.8)
        box(
          root,
          room.x + room.w / 2,
          0.183,
          z,
          room.w,
          0.003,
          0.008,
          mat("#b4b9ad"),
        );
    }
  }
  for (const wall of project.walls) {
    const group = new THREE.Group();
    group.position.set(wall.x, 0.18, wall.y);
    if (wall.axis === "y") group.rotation.y = -Math.PI / 2;
    group.userData.selection = { type: "wall", id: wall.id };
    root.add(group);
    const h =
      view === "dollhouse" && !roof ? Math.min(1.05, wall.height) : wall.height;
    const wallMaterial =
      selected?.type === "wall" && selected.id === wall.id
        ? mat("#91b3a2")
        : white;
    for (const segment of openingSegments(wall, project.openings)) {
      const length = segment.end - segment.start,
        center = (segment.end + segment.start) / 2;
      if (!segment.opening) {
        box(group, center, h / 2, 0, length, h, wall.thickness, wallMaterial);
        box(
          group,
          center,
          0.065,
          wall.thickness / 2 + 0.012,
          length,
          0.13,
          0.023,
          mat("#e3dfd2"),
        );
        continue;
      }
      const opening = segment.opening,
        frame = new THREE.Group();
      frame.userData.selection = { type: "opening", id: opening.id };
      group.add(frame);
      const frameMat =
        selected?.type === "opening" && selected.id === opening.id
          ? mat("#3a9690")
          : dark;
      const bottom = opening.kind === "window" ? Math.min(0.5, h * 0.3) : 0,
        top = Math.min(h, 2.65);
      if (bottom)
        box(
          frame,
          center,
          bottom / 2,
          0,
          length,
          bottom,
          wall.thickness,
          wallMaterial,
        );
      if (h > top)
        box(
          frame,
          center,
          top + (h - top) / 2,
          0,
          length,
          h - top,
          wall.thickness,
          wallMaterial,
        );
      if (opening.kind === "window" || !opening.swing) {
        box(
          frame,
          center,
          (top + bottom) / 2,
          0,
          length,
          top - bottom,
          0.025,
          glass,
        );
        box(
          frame,
          center,
          bottom + 0.04,
          0,
          length,
          0.07,
          wall.thickness,
          frameMat,
        );
        box(
          frame,
          center,
          top - 0.035,
          0,
          length,
          0.07,
          wall.thickness,
          frameMat,
        );
        const divisions = Math.ceil(length / 1.4);
        for (let i = 0; i <= divisions; i++)
          box(
            frame,
            segment.start + (length * i) / divisions,
            (top + bottom) / 2,
            0,
            0.055,
            top - bottom,
            wall.thickness,
            frameMat,
          );
      } else {
        box(frame, segment.start, top / 2, length / 2, 0.055, top, length, oak);
        cyl(
          frame,
          segment.start + 0.08,
          Math.min(0.9, top * 0.7),
          length - 0.13,
          0.03,
          0.05,
          dark,
        );
      }
    }
  }
  const rug = mat("#d7d0be");
  box(root, 4, 0.193, 3.0, 5.8, 0.025, 3.9, rug, true);
  for (let i = 0; i < 42; i++)
    box(
      root,
      4,
      0.21,
      1.1 + i * 0.091,
      5.7,
      0.005,
      0.008,
      mat(i % 3 ? "#bfb8a6" : "#eee9dd"),
    );
  box(root, 12.2, 0.193, 10.6, 4.7, 0.025, 4.1, rug);
  box(root, 16.5, 0.193, 3.4, 4.6, 0.025, 4.1, mat("#e4ded1"));
  const legs = (g: THREE.Group, w: number, d: number, h: number, m = oak) => {
    for (const x of [-w / 2 + 0.09, w / 2 - 0.09])
      for (const z of [-d / 2 + 0.09, d / 2 - 0.09])
        box(g, x, h / 2, z, 0.065, h, 0.065, m);
  };
  const seat = (
    g: THREE.Group,
    x: number,
    z: number,
    rotation: number,
    color = "#c3b597",
  ) => {
    const chair = new THREE.Group();
    chair.position.set(x, 0, z);
    chair.rotation.y = rotation;
    g.add(chair);
    box(chair, 0, 0.47, 0, 0.48, 0.11, 0.5, mat(color), true);
    box(chair, 0, 0.75, 0.22, 0.5, 0.5, 0.09, oak, true);
    legs(chair, 0.44, 0.43, 0.45);
  };
  const addFurniture = (f: Furniture) => {
    const g = new THREE.Group();
    root.add(g);
    g.position.set(f.x, 0.2, f.y);
    g.rotation.y = (-f.rotation * Math.PI) / 180;
    g.userData.selection = { type: "furniture", id: f.id };
    const c = mat(materials[f.material].color),
      { w, d } = f;
    if (selected?.type === "furniture" && selected.id === f.id) {
      const outline = new THREE.Mesh(
        new THREE.BoxGeometry(w + 0.13, 0.014, d + 0.13),
        new THREE.MeshBasicMaterial({ color: "#328980" }),
      );
      g.add(outline);
    }
    if (f.kind === "plant") plant(g, 0, 0, w * 1.35);
    if (f.kind === "sofa" || f.kind === "chair") {
      legs(g, w - 0.15, d - 0.12, 0.21, dark);
      box(g, 0, 0.3, 0, w, 0.26, d, c, true);
      box(g, 0, 0.65, d / 2 - 0.14, w, 0.62, 0.26, c, true);
      const n = f.kind === "sofa" ? 3 : 1;
      for (let i = 0; i < n; i++)
        box(
          g,
          -w / 2 + (w / n) * (i + 0.5),
          0.5,
          -0.05,
          w / n - 0.06,
          0.21,
          d - 0.3,
          c,
          true,
        );
      for (const x of [-w / 2 + 0.09, w / 2 - 0.09])
        box(g, x, 0.55, 0, 0.18, 0.48, d, c, true);
      if (f.kind === "sofa")
        for (let i = 0; i < 3; i++) {
          const pillow = box(
            g,
            -w / 2 + 0.45 + (i * (w - 0.9)) / 2,
            0.76,
            d / 2 - 0.3,
            0.47,
            0.44,
            0.15,
            mat(i % 2 ? "#bbae94" : "#8e9e8c"),
            true,
          );
          pillow.rotation.z = i % 2 ? 0.12 : -0.13;
        }
    }
    if (f.kind === "table") {
      const height = f.w > 2 ? 0.77 : 0.4;
      box(g, 0, height, 0, w, 0.08, d, c, true);
      legs(g, w - 0.2, d - 0.15, height, c);
      if (f.w > 2)
        for (const x of [-w / 3, 0, w / 3]) {
          seat(g, x, -d / 2 - 0.32, Math.PI);
          seat(g, x, d / 2 + 0.32, 0);
        }
      cyl(g, 0, height + 0.13, 0, 0.11, 0.2, white, 0.08);
      cyl(g, 0, height + 0.33, 0, 0.014, 0.23, foliage[1]);
      for (let i = 0; i < 3; i++)
        box(
          g,
          0.35,
          height + 0.07 + i * 0.025,
          0,
          0.28,
          0.025,
          0.2,
          mat(["#9b8770", "#e7ded0", "#6c7d74"][i]),
        );
    }
    if (f.kind === "bed") {
      box(g, 0, 0.2, 0, w + 0.12, 0.35, d + 0.12, oak, true);
      box(g, 0, 0.48, 0, w, 0.3, d, white, true);
      box(g, 0, 0.62, -d * 0.16, w + 0.04, 0.09, d * 0.63, c, true);
      box(g, 0, 0.85, d / 2, w + 0.3, 1.25, 0.15, mat("#b9af98"), true);
      for (const x of [-w / 4, w / 4])
        box(g, x, 0.7, d / 2 - 0.39, w / 2 - 0.08, 0.17, 0.48, white, true);
      box(g, 0, 0.68, -d / 2 + 0.45, w + 0.04, 0.025, 0.48, mat("#b8b49e"));
    }
    if (f.kind === "cabinet" || f.kind === "island") {
      const h =
        f.id === "wardrobe" || f.id === "bookcase"
          ? 2.2
          : f.name.includes("night")
            ? 0.6
            : 0.85;
      box(g, 0, h / 2, 0, w, h, d, c);
      box(
        g,
        0,
        h + 0.025,
        0,
        w + 0.07,
        0.05,
        d + 0.07,
        f.kind === "island" ? white : oak,
      );
      const n = Math.max(1, Math.round(w / 0.5));
      for (let i = 0; i < n; i++) {
        const x = -w / 2 + ((i + 0.5) * w) / n;
        box(g, x, h / 2, -d / 2 - 0.007, w / n - 0.045, h - 0.12, 0.018, c);
        box(g, x, h - 0.14, -d / 2 - 0.035, 0.16, 0.018, 0.035, dark);
      }
      if (f.kind === "island") {
        box(g, 0, h + 0.06, 0, 0.62, 0.01, 0.42, mat("#788f8b"), true);
        cyl(g, 0, h + 0.2, 0.3, 0.022, 0.35, dark);
        box(g, 0, h + 0.37, 0.21, 0.035, 0.035, 0.2, dark);
        for (const x of [-1, 0, 1]) {
          cyl(g, x, 0.66, -d / 2 - 0.46, 0.22, 0.09, oak);
          for (const dx of [-0.14, 0.14])
            box(g, x + dx, 0.33, -d / 2 - 0.46, 0.035, 0.65, 0.035, dark);
        }
      }
      if (f.id === "kitchen-1") {
        box(g, 0, h + 0.06, 0, w - 0.14, 0.025, d - 0.1, dark);
        for (const x of [-0.22, 0.22])
          for (const z of [-0.13, 0.13])
            cyl(g, x, h + 0.08, z, 0.085, 0.01, mat("#9c9d96"));
      }
      if (f.id === "vanity")
        for (const x of [-0.7, 0.7]) {
          box(g, x, h + 0.1, 0, 0.64, 0.12, 0.42, white, true);
          box(g, x, h + 0.17, -0.02, 0.5, 0.01, 0.29, mat("#c9d6d0"), true);
        }
    }
    if (f.kind === "bath") {
      box(g, 0, 0.3, 0, w, 0.6, d, white, true);
      box(g, 0, 0.603, 0, w - 0.17, 0.012, d - 0.16, mat("#b4cfca"), true);
      cyl(g, w / 2 + 0.05, 0.44, 0, 0.025, 0.85, dark);
      box(g, w / 2 - 0.05, 0.85, 0, 0.25, 0.04, 0.04, dark);
    }
  };
  project.furniture.forEach(addFurniture);
  if (roof) {
    const roofMat = mat("#47534e");
    for (const side of [-1, 1]) {
      const panel = box(
        root,
        10,
        4.8,
        6.5 + side * 3.5,
        21.2,
        0.14,
        7.9,
        roofMat,
      );
      panel.rotation.x = side * 0.45;
      for (let x = -0.5; x < 20.5; x += 0.5) {
        const seam = box(
          root,
          x,
          4.88,
          6.5 + side * 3.5,
          0.026,
          0.06,
          7.9,
          dark,
        );
        seam.rotation.x = side * 0.45;
      }
    }
    box(root, 10, 6.55, 6.5, 21.2, 0.13, 0.15, dark);
  }
  return root;
}
export default function Scene(props: Props) {
  const host = useRef<HTMLDivElement>(null);
  const runtime = useRef<{
    renderer: THREE.WebGLRenderer;
    scene: THREE.Scene;
    camera: THREE.PerspectiveCamera;
    controls: OrbitControls;
    root?: THREE.Group;
  } | null>(null);
  const current = useRef(props);
  current.current = props;
  const [error, setError] = useState("");
  useEffect(() => {
    const container = host.current!;
    let renderer: THREE.WebGLRenderer;
    try {
      renderer = new THREE.WebGLRenderer({
        antialias: true,
        preserveDrawingBuffer: true,
      });
    } catch {
      setError(
        "WebGL is unavailable. Use the Floor Plan tab to edit this project.",
      );
      return;
    }
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 1.75));
    renderer.shadowMap.enabled = true;
    renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    renderer.outputColorSpace = THREE.SRGBColorSpace;
    renderer.toneMapping = THREE.ACESFilmicToneMapping;
    renderer.toneMappingExposure = 1.25;
    container.appendChild(renderer.domElement);
    const scene = new THREE.Scene();
    scene.background = new THREE.Color("#e3e8e4");
    scene.fog = new THREE.Fog("#e3e8e4", 60, 115);
    const camera = new THREE.PerspectiveCamera(36, 1, 0.1, 180);
    camera.position.set(32, 28, 35);
    const controls = new OrbitControls(camera, renderer.domElement);
    controls.target.set(10, 0, 5);
    controls.enableDamping = true;
    controls.dampingFactor = 0.09;
    controls.maxPolarAngle = Math.PI / 2.03;
    controls.minDistance = 8;
    controls.maxDistance = 65;
    scene.add(new THREE.HemisphereLight("#f3f6ee", "#83906f", 2.2));
    const sun = new THREE.DirectionalLight("#fff3d7", 3.6);
    sun.position.set(-12, 32, 7);
    sun.castShadow = true;
    sun.shadow.mapSize.set(2048, 2048);
    sun.shadow.camera.left = -35;
    sun.shadow.camera.right = 35;
    sun.shadow.camera.top = 35;
    sun.shadow.camera.bottom = -35;
    sun.shadow.normalBias = 0.035;
    sun.shadow.bias = -0.0001;
    sun.shadow.radius = 4;
    scene.add(sun);
    runtime.current = { renderer, scene, camera, controls };
    const observer = new ResizeObserver(() => {
      const { width, height } = container.getBoundingClientRect();
      renderer.setSize(width, height);
      camera.aspect = width / height;
      camera.updateProjectionMatrix();
    });
    observer.observe(container);
    let frame = 0;
    const draw = () => {
      frame = requestAnimationFrame(draw);
      controls.update();
      renderer.render(scene, camera);
    };
    draw();
    const ray = new THREE.Raycaster(),
      pointer = new THREE.Vector2();
    let downX = 0,
      downY = 0;
    const down = (e: PointerEvent) => {
      downX = e.clientX;
      downY = e.clientY;
    };
    const up = (e: PointerEvent) => {
      if (Math.hypot(e.clientX - downX, e.clientY - downY) > 5) return;
      const bounds = renderer.domElement.getBoundingClientRect();
      pointer.set(
        ((e.clientX - bounds.left) / bounds.width) * 2 - 1,
        (-(e.clientY - bounds.top) / bounds.height) * 2 + 1,
      );
      ray.setFromCamera(pointer, camera);
      if (current.current.placing) {
        const point = new THREE.Vector3();
        if (
          ray.ray.intersectPlane(
            new THREE.Plane(new THREE.Vector3(0, 1, 0), -0.2),
            point,
          )
        )
          current.current.onPlace(point.x, point.z);
      } else if (runtime.current?.root) {
        const hit = ray
          .intersectObject(runtime.current.root, true)
          .find((hit) => {
            let node: THREE.Object3D | null = hit.object;
            while (node) {
              if (node.userData.selection) return true;
              node = node.parent;
            }
            return false;
          });
        let node: THREE.Object3D | null = hit?.object ?? null;
        while (node && !node.userData.selection) node = node.parent;
        current.current.onSelect(
          node ? (node.userData.selection as Selection) : null,
        );
      }
    };
    renderer.domElement.addEventListener("pointerdown", down);
    renderer.domElement.addEventListener("pointerup", up);
    props.exportRef.current = () =>
      new Promise((resolve) => {
        renderer.render(scene, camera);
        renderer.domElement.toBlob(resolve, "image/png");
      });
    return () => {
      cancelAnimationFrame(frame);
      observer.disconnect();
      controls.dispose();
      renderer.domElement.removeEventListener("pointerdown", down);
      renderer.domElement.removeEventListener("pointerup", up);
      dispose(scene);
      renderer.dispose();
      renderer.domElement.remove();
      runtime.current = null;
    };
  }, []);
  useEffect(() => {
    const r = runtime.current;
    if (!r) return;
    if (r.root) {
      r.scene.remove(r.root);
      dispose(r.root);
    }
    r.root = makeHouse(
      props.project,
      props.view,
      props.roof,
      props.terrain,
      props.level,
      props.selected,
    );
    r.scene.add(r.root);
  }, [
    props.project,
    props.view,
    props.roof,
    props.terrain,
    props.level,
    props.selected,
  ]);
  useEffect(() => {
    const r = runtime.current;
    if (!r) return;
    const positions: [number, number, number][] =
      props.view === "perspective"
        ? [
            [29, 10, -23],
            [27, 7, 27],
            [-12, 7, -20],
          ]
        : [
            [32, 28, 35],
            [-17, 28, 30],
            [10, 40, 5.1],
          ];
    const damping = r.controls.enableDamping;
    r.controls.enableDamping = false;
    r.controls.update();
    r.camera.position.set(...positions[props.preset % positions.length]);
    r.controls.target.set(10, props.view === "perspective" ? 1.4 : 0, 5);
    r.controls.update();
    r.controls.enableDamping = damping;
  }, [props.preset, props.view]);
  return (
    <div
      ref={host}
      className={`scene ${props.placing ? "placing" : ""}`}
      aria-label="Interactive 3D lake house"
    >
      {error && <div className="webgl-error">{error}</div>}
    </div>
  );
}
