/**
 * DMD — Branchement Socket.IO sur le renderer et les indicateurs DOM.
 */
import { initNetwork } from "../adapters/network.js";
import { triggerDmdVfx } from "../vfx.js";

export function wireDmdNetwork({ refs, renderer }) {
  const { socketStatus, stateStatus } = refs;
  let previousScore = 0;

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
      if (Math.floor(score / 1000) > Math.floor(previousScore / 1000)) {
        triggerDmdVfx("milestone");
      }
      previousScore = score;
    },
    onGameStarted() {
      previousScore = 0;
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
