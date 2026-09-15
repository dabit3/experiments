import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it } from "vitest";
import { PropertyForm } from "./App";
import { catalog, createProject, placeFurniture } from "./model";
import type { Furniture, Opening, Project, Room, Selection, Wall } from "./model";

function validateNumericControls(
  project: Project,
  type: NonNullable<Selection>["type"],
  item: Room | Wall | Opening | Furniture,
) {
  const html = renderToStaticMarkup(
    <PropertyForm
      selection={{ type, id: item.id }}
      item={item}
      project={project}
      onChange={() => {}}
      onDelete={() => {}}
    />,
  );
  const inputs = html.match(/<input\b[^>]*type="number"[^>]*>/g) ?? [];
  expect(inputs.length).toBeGreaterThan(0);
  for (const input of inputs) {
    const attrs = Object.fromEntries(
      [...input.matchAll(/([\w-]+)="([^"]*)"/g)].map((m) => [m[1], m[2]]),
    );
    const value = Number(attrs.value);
    expect(Number.isFinite(value), attrs["aria-label"]).toBe(true);
    expect(value, attrs["aria-label"]).toBeGreaterThanOrEqual(Number(attrs.min));
    expect(value, attrs["aria-label"]).toBeLessThanOrEqual(Number(attrs.max));
    if (attrs.step !== "any") {
      const steps = (value - Number(attrs.min)) / Number(attrs.step ?? 1);
      expect(steps, `${attrs["aria-label"]} ${value}`).toBeCloseTo(
        Math.round(steps),
        8,
      );
    }
  }
}

describe("property form numeric constraints", () => {
  it("accepts every built-in object without changing its existing dimensions", () => {
    const project = createProject();
    for (const room of project.rooms) validateNumericControls(project, "room", room);
    for (const wall of project.walls) validateNumericControls(project, "wall", wall);
    for (const opening of project.openings)
      validateNumericControls(project, "opening", opening);
    for (const item of project.furniture)
      validateNumericControls(project, "furniture", item);
  });

  it("accepts all placed library dimensions and precise imported dimensions", () => {
    const project = createProject();
    for (const item of catalog) {
      const placed = placeFurniture(project, item.kind, 3.14, 2.76, item.kind);
      validateNumericControls(placed, "furniture", placed.furniture.at(-1)!);
    }
    validateNumericControls(project, "furniture", {
      ...project.furniture[0],
      x: 5.125,
      w: 0.853,
      rotation: 22.5,
    });
  });
});
