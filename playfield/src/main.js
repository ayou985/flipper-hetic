/**
 * Playfield — Composition root.
 */
import "./styles.css";
import { createScene } from "./adapters/renderer/scene.js";
import {
  initRapier,
  createPhysicsWorld,
  attachCollisionListener,
  launchBallBody,
  resetBallBody,
  setFlipperActive,
  openLaunchGate,
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
import { addThemeDecor } from "./adapters/renderer/themeDecor.js";
import { addAmbiance } from "./adapters/renderer/ambiance.js";
import { addRails } from "./adapters/renderer/rails.js";
import { startPlayfieldLoop } from "./composition/runGameLoop.js";
import { flashBumper } from "./adapters/renderer/vfx/bumperFlash.js";
import { flashState } from "./adapters/renderer/vfx/stateOverlay.js";
import { createAudioEngine } from "./adapters/audio.js";
import { mountAudioControls, updateAudioHud } from "./adapters/audio-controls.js";
import { mountPlayfieldHud } from "./adapters/renderer/hudOverlay.js";

const audio = createAudioEngine(updateAudioHud);
mountAudioControls(audio);
mountPlayfieldHud();

const actuators = createActuators(audio);
window.actuators = actuators;

const { scene, camera, renderer, composer } = createScene();
addAmbiance(scene);
const world = createPhysicsWorld();
const level = buildLevel({ scene, world });
addThemeDecor(scene, [level.syncPairs[0].mesh]);
addRails(scene);

// Le moteur physique nous donne juste une position de collision : on retrouve
// le mesh bumper le plus proche pour declencher l'animation au bon endroit.
function closestBumper(pos) {
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

let milestoneTier = 0;
function checkMilestone(score) {
  if (typeof score !== "number") return;
  const tier = Math.floor(score / 1000);
  if (tier > milestoneTier) {
    milestoneTier = tier;
    actuators.onMilestone();
    flashState("milestone", 600);
  }
}

const socket = initNetwork({
  onGameStarted() {
    resetBallBody(level.ballBody);
    openLaunchGate(level.launchGateBody);
    collisionHandler.resetDrainFlag();
    collisionHandler.resetCollisionCooldowns();
    setFlipperActive(level.flipperBodies, "left", false);
    setFlipperActive(level.flipperBodies, "right", false);
    milestoneTier = 0;
    actuators.onGameStart();
    flashState("start", 1200);
  },
  onGameOver(data) {
    flashState("gameOver", 1100);
    console.log("[main] game over, score:", data?.score);
  },
  onStateUpdated(data) {
    checkMilestone(data?.score);
  },
});

const collisionHandler = createCollisionHandler({
  onCollision: (type, ctx) => {
    emitCollision(socket, type);
    if (type === "bumper") {
      actuators.onBumperHit();
      const mesh = closestBumper(ctx?.otherPos);
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
  onStart() { emitStartGame(socket); },
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
    openLaunchGate(level.launchGateBody);
  },
});

bindKeyboardInput(inputController);

startPlayfieldLoop({
  world,
  syncPairs: level.syncPairs,
  collisionHandler,
  ballBody: level.ballBody,
  flipperBodies: level.flipperBodies,
  launchGateBody: level.launchGateBody,
  renderer,
  scene,
  camera,
  composer,
  gameState,
});
