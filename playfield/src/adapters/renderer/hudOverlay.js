/**
 * Petit overlay HUD en bas de l'ecran : statut connexion + label projet.
 */
export function mountPlayfieldHud() {
  if (document.getElementById("playfield-hud")) return null;
  const el = document.createElement("div");
  el.id = "playfield-hud";
  el.className = "playfield-hud";
  el.innerHTML = `<span>FLIPPER HETIC W3</span>`;
  document.body.appendChild(el);
  return el;
}
