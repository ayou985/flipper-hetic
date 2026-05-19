#!/usr/bin/env bash
# ============================================================
# apply-vfx.sh — Patch VFX Breaking Bad pour Flipper HETIC
# Issue #79 — VFX bonus (playfield + backglass + DMD)
#
# Usage : depuis le dossier racine flipper-hetic, lancer :
#   bash apply-vfx.sh
# ============================================================
set -e

echo "🎬 Application du patch VFX..."

# Sanity check
if [ ! -d "playfield" ] || [ ! -d "backglass" ] || [ ! -d "dmd" ]; then
  echo "❌ Erreur : ce script doit être lancé depuis la racine du projet flipper-hetic."
  exit 1
fi

# ============================================================
# 1. NOUVEAU — playfield/src/domain/theme.js
# ============================================================
mkdir -p playfield/src/domain
cat > playfield/src/domain/theme.js << 'EOF'
/**
 * Palette VFX Breaking Bad — utilisée par playfield + backglass + DMD.
 */
export const THEME = {
  meth: 0xC7E73C,    // jaune méthamphétamine
  toxic: 0x39FF14,   // vert toxique
  amber: 0xFFB300,   // ambre
  alert: 0xFF2D2D,   // rouge alerte
  dark: 0x0A0A0A,
};

export const THEME_CSS = {
  meth: "#C7E73C",
  toxic: "#39FF14",
  amber: "#FFB300",
  alert: "#FF2D2D",
};
EOF

# ============================================================
# 2. NOUVEAU — playfield/src/adapters/renderer/vfx/bumperFlash.js
# ============================================================
mkdir -p playfield/src/adapters/renderer/vfx
cat > playfield/src/adapters/renderer/vfx/bumperFlash.js << 'EOF'
/**
 * VFX — Flash émissif + scale pulse sur un bumper lors d'un hit.
 */
import * as THREE from "three";
import { THEME } from "../../../domain/theme.js";

const FLASH_MS = 220;
const SCALE_PEAK = 1.18;
const PEAK_INTENSITY = 4.5;

export function flashBumper(bumperMesh, color = THEME.meth) {
  if (!bumperMesh?.material) return;
  const mat = bumperMesh.material;
  const origEmissive = mat.emissive ? mat.emissive.getHex() : 0x000000;
  const origIntensity = mat.emissiveIntensity ?? 1;
  const origScale = bumperMesh.scale.x;

  mat.emissive = new THREE.Color(color);
  mat.emissiveIntensity = PEAK_INTENSITY;

  const start = performance.now();
  function tick() {
    const t = (performance.now() - start) / FLASH_MS;
    if (t >= 1) {
      mat.emissive = new THREE.Color(origEmissive);
      mat.emissiveIntensity = origIntensity;
      bumperMesh.scale.setScalar(origScale);
      return;
    }
    const eased = 1 - Math.pow(1 - t, 3);
    bumperMesh.scale.setScalar(origScale + (SCALE_PEAK - origScale) * (1 - eased));
    mat.emissiveIntensity = origIntensity + (PEAK_INTENSITY - origIntensity) * (1 - eased);
    requestAnimationFrame(tick);
  }
  tick();
}
EOF

# ============================================================
# 3. NOUVEAU — playfield/src/adapters/renderer/vfx/stateOverlay.js
# ============================================================
cat > playfield/src/adapters/renderer/vfx/stateOverlay.js << 'EOF'
/**
 * VFX — Overlay plein écran pour les états de jeu (start, gameOver, milestone).
 */
import { THEME_CSS } from "../../../domain/theme.js";

let overlay;

function ensureOverlay() {
  if (overlay) return overlay;
  overlay = document.createElement("div");
  overlay.id = "vfx-state-overlay";
  overlay.style.cssText = [
    "position:fixed",
    "inset:0",
    "pointer-events:none",
    "z-index:9999",
    "opacity:0",
    "transition:opacity 320ms ease",
    "mix-blend-mode:screen",
  ].join(";");
  document.body.appendChild(overlay);
  return overlay;
}

