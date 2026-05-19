/**
 * Audio Controls — UI overlay discret + bindings clavier.
 *
 * Touches :
 *   M       : toggle mute
 *   + / =   : volume +5%
 *   - / _   : volume -5%
 *
 * Visuel : pill en haut-droite (icône + barre), apparaît brièvement
 * lors d'un changement puis fade out.
 */

const STYLE = `
#audio-hud {
  position: fixed; top: 16px; right: 16px; z-index: 10000;
  display: flex; align-items: center; gap: 10px;
  padding: 8px 14px; border-radius: 999px;
  background: rgba(0, 0, 0, 0.55);
  border: 1px solid rgba(199, 231, 60, 0.3);
  color: #C7E73C;
  font-family: 'Courier New', monospace;
  font-size: 14px; letter-spacing: 1px;
  opacity: 0.25; transition: opacity 250ms ease;
  pointer-events: auto; user-select: none;
  backdrop-filter: blur(6px);
}
#audio-hud:hover { opacity: 1; }
#audio-hud.active { opacity: 1; }
#audio-hud .audio-icon {
  cursor: pointer; font-size: 18px;
  text-shadow: 0 0 8px rgba(199, 231, 60, 0.7);
}
#audio-hud .audio-bar {
  width: 80px; height: 6px; border-radius: 3px;
  background: rgba(255, 255, 255, 0.12);
  overflow: hidden; position: relative;
}
#audio-hud .audio-bar-fill {
  height: 100%; background: linear-gradient(90deg, #FFB300, #C7E73C);
  box-shadow: 0 0 8px rgba(199, 231, 60, 0.6);
  transition: width 120ms ease;
}
#audio-hud .audio-val { min-width: 32px; text-align: right; font-size: 12px; }
#audio-hud.muted { border-color: rgba(255, 45, 45, 0.4); color: #FF6B6B; }
#audio-hud.muted .audio-icon { text-shadow: 0 0 8px rgba(255, 45, 45, 0.7); }
#audio-hud.muted .audio-bar-fill { background: #555; box-shadow: none; }
#audio-hud .audio-hint {
  font-size: 10px; opacity: 0.55; letter-spacing: 0.5px;
}
`;

export function mountAudioControls(audio) {
  if (document.getElementById("audio-hud-style")) {
    // déjà monté
    return;
  }
  const style = document.createElement("style");
  style.id = "audio-hud-style";
  style.textContent = STYLE;
  document.head.appendChild(style);

  const hud = document.createElement("div");
  hud.id = "audio-hud";
  hud.innerHTML = `
    <span class="audio-icon" title="Mute / Unmute (M)">🔊</span>
    <div class="audio-bar"><div class="audio-bar-fill"></div></div>
    <span class="audio-val">60%</span>
    <span class="audio-hint">M · +/-</span>
  `;
  document.body.appendChild(hud);

  const iconEl = hud.querySelector(".audio-icon");
  const fillEl = hud.querySelector(".audio-bar-fill");
  const valEl = hud.querySelector(".audio-val");

  let activeTimer = null;
  function pulseActive() {
    hud.classList.add("active");
    if (activeTimer) clearTimeout(activeTimer);
    activeTimer = setTimeout(() => hud.classList.remove("active"), 1400);
  }

  function render({ volume, muted }) {
    const pct = Math.round(volume * 100);
    fillEl.style.width = (muted ? 0 : pct) + "%";
    valEl.textContent = muted ? "MUTE" : `${pct}%`;
    iconEl.textContent = muted ? "🔇" : (pct === 0 ? "🔈" : pct < 50 ? "🔉" : "🔊");
    hud.classList.toggle("muted", muted);
  }

  audio.subscribe(render);

  iconEl.addEventListener("click", () => {
    audio.toggleMute();
    pulseActive();
  });

  function onKey(event) {
    if (event.repeat) return;
    // M : toggle mute
    if (event.code === "KeyM") {
      event.preventDefault();
      audio.toggleMute();
      pulseActive();
      return;
    }
    // + / = (mêmes touches sur AZERTY/QWERTY) : volume up
    if (event.key === "+" || event.key === "=" || event.code === "NumpadAdd") {
      event.preventDefault();
      audio.adjustVolume(0.05);
      pulseActive();
      return;
    }
    // - / _ : volume down
    if (event.key === "-" || event.key === "_" || event.code === "NumpadSubtract") {
      event.preventDefault();
      audio.adjustVolume(-0.05);
      pulseActive();
      return;
    }
  }
  window.addEventListener("keydown", onKey);

  return function unmount() {
    window.removeEventListener("keydown", onKey);
    hud.remove();
    style.remove();
  };
}
