/**
 * DMD — Composition root.
 */
import "./styles.css";
import { mountDmdShell } from "./renderer/mount.js";
import { createDotMatrixRenderer } from "./renderer/dotMatrix.js";
import { wireDmdNetwork } from "./composition/wireDmdNetwork.js";
import { initDmdVfx } from "./vfx.js";

const refs = mountDmdShell();
const renderer = createDotMatrixRenderer(refs.canvas);

initDmdVfx();
wireDmdNetwork({ refs, renderer });
renderer.init();
