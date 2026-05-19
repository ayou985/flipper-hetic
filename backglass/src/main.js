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

// On detecte les paliers de score cote client pour synchroniser le VFX
let previousScore = 0;

initNetwork({
  onStateUpdated(data) {
    renderState(data);
    const score = data?.score ?? 0;
    if (Math.floor(score / 1000) > Math.floor(previousScore / 1000)) {
      triggerBackglassVfx("milestone");
    } else if (score > previousScore) {
      triggerBackglassVfx("bumper");
    }
    previousScore = score;
  },
  onGameStarted() {
    previousScore = 0;
    triggerBackglassVfx("start");
  },
  onGameOver() {
    triggerBackglassVfx("gameOver");
  },
});
