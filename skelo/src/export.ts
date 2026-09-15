import * as THREE from 'three'
import { OBJExporter } from 'three/addons/exporters/OBJExporter.js'
import { buildModel, disposeObject } from './geometry.ts'
import type { Project } from './model.ts'

export function exportObj(project: Project): string {
  const model = buildModel(project)
  const instances: THREE.InstancedMesh[] = []
  model.traverse(child => { if (child instanceof THREE.InstancedMesh) instances.push(child) })
  for (const instance of instances) {
    const parent = instance.parent!
    for (let i = 0; i < instance.count; i++) {
      const matrix = new THREE.Matrix4()
      instance.getMatrixAt(i, matrix)
      const mesh = new THREE.Mesh(instance.geometry.clone(), Array.isArray(instance.material) ? instance.material.map(m => m.clone()) : instance.material.clone())
      mesh.applyMatrix4(instance.matrix.clone().multiply(matrix))
      parent.add(mesh)
    }
    instance.removeFromParent()
    disposeObject(instance)
  }
  model.updateMatrixWorld(true)
  const text = `# Skelo ${project.name}\n# Units: meters. Visible tags only. Geometry without MTL.\n${new OBJExporter().parse(model)}`
  disposeObject(model)
  return text
}
