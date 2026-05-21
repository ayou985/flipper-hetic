/**
 * Petit rappel des touches en bas a gauche.
 */
export function mountPlayfieldHud() {
  if (document.getElementById("playfield-hud")) return null;
  const el = document.createElement("div");
  el.id = "playfield-hud";
  el.className = "playfield-hud";
  el.innerHTML = `<span>D: start · espace: lancer · X/C: flippers</span>`;
  document.body.appendChild(el);
  return el;
}