const GRADIENTS = {
  start: "radial-gradient(circle, " + THEME_CSS.meth + "66, transparent 70%)",
  gameOver: "radial-gradient(circle, " + THEME_CSS.alert + "AA, transparent 65%)",
  milestone: "radial-gradient(circle, " + THEME_CSS.toxic + "88, transparent 70%)",
  bumper: "radial-gradient(circle, " + THEME_CSS.meth + "55, transparent 60%)",
};

export function flashState(type, duration = 500) {
  const el = ensureOverlay();
  el.style.background = GRADIENTS[type] || GRADIENTS.milestone;
  el.style.opacity = "1";
  setTimeout(() => { el.style.opacity = "0"; }, duration);
}
EOF

# ============================================================
# 4. REMPLACE — playfield/src/adapters/renderer/scene.js (Bloom)
# ============================================================
cat > playfield/src/adapters/renderer/scene.js << 'EOF'
/**
 * Playfield — Scene Three.js, camera, lumieres, renderer + Bloom postprocessing.
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
  document.body.style.margin = "0";
  document.body.style.overflow = "hidden";
  document.body.appendChild(renderer.domElement);

  scene.add(new THREE.AmbientLight(0xffffff, 0.45));
  const dirLight = new THREE.DirectionalLight(0xffffff, 0.85);
  dirLight.position.set(5, 15, 5);
  scene.add(dirLight);

  // Postprocessing : bloom pour le look arcade
  const composer = new EffectComposer(renderer);
  composer.addPass(new RenderPass(scene, camera));
  const bloomPass = new UnrealBloomPass(
    new THREE.Vector2(window.innerWidth, window.innerHeight),
    0.85, // strength
    0.4,  // radius
    0.82, // threshold
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

# ============================================================
# 5. REMPLACE — playfield/src/adapters/renderer/ballMesh.js (Glow ambre)
# ============================================================
cat > playfield/src/adapters/renderer/ballMesh.js << 'EOF'
/**
 * Playfield — Mesh Three.js de la bille avec glow ambre (Breaking Bad).
 */
import * as THREE from "three";
import { BALL_RADIUS } from "../../domain/constants.js";
import { THEME } from "../../domain/theme.js";

export function createBallMesh(scene) {
  const mesh = new THREE.Mesh(
    new THREE.SphereGeometry(BALL_RADIUS, 32, 32),
    new THREE.MeshStandardMaterial({
      color: 0xdddddd,
      metalness: 0.95,
      roughness: 0.15,
      emissive: new THREE.Color(THEME.amber),
      emissiveIntensity: 0.4,
    }),
  );
  const glowLight = new THREE.PointLight(THEME.amber, 1.8, 6, 2);
  mesh.add(glowLight);
  scene.add(mesh);
  return mesh;
}
EOF

# ============================================================
# 6. REMPLACE — playfield/src/adapters/renderer/bumperMesh.js (Couleur meth)
# ============================================================
cat > playfield/src/adapters/renderer/bumperMesh.js << 'EOF'
/**
 * Playfield — Meshes Three.js des bumpers (jaune méthamphétamine, émissifs).
 */
import * as THREE from "three";
import {
  BUMPER_RADIUS,
  BUMPER_HEIGHT,
  BUMPER_POSITIONS,
} from "../../domain/constants.js";
import { THEME } from "../../domain/theme.js";

export function createBumperMeshes(scene) {
  const meshes = [];
  for (const pos of BUMPER_POSITIONS) {
    const material = new THREE.MeshStandardMaterial({
      color: THEME.meth,
      metalness: 0.5,
      roughness: 0.3,
      emissive: new THREE.Color(THEME.meth),
      emissiveIntensity: 0.65,
    });
    const mesh = new THREE.Mesh(
      new THREE.CylinderGeometry(BUMPER_RADIUS, BUMPER_RADIUS, BUMPER_HEIGHT, 24),
      material,
    );
    mesh.position.set(pos.x, BUMPER_HEIGHT / 2, pos.z);
    scene.add(mesh);
    meshes.push(mesh);
  }
  return meshes;
}
EOF

