import { describe, expect, it } from 'vitest';
import { addObject, commit, createProject, exportProject, parseProject, redo, searchLibrary, seededRandom, sunPosition, undo, updateObject } from '../src/model';
import type { History } from '../src/model';

describe('Forest House fixture', () => {
  it('opens to furnished architecture with valid persisted geometry and three distinct cameras', () => {
    const project = createProject();
    expect(parseProject(exportProject(project))).toEqual(project);
    expect(project.objects.map(o => o.kind)).toEqual(expect.arrayContaining(['pavilion', 'deck', 'chair', 'maple', 'birch']));
    expect(new Set(project.shots.map(s => s.position.join(','))).size).toBe(3);
    expect(project.objects.find(o => o.id === 'chair-1')!.position[1]).toBe(1.03);
  });
  it('returns independent fixtures', () => {
    const a = createProject(), b = createProject();
    a.objects[0].position[0] = 40;
    a.ambience.time = 7;
    expect(b.objects[0].position[0]).toBe(0);
    expect(b.ambience.time).toBe(16.5);
  });
});
describe('Library and transforms', () => {
  it('filters real names and descriptions case-insensitively, respecting categories', () => {
    expect(searchLibrary(' MAPLE ', 'All').map(a => a.kind)).toEqual(['maple']);
    expect(searchLibrary('oak', 'Objects').map(a => a.kind)).toEqual(['chair']);
    expect(searchLibrary('maple', 'Lights')).toEqual([]);
    expect(searchLibrary('missing', 'All')).toEqual([]);
  });
  it('places actual typed geometry, selects distinct identifiers and offsets repeated placements', () => {
    const before = createProject();
    const once = addObject(before, 'bench', 'bench-new');
    const twice = addObject(once, 'bench', 'bench-two');
    expect(before.objects).toHaveLength(7);
    expect(twice.objects).toHaveLength(9);
    expect(twice.objects.at(-1)!.position[0]).toBeGreaterThan(once.objects.at(-1)!.position[0]);
    expect(twice.objects.at(-1)!.name).toBe('Timber bench 02');
    expect(addObject(twice, 'bench', 'bench-new')).toBe(twice);
  });
  it('changes only selected object coordinates, visibility and material', () => {
    const before = createProject();
    const after = updateObject(before, 'pavilion', { position: [1.5, 2, -4], rotation: 40, scale: 1.2, material: 'charcoal', visible: false });
    expect(after.objects[0]).toMatchObject({ position: [1.5, 2, -4], rotation: 40, scale: 1.2, material: 'charcoal', visible: false });
    expect(after.objects[1]).toBe(before.objects[1]);
    expect(before.objects[0].position).toEqual([0, 0, -3]);
  });
});
describe('Undo and redo transactions', () => {
  it('restores geometry, material and environment, and clears redo on a branch', () => {
    const base: History = { past: [], present: createProject(), future: [] };
    const placed = commit(base, addObject(base.present, 'bench', 'new'));
    const recolored = commit(placed, updateObject(placed.present, 'new', { material: 'terracotta', position: [8, 0, 4] }));
    const weather = commit(recolored, { ...recolored.present, ambience: { ...recolored.present.ambience, season: 'Autumn', time: 19 } });
    expect(undo(weather).present).toEqual(recolored.present);
    expect(undo(undo(undo(weather))).present).toEqual(base.present);
    expect(redo(undo(weather)).present).toEqual(weather.present);
    expect(commit(undo(weather), base.present).future).toEqual([]);
    expect(undo(base)).toBe(base);
    expect(redo(base)).toBe(base);
  });
  it('limits history without treating a no-op as a transaction', () => {
    let history: History = { past: [], present: createProject(), future: [] };
    expect(commit(history, createProject())).toBe(history);
    for (let i = 0; i < 80; i++) history = commit(history, { ...history.present, name: `Edit ${i}` });
    expect(history.past).toHaveLength(60);
  });
});
describe('Persistence and genuine project export', () => {
  it('round trips object edits, saved camera, weather and names without losing precision', () => {
    let project = addObject(createProject(), 'rock', 'new');
    project = updateObject(project, 'new', { name: 'River edge <rock>', position: [3.145, 0.62, -1.2] });
    project.shots.push({ id: 'custom', name: 'My shot', position: [9.3, 4.2, 11.8], target: [2, 0, -1], ambience: { time: 19.25, season: 'Autumn', weather: 'Mist', fog: 30 } });
    const exported = exportProject(project);
    expect(JSON.parse(exported).objects.at(-1).position).toEqual([3.145, 0.62, -1.2]);
    expect(parseProject(exported)).toEqual(project);
  });
  it.each(['', '{', 'null', '[]', '{"version":2}', '{"version":1}', '"not a project"'])('rejects malformed payload %j', raw => {
    expect(parseProject(raw)).toBeNull();
  });
  it('rejects malformed transforms, duplicate IDs, unknown materials, corrupt shots and oversized input', () => {
    const values = [
      { ...createProject(), objects: [{ ...createProject().objects[0], scale: -1 }] },
      { ...createProject(), objects: [{ ...createProject().objects[0], position: [0, 'oops', 0] }] },
      { ...createProject(), objects: [{ ...createProject().objects[0], material: 'malicious' }] },
      { ...createProject(), objects: [createProject().objects[0], createProject().objects[0]] },
      { ...createProject(), shots: [{ ...createProject().shots[0], target: [0, 0] }] },
      { ...createProject(), ambience: { ...createProject().ambience, time: 99 } },
    ];
    values.forEach(value => expect(parseProject(JSON.stringify(value))).toBeNull());
    expect(parseProject(' '.repeat(500_001))).toBeNull();
  });
});
describe('Procedural geometry and sun', () => {
  it('uses a deterministic vegetation generator within its range', () => {
    const a = seededRandom(311), b = seededRandom(311), c = seededRandom(312);
    const sequence = Array.from({ length: 100 }, a);
    expect(sequence).toEqual(Array.from({ length: 100 }, b));
    expect(sequence).not.toEqual(Array.from({ length: 100 }, c));
    expect(sequence.every(value => value >= 0 && value < 1)).toBe(true);
  });
  it('moves sunlight east to west and keeps it above the horizon at supported times', () => {
    expect(sunPosition(6)[0]).toBeGreaterThan(0);
    expect(sunPosition(21)[0]).toBeLessThan(0);
    expect(sunPosition(13.5)[1]).toBe(27);
    for (let time = 6; time <= 21; time += 0.25) expect(sunPosition(time)[1]).toBeGreaterThanOrEqual(2);
  });
});
