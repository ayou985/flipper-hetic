/**
 * Backglass — Mise a jour de la vue a partir de l'etat serveur.
 */
const STATUS_CLASSES = ["status-idle", "status-playing", "status-game_over"];

export function createBackglassView(refs) {
  const { scoreValue, ballsLeftValue, statusValue } = refs;

  return {
    renderState(nextState) {
      scoreValue.textContent = String(nextState.score ?? 0);
      ballsLeftValue.textContent = String(nextState.ballsLeft ?? 0);

      const status = String(nextState.status ?? "idle");
      statusValue.textContent = status;
      statusValue.classList.remove(...STATUS_CLASSES);
      statusValue.classList.add(`status-${status}`);
    },
  };
}