# ============================================================
# 7. REMPLACE — playfield/src/composition/runGameLoop.js (composer.render)
# ============================================================
cat > playfield/src/composition/runGameLoop.js << 'EOF'
/**
 * Boucle de rendu + pas de simulation physique (séparée de la composition root).
 */
import {
  syncMeshesWithBodies,
  FIXED_TIME_STEP,
  MAX_SUB_STEPS,
  updateFlippers,
  postStepFlippers,
  clampBallBody,
  resetBallBody,
} from "../adapters/physics/index.js";

/**
 * Démarre la boucle requestAnimationFrame (physique + sync meshes + rendu).
 */
export function startPlayfieldLoop(deps) {
  const {
    world,
    syncPairs,
    collisionHandler,
    ballBody,
    flipperBodies,
    renderer,
    scene,
    camera,
    composer,
    gameState,
  } = deps;

  let lastTime = performance.now();

  function animate() {
    requestAnimationFrame(animate);

    const now = performance.now();
    const delta = Math.min((now - lastTime) / 1000, 0.1);
    lastTime = now;

    updateFlippers(flipperBodies);
    world.step(FIXED_TIME_STEP, delta, MAX_SUB_STEPS);
    postStepFlippers(flipperBodies);
    clampBallBody(ballBody);

    if (collisionHandler.checkDrain(ballBody.position.z, gameState.status)) {
      resetBallBody(ballBody);
      collisionHandler.resetDrainFlag();
    }

    syncMeshesWithBodies(syncPairs);

    if (composer) {
      composer.render();
    } else {
      renderer.render(scene, camera);
    }
  }

  animate();
}
EOF

# ============================================================
# 8. REMPLACE — playfield/src/usecases/collisionHandler.js (passe ctx au callback)
# ============================================================
cat > playfield/src/usecases/collisionHandler.js << 'EOF'
/**
 * Playfield — Use case : decisions collision + drain.
 */
import {
  DRAIN_Z_THRESHOLD,
  COLLISION_COOLDOWN_MS,
  BUMPER_REPULSE_FORCE,
} from "../domain/constants.js";

const IGNORED_TYPES = new Set(["ball", "table"]);

export function createCollisionHandler(callbacks) {
  const lastEmitByType = {};
  let ballLostEmitted = false;

  function canEmit(type, now) {
    if (lastEmitByType[type] && now - lastEmitByType[type] < COLLISION_COOLDOWN_MS) {
      return false;
    }
    lastEmitByType[type] = now;
    return true;
  }

  function emitBumperImpulse(ballPos, otherPos) {
    if (!callbacks.onBumperImpulse || !ballPos || !otherPos) return;
    const dx = ballPos.x - otherPos.x;
    const dz = ballPos.z - otherPos.z;
    const len = Math.hypot(dx, dz) || 1;
    callbacks.onBumperImpulse({
      x: (dx / len) * BUMPER_REPULSE_FORCE,
      y: 0,
      z: (dz / len) * BUMPER_REPULSE_FORCE,
    });
  }

  return {
    handleCollision(type, now, ctx = {}) {
      if (!type || IGNORED_TYPES.has(type)) return false;
      if (!canEmit(type, now)) return false;
      callbacks.onCollision(type, ctx);
      if (type === "bumper") emitBumperImpulse(ctx.ballPos, ctx.otherPos);
      return true;
    },

    checkDrain(ballZ, gameStatus) {
      if (gameStatus !== "playing") {
        ballLostEmitted = false;
        return false;
      }
      if (ballZ > DRAIN_Z_THRESHOLD) {
        if (!ballLostEmitted) {
          ballLostEmitted = true;
          callbacks.onBallLost();
          return true;
        }
      } else {
        ballLostEmitted = false;
      }
      return false;
    },

    resetDrainFlag() {
      ballLostEmitted = false;
    },

    resetCollisionCooldowns() {
      for (const key of Object.keys(lastEmitByType)) {
        delete lastEmitByType[key];
      }
    },
  };
}
EOF

# ============================================================
# 9. REMPLACE — playfield/src/main.js (hook VFX)
# ============================================================
cat > playfield/src/main.js << 'EOF'
/**
 * Playfield — Composition root.
 * Délègue la construction du niveau et la boucle de jeu à `composition/`.
 */
