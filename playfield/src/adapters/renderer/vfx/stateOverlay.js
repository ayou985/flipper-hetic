/**
 * Overlay plein ecran pour signaler les transitions d'etat de jeu.
 */
import { CSS_COLORS } from "../../../domain/theme.js";

let overlay = null;

function ensureOverlay() {
  if (overlay) return overlay;
  overlay = document.createElement("div");
  overlay.id = "playfield-state-overlay";
  Object.assign(overlay.style, {
    position: "fixed",
    inset: "0",
    pointerEvents: "none",
    zIndex: "9999",
    opacity: "0",
    transition: "opacity 320ms ease",
    mixBlendMode: "screen",
  });
  document.body.appendChild(overlay);
  return overlay;
}

const GRADIENTS = {
  start: `radial-gradient(circle, ${CSS_COLORS.primary}66, transparent 70%)`,
  gameOver: `radial-gradient(circle, ${CSS_COLORS.warning}AA, transparent 65%)`,
  milestone: `radial-gradient(circle, ${CSS_COLORS.accent}88, transparent 70%)`,
  bumper: `radial-gradient(circle, ${CSS_COLORS.primary}55, transparent 60%)`,
};

export function flashState(type, duration = 500) {
  const el = ensureOverlay();
  el.style.background = GRADIENTS[type] || GRADIENTS.milestone;
  el.style.opacity = "1";
  setTimeout(() => { el.style.opacity = "0"; }, duration);
}
