/**
 * Playfield : meshes du plateau et des murs (rendu type table d'arcade).
 */
import * as THREE from "three";
import {
  TABLE_WIDTH,
  TABLE_DEPTH,
  TABLE_THICKNESS,
  WALL_HEIGHT,
  WALL_THICKNESS,
  DRAIN_OPENING_WIDTH,
} from "../../domain/constants.js";

export function createTableMeshes(scene) {
  // Plateau : vert fonce mat facon feutre, leger relief
  const tableMat = new THREE.MeshStandardMaterial({
    color: 0x1f4a1c,
    roughness: 0.85,
    metalness: 0.05,
  });
  // Murs : bois sombre vernis
  const wallMat = new THREE.MeshStandardMaterial({
    color: 0x5a2f12,
    roughness: 0.5,
    metalness: 0.2,
  });

  const meshes = [];

  const table = new THREE.Mesh(
    new THREE.BoxGeometry(TABLE_WIDTH, TABLE_THICKNESS, TABLE_DEPTH),
    tableMat,
  );
  table.position.y = -TABLE_THICKNESS / 2;
  table.receiveShadow = true;
  scene.add(table);
  meshes.push(table);

  function addWall(w, h, d, x, y, z) {
    const mesh = new THREE.Mesh(new THREE.BoxGeometry(w, h, d), wallMat);
    mesh.position.set(x, y, z);
    mesh.castShadow = true;
    mesh.receiveShadow = true;
    scene.add(mesh);
    meshes.push(mesh);
    return mesh;
  }

  addWall(
    WALL_THICKNESS, WALL_HEIGHT, TABLE_DEPTH,
    -TABLE_WIDTH / 2 - WALL_THICKNESS / 2, WALL_HEIGHT / 2, 0,
  );
  addWall(
    WALL_THICKNESS, WALL_HEIGHT, TABLE_DEPTH,
    TABLE_WIDTH / 2 + WALL_THICKNESS / 2, WALL_HEIGHT / 2, 0,
  );
  addWall(
    TABLE_WIDTH + WALL_THICKNESS * 2, WALL_HEIGHT, WALL_THICKNESS,
    0, WALL_HEIGHT / 2, -TABLE_DEPTH / 2 - WALL_THICKNESS / 2,
  );

  const bottomWallWidth = (TABLE_WIDTH - DRAIN_OPENING_WIDTH) / 2;
  const bottomZ = TABLE_DEPTH / 2 + WALL_THICKNESS / 2;

  addWall(
    bottomWallWidth, WALL_HEIGHT, WALL_THICKNESS,
    -(DRAIN_OPENING_WIDTH / 2 + bottomWallWidth / 2), WALL_HEIGHT / 2, bottomZ,
  );
  addWall(
    bottomWallWidth, WALL_HEIGHT, WALL_THICKNESS,
    (DRAIN_OPENING_WIDTH / 2 + bottomWallWidth / 2), WALL_HEIGHT / 2, bottomZ,
  );

  // Decor non physique : liseres lumineux le long des murs lateraux
  const trimMat = new THREE.MeshStandardMaterial({
    color: 0xffb300,
    emissive: 0xffb300,
    emissiveIntensity: 0.6,
    roughness: 0.4,
  });
  const trimGeo = new THREE.BoxGeometry(0.15, 0.15, TABLE_DEPTH);
  const trimLeft = new THREE.Mesh(trimGeo, trimMat);
  trimLeft.position.set(-TABLE_WIDTH / 2 + 0.1, WALL_HEIGHT, 0);
  scene.add(trimLeft);
  const trimRight = new THREE.Mesh(trimGeo, trimMat);
  trimRight.position.set(TABLE_WIDTH / 2 - 0.1, WALL_HEIGHT, 0);
  scene.add(trimRight);

  return meshes;
}