import { createScene } from "./adapters/renderer/scene.js";
import {
  initRapier,
  createPhysicsWorld,
  attachCollisionListener,
  launchBallBody,
  resetBallBody,
  setFlipperActive,
} from "./adapters/physics/index.js";

await initRapier();

import {
  initNetwork,
  emitStartGame,
  emitLaunchBall,
  emitFlipperLeftDown,
  emitFlipperLeftUp,
  emitFlipperRightDown,
  emitFlipperRightUp,
  emitCollision,
  emitBallLost,
  gameState,
} from "./adapters/network.js";
import { createCollisionHandler } from "./usecases/collisionHandler.js";
import { createActuators } from "./adapters/actuators.js";
import { createGameInputController, bindKeyboardInput } from "./adapters/input.js";
import { buildLevel } from "./composition/buildLevel.js";
import { startPlayfieldLoop } from "./composition/runGameLoop.js";
import { flashBumper } from "./adapters/renderer/vfx/bumperFlash.js";
import { flashState } from "./adapters/renderer/vfx/stateOverlay.js";

const actuators = createActuators();
window.actuators = actuators;

const { scene, camera, renderer, composer, bloomPass } = createScene();
const world = createPhysicsWorld();
const level = buildLevel({ scene, world });

// VFX helper : trouve le bumperMesh le plus proche de la position de collision
function findClosestBumperMesh(pos) {
  if (!pos || !level.bumperMeshes?.length) return null;
  let best = level.bumperMeshes[0];
  let bestDist = Infinity;
  for (const mesh of level.bumperMeshes) {
    const dx = mesh.position.x - pos.x;
    const dz = mesh.position.z - pos.z;
    const d = dx * dx + dz * dz;
    if (d < bestDist) { bestDist = d; best = mesh; }
  }
  return best;
}

const socket = initNetwork({
  onGameStarted() {
    resetBallBody(level.ballBody);
    collisionHandler.resetDrainFlag();
    collisionHandler.resetCollisionCooldowns();
    setFlipperActive(level.flipperBodies, "left", false);
    setFlipperActive(level.flipperBodies, "right", false);
    actuators.onGameStart();
    flashState("start", 1200);
    console.log("[main] game started — bille au spawn");
  },
  onGameOver(data) {
    flashState("gameOver", 1100);
    console.log("[main] game over — score final :", data.score);
  },
});

const collisionHandler = createCollisionHandler({
  onCollision: (type, ctx) => {
    emitCollision(socket, type);
    if (type === "bumper") {
      actuators.onBumperHit();
      const mesh = findClosestBumperMesh(ctx?.otherPos);
      if (mesh) flashBumper(mesh);
      flashState("bumper", 180);
    } else if (type === "slingshot") {
      actuators.onSlingshotHit();
    }
  },
  onBallLost: () => {
    emitBallLost(socket);
    actuators.onBallLost();
  },
  onBumperImpulse: (vec3) => {
    level.ballBody.applyImpulse(vec3);
  },
});
attachCollisionListener(level.ballBody, collisionHandler);

const inputController = createGameInputController({
  onStart() {
    emitStartGame(socket);
  },
  onLaunch() {
    if (gameState.status === "playing" && launchBallBody(level.ballBody)) {
      emitLaunchBall(socket);
    }
  },
  onLeftFlipperDown() {
    setFlipperActive(level.flipperBodies, "left", true);
    emitFlipperLeftDown(socket);
    actuators.onFlipperFire("left");
  },
  onLeftFlipperUp() {
    setFlipperActive(level.flipperBodies, "left", false);
    emitFlipperLeftUp(socket);
  },
  onRightFlipperDown() {
    setFlipperActive(level.flipperBodies, "right", true);
    emitFlipperRightDown(socket);
    actuators.onFlipperFire("right");
  },
  onRightFlipperUp() {
    setFlipperActive(level.flipperBodies, "right", false);
    emitFlipperRightUp(socket);
  },
  onDebugResetBall() {
    resetBallBody(level.ballBody);
  },
});

bindKeyboardInput(inputController);

