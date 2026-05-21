#!/usr/bin/env bash
# Refonte arcade vague 1 : plateau + murs + ombres + lumieres
set -e

if [ ! -d "playfield" ]; then
  echo "Erreur : lance depuis la racine du projet."
  exit 1
fi

git tag backup-before-arcade-v2 2>/dev/null || true

# === tableMesh.js : plateau feutre + bois + biseaux ===
cat > playfield/src/adapters/renderer/tableMesh.js << 'EOF'
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
EOF

# === scene.js : activer les ombres + spotlight ===
cat > playfield/src/adapters/renderer/scene.js << 'EOF'
/**
 * Playfield : scene Three.js, camera, lumieres, renderer + post-processing.
 */
import * as THREE from "three";
import { EffectComposer } from "three/examples/jsm/postprocessing/EffectComposer.js";
import { RenderPass } from "three/examples/jsm/postprocessing/RenderPass.js";
import { UnrealBloomPass } from "three/examples/jsm/postprocessing/UnrealBloomPass.js";
import {
  MAX_RENDERER_PIXEL_RATIO,
  RENDERER_ANTIALIAS,
} from "../../domain/constants.js";

function effectivePixelRatio() {
  return Math.min(window.devicePixelRatio || 1, MAX_RENDERER_PIXEL_RATIO);
}

export function createScene() {
  const scene = new THREE.Scene();
  scene.background = new THREE.Color(0x0a0a12);

  const camera = new THREE.PerspectiveCamera(
    60,
    window.innerWidth / window.innerHeight,
    0.1,
    100,
  );
  camera.position.set(0, 20, 0);
  camera.lookAt(0, 0, 0);
  camera.up.set(0, 0, -1);

  const renderer = new THREE.WebGLRenderer({
    antialias: RENDERER_ANTIALIAS,
    powerPreference: "high-performance",
  });
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.setPixelRatio(effectivePixelRatio());
  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = THREE.PCFSoftShadowMap;
  document.body.style.margin = "0";
  document.body.style.overflow = "hidden";
  document.body.appendChild(renderer.domElement);

  scene.add(new THREE.AmbientLight(0xffffff, 0.35));

  // Spot principal facon eclairage de cabinet, projette des ombres
  const spot = new THREE.SpotLight(0xfff2d6, 1.2, 60, Math.PI / 3, 0.4, 1.2);
  spot.position.set(0, 25, 0);
  spot.target.position.set(0, 0, 0);
  spot.castShadow = true;
  spot.shadow.mapSize.set(1024, 1024);
  scene.add(spot);
  scene.add(spot.target);

  const dirLight = new THREE.DirectionalLight(0xffffff, 0.5);
  dirLight.position.set(5, 15, 5);
  scene.add(dirLight);

  const composer = new EffectComposer(renderer);
  composer.addPass(new RenderPass(scene, camera));
  const bloomPass = new UnrealBloomPass(
    new THREE.Vector2(window.innerWidth, window.innerHeight),
    0.85,
    0.4,
    0.82,
  );
  composer.addPass(bloomPass);
  composer.setSize(window.innerWidth, window.innerHeight);

  window.addEventListener("resize", () => {
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(window.innerWidth, window.innerHeight);
    renderer.setPixelRatio(effectivePixelRatio());
    composer.setSize(window.innerWidth, window.innerHeight);
  });

  return { scene, camera, renderer, composer, bloomPass };
}
EOF

# === ballMesh.js : la bille projette une ombre ===
cat > playfield/src/adapters/renderer/ballMesh.js << 'EOF'
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
EOF

git add -A
git commit -m "feat: rendu plateau type table d'arcade

Plateau feutre vert mat, murs bois vernis, liseres lumineux sur les
cotes. Ombres portees activees (spot principal facon cabinet) et la
bille projette son ombre sur le plateau."

git push origin feat/vfx-bonus --force-with-lease

echo ""
echo "Vague 1 OK. Recharge le playfield (Ctrl+Shift+R)."
echo "Verifie : le plateau a un rendu feutre, ombres visibles, liseres dores sur les bords."
echo "TEST CRITIQUE : la balle se lance toujours (D puis Espace) ?"