/**
 * Ambiance industrielle : fond de scene degrade et mur de fenetres
 * retroeclairees place derriere le haut du plateau. Purement visuel.
 */
import * as THREE from "three";
import { TABLE_WIDTH, TABLE_DEPTH } from "../../domain/constants.js";

// Texture canvas : grille de fenetres industrielles retroeclairees
function makeWindowTexture() {
  const c = document.createElement("canvas");
  c.width = 512;
  c.height = 256;
  const ctx = c.getContext("2d");

  // Halo lumineux vert-jaune derriere les vitres
  const grad = ctx.createLinearGradient(0, 0, 0, c.height);
  grad.addColorStop(0, "#cdd94a");
  grad.addColorStop(0.5, "#7e9c2e");
  grad.addColorStop(1, "#33491c");
  ctx.fillStyle = grad;
  ctx.fillRect(0, 0, c.width, c.height);

  // Meneaux (barres metalliques sombres) en grille
  ctx.strokeStyle = "rgba(20, 28, 14, 0.85)";
  ctx.lineWidth = 6;
  const cols = 8;
  const rows = 4;
  const cw = c.width / cols;
  const rh = c.height / rows;
  for (let i = 0; i <= cols; i++) {
    ctx.beginPath();
    ctx.moveTo(i * cw, 0);
    ctx.lineTo(i * cw, c.height);
    ctx.stroke();
  }
  for (let j = 0; j <= rows; j++) {
    ctx.beginPath();
    ctx.moveTo(0, j * rh);
    ctx.lineTo(c.width, j * rh);
    ctx.stroke();
  }
  // Reflets clairs aleatoires sur quelques carreaux
  ctx.fillStyle = "rgba(255, 255, 220, 0.15)";
  for (let i = 0; i < cols; i++) {
    for (let j = 0; j < rows; j++) {
      if (Math.random() > 0.6) {
        ctx.fillRect(i * cw + 4, j * rh + 4, cw - 8, rh - 8);
      }
    }
  }

  return new THREE.CanvasTexture(c);
}

export function addAmbiance(scene) {
  // 1. Fond de scene : vert tres sombre plutot que noir pur
  scene.background = new THREE.Color(0x0c1408);

  // 2. Brouillard leger pour la profondeur (teinte verte)
  scene.fog = new THREE.Fog(0x0c1408, 30, 70);

  // 3. Mur de fenetres derriere le haut du plateau (Z negatif = haut)
  const wall = new THREE.Mesh(
    new THREE.PlaneGeometry(TABLE_WIDTH * 2.2, 14),
    new THREE.MeshBasicMaterial({
      map: makeWindowTexture(),
      transparent: true,
      opacity: 0.9,
    }),
  );
  // Vertical, derriere le plateau, legerement sureleve
  wall.position.set(0, 4, -TABLE_DEPTH / 2 - 6);
  wall.rotation.x = -Math.PI / 2 + 0.35; // legerement inclinee vers la camera
  scene.add(wall);

  // 4. Lueur verte diffuse qui emane des fenetres
  const glow = new THREE.PointLight(0x9bc23a, 1.4, 40, 2);
  glow.position.set(0, 6, -TABLE_DEPTH / 2 - 4);
  scene.add(glow);
}