startPlayfieldLoop({
  world,
  syncPairs: level.syncPairs,
  collisionHandler,
  ballBody: level.ballBody,
  flipperBodies: level.flipperBodies,
  renderer,
  scene,
  camera,
  composer,
  gameState,
});
EOF

# ============================================================
# 10. NOUVEAU — backglass/src/vfx.css
# ============================================================
cat > backglass/src/vfx.css << 'EOF'
:root {
  --vfx-meth: #C7E73C;
  --vfx-toxic: #39FF14;
  --vfx-amber: #FFB300;
  --vfx-alert: #FF2D2D;
}

body.backglass-vfx-root { position: relative; overflow: hidden; }

body.backglass-vfx-root::after {
  content: "";
  position: fixed;
  inset: 0;
  pointer-events: none;
  opacity: 0;
  z-index: 9999;
  background: radial-gradient(circle, var(--vfx-meth) 0%, transparent 60%);
  mix-blend-mode: screen;
  transition: opacity 220ms ease;
}

body.backglass-vfx-root.flash-bumper::after {
  animation: vfxBumperPulse 300ms ease-out;
}
body.backglass-vfx-root.flash-gameOver::after {
  animation: vfxGameOverFade 1100ms ease-out;
  background: radial-gradient(circle, var(--vfx-alert) 0%, transparent 65%);
}
body.backglass-vfx-root.flash-start::after {
  animation: vfxStartFade 1400ms ease-out;
  background: radial-gradient(circle, var(--vfx-meth) 0%, transparent 70%);
}
body.backglass-vfx-root.flash-milestone::after {
  animation: vfxMilestoneFade 700ms ease-out;
  background: radial-gradient(circle, var(--vfx-toxic) 0%, transparent 65%);
}

@keyframes vfxBumperPulse {
  0%   { opacity: 0; transform: scale(0.9); }
  40%  { opacity: 0.75; transform: scale(1); }
  100% { opacity: 0; transform: scale(1.08); }
}
@keyframes vfxGameOverFade {
  0%   { opacity: 0.9; }
  100% { opacity: 0; }
}
@keyframes vfxStartFade {
  0%   { opacity: 0.75; }
  100% { opacity: 0; }
}
@keyframes vfxMilestoneFade {
  0%   { opacity: 0.75; }
  100% { opacity: 0; }
}

/* Glow permanent sur le titre */
.backglass__title {
  color: var(--vfx-meth) !important;
  text-shadow:
    0 0 10px var(--vfx-meth),
    0 0 25px var(--vfx-meth),
    0 0 50px rgba(199, 231, 60, 0.45) !important;
  letter-spacing: 4px !important;
}

/* Score glow */
#scoreValue {
  color: var(--vfx-amber) !important;
  text-shadow:
    0 0 8px var(--vfx-amber),
    0 0 22px var(--vfx-amber);
}
EOF

# ============================================================
# 11. NOUVEAU — backglass/src/vfx.js
# ============================================================
cat > backglass/src/vfx.js << 'EOF'
/**
 * Backglass — Helpers VFX (initialisation + trigger).
 */
import "./vfx.css";

let rootEl;

export function initBackglassVfx() {
  rootEl = document.body;
  rootEl.classList.add("backglass-vfx-root");
}

const DURATIONS = { bumper: 320, milestone: 720, gameOver: 1150, start: 1500 };

export function triggerBackglassVfx(type) {
  if (!rootEl) return;
  const cls = `flash-${type}`;
  rootEl.classList.remove(cls);
  // force reflow pour pouvoir relancer l'animation
  // eslint-disable-next-line no-unused-expressions
  void rootEl.offsetWidth;
  rootEl.classList.add(cls);
  setTimeout(() => rootEl.classList.remove(cls), DURATIONS[type] || 500);
}
EOF

# ============================================================
# 12. REMPLACE — backglass/src/adapters/network.js (écoute game events)
# ============================================================
cat > backglass/src/adapters/network.js << 'EOF'
/**
 * Backglass — Couche reseau Socket.IO.
 */
import { io } from "socket.io-client";
import { SERVER_EVENTS } from "shared";

