import "./vfx.css";

const DURATIONS = { bumper: 320, milestone: 720, gameOver: 1150, start: 1500 };
let root = null;

export function initBackglassVfx() {
  root = document.body;
  root.classList.add("has-vfx");
}

export function triggerBackglassVfx(type) {
  if (!root) return;
  const cls = `flash-${type}`;
  root.classList.remove(cls);
  // force reflow pour pouvoir relancer l'animation
  void root.offsetWidth;
  root.classList.add(cls);
  setTimeout(() => root.classList.remove(cls), DURATIONS[type] || 500);
}
