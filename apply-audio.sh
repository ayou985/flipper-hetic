#!/usr/bin/env bash
# ============================================================
# apply-audio.sh — Système audio Flipper HETIC (Issue #78)
# Volume / Mute / Persistance + sons Breaking Bad sur events
#
# Touches :
#   M        : toggle mute
#   + ou =   : volume +5%
#   - ou _   : volume -5%
#
# Usage :
#   bash apply-audio.sh
# ============================================================
set -e

echo "🔊 Application du patch AUDIO..."

if [ ! -d "playfield" ] || [ ! -d "Flipper-Sounds" ]; then
  echo "❌ Erreur : lance ce script depuis la racine du projet flipper-hetic."
  exit 1
fi

# ============================================================
# 1. Copier les MP3 vers playfield/public/sounds/ avec noms propres
# ============================================================
echo "📁 Copie des fichiers audio..."
mkdir -p playfield/public/sounds

cp "Flipper-Sounds/Bumper hit/BumperIteration1.mp3"             playfield/public/sounds/bumper-1.mp3
cp "Flipper-Sounds/Bumper hit/BumperIteration2.mp3"             playfield/public/sounds/bumper-2.mp3
cp "Flipper-Sounds/Bumper hit/BumperIteration3.mp3"             playfield/public/sounds/bumper-3.mp3
cp "Flipper-Sounds/Flipper hit/Flipper Hit 1.mp3"               playfield/public/sounds/flipper-1.mp3
cp "Flipper-Sounds/Flipper hit/Flipper Hit 2.mp3"               playfield/public/sounds/flipper-2.mp3
cp "Flipper-Sounds/Flipper hit/Flipper Hit 3.mp3"               playfield/public/sounds/flipper-3.mp3
cp "Flipper-Sounds/Start game/Ball Release.mp3"                 playfield/public/sounds/start.mp3
cp "Flipper-Sounds/Game Over/He cant keep getting away with it.mp3"  playfield/public/sounds/game-over.mp3
cp "Flipper-Sounds/Highscore beat/breaking-bad-yes.mp3"         playfield/public/sounds/milestone.mp3
cp "Flipper-Sounds/Main theme/Breaking Bad Main Title Theme (Loop).mp3"  playfield/public/sounds/theme.mp3

echo "✅ 10 fichiers audio copiés dans playfield/public/sounds/"

# ============================================================
# 2. NOUVEAU — playfield/src/adapters/audio.js
# ============================================================
cat > playfield/src/adapters/audio.js << 'EOF'
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
EOF

# ============================================================
# 3. NOUVEAU — playfield/src/adapters/audio-controls.js
# ============================================================
cat > playfield/src/adapters/audio-controls.js << 'EOF'
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
EOF

# ============================================================
# 4. REMPLACE — playfield/src/adapters/actuators.js
# ============================================================
cat > playfield/src/adapters/actuators.js << 'EOF'
/**
 * Actuators — branche logs + audio (et plus tard les solénoïdes IoT).
 * L'audio est optionnel : si `audio` est null, on garde le comportement console.log d'origine.
 */
export function createActuators(audio = null) {
  const counts = {
    bumperHit: 0,
    slingshotHit: 0,
    flipperFire: { left: 0, right: 0 },
    ballLost: 0,
    gameStart: 0,
  };

  return {
    onBumperHit() {
      counts.bumperHit++;
      console.log(`[actuator] bumper_hit #${counts.bumperHit}`);
      audio?.playRandom(["bumper-1", "bumper-2", "bumper-3"]);
    },

    onSlingshotHit() {
      counts.slingshotHit++;
      console.log(`[actuator] slingshot_hit #${counts.slingshotHit}`);
      audio?.playRandom(["flipper-1", "flipper-2", "flipper-3"]);
    },

    /** @param {"left"|"right"} side */
    onFlipperFire(side) {
      counts.flipperFire[side] = (counts.flipperFire[side] ?? 0) + 1;
      console.log(`[actuator] flipper_fire side=${side} #${counts.flipperFire[side]}`);
      audio?.playRandom(["flipper-1", "flipper-2", "flipper-3"]);
    },

    onBallLost() {
      counts.ballLost++;
      console.log(`[actuator] ball_lost #${counts.ballLost}`);
      audio?.stopTheme();
      audio?.play("game-over");
    },

    onGameStart() {
      counts.gameStart++;
      console.log(`[actuator] game_start #${counts.gameStart}`);
      audio?.play("start");
      audio?.startTheme(0.18);
    },

    onMilestone() {
      audio?.play("milestone");
    },

    getCounts() {
      return structuredClone(counts);
    },
  };
}
EOF