const SERVER_URL = "http://localhost:3000";

export function initNetwork(callbacks = {}) {
  const socket = io(SERVER_URL);

  socket.on(SERVER_EVENTS.STATE_UPDATED, (data) => {
    callbacks.onStateUpdated?.(data);
  });
  socket.on(SERVER_EVENTS.GAME_STARTED, () => {
    callbacks.onGameStarted?.();
  });
  socket.on(SERVER_EVENTS.GAME_OVER, () => {
    callbacks.onGameOver?.();
  });

  return socket;
}
EOF

# ============================================================
# 13. REMPLACE — backglass/src/main.js (hook VFX)
# ============================================================
cat > backglass/src/main.js << 'EOF'
/**
 * Backglass — Composition root.
 */
import "./styles.css";
import { mountBackglassRoot } from "./renderer/mount.js";
import { createBackglassView } from "./renderer/view.js";
import { initNetwork } from "./adapters/network.js";
import { initBackglassVfx, triggerBackglassVfx } from "./vfx.js";

const refs = mountBackglassRoot();
const { renderState } = createBackglassView(refs);
initBackglassVfx();

let lastScore = 0;

initNetwork({
  onStateUpdated(data) {
    renderState(data);
    const score = data?.score ?? 0;
    if (Math.floor(score / 1000) > Math.floor(lastScore / 1000)) {
      triggerBackglassVfx("milestone");
    } else if (score > lastScore) {
      triggerBackglassVfx("bumper");
    }
    lastScore = score;
  },
  onGameStarted() {
    lastScore = 0;
    triggerBackglassVfx("start");
  },
  onGameOver() {
    triggerBackglassVfx("gameOver");
  },
});
EOF

# ============================================================
# 14. NOUVEAU — dmd/src/vfx.css
# ============================================================
cat > dmd/src/vfx.css << 'EOF'
:root {
  --vfx-meth: #C7E73C;
  --vfx-toxic: #39FF14;
  --vfx-amber: #FFB300;
  --vfx-alert: #FF2D2D;
}

body.dmd-vfx-root { position: relative; overflow: hidden; }

body.dmd-vfx-root::after {
  content: "";
  position: fixed;
  inset: 0;
  pointer-events: none;
  opacity: 0;
  z-index: 9999;
  background: radial-gradient(circle, var(--vfx-amber) 0%, transparent 65%);
  mix-blend-mode: screen;
  transition: opacity 220ms ease;
}

body.dmd-vfx-root.flash-start::after {
  animation: dmdStartFade 1300ms ease-out;
  background: radial-gradient(circle, var(--vfx-meth) 0%, transparent 70%);
}
body.dmd-vfx-root.flash-gameOver::after {
  animation: dmdGameOverFade 1300ms ease-out;
  background: radial-gradient(circle, var(--vfx-alert) 0%, transparent 65%);
}
body.dmd-vfx-root.flash-milestone::after {
  animation: dmdMilestoneFade 700ms ease-out;
  background: radial-gradient(circle, var(--vfx-toxic) 0%, transparent 65%);
}

@keyframes dmdStartFade {
  0%   { opacity: 0.7; }
  100% { opacity: 0; }
}
@keyframes dmdGameOverFade {
  0%   { opacity: 0.9; }
  100% { opacity: 0; }
}
@keyframes dmdMilestoneFade {
  0%   { opacity: 0.75; }
  100% { opacity: 0; }
}

/* Canvas DMD : effet CRT subtil + pulse sur milestone */
body.dmd-vfx-root .dmd__canvas {
  filter: drop-shadow(0 0 12px rgba(255, 179, 0, 0.45));
  transition: filter 200ms ease;
}
body.dmd-vfx-root.flash-milestone .dmd__canvas {
  animation: dmdCanvasPulse 700ms ease-out;
}
@keyframes dmdCanvasPulse {
  0%, 100% { filter: drop-shadow(0 0 12px rgba(255, 179, 0, 0.45)); }
  50% {
    filter:
      drop-shadow(0 0 25px var(--vfx-toxic))
      drop-shadow(0 0 45px var(--vfx-toxic))
      brightness(1.3);
  }
}
EOF

