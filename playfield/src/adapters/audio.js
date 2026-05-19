/**
 * Moteur audio base sur la Web Audio API.
 * Precharge les samples, gere le volume / mute global et persiste les prefs.
 */

const STORAGE_KEY = "flipper.audio";
const DEFAULT_VOLUME = 0.6;
const SAMPLE_COOLDOWN_MS = 60;

const SAMPLES = {
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
    if (!raw) return { volume: DEFAULT_VOLUME, muted: false };
    const parsed = JSON.parse(raw);
    return {
      volume: typeof parsed.volume === "number"
        ? Math.max(0, Math.min(1, parsed.volume))
        : DEFAULT_VOLUME,
      muted: !!parsed.muted,
    };
  } catch {
    return { volume: DEFAULT_VOLUME, muted: false };
  }
}

function savePrefs(prefs) {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(prefs));
  } catch {
    // localStorage indisponible : on continue sans persistance
  }
}

export function createAudioEngine() {
  const prefs = loadPrefs();
  let volume = prefs.volume;
  let muted = prefs.muted;

  const ctx = new (window.AudioContext || window.webkitAudioContext)();
  const master = ctx.createGain();
  master.gain.value = muted ? 0 : volume;
  master.connect(ctx.destination);

  const buffers = new Map();
  const lastPlayed = new Map();
  let themeSource = null;
  let ready = false;
  const listeners = new Set();

  function notify() {
    for (const fn of listeners) fn({ volume, muted });
  }

  async function load(name, url) {
    try {
      const res = await fetch(url);
      const arr = await res.arrayBuffer();
      buffers.set(name, await ctx.decodeAudioData(arr));
    } catch (err) {
      console.warn(`audio: failed to load ${name}`, err);
    }
  }

  // L'AudioContext demarre suspendu (autoplay policy), on le reprend au 1er input
  function bindUserGesture() {
    const resume = () => {
      if (ctx.state === "suspended") ctx.resume().catch(() => {});
    };
    ["click", "keydown", "touchstart"].forEach((evt) =>
      window.addEventListener(evt, resume, { passive: true }),
    );
  }

  function play(name) {
    if (!ready) return;
    const buf = buffers.get(name);
    if (!buf) return;
    const now = performance.now();
    if (now - (lastPlayed.get(name) || 0) < SAMPLE_COOLDOWN_MS) return;
    lastPlayed.set(name, now);

    const src = ctx.createBufferSource();
    src.buffer = buf;
    src.connect(master);
    try { src.start(0); } catch { /* deja demarre */ }
  }

  function playRandom(names) {
    if (!names?.length) return;
    play(names[Math.floor(Math.random() * names.length)]);
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
    themeGain.connect(master);
    try { src.start(0); } catch { /* deja demarre */ }
    themeSource = src;
  }

  function stopTheme() {
    if (!themeSource) return;
    try { themeSource.stop(); } catch { /* deja arrete */ }
    themeSource = null;
  }

  function applyGain() {
    master.gain.cancelScheduledValues(ctx.currentTime);
    master.gain.setTargetAtTime(muted ? 0 : volume, ctx.currentTime, 0.02);
  }

  function setVolume(v) {
    volume = Math.max(0, Math.min(1, v));
    if (volume > 0 && muted) muted = false;
    applyGain();
    savePrefs({ volume, muted });
    notify();
  }

  function setMuted(m) {
    muted = !!m;
    applyGain();
    savePrefs({ volume, muted });
    notify();
  }

  function subscribe(fn) {
    listeners.add(fn);
    fn({ volume, muted });
    return () => listeners.delete(fn);
  }

  bindUserGesture();
  Promise.all(Object.entries(SAMPLES).map(([k, v]) => load(k, v)))
    .then(() => { ready = true; });

  return {
    play,
    playRandom,
    startTheme,
    stopTheme,
    setVolume,
    adjustVolume: (delta) => setVolume(volume + delta),
    setMuted,
    toggleMute: () => setMuted(!muted),
    getState: () => ({ volume, muted, ready }),
    subscribe,
  };
}