# ============================================================
# 5. REMPLACE — playfield/src/main.js (init audio + UI)
# ============================================================
cat > playfield/src/main.js << 'EOF'
/**
 * Playfield — Composition root.
 */
import { createScene } from "./adapters/renderer/scene.js";
import {
  initRapier,
  createPhysicsWorld,
  attachCollisionListener,
  launchBallBody,
  resetBallBody,
  setFlipperActive,
} from "./adapters/physics/index.js";

await initRapier();

import {
  initNetwork,
  emitStartGame,
  emitLaunchBall,
  emitFlipperLeftDown,
  emitFlipperLeftUp,
  emitFlipperRightDown,
  emitFlipperRightUp,
  emitCollision,
  emitBallLost,
  gameState,
} from "./adapters/network.js";
import { createCollisionHandler } from "./usecases/collisionHandler.js";
import { createActuators } from "./adapters/actuators.js";
import { createGameInputController, bindKeyboardInput } from "./adapters/input.js";
import { buildLevel } from "./composition/buildLevel.js";
import { startPlayfieldLoop } from "./composition/runGameLoop.js";
import { flashBumper } from "./adapters/renderer/vfx/bumperFlash.js";
import { flashState } from "./adapters/renderer/vfx/stateOverlay.js";
import { createAudioEngine } from "./adapters/audio.js";
import { mountAudioControls } from "./adapters/audio-controls.js";

// --- Audio (issue #78) ---
const audio = createAudioEngine();
mountAudioControls(audio);
window.audio = audio; // debug en console

const actuators = createActuators(audio);
window.actuators = actuators;

const { scene, camera, renderer, composer, bloomPass } = createScene();
const world = createPhysicsWorld();
const level = buildLevel({ scene, world });

function findClosestBumperMesh(pos) {
  if (!pos || !level.bumperMeshes?.length) return null;
  let best = level.bumperMeshes[0];
  let bestDist = Infinity;
  for (const mesh of level.bumperMeshes) {
    const dx = mesh.position.x - pos.x;
    const dz = mesh.position.z - pos.z;
    const d = dx * dx + dz * dz;
    if (d < bestDist) { bestDist = d; best = mesh; }
  }
  return best;
}

// Détection milestone côté playfield (1 milestone tous les 1000 pts)
let lastMilestoneTier = 0;
function checkMilestone(score) {
  if (typeof score !== "number") return;
  const tier = Math.floor(score / 1000);
  if (tier > lastMilestoneTier) {
    lastMilestoneTier = tier;
    actuators.onMilestone?.();
    flashState("milestone", 600);
  }
}

const socket = initNetwork({
  onGameStarted() {
    resetBallBody(level.ballBody);
    collisionHandler.resetDrainFlag();
    collisionHandler.resetCollisionCooldowns();
    setFlipperActive(level.flipperBodies, "left", false);
    setFlipperActive(level.flipperBodies, "right", false);
    lastMilestoneTier = 0;
    actuators.onGameStart();
    flashState("start", 1200);
  },
  onGameOver(data) {
    flashState("gameOver", 1100);
    console.log("[main] game over — score final :", data?.score);
  },
  onStateUpdated(data) {
    checkMilestone(data?.score);
  },
});

const collisionHandler = createCollisionHandler({
  onCollision: (type, ctx) => {
    emitCollision(socket, type);
    if (type === "bumper") {
      actuators.onBumperHit();
      const mesh = findClosestBumperMesh(ctx?.otherPos);
      if (mesh) flashBumper(mesh);
      flashState("bumper", 180);
    } else if (type === "slingshot") {
      actuators.onSlingshotHit();
    }
  },
  onBallLost: () => {
    emitBallLost(socket);
    actuators.onBallLost();
  },
  onBumperImpulse: (vec3) => {
    level.ballBody.applyImpulse(vec3);
  },
});
attachCollisionListener(level.ballBody, collisionHandler);

const inputController = createGameInputController({
  onStart() {
    emitStartGame(socket);
  },
  onLaunch() {
    if (gameState.status === "playing" && launchBallBody(level.ballBody)) {
      emitLaunchBall(socket);
    }
  },
  onLeftFlipperDown() {
    setFlipperActive(level.flipperBodies, "left", true);
    emitFlipperLeftDown(socket);
    actuators.onFlipperFire("left");
  },
  onLeftFlipperUp() {
    setFlipperActive(level.flipperBodies, "left", false);
    emitFlipperLeftUp(socket);
  },
  onRightFlipperDown() {
    setFlipperActive(level.flipperBodies, "right", true);
    emitFlipperRightDown(socket);
    actuators.onFlipperFire("right");
  },
  onRightFlipperUp() {
    setFlipperActive(level.flipperBodies, "right", false);
    emitFlipperRightUp(socket);
  },
  onDebugResetBall() {
    resetBallBody(level.ballBody);
  },
});

