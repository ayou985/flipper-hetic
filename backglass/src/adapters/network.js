/**
 * Backglass — Couche reseau Socket.IO.
 */
import { io } from "socket.io-client";
import { SERVER_EVENTS } from "shared";

const SERVER_URL = "http://localhost:3000";

export function initNetwork(callbacks = {}) {
  const socket = io(SERVER_URL);

  socket.on(SERVER_EVENTS.STATE_UPDATED, (data) => {
    callbacks.onStateUpdated?.(data);
  });
  socket.on(SERVER_EVENTS.GAME_STARTED, () => {
    callbacks.onGameStarted?.();
  });
  socket.on(SERVER_EVENTS.GAME_OVER, () => {
    callbacks.onGameOver?.();
  });

  return socket;
}
