/**
 * Animation flash sur impact bumper : boost emissif + pulse de scale.
 */
import * as THREE from "three";
import { COLORS } from "../../../domain/theme.js";

const DURATION_MS = 220;
const PEAK_SCALE = 1.18;
const PEAK_INTENSITY = 4.5;

export function flashBumper(mesh, color = COLORS.primary) {
  if (!mesh?.material) return;
  const mat = mesh.material;
  const baseEmissive = mat.emissive ? mat.emissive.getHex() : 0x000000;
  const baseIntensity = mat.emissiveIntensity ?? 1;
  const baseScale = mesh.scale.x;

  mat.emissive = new THREE.Color(color);
  mat.emissiveIntensity = PEAK_INTENSITY;

  const start = performance.now();
  function step() {
    const t = (performance.now() - start) / DURATION_MS;
    if (t >= 1) {
      mat.emissive = new THREE.Color(baseEmissive);
      mat.emissiveIntensity = baseIntensity;
      mesh.scale.setScalar(baseScale);
      return;
    }
    const eased = 1 - Math.pow(1 - t, 3);
    mesh.scale.setScalar(baseScale + (PEAK_SCALE - baseScale) * (1 - eased));
    mat.emissiveIntensity = baseIntensity + (PEAK_INTENSITY - baseIntensity) * (1 - eased);
    requestAnimationFrame(step);
  }
  step();
}
