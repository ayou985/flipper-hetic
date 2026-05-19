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
