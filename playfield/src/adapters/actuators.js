/**
 * Actuators — branche logs + audio (et plus tard les solénoïdes IoT).
 * L'audio est optionnel : si `audio` est null, on garde le comportement console.log d'origine.
 */
export function createActuators(audio = null) {
  const counts = {
    bumperHit: 0,
    slingshotHit: 0,
    flipperFire: { left: 0, right: 0 },
    ballLost: 0,
    gameStart: 0,
  };

  return {
    onBumperHit() {
      counts.bumperHit++;
      console.log(`[actuator] bumper_hit #${counts.bumperHit}`);
      audio?.playRandom(["bumper-1", "bumper-2", "bumper-3"]);
    },

    onSlingshotHit() {
      counts.slingshotHit++;
      console.log(`[actuator] slingshot_hit #${counts.slingshotHit}`);
      audio?.playRandom(["flipper-1", "flipper-2", "flipper-3"]);
    },

    /** @param {"left"|"right"} side */
    onFlipperFire(side) {
      counts.flipperFire[side] = (counts.flipperFire[side] ?? 0) + 1;
      console.log(`[actuator] flipper_fire side=${side} #${counts.flipperFire[side]}`);
      audio?.playRandom(["flipper-1", "flipper-2", "flipper-3"]);
    },

    onBallLost() {
      counts.ballLost++;
      console.log(`[actuator] ball_lost #${counts.ballLost}`);
      audio?.stopTheme();
      audio?.play("game-over");
    },

    onGameStart() {
      counts.gameStart++;
      console.log(`[actuator] game_start #${counts.gameStart}`);
      audio?.play("start");
      audio?.startTheme(0.18);
    },

    onMilestone() {
      audio?.play("milestone");
    },

    getCounts() {
      return structuredClone(counts);
    },
  };
}
