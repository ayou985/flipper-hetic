#!/usr/bin/env bash
# Vague 3 : couche thematique (texture plateau labo + fioles/molecules 3D)
set -e

if [ ! -d "playfield" ]; then
  echo "Erreur : lance depuis la racine du projet."
  exit 1
fi

git tag backup-before-arcade-v3-theme 2>/dev/null || true

# === Decor thematique : texture canvas + elements 3D non physiques ===
cat > playfield/src/adapters/renderer/themeDecor.js << 'EOF'
/**
 * Decor thematique (labo / chimie) ajoute par-dessus le plateau.
 * Purement visuel : aucun corps physique, place hors des trajectoires.
 */
import * as THREE from "three";
import { TABLE_WIDTH, TABLE_DEPTH } from "../../domain/constants.js";
import { COLORS } from "../../domain/theme.js";

// Genere une texture "feutre + voile chimique" via canvas 2D
function makePlayfieldTexture() {
  const c = document.createElement("canvas");
  c.width = 512;
  c.height = 1024;
  const ctx = c.getContext("2d");

  // Fond degrade desert -> vert toxique
  const grad = ctx.createLinearGradient(0, 0, 0, c.height);
  grad.addColorStop(0, "#1a3a16");
  grad.addColorStop(0.5, "#21421d");
  grad.addColorStop(1, "#2a3315");
  ctx.fillStyle = grad;
  ctx.fillRect(0, 0, c.width, c.height);

  // Halos verts diffus facon fioles bouillonnantes
  const blobs = [
    [120, 250, 90], [400, 500, 120], [200, 780, 100], [330, 160, 70],
  ];
  for (const [x, y, r] of blobs) {
    const g = ctx.createRadialGradient(x, y, 0, x, y, r);
    g.addColorStop(0, "rgba(57, 255, 20, 0.10)");
    g.addColorStop(1, "rgba(57, 255, 20, 0)");
    ctx.fillStyle = g;
    ctx.beginPath();
    ctx.arc(x, y, r, 0, Math.PI * 2);
    ctx.fill();
  }

  // Molecules stylisees (cercles relies par des traits)
  ctx.strokeStyle = "rgba(199, 231, 60, 0.18)";
  ctx.fillStyle = "rgba(199, 231, 60, 0.22)";
  ctx.lineWidth = 3;
  const molecules = [
    [{ x: 90, y: 120 }, { x: 150, y: 90 }, { x: 150, y: 160 }],
    [{ x: 380, y: 700 }, { x: 440, y: 730 }, { x: 410, y: 790 }, { x: 350, y: 760 }],
    [{ x: 250, y: 420 }, { x: 310, y: 400 }, { x: 290, y: 470 }],
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

// Une fiole : cylindre de verre + liquide vert emissif
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
      emissiveIntensity: 1.2,
      roughness: 0.3,
    }),
  );
  liquid.position.y = 0.22 * scale;
  group.add(liquid);

  // Petite lumiere pour le glow avec le bloom
  group.add(new THREE.PointLight(COLORS.accent, 0.8, 3, 2));

  group.position.set(x, 0, z);
  scene.add(group);
  return group;
}

export function addThemeDecor(scene, tableMeshes) {
  // 1. Applique la texture sur le plateau (mesh 0 = plateau)
  const playfield = tableMeshes[0];
  if (playfield?.material) {
    playfield.material.map = makePlayfieldTexture();
    playfield.material.color.set(0xffffff); // laisse la texture parler
    playfield.material.needsUpdate = true;
  }

  // 2. Place 3 fioles dans des coins libres (hors trajectoires et bumpers)
  const halfW = TABLE_WIDTH / 2;
  const halfD = TABLE_DEPTH / 2;
  makeFlask(scene, -halfW + 0.9, -halfD + 1.0, 0.8);  // coin haut gauche
  makeFlask(scene, halfW - 0.9, -halfD + 1.4, 1.0);   // coin haut droit
  makeFlask(scene, halfW - 1.0, 0.5, 0.7);            // milieu droit
}
EOF

# === Hook addThemeDecor dans main.js ===
python3 - <<'PYEOF'
path = "playfield/src/main.js"
with open(path) as f:
    c = f.read()

if "addThemeDecor" not in c:
    # import
    c = c.replace(
        'import { buildLevel } from "./composition/buildLevel.js";',
        'import { buildLevel } from "./composition/buildLevel.js";\nimport { addThemeDecor } from "./adapters/renderer/themeDecor.js";',
    )
    # appel juste apres buildLevel (level expose tableMeshes ? sinon via scene)
    # buildLevel retourne syncPairs ; le plateau est syncPairs[0].mesh
    c = c.replace(
        "const level = buildLevel({ scene, world });",
        "const level = buildLevel({ scene, world });\naddThemeDecor(scene, [level.syncPairs[0].mesh]);",
    )

with open(path, "w") as f:
    f.write(c)
print("main.js : decor thematique branche.")
PYEOF

git add -A
git commit -m "feat: habillage thematique du plateau

Texture procedurale facon labo (degrade desertique, halos verts,
molecules stylisees) appliquee sur le plateau, plus trois fioles
lumineuses placees dans les coins libres. Purement visuel, sans
corps physique."

git push origin feat/vfx-bonus --force-with-lease

echo ""
echo "Vague 3 OK. Recharge le playfield (Ctrl+Shift+R)."
echo "TEST CRITIQUE : la balle se lance et rebondit toujours normalement ?"
echo "Les fioles sont dans les coins (elles ne doivent PAS gener la balle)."