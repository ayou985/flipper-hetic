/**
 * Playfield — Meshes Three.js des bumpers.
 */
import * as THREE from "three";
import {
  BUMPER_RADIUS,
  BUMPER_HEIGHT,
  BUMPER_POSITIONS,
} from "../../domain/constants.js";
import { COLORS } from "../../domain/theme.js";

export function createBumperMeshes(scene) {
  const meshes = [];
  for (const pos of BUMPER_POSITIONS) {
    // Chaque bumper a son propre materiau pour pouvoir flasher individuellement
    const material = new THREE.MeshStandardMaterial({
      color: COLORS.primary,
      metalness: 0.5,
      roughness: 0.3,
      emissive: new THREE.Color(COLORS.primary),
      emissiveIntensity: 0.65,
    });
    const mesh = new THREE.Mesh(
      new THREE.CylinderGeometry(BUMPER_RADIUS, BUMPER_RADIUS, BUMPER_HEIGHT, 24),
      material,
    );
    mesh.position.set(pos.x, BUMPER_HEIGHT / 2, pos.z);
    scene.add(mesh);
    meshes.push(mesh);
  }
  return meshes;
}
