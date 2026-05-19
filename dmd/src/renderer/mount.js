/**
 * DMD — Montage du DOM (structure statique uniquement).
 */
export function mountDmdShell() {
  const app = document.createElement("main");
  app.className = "dmd";
  app.innerHTML = `
    <section class="dmd__screen" aria-live="polite">
      <span class="dmd__led" aria-hidden="true"></span>
      <div class="dmd__meta">
        <span id="socketStatus">socket: connecting...</span>
        <span id="stateStatus">state: idle</span>
      </div>
      <canvas id="dmdCanvas" class="dmd__canvas" aria-label="Dot matrix display"></canvas>
    </section>
    <p class="dmd__caption">DOT MATRIX DISPLAY · RT-128X32</p>
  `;

  document.body.append(app);

  return {
    socketStatus: document.getElementById("socketStatus"),
    stateStatus: document.getElementById("stateStatus"),
    canvas: document.getElementById("dmdCanvas"),
  };
}
