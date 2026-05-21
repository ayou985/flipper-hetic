/**
 * Rails metalliques decoratifs le long des bords du plateau.
 * Purement visuel : poses contre les murs, hors des trajectoires de bille.
 */
import * as THREE from "three";
import { TABLE_WIDTH, TABLE_DEPTH } from "../../domain/constants.js";

const railMat = new THREE.MeshStandardMaterial({
  color: 0xc8ccd0,
  metalness: 0.95,
  roughness: 0.2,
});

// Un rail = tube le long d'une courbe
function addRail(scene, points, radius = 0.05) {
  const curve = new THREE.CatmullRomCurve3(
    points.map((p) => new THREE.Vector3(p.x, p.y ?? 0.5, p.z)),
  );
  const geo = new THREE.TubeGeometry(curve, 32, radius, 8, false);
  const mesh = new THREE.Mesh(geo, railMat);
  mesh.castShadow = true;
  scene.add(mesh);
  return mesh;
}

export function addRails(scene) {
  const halfW = TABLE_WIDTH / 2;
  const halfD = TABLE_DEPTH / 2;
  const inset = 0.55; // ecart depuis le mur, contre la bordure

  // Rail courbe haut gauche -> descend le long du mur gauche
  addRail(scene, [
    { x: -halfW + inset, z: halfD - 3 },
    { x: -halfW + inset, z: 0 },
    { x: -halfW + inset + 0.3, z: -halfD + 4 },
    { x: -halfW + inset + 1.5, z: -halfD + 1.5 },
  ]);

  // Rail courbe haut droit symetrique
  addRail(scene, [
    { x: halfW - inset, z: halfD - 3 },
    { x: halfW - inset, z: 0 },
    { x: halfW - inset - 0.3, z: -halfD + 4 },
    { x: halfW - inset - 1.5, z: -halfD + 1.5 },
  ]);

  // Petit rail courbe en haut au centre (arc facon lanceur)
  addRail(scene, [
    { x: -2, z: -halfD + 1 },
    { x: 0, z: -halfD + 0.5 },
    { x: 2, z: -halfD + 1 },
  ], 0.045);

  // Liseres LED verts qui suivent les rails lateraux (emissifs)
  const ledMat = new THREE.MeshStandardMaterial({
    color: 0x39ff14,
    emissive: new THREE.Color(0x39ff14),
    emissiveIntensity: 1.4,
  });
  function addLed(x) {
    const geo = new THREE.BoxGeometry(0.04, 0.04, TABLE_DEPTH - 4);
    const led = new THREE.Mesh(geo, ledMat);
    led.position.set(x, 0.55, -1);
    scene.add(led);
  }
  addLed(-halfW + inset - 0.15);
  addLed(halfW - inset + 0.15);
}
