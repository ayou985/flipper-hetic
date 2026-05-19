import "./vfx.css";

const DURATIONS = { start: 1350, gameOver: 1350, milestone: 750 };
let root = null;

export function initDmdVfx() {
  root = document.body;
  root.classList.add("has-vfx");
}

export function triggerDmdVfx(type) {
  if (!root) return;
  const cls = `flash-${type}`;
  root.classList.remove(cls);
  void root.offsetWidth;
  root.classList.add(cls);
  setTimeout(() => root.classList.remove(cls), DURATIONS[type] || 800);
}
