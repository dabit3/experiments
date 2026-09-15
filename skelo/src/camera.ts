import * as THREE from 'three'

export function fitCamera(bounds: THREE.Box3, direction: THREE.Vector3, fov: number, aspect: number) {
  const target = bounds.getCenter(new THREE.Vector3())
  const orientation = new THREE.Matrix4().lookAt(direction, new THREE.Vector3(), new THREE.Vector3(0, 1, 0))
  const inverse = new THREE.Quaternion().setFromRotationMatrix(orientation).invert()
  const vertical = Math.tan(THREE.MathUtils.degToRad(fov) / 2)
  const horizontal = vertical * aspect
  let distance = 3
  for (const x of [bounds.min.x, bounds.max.x]) {
    for (const y of [bounds.min.y, bounds.max.y]) {
      for (const z of [bounds.min.z, bounds.max.z]) {
        const corner = new THREE.Vector3(x, y, z).sub(target).applyQuaternion(inverse)
        distance = Math.max(distance, corner.z + Math.abs(corner.x) * 1.12 / horizontal, corner.z + Math.abs(corner.y) * 1.12 / vertical)
      }
    }
  }
  return { target, position: direction.clone().normalize().multiplyScalar(distance).add(target), distance }
}
