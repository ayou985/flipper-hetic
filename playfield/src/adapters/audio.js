/**
 * Audio engine — Web Audio API natif.
 * - Préchargement des samples (decodeAudioData)
 * - GainNode master pour volume + mute global
 * - Persistance localStorage (clé : "flipper.audio")
 * - Anti-spam : cooldown par sample
 */

const STORAGE_KEY = "flipper.audio";
const DEFAULT_VOLUME = 0.6;
const DEFAULT_MUTED = false;
const SAMPLE_COOLDOWN_MS = 60;

const SAMPLE_PATHS = {
  "bumper-1": "/sounds/bumper-1.mp3",
  "bumper-2": "/sounds/bumper-2.mp3",
  "bumper-3": "/sounds/bumper-3.mp3",
  "flipper-1": "/sounds/flipper-1.mp3",
  "flipper-2": "/sounds/flipper-2.mp3",
  "flipper-3": "/sounds/flipper-3.mp3",
  "start": "/sounds/start.mp3",
  "game-over": "/sounds/game-over.mp3",
  "milestone": "/sounds/milestone.mp3",
  "theme": "/sounds/theme.mp3",
};

function loadPrefs() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return { volume: DEFAULT_VOLUME, muted: DEFAULT_MUTED };
    const parsed = JSON.parse(raw);
    return {
      volume: typeof parsed.volume === "number" ? Math.max(0, Math.min(1, parsed.volume)) : DEFAULT_VOLUME,
      muted: !!parsed.muted,
    };
  } catch {
    return { volume: DEFAULT_VOLUME, muted: DEFAULT_MUTED };
  }
}

function savePrefs(prefs) {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(prefs));
  } catch {
    // localStorage indisponible (mode privé, etc.) — ignore silencieusement
  }
}

export function createAudioEngine() {
  const prefs = loadPrefs();
  let volume = prefs.volume;
  let muted = prefs.muted;

  const ctx = new (window.AudioContext || window.webkitAudioContext)();
  const masterGain = ctx.createGain();
  masterGain.gain.value = muted ? 0 : volume;
  masterGain.connect(ctx.destination);

  const buffers = new Map();
  const lastPlayedAt = new Map();
  let themeSource = null;
  let ready = false;

  const listeners = new Set();
  function emit() {
    for (const fn of listeners) fn({ volume, muted });
  }

  async function loadSample(name, url) {
    try {
      const res = await fetch(url);
      const arr = await res.arrayBuffer();
      const buf = await ctx.decodeAudioData(arr);
      buffers.set(name, buf);
    } catch (err) {
      console.warn(`[audio] échec chargement ${name}:`, err);
    }
  }

  async function preload() {
    await Promise.all(
      Object.entries(SAMPLE_PATHS).map(([name, url]) => loadSample(name, url)),
    );
    ready = true;
    console.log("[audio] samples préchargés:", buffers.size);
  }

  // L'AudioContext démarre suspendu sur la plupart des navigateurs (autoplay policy).
  // On le reprend dès la première interaction utilisateur.
  function resumeOnInteraction() {
    const resume = () => {
      if (ctx.state === "suspended") ctx.resume().catch(() => {});
    };
    ["click", "keydown", "touchstart"].forEach((evt) =>
      window.addEventListener(evt, resume, { once: false, passive: true }),
    );
  }

  function play(name) {
    if (!ready) return;
    const buf = buffers.get(name);
    if (!buf) return;
    const now = performance.now();
    const last = lastPlayedAt.get(name) || 0;
    if (now - last < SAMPLE_COOLDOWN_MS) return;
    lastPlayedAt.set(name, now);

    const src = ctx.createBufferSource();
    src.buffer = buf;
    src.connect(masterGain);
    try { src.start(0); } catch { /* déjà démarré */ }
  }

  /** Joue un sample choisi aléatoirement parmi plusieurs (ex: bumper-1/2/3) */
  function playRandom(names) {
    if (!names || !names.length) return;
    const pick = names[Math.floor(Math.random() * names.length)];
    play(pick);
  }

  function startTheme(loopVolume = 0.35) {
    if (!ready) return;
    const buf = buffers.get("theme");
    if (!buf) return;
    stopTheme();
    const src = ctx.createBufferSource();
    src.buffer = buf;
    src.loop = true;
    const themeGain = ctx.createGain();
    themeGain.gain.value = loopVolume;
    src.connect(themeGain);
    themeGain.connect(masterGain);
    try { src.start(0); } catch { /* déjà démarré */ }
    themeSource = src;
  }

  function stopTheme() {
    if (themeSource) {
      try { themeSource.stop(); } catch { /* déjà arrêté */ }
      themeSource = null;
    }
  }

  function applyGain() {
    masterGain.gain.cancelScheduledValues(ctx.currentTime);
    masterGain.gain.setTargetAtTime(muted ? 0 : volume, ctx.currentTime, 0.02);
  }

  function setVolume(v) {
    volume = Math.max(0, Math.min(1, v));
    if (volume > 0 && muted) muted = false; // unmute auto si on bouge le slider
    applyGain();
    savePrefs({ volume, muted });
    emit();
  }

  function adjustVolume(delta) {
    setVolume(volume + delta);
  }

  function setMuted(m) {
    muted = !!m;
    applyGain();
    savePrefs({ volume, muted });
    emit();
  }

  function toggleMute() {
    setMuted(!muted);
  }

  function getState() {
    return { volume, muted, ready };
  }

  function subscribe(fn) {
    listeners.add(fn);
    fn({ volume, muted });
    return () => listeners.delete(fn);
  }

  resumeOnInteraction();
  preload();

  return {
    play,
    playRandom,
    startTheme,
    stopTheme,
    setVolume,
    adjustVolume,
    setMuted,
    toggleMute,
    getState,
    subscribe,
  };
}
