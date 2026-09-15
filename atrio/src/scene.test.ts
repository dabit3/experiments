import { describe, expect, it } from 'vitest'
import { Raycaster, Vector3 } from 'three'
import { doorOnWall, wallFromPoints } from './model'
import type { Project } from './model'
import { buildCampus, disposeScene } from './scene'

describe('rendered wall openings', () => {
  it.each(['timber', 'glass'] as const)('keeps %s wall decorations out of a hosted doorway', material => {
    const wall = wallFromPoints('wall', { x: -4, z: 0 }, { x: 4, z: 0 }, 0, material)
    const project: Project = { version: 1, name: 'Door clearance', elements: [wall] }
    const door = { ...doorOnWall('door', wall, { x: 0, z: 0 }, project), height: 2.8 }
    project.elements.push(door)
    const { root, elements } = buildCampus(project, 'Structure only', false, 'Surfaces')
    root.updateMatrixWorld(true)
    const geometry = elements.get(wall.id)!
    for (const height of [1, wall.height * .64]) {
      const ray = new Raycaster(new Vector3(.12, height + .23, -2), new Vector3(0, 0, 1))
      expect(ray.intersectObject(geometry, true)).toHaveLength(0)
    }
    const solidWall = new Raycaster(new Vector3(-3, 1.23, -2), new Vector3(0, 0, 1))
    expect(solidWall.intersectObject(geometry, true).length).toBeGreaterThan(0)
    disposeScene(root)
  })
})
