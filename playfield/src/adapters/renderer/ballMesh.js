/**
 * Playfield : mesh de la bille (chrome + halo).
 */
import * as THREE from "three";
import { BALL_RADIUS } from "../../domain/constants.js";
import { COLORS } from "../../domain/theme.js";

export function createBallMesh(scene) {
  const mesh = new THREE.Mesh(
    new THREE.SphereGeometry(BALL_RADIUS, 32, 32),
    new THREE.MeshStandardMaterial({
      color: 0xdddddd,
      metalness: 0.95,
      roughness: 0.15,
      emissive: new THREE.Color(COLORS.highlight),
      emissiveIntensity: 0.4,
    }),
  );
  mesh.castShadow = true;
  mesh.add(new THREE.PointLight(COLORS.highlight, 1.8, 6, 2));
  scene.add(mesh);
  return mesh;
}
