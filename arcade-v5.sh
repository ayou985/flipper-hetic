#!/usr/bin/env bash
# Vague 5 : rails metalliques decoratifs + palette plus chimique
set -e

if [ ! -d "playfield" ]; then
  echo "Erreur : lance depuis la racine du projet."
  exit 1
fi

git tag backup-before-arcade-v5 2>/dev/null || true

# === rails.js : rails metalliques courbes en bordure (decoratifs) ===
cat > playfield/src/adapters/renderer/rails.js << 'EOF'
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
EOF

# === themeDecor.js : pousser la palette plus chimique dans la texture ===
cat > playfield/src/adapters/renderer/themeDecor.js << 'EOF'
/**
 * Decor thematique (labo / chimie) : texture du plateau + fioles 3D.
 * Purement visuel, hors des trajectoires.
 */
import * as THREE from "three";
import { TABLE_WIDTH, TABLE_DEPTH } from "../../domain/constants.js";
import { COLORS } from "../../domain/theme.js";

function makePlayfieldTexture() {
  const c = document.createElement("canvas");
  c.width = 512;
  c.height = 1024;
  const ctx = c.getContext("2d");

  // Degrade pousse cote vert/jaune chimique
  const grad = ctx.createLinearGradient(0, 0, 0, c.height);
  grad.addColorStop(0, "#1c4a10");
  grad.addColorStop(0.45, "#28571a");
  grad.addColorStop(0.75, "#3a5e12");
  grad.addColorStop(1, "#243f0c");
  ctx.fillStyle = grad;
  ctx.fillRect(0, 0, c.width, c.height);

  // Halos verts toxiques plus marques
  const blobs = [
    [120, 250, 110], [400, 500, 140], [200, 780, 120], [330, 160, 80], [430, 880, 90],
  ];
  for (const [x, y, r] of blobs) {
    const g = ctx.createRadialGradient(x, y, 0, x, y, r);
    g.addColorStop(0, "rgba(57, 255, 20, 0.16)");
    g.addColorStop(1, "rgba(57, 255, 20, 0)");
    ctx.fillStyle = g;
    ctx.beginPath();
    ctx.arc(x, y, r, 0, Math.PI * 2);
    ctx.fill();
  }

  // Lanes lumineuses jaunes (bandes facon couloirs de flipper)
  ctx.strokeStyle = "rgba(199, 231, 60, 0.30)";
  ctx.lineWidth = 10;
  ctx.beginPath();
  ctx.moveTo(80, 60); ctx.lineTo(80, 240);
  ctx.moveTo(130, 60); ctx.lineTo(130, 240);
  ctx.moveTo(432, 60); ctx.lineTo(432, 240);
  ctx.moveTo(382, 60); ctx.lineTo(382, 240);
  ctx.stroke();

  // Molecules stylisees
  ctx.strokeStyle = "rgba(199, 231, 60, 0.22)";
  ctx.fillStyle = "rgba(199, 231, 60, 0.28)";
  ctx.lineWidth = 3;
  const molecules = [
    [{ x: 90, y: 360 }, { x: 150, y: 330 }, { x: 150, y: 400 }],
    [{ x: 380, y: 700 }, { x: 440, y: 730 }, { x: 410, y: 790 }, { x: 350, y: 760 }],
    [{ x: 250, y: 480 }, { x: 310, y: 460 }, { x: 290, y: 530 }],
  ];
  for (const atoms of molecules) {
    ctx.beginPath();
    ctx.moveTo(atoms[0].x, atoms[0].y);
    for (let i = 1; i < atoms.length; i++) ctx.lineTo(atoms[i].x, atoms[i].y);
    ctx.closePath();
    ctx.stroke();
    for (const a of atoms) {
      ctx.beginPath();
      ctx.arc(a.x, a.y, 8, 0, Math.PI * 2);
      ctx.fill();
    }
  }

  const tex = new THREE.CanvasTexture(c);
  tex.anisotropy = 4;
  return tex;
}

function makeFlask(scene, x, z, scale = 1) {
  const group = new THREE.Group();

  const glass = new THREE.Mesh(
    new THREE.CylinderGeometry(0.28 * scale, 0.34 * scale, 0.9 * scale, 16, 1, true),
    new THREE.MeshStandardMaterial({
      color: 0xaaffcc,
      transparent: true,
      opacity: 0.25,
      roughness: 0.1,
      metalness: 0.2,
      side: THREE.DoubleSide,
    }),
  );
  glass.position.y = 0.45 * scale;
  group.add(glass);

  const liquid = new THREE.Mesh(
    new THREE.CylinderGeometry(0.25 * scale, 0.31 * scale, 0.4 * scale, 16),
    new THREE.MeshStandardMaterial({
      color: COLORS.accent,
      emissive: new THREE.Color(COLORS.accent),
      emissiveIntensity: 1.3,
      roughness: 0.3,
    }),
  );
  liquid.position.y = 0.22 * scale;
  group.add(liquid);

  group.add(new THREE.PointLight(COLORS.accent, 0.9, 3, 2));

  group.position.set(x, 0, z);
  scene.add(group);
  return group;
}

export function addThemeDecor(scene, tableMeshes) {
  const playfield = tableMeshes[0];
  if (playfield?.material) {
    playfield.material.map = makePlayfieldTexture();
    playfield.material.color.set(0xffffff);
    playfield.material.needsUpdate = true;
  }

  const halfW = TABLE_WIDTH / 2;
  const halfD = TABLE_DEPTH / 2;
  makeFlask(scene, -halfW + 0.9, -halfD + 1.0, 0.8);
  makeFlask(scene, halfW - 0.9, -halfD + 1.4, 1.0);
  makeFlask(scene, halfW - 1.0, 0.5, 0.7);
}
EOF

# === main.js : appeler addRails ===
python3 - <<'PYEOF'
path = "playfield/src/main.js"
with open(path) as f:
    c = f.read()

if "addRails" not in c:
    c = c.replace(
        'import { addAmbiance } from "./adapters/renderer/ambiance.js";',
        'import { addAmbiance } from "./adapters/renderer/ambiance.js";\nimport { addRails } from "./adapters/renderer/rails.js";',
    )
    # Appeler addRails apres addThemeDecor
    c = c.replace(
        "addThemeDecor(scene, [level.syncPairs[0].mesh]);",
        "addThemeDecor(scene, [level.syncPairs[0].mesh]);\naddRails(scene);",
    )

with open(path, "w") as f:
    f.write(c)
print("main.js : rails branches.")
PYEOF

git add -A
git commit -m "feat: rails metalliques et palette chimique renforcee

Rails decoratifs courbes le long des bordures (metal + liseres LED
verts), texture du plateau poussee vers le vert/jaune chimique avec
lanes lumineuses. Aucun corps physique ajoute."

git push origin feat/vfx-bonus --force-with-lease

echo ""
echo "Vague 5 OK. Recharge le playfield (Ctrl+Shift+R)."
echo "TEST CRITIQUE : la balle ne doit PAS toucher les rails (ils sont colles aux murs)."
echo "Verifie que les rebonds bumpers/flippers sont inchanges."