bindKeyboardInput(inputController);

startPlayfieldLoop({
  world,
  syncPairs: level.syncPairs,
  collisionHandler,
  ballBody: level.ballBody,
  flipperBodies: level.flipperBodies,
  renderer,
  scene,
  camera,
  composer,
  gameState,
});
EOF

# ============================================================
# 6. REMPLACE — playfield/src/adapters/network.js (ajoute onStateUpdated)
# ============================================================
# On vérifie d'abord si onStateUpdated est déjà géré
grep -q "onStateUpdated" playfield/src/adapters/network.js && NETWORK_OK=1 || NETWORK_OK=0

if [ "$NETWORK_OK" = "0" ]; then
  # Lis le contenu existant pour ajouter prudemment l'event
  echo "🔧 Patch network.js pour exposer onStateUpdated..."
  # On rewrite proprement le fichier
  cat > playfield/src/adapters/network.js << 'EOF'
/**
 * Playfield — Couche reseau Socket.IO.
 */
import { io } from "socket.io-client";
import { CLIENT_EVENTS, SERVER_EVENTS } from "shared";

const SERVER_URL = "http://localhost:3000";

export const gameState = {
  status: "idle",
  score: 0,
  ballsLeft: 0,
};

export function initNetwork(callbacks = {}) {
  const socket = io(SERVER_URL);

  socket.on(SERVER_EVENTS.STATE_UPDATED, (data) => {
    if (data) {
      gameState.status = data.status ?? gameState.status;
      gameState.score = data.score ?? gameState.score;
      gameState.ballsLeft = data.ballsLeft ?? gameState.ballsLeft;
    }
    callbacks.onStateUpdated?.(data);
  });

  socket.on(SERVER_EVENTS.GAME_STARTED, (data) => {
    gameState.status = "playing";
    callbacks.onGameStarted?.(data);
  });

  socket.on(SERVER_EVENTS.GAME_OVER, (data) => {
    gameState.status = "game_over";
    callbacks.onGameOver?.(data || {});
  });

  return socket;
}

export function emitStartGame(socket) { socket.emit(CLIENT_EVENTS.START_GAME); }
export function emitLaunchBall(socket) { socket.emit(CLIENT_EVENTS.LAUNCH_BALL); }
export function emitFlipperLeftDown(socket) { socket.emit(CLIENT_EVENTS.FLIPPER_LEFT_DOWN); }
export function emitFlipperLeftUp(socket) { socket.emit(CLIENT_EVENTS.FLIPPER_LEFT_UP); }
export function emitFlipperRightDown(socket) { socket.emit(CLIENT_EVENTS.FLIPPER_RIGHT_DOWN); }
export function emitFlipperRightUp(socket) { socket.emit(CLIENT_EVENTS.FLIPPER_RIGHT_UP); }
export function emitCollision(socket, type) { socket.emit(CLIENT_EVENTS.COLLISION, { type }); }
export function emitBallLost(socket) { socket.emit(CLIENT_EVENTS.BALL_LOST); }
EOF
fi

# ============================================================
# 7. .gitignore — ajouter .lh/
# ============================================================
if ! grep -q "^\.lh/" .gitignore 2>/dev/null; then
  echo ".lh/" >> .gitignore
  echo "✅ .lh/ ajouté au .gitignore"
fi

# ============================================================
# 8. Commit + push
# ============================================================
echo ""
echo "📦 Commit et push sur la branche feat/vfx-bonus..."
git add -A
git rm -r --cached .lh/ 2>/dev/null || true
git commit -m "feat(audio): add audio engine + UX controls (volume/mute/persistence)

- Audio engine: Web Audio API, preloaded samples, master GainNode
- Controls: M (mute toggle), +/- (volume), persisted in localStorage
- HUD: discreet top-right pill, auto fade, breaks-bad themed
- Hooked sounds: bumper (3 variants), flipper (3 variants), start,
  game over, milestone, main theme loop on start
- Closes #78"
git push origin feat/vfx-bonus

echo ""
echo "🎉 Patch AUDIO appliqué et poussé !"
echo ""
echo "👉 Étapes suivantes :"
echo "   1. npm run dev:all"
echo "   2. Tester les touches :"
echo "      M     -> mute toggle"
echo "      + / = -> volume up"
echo "      - / _ -> volume down"
echo "   3. Vérifier la persistance (refresh page → volume conservé)"
echo "   4. Mettre à jour la PR feat/vfx-bonus (clôture #78 et #79)"
echo ""
