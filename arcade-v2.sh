#!/usr/bin/env bash
# Refonte arcade vague 2 : bumpers champignon + flippers metal/caoutchouc
set -e

if [ ! -d "playfield" ]; then
  echo "Erreur : lance depuis la racine du projet."
  exit 1
fi

git tag backup-before-arcade-v3 2>/dev/null || true

# === bumperMesh.js : champignon metal + cap + anneau LED ===
cat > playfield/src/adapters/renderer/bumperMesh.js << 'EOF'
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
EOF

# === flipperMesh.js : metal chrome + bout caoutchoute ===
cat > playfield/src/adapters/renderer/flipperMesh.js << 'EOF'
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
EOF

git add -A
git commit -m "feat: bumpers et flippers en relief

Bumpers facon champignon : base metallique, chapeau bombe emissif et
anneau lumineux. Flippers en metal sombre avec bande caoutchoutee rouge
et capuchon arrondi au bout."

git push origin feat/vfx-bonus --force-with-lease

echo ""
echo "Vague 2 OK. Recharge le playfield (Ctrl+Shift+R)."
echo "TEST CRITIQUE : la balle rebondit toujours bien sur les bumpers et les flippers ?"