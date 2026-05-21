/**
 * Playfield : bumpers facon champignon d'arcade (base metal + cap + anneau lumineux).
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
    // Le mesh principal (synchro physique) reste un cylindre de la bonne taille.
    // On lui donne le materiau emissif, et on accroche le decor en sous-meshes.
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
    mesh.castShadow = true;

    // Base metallique large
    const base = new THREE.Mesh(
      new THREE.CylinderGeometry(BUMPER_RADIUS * 1.35, BUMPER_RADIUS * 1.5, BUMPER_HEIGHT * 0.3, 24),
      new THREE.MeshStandardMaterial({ color: 0x9a9a9a, metalness: 0.9, roughness: 0.25 }),
    );
    base.position.y = -BUMPER_HEIGHT * 0.35;
    mesh.add(base);

    // Chapeau bombe
    const cap = new THREE.Mesh(
      new THREE.SphereGeometry(BUMPER_RADIUS * 0.9, 20, 12, 0, Math.PI * 2, 0, Math.PI / 2),
      new THREE.MeshStandardMaterial({
        color: COLORS.primary,
        emissive: new THREE.Color(COLORS.primary),
        emissiveIntensity: 0.9,
        roughness: 0.3,
      }),
    );
    cap.position.y = BUMPER_HEIGHT * 0.5;
    mesh.add(cap);

    // Anneau LED lumineux autour de la base
    const ring = new THREE.Mesh(
      new THREE.TorusGeometry(BUMPER_RADIUS * 1.15, 0.06, 8, 32),
      new THREE.MeshStandardMaterial({
        color: 0xffffff,
        emissive: new THREE.Color(COLORS.highlight),
        emissiveIntensity: 1.5,
      }),
    );
    ring.rotation.x = Math.PI / 2;
    ring.position.y = -BUMPER_HEIGHT * 0.15;
    mesh.add(ring);

    scene.add(mesh);
    meshes.push(mesh);
  }

  return meshes;
}