# ============================================================
# 15. NOUVEAU — dmd/src/vfx.js
# ============================================================
cat > dmd/src/vfx.js << 'EOF'
/**
 * DMD — Helpers VFX (overlay plein écran + pulse canvas).
 */
import "./vfx.css";

let rootEl;

export function initDmdVfx() {
  rootEl = document.body;
  rootEl.classList.add("dmd-vfx-root");
}

const DURATIONS = { start: 1350, gameOver: 1350, milestone: 750 };

export function triggerDmdVfx(type) {
  if (!rootEl) return;
  const cls = `flash-${type}`;
  rootEl.classList.remove(cls);
  void rootEl.offsetWidth;
  rootEl.classList.add(cls);
  setTimeout(() => rootEl.classList.remove(cls), DURATIONS[type] || 800);
}
EOF

# ============================================================
# 16. REMPLACE — dmd/src/main.js
# ============================================================
cat > dmd/src/main.js << 'EOF'
/**
 * DMD — Composition root.
 */
import "./styles.css";
import { mountDmdShell } from "./renderer/mount.js";
import { createDotMatrixRenderer } from "./renderer/dotMatrix.js";
import { wireDmdNetwork } from "./composition/wireDmdNetwork.js";
import { initDmdVfx } from "./vfx.js";

const refs = mountDmdShell();
const renderer = createDotMatrixRenderer(refs.canvas);

initDmdVfx();
wireDmdNetwork({ refs, renderer });
renderer.init();
EOF

# ============================================================
# 17. REMPLACE — dmd/src/composition/wireDmdNetwork.js (hook VFX)
# ============================================================
cat > dmd/src/composition/wireDmdNetwork.js << 'EOF'
/**
 * DMD — Branchement Socket.IO sur le renderer et les indicateurs DOM.
 */
import { initNetwork } from "../adapters/network.js";
import { triggerDmdVfx } from "../vfx.js";

export function wireDmdNetwork({ refs, renderer }) {
  const { socketStatus, stateStatus } = refs;
  let lastScore = 0;

  initNetwork({
    onConnect() {
      socketStatus.textContent = "socket: connected";
    },
    onDisconnect() {
      socketStatus.textContent = "socket: disconnected";
    },
    onDmdMessage(text) {
      renderer.renderMessage(text);
    },
    onStateUpdated(data) {
      renderer.renderScore(data?.score);
      renderer.updateStatus(data?.status);
      stateStatus.textContent = `state: ${data?.status ?? "idle"}`;
      const score = data?.score ?? 0;
      if (Math.floor(score / 1000) > Math.floor(lastScore / 1000)) {
        triggerDmdVfx("milestone");
      }
      lastScore = score;
    },
    onGameStarted() {
      lastScore = 0;
      renderer.updateStatus("playing");
      stateStatus.textContent = "state: playing";
      triggerDmdVfx("start");
    },
    onGameOver() {
      renderer.updateStatus("game_over");
      stateStatus.textContent = "state: game_over";
      triggerDmdVfx("gameOver");
    },
  });
}
EOF

echo ""
echo "✅ Tous les fichiers VFX sont créés/mis à jour."
echo ""
echo "📦 Création de la branche, commit et push..."

git checkout -b feat/vfx-bonus 2>/dev/null || git checkout feat/vfx-bonus
git add .
git commit -m "feat(vfx): add Breaking Bad themed VFX system

- Playfield: bloom postprocessing, ball glow, bumper flash on hit, state overlays
- Backglass: pulse on score/milestone/start/gameOver, glow on title and score
- DMD: full-screen flashes on game events, canvas glow + milestone pulse
- Closes #79"
git push origin feat/vfx-bonus

echo ""
echo "🎉 Patch VFX appliqué et poussé sur la branche feat/vfx-bonus !"
echo ""
echo "👉 Étapes suivantes :"
echo "   1. cd playfield && npm install (au cas où three/examples manque)"
echo "   2. npm run dev (depuis la racine) pour tester"
echo "   3. Ouvrir une PR depuis feat/vfx-bonus vers main sur GitHub"
echo ""
