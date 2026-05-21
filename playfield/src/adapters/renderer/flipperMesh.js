/**
 * Playfield : meshes des flippers (corps metal + bord caoutchoute).
 */
import * as THREE from "three";
import {
  FLIPPER_LENGTH,
  FLIPPER_WIDTH,
  FLIPPER_HEIGHT,
  FLIPPER_PIVOT_X,
  FLIPPER_PIVOT_Z,
  FLIPPER_PIVOT_Y,
} from "../../domain/constants.js";

function createOneFlipperMesh(scene, side) {
  const isLeft = side === "left";
  const pivotX = isLeft ? -FLIPPER_PIVOT_X : FLIPPER_PIVOT_X;
  const shapeOffsetX = isLeft ? FLIPPER_LENGTH / 2 : -FLIPPER_LENGTH / 2;

  // Corps principal (synchro physique) : metal sombre
  const geometry = new THREE.BoxGeometry(FLIPPER_LENGTH, FLIPPER_HEIGHT, FLIPPER_WIDTH);
  geometry.translate(shapeOffsetX, 0, 0);
  const mesh = new THREE.Mesh(
    geometry,
    new THREE.MeshStandardMaterial({ color: 0x2a2a2a, metalness: 0.85, roughness: 0.3 }),
  );
  mesh.position.set(pivotX, FLIPPER_PIVOT_Y, FLIPPER_PIVOT_Z);
  mesh.castShadow = true;

  // Bande caoutchoutee rouge sur le dessus
  const rubber = new THREE.Mesh(
    new THREE.BoxGeometry(FLIPPER_LENGTH * 0.95, FLIPPER_HEIGHT * 0.4, FLIPPER_WIDTH * 1.05),
    new THREE.MeshStandardMaterial({ color: 0xcc2222, roughness: 0.6, metalness: 0.1 }),
  );
  rubber.position.set(shapeOffsetX, FLIPPER_HEIGHT * 0.5, 0);
  mesh.add(rubber);

  // Capuchon arrondi au bout (cote frappe)
  const tipX = isLeft ? FLIPPER_LENGTH : -FLIPPER_LENGTH;
  const tip = new THREE.Mesh(
    new THREE.CylinderGeometry(FLIPPER_WIDTH * 0.55, FLIPPER_WIDTH * 0.55, FLIPPER_HEIGHT * 1.1, 16),
    new THREE.MeshStandardMaterial({ color: 0xcc2222, roughness: 0.6 }),
  );
  tip.position.set(tipX, 0, 0);
  mesh.add(tip);

  scene.add(mesh);
  return mesh;
}

export function createFlipperMeshes(scene) {
  return {
    left: createOneFlipperMesh(scene, "left"),
    right: createOneFlipperMesh(scene, "right"),
  };
}